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
    private let geocodeService: GeocodeService
    private let locationManager: LocationManager
    private let disposeBag = DisposeBag()

    init(estateRepository: EstateRepository, clusteringEngine: ClusteringEngine<EstateDTO>, geocodeService: GeocodeService = .shared, locationManager: LocationManager = .shared) {
        self.estateRepository = estateRepository
        self.clusteringEngine = clusteringEngine
        self.geocodeService = geocodeService
        self.locationManager = locationManager
    }
    
    struct Input {
        let viewDidLoad: Observable<Void>
        let mapRegionChanged: Observable<(region: MKCoordinateRegion, zoom: Int)>
        let searchLocationSelected: Observable<CLLocationCoordinate2D>
        let currentLocationTapped: Observable<Void>
    }

    struct Output {
        let annotations: Driver<[MKAnnotation]>
        let error: Driver<String>
        let moveToLocation: Driver<MKCoordinateRegion>
        let locationTitle: Driver<String>
        let initialRegion: Driver<MKCoordinateRegion>
        let showLocationPermissionDeniedAlert: Driver<Void>
    }
    
    func transform(input: Input) -> Output {
        let annotationsRelay = PublishRelay<[MKAnnotation]>()
        let errorRelay = PublishRelay<String>()
        let moveToLocationRelay = PublishRelay<MKCoordinateRegion>()
        let locationTitleRelay = PublishRelay<String>()
        let initialRegionRelay = PublishRelay<MKCoordinateRegion>()
        let showLocationPermissionDeniedAlertRelay = PublishRelay<Void>()

        input.viewDidLoad
            .withUnretained(self)
            .do(onNext: { owner, _ in
                owner.locationManager.requestWhenInUseAuthorization()
            })
            .flatMapLatest { owner, _ in
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

        locationManager.currentLocation
            .take(1)
            .map { location in
                Logger.location.notice("Moving to current location - latitude: \(location.coordinate.latitude, privacy: .public), longitude: \(location.coordinate.longitude, privacy: .public)")
                return MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.0055, longitudeDelta: 0.0055)
                )
            }
            .bind(to: initialRegionRelay)
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

                let clusters = owner.clusteringEngine.getClusters(bbox: bbox, zoom: zoom)

                let annotations: [MKAnnotation] = clusters.map { cluster in
                    EstateClusterAnnotation(cluster: cluster)
                }

                annotationsRelay.accept(annotations)

                owner.geocodeService.reverseGeocodeForLocationTitle(
                    latitude: region.center.latitude,
                    longitude: region.center.longitude
                )
                .asObservable()
                .observe(on: MainScheduler.instance)
                .subscribe(
                    onNext: { locationTitle in
                        locationTitleRelay.accept(locationTitle)
                    },
                    onError: { _ in
                        locationTitleRelay.accept("위치 확인 중...")
                    }
                )
                .disposed(by: owner.disposeBag)
            })
            .disposed(by: disposeBag)

        input.searchLocationSelected
            .map { coordinate in
                Logger.map.notice("Moving map to searched location - center: (\(coordinate.latitude, privacy: .public), \(coordinate.longitude, privacy: .public))")
                return MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            .bind(to: moveToLocationRelay)
            .disposed(by: disposeBag)

        input.currentLocationTapped
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                if owner.locationManager.isAuthorized() {
                    owner.locationManager.requestCurrentLocation()
                    owner.locationManager.currentLocation
                        .take(1)
                        .map { location in
                            Logger.map.notice("Moving to current location - center: (\(location.coordinate.latitude, privacy: .public), \(location.coordinate.longitude, privacy: .public))")
                            return MKCoordinateRegion(
                                center: location.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.0055, longitudeDelta: 0.0055)
                            )
                        }
                        .timeout(.seconds(5), scheduler: MainScheduler.instance)
                        .catch { error in
                            Logger.location.error("Failed to get current location - \(error.localizedDescription)")
                            errorRelay.accept("현재 위치를 가져올 수 없습니다")
                            return .empty()
                        }
                        .bind(to: moveToLocationRelay)
                        .disposed(by: owner.disposeBag)
                } else {
                    Logger.location.notice("Location permission denied or not determined")
                    showLocationPermissionDeniedAlertRelay.accept(())
                }
            })
            .disposed(by: disposeBag)

        return Output(
            annotations: annotationsRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorJustReturn: ""),
            moveToLocation: moveToLocationRelay.asDriver(onErrorDriveWith: .empty()),
            locationTitle: locationTitleRelay.asDriver(onErrorJustReturn: "위치 확인 중..."),
            initialRegion: initialRegionRelay.asDriver(onErrorDriveWith: .empty()),
            showLocationPermissionDeniedAlert: showLocationPermissionDeniedAlertRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
