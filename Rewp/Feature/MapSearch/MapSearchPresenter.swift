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
    private let amenitySearchService: AmenitySearchService
    private let disposeBag = DisposeBag()

    private var isEstatesLoaded = false
    private var isLoadingInitialEstates = false
    private var pendingRegionData: (region: MKCoordinateRegion, zoom: Int)?
    private var currentFilter = EstateFilter()

    init(estateRepository: EstateRepository, clusteringEngine: ClusteringEngine<EstateDTO>, geocodeService: GeocodeService = .shared, locationManager: LocationManager = .shared, amenitySearchService: AmenitySearchService = .shared) {
        self.estateRepository = estateRepository
        self.clusteringEngine = clusteringEngine
        self.geocodeService = geocodeService
        self.locationManager = locationManager
        self.amenitySearchService = amenitySearchService
    }
    
    struct Input {
        let viewDidLoad: Observable<Void>
        let mapRegionChanged: Observable<(region: MKCoordinateRegion, zoom: Int)>
        let searchLocationSelected: Observable<CLLocationCoordinate2D>
        let currentLocationTapped: Observable<Void>
        let annotationSelected: Observable<(annotation: MKAnnotation, zoom: Int)>
        let estateCardTapped: Observable<String>
        let mapTapped: Observable<Void>
        let areaFilterTapped: Observable<Void>
        let areaFilterApplied: Observable<(min: Int, max: Int)>
        let areaFilterReset: Observable<Void>
    }

    struct Output {
        let annotations: Driver<[MKAnnotation]>
        let error: Driver<String>
        let moveToLocation: Driver<MKCoordinateRegion>
        let locationTitle: Driver<String>
        let initialRegion: Driver<MKCoordinateRegion>
        let showLocationPermissionDeniedAlert: Driver<Void>
        let showEstateCards: Driver<[EstateDTO]>
        let navigateToDetail: Driver<String>
        let zoomToCluster: Driver<MKCoordinateRegion>
        let hideEstateCards: Driver<Void>
        let isLoadingInitialEstates: Driver<Bool>
        let showAreaFilter: Driver<(min: Int, max: Int)>
    }
    
    func transform(input: Input) -> Output {
        let annotationsRelay = PublishRelay<[MKAnnotation]>()
        let errorRelay = PublishRelay<String>()
        let moveToLocationRelay = PublishRelay<MKCoordinateRegion>()
        let locationTitleRelay = PublishRelay<String>()
        let initialRegionRelay = PublishRelay<MKCoordinateRegion>()
        let showLocationPermissionDeniedAlertRelay = PublishRelay<Void>()
        let showEstateCardsRelay = PublishRelay<[EstateDTO]>()
        let navigateToDetailRelay = PublishRelay<String>()
        let zoomToClusterRelay = PublishRelay<MKCoordinateRegion>()
        let hideEstateCardsRelay = PublishRelay<Void>()
        let isLoadingInitialEstatesRelay = PublishRelay<Bool>()
        let showAreaFilterRelay = PublishRelay<(min: Int, max: Int)>()

        input.viewDidLoad
            .withUnretained(self)
            .do(onNext: { owner, _ in
                owner.locationManager.requestWhenInUseAuthorization()
                Logger.map.notice("MapSearch initialized - loading nationwide estates")
            })
            .flatMapLatest { owner, _ -> Observable<[EstateDTO]> in
                guard !owner.isEstatesLoaded && !owner.isLoadingInitialEstates else {
                    Logger.map.debug("Estates already loaded or loading")
                    return .empty()
                }

                owner.isLoadingInitialEstates = true
                isLoadingInitialEstatesRelay.accept(true)

                Logger.map.notice("Fetching nationwide estates - center: (36.5, 127.5), radius: 500000m")

                return owner.estateRepository
                    .fetchEstatesByLocation(
                        longitude: 127.5,
                        latitude: 36.5,
                        maxDistance: 500000,
                        category: nil
                    )
                    .asObservable()
                    .do(
                        onNext: { estates in
                            owner.isLoadingInitialEstates = false
                            owner.isEstatesLoaded = true
                            isLoadingInitialEstatesRelay.accept(false)

                            Logger.map.notice("Nationwide estates loaded - count: \(estates.count)")
                            owner.clusteringEngine.load(points: estates)
                            Logger.map.notice("Clustering tree built successfully")

                            if let regionData = owner.pendingRegionData {
                                let region = regionData.region
                                let zoom = regionData.zoom
                                let bbox = (
                                    minLon: region.center.longitude - region.span.longitudeDelta / 2,
                                    minLat: region.center.latitude - region.span.latitudeDelta / 2,
                                    maxLon: region.center.longitude + region.span.longitudeDelta / 2,
                                    maxLat: region.center.latitude + region.span.latitudeDelta / 2
                                )

                                let clusters = owner.clusteringEngine.getClusters(bbox: bbox, zoom: zoom)
                                let annotations: [MKAnnotation] = clusters.map { cluster in
                                    EstateClusterAnnotation(cluster: cluster)
                                }
                                annotationsRelay.accept(annotations)
                                Logger.map.notice("Initial clustering complete - found \(annotations.count) annotations")
                            }
                        },
                        onError: { error in
                            owner.isLoadingInitialEstates = false
                            isLoadingInitialEstatesRelay.accept(false)
                            Logger.map.error("Failed to load nationwide estates - \(error.localizedDescription)")
                        }
                    )
                    .catch { error in
                        errorRelay.accept("전국 매물 정보를 불러올 수 없습니다")
                        return .empty()
                    }
            }
            .subscribe()
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
                owner.pendingRegionData = regionData

                guard owner.isEstatesLoaded else {
                    Logger.map.debug("Estates not loaded yet - skipping clustering")
                    return
                }

                let region = regionData.region
                let zoom = regionData.zoom
                let bbox = (
                    minLon: region.center.longitude - region.span.longitudeDelta / 2,
                    minLat: region.center.latitude - region.span.latitudeDelta / 2,
                    maxLon: region.center.longitude + region.span.longitudeDelta / 2,
                    maxLat: region.center.latitude + region.span.latitudeDelta / 2
                )

                Logger.map.debug("Fast clustering query - zoom: \(zoom, privacy: .public) (NO network, NO tree rebuild)")

                var clusters = owner.clusteringEngine.getClusters(bbox: bbox, zoom: zoom)

                if owner.currentFilter.isActive {
                    clusters = clusters.compactMap { cluster -> Cluster<EstateDTO>? in
                        let filteredPoints = cluster.points.filter { owner.currentFilter.matches($0) }
                        guard !filteredPoints.isEmpty else { return nil }
                        return Cluster(
                            id: cluster.id,
                            latitude: cluster.latitude,
                            longitude: cluster.longitude,
                            points: filteredPoints,
                            actualCount: filteredPoints.count,
                            amenityInfo: cluster.amenityInfo
                        )
                    }
                }

                if zoom >= 13 && zoom < 16 {
                    let mapCenter = region.center
                    clusters = Array(clusters
                        .sorted { cluster1, cluster2 in
                            let dist1 = pow(cluster1.latitude - mapCenter.latitude, 2) + pow(cluster1.longitude - mapCenter.longitude, 2)
                            let dist2 = pow(cluster2.latitude - mapCenter.latitude, 2) + pow(cluster2.longitude - mapCenter.longitude, 2)
                            return dist1 < dist2
                        }
                        .prefix(20)
                    )

                    let amenitySearches: [Single<(clusterId: String, amenityInfo: AmenityInfo)>] = clusters.map { cluster in
                        let radiusInMeters = Int(cluster.radiusInMeters(zoom: zoom, radius: 120, extent: 256))
                        return owner.amenitySearchService
                            .searchAmenities(latitude: cluster.latitude, longitude: cluster.longitude, radius: radiusInMeters)
                            .map { amenityInfo in
                                return (clusterId: cluster.id, amenityInfo: amenityInfo)
                            }
                    }

                    if !amenitySearches.isEmpty {
                        Single.zip(amenitySearches)
                            .asObservable()
                            .observe(on: MainScheduler.instance)
                            .subscribe(
                                onNext: { results in
                                    for (index, result) in results.enumerated() {
                                        if index < clusters.count {
                                            clusters[index].amenityInfo = result.amenityInfo
                                        }
                                    }

                                    let annotations: [MKAnnotation] = clusters.map { cluster in
                                        EstateClusterAnnotation(cluster: cluster)
                                    }
                                    annotationsRelay.accept(annotations)
                                },
                                onError: { _ in
                                    let annotations: [MKAnnotation] = clusters.map { cluster in
                                        EstateClusterAnnotation(cluster: cluster)
                                    }
                                    annotationsRelay.accept(annotations)
                                }
                            )
                            .disposed(by: owner.disposeBag)
                    } else {
                        let annotations: [MKAnnotation] = clusters.map { cluster in
                            EstateClusterAnnotation(cluster: cluster)
                        }
                        annotationsRelay.accept(annotations)
                    }
                } else {
                    let annotations: [MKAnnotation] = clusters.map { cluster in
                        EstateClusterAnnotation(cluster: cluster)
                    }
                    annotationsRelay.accept(annotations)
                }

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

        input.annotationSelected
            .withUnretained(self)
            .subscribe(onNext: { owner, data in
                let annotation = data.annotation
                let zoom = data.zoom

                if let clusterAnnotation = annotation as? EstateClusterAnnotation {
                    Logger.map.notice("Annotation selected - zoom: \(zoom, privacy: .public), count: \(clusterAnnotation.count, privacy: .public)")

                    clusterAnnotation.cluster.points.enumerated().forEach { index, estate in
                    }

                    if zoom >= 16 {
                        if clusterAnnotation.count > 1 {
                            showEstateCardsRelay.accept(clusterAnnotation.cluster.points)
                        } else if clusterAnnotation.count == 1 {
                            if let estate = clusterAnnotation.cluster.points.first {
                                navigateToDetailRelay.accept(estate.estate_id)
                            }
                        }
                    } else {
                        let targetZoom = zoom + 1
                        let newSpan = MKCoordinateSpan(
                            latitudeDelta: 360.0 / pow(2.0, Double(targetZoom)),
                            longitudeDelta: 360.0 / pow(2.0, Double(targetZoom))
                        )
                        let newRegion = MKCoordinateRegion(
                            center: clusterAnnotation.coordinate,
                            span: newSpan
                        )
                        zoomToClusterRelay.accept(newRegion)
                    }
                } else if let estateAnnotation = annotation as? EstateAnnotation {
                    Logger.map.notice("Single estate annotation selected - id: \(estateAnnotation.estate.estate_id, privacy: .public)")
                    navigateToDetailRelay.accept(estateAnnotation.estate.estate_id)
                }
            })
            .disposed(by: disposeBag)

        input.estateCardTapped
            .bind(to: navigateToDetailRelay)
            .disposed(by: disposeBag)

        input.mapTapped
            .map { _ in () }
            .bind(to: hideEstateCardsRelay)
            .disposed(by: disposeBag)

        input.areaFilterTapped
            .withUnretained(self)
            .map { owner, _ in owner.currentFilter.areaRange ?? (min: 0, max: 100) }
            .bind(to: showAreaFilterRelay)
            .disposed(by: disposeBag)

        input.areaFilterApplied
            .withUnretained(self)
            .subscribe(onNext: { owner, range in
                owner.currentFilter.areaRange = range

                if let regionData = owner.pendingRegionData {
                    let region = regionData.region
                    let zoom = regionData.zoom
                    let bbox = (
                        minLon: region.center.longitude - region.span.longitudeDelta / 2,
                        minLat: region.center.latitude - region.span.latitudeDelta / 2,
                        maxLon: region.center.longitude + region.span.longitudeDelta / 2,
                        maxLat: region.center.latitude + region.span.latitudeDelta / 2
                    )

                    let clusters = owner.clusteringEngine.getClusters(bbox: bbox, zoom: zoom)

                    let filteredClusters = clusters.compactMap { cluster -> Cluster<EstateDTO>? in
                        let filteredPoints = cluster.points.filter { owner.currentFilter.matches($0) }
                        guard !filteredPoints.isEmpty else { return nil }
                        return Cluster(
                            id: cluster.id,
                            latitude: cluster.latitude,
                            longitude: cluster.longitude,
                            points: filteredPoints,
                            actualCount: filteredPoints.count,
                            amenityInfo: cluster.amenityInfo
                        )
                    }

                    let annotations: [MKAnnotation] = filteredClusters.map { cluster in
                        EstateClusterAnnotation(cluster: cluster)
                    }
                    annotationsRelay.accept(annotations)
                }
            })
            .disposed(by: disposeBag)

        input.areaFilterReset
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.currentFilter.areaRange = nil

                if let regionData = owner.pendingRegionData {
                    let region = regionData.region
                    let zoom = regionData.zoom
                    let bbox = (
                        minLon: region.center.longitude - region.span.longitudeDelta / 2,
                        minLat: region.center.latitude - region.span.latitudeDelta / 2,
                        maxLon: region.center.longitude + region.span.longitudeDelta / 2,
                        maxLat: region.center.latitude + region.span.latitudeDelta / 2
                    )

                    let clusters = owner.clusteringEngine.getClusters(bbox: bbox, zoom: zoom)

                    let filteredClusters = clusters.compactMap { cluster -> Cluster<EstateDTO>? in
                        let filteredPoints = cluster.points.filter { owner.currentFilter.matches($0) }
                        guard !filteredPoints.isEmpty else { return nil }
                        return Cluster(
                            id: cluster.id,
                            latitude: cluster.latitude,
                            longitude: cluster.longitude,
                            points: filteredPoints,
                            actualCount: filteredPoints.count,
                            amenityInfo: cluster.amenityInfo
                        )
                    }

                    let annotations: [MKAnnotation] = filteredClusters.map { cluster in
                        EstateClusterAnnotation(cluster: cluster)
                    }
                    annotationsRelay.accept(annotations)
                }
            })
            .disposed(by: disposeBag)

        return Output(
            annotations: annotationsRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorJustReturn: ""),
            moveToLocation: moveToLocationRelay.asDriver(onErrorDriveWith: .empty()),
            locationTitle: locationTitleRelay.asDriver(onErrorJustReturn: "위치 확인 중..."),
            initialRegion: initialRegionRelay.asDriver(onErrorDriveWith: .empty()),
            showLocationPermissionDeniedAlert: showLocationPermissionDeniedAlertRelay.asDriver(onErrorDriveWith: .empty()),
            showEstateCards: showEstateCardsRelay.asDriver(onErrorDriveWith: .empty()),
            navigateToDetail: navigateToDetailRelay.asDriver(onErrorDriveWith: .empty()),
            zoomToCluster: zoomToClusterRelay.asDriver(onErrorDriveWith: .empty()),
            hideEstateCards: hideEstateCardsRelay.asDriver(onErrorDriveWith: .empty()),
            isLoadingInitialEstates: isLoadingInitialEstatesRelay.asDriver(onErrorJustReturn: false),
            showAreaFilter: showAreaFilterRelay.asDriver(onErrorJustReturn: (min: 0, max: 100))
        )
    }
}
