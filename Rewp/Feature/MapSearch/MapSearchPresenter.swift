//
//  MapSearchPresenter.swift
//  Rewp
//
//  Created by 금가경 on 01/08/26.
//

import Foundation
import MapKit
import RxSwift
import RxCocoa
import OSLog

final class MapSearchPresenter {
    private let estateRepository: EstateRepository
    private let clusteringEngine: ClusteringEngine<EstateDTO>
    private let disposeBag = DisposeBag()
    
    init(estateRepository: EstateRepository, clusteringEngine: ClusteringEngine<EstateDTO>) {
        self.estateRepository = estateRepository
        self.clusteringEngine = clusteringEngine
    }
    
    struct Input {
        let viewDidLoad: Observable<Void>
        let mapRegionChanged: Observable<(region: MKCoordinateRegion, zoom: Int)>
    }
    
    struct Output {
        let annotations: Driver<[MKAnnotation]>
        let error: Driver<String>
    }
    
    func transform(input: Input) -> Output {
        let annotationsRelay = PublishRelay<[MKAnnotation]>()
        let errorRelay = PublishRelay<String>()
        
        input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, estates in
                owner.estateRepository.fetchEstatesByLocation(
                    longitude: nil,
                    latitude: nil,
                    maxDistance: nil,
                    category: nil
                )
            }
            .withUnretained(self)
            .subscribe(
                onNext: { owner, estates in
                    owner.clusteringEngine.load(points: estates)
                },
                onError: { error in
                    errorRelay.accept(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
        
        input.mapRegionChanged
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { owner, regionData in
                let region = regionData.region
                let zoom = regionData.zoom
                let bbox = (
                    minLon: region.center.longitude - region.span.longitudeDelta / 2,
                    minLat: region.center.latitude - region.span.latitudeDelta / 2,
                    maxLon: region.center.longitude + region.span.longitudeDelta / 2,
                    maxLat: region.center.latitude + region.span.latitudeDelta / 2
                )

                Logger.map.debug("Map region changed - zoom: \(zoom, privacy: .public), center: (\(region.center.latitude, privacy: .public), \(region.center.longitude, privacy: .public)), bbox: (\(bbox.minLon, privacy: .public), \(bbox.minLat, privacy: .public), \(bbox.maxLon, privacy: .public), \(bbox.maxLat, privacy: .public))")

                let clusterResults = owner.clusteringEngine.getClusters(bbox: bbox, zoom: zoom)

                let annotations: [MKAnnotation] = clusterResults.map { result in
                    switch result {
                    case .single(let estate):
                        if zoom < 16 {
                            let cluster = Cluster(
                                id: "single_\(estate.estate_id)",
                                latitude: estate.latitude,
                                longitude: estate.longitude,
                                points: [estate],
                                expansionZoom: nil,
                                actualCount: 1
                            )
                            return EstateClusterAnnotation(cluster: cluster)
                        } else {
                            return EstateAnnotation(estate: estate)
                        }
                    case .cluster(let cluster):
                        return EstateClusterAnnotation(cluster: cluster)
                    }
                }

                annotationsRelay.accept(annotations)
            })
            .disposed(by: disposeBag)
        
        return Output(
            annotations: annotationsRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorJustReturn: "")
        )
    }
}
