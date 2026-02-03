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
    private let sidoBoundaryService: SidoBoundaryService
    private let disposeBag = DisposeBag()

    private var isEstatesLoaded = false
    private var isLoadingInitialEstates = false
    private var pendingRegionData: (region: MKCoordinateRegion, zoom: Int)?
    private var currentFilter = EstateFilter()
    private var loadedEstates: [EstateDTO] = []
    private var cachedSidoCounts: [String: (sido: Sido, count: Int)] = [:]

    static let sidoModeZoomThreshold = 10

    init(estateRepository: EstateRepository, clusteringEngine: ClusteringEngine<EstateDTO>, geocodeService: GeocodeService = .shared, locationManager: LocationManager = .shared, amenitySearchService: AmenitySearchService = .shared, sidoBoundaryService: SidoBoundaryService = .shared) {
        self.estateRepository = estateRepository
        self.clusteringEngine = clusteringEngine
        self.geocodeService = geocodeService
        self.locationManager = locationManager
        self.amenitySearchService = amenitySearchService
        self.sidoBoundaryService = sidoBoundaryService
    }
    
    struct Input {
        let viewDidLoad: Observable<Void>
        let mapRegionChanged: Observable<(region: MKCoordinateRegion, zoom: Int)>
        let searchLocationSelected: Observable<CLLocationCoordinate2D>
        let currentLocationTapped: Observable<Void>
        let annotationSelected: Observable<(annotation: MKAnnotation, zoom: Int)>
        let sidoAnnotationSelected: Observable<SidoAnnotation>
        let estateCardTapped: Observable<String>
        let mapTapped: Observable<Void>
        let areaFilterTapped: Observable<Void>
        let areaFilterApplied: Observable<(min: Int, max: Int)>
        let areaFilterReset: Observable<Void>
        let depositFilterTapped: Observable<Void>
        let depositFilterApplied: Observable<(min: Int, max: Int)>
        let depositFilterReset: Observable<Void>
        let rentFilterTapped: Observable<Void>
        let rentFilterApplied: Observable<(min: Int, max: Int)>
        let rentFilterReset: Observable<Void>
    }

    struct Output {
        let annotations: Driver<[MKAnnotation]>
        let sidoAnnotations: Driver<[SidoAnnotation]>
        let showSidoMode: Driver<Bool>
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
        let showDepositFilter: Driver<(min: Int, max: Int)>
        let showRentFilter: Driver<(min: Int, max: Int)>
        let updateAreaFilterButton: Driver<Bool>
        let updateDepositFilterButton: Driver<Bool>
        let updateRentFilterButton: Driver<Bool>
    }
    
    func transform(input: Input) -> Output {
        let annotationsRelay = PublishRelay<[MKAnnotation]>()
        let sidoAnnotationsRelay = PublishRelay<[SidoAnnotation]>()
        let showSidoModeRelay = PublishRelay<Bool>()
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
        let showDepositFilterRelay = PublishRelay<(min: Int, max: Int)>()
        let showRentFilterRelay = PublishRelay<(min: Int, max: Int)>()
        let updateAreaFilterButtonRelay = PublishRelay<Bool>()
        let updateDepositFilterButtonRelay = PublishRelay<Bool>()
        let updateRentFilterButtonRelay = PublishRelay<Bool>()

        input.viewDidLoad
            .withUnretained(self)
            .do(onNext: { _, _ in
                Logger.map.notice("MapSearch initialized - loading nationwide estates")
            })
            .filter { owner, _ in
                guard !owner.isEstatesLoaded && !owner.isLoadingInitialEstates else {
                    Logger.map.debug("Estates already loaded or loading")
                    return false
                }
                return true
            }
            .do(onNext: { owner, _ in
                owner.isLoadingInitialEstates = true
                isLoadingInitialEstatesRelay.accept(true)
                Logger.map.notice("Using MockData - 5000 estates with wide distribution")
            })
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .map { _, _ in
                MockDataGenerator.generateEstates(count: 5000)
            }
            .withUnretained(self)
            .do(onNext: { owner, estates in
                Logger.map.notice("Nationwide estates loaded - count: \(estates.count)")
                owner.loadedEstates = estates
            })
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { owner, _ in
                    owner.isLoadingInitialEstates = false
                    owner.isEstatesLoaded = true
                    isLoadingInitialEstatesRelay.accept(false)

                    Observable.just(owner.loadedEstates)
                        .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                        .map { estates in
                            owner.clusteringEngine.loadInitial(points: estates)
                            return ()
                        }
                        .observe(on: MainScheduler.instance)
                        .subscribe(onNext: { _ in
                            Logger.map.notice("Initial clustering tree built (zoom 16-17 only)")

                            if let regionData = owner.pendingRegionData {
                                let region = regionData.region
                                let zoom = regionData.zoom
                                let bbox = (
                                    minLon: region.center.longitude - region.span.longitudeDelta / 2,
                                    minLat: region.center.latitude - region.span.latitudeDelta / 2,
                                    maxLon: region.center.longitude + region.span.longitudeDelta / 2,
                                    maxLat: region.center.latitude + region.span.latitudeDelta / 2
                                )

                                if owner.clusteringEngine.isZoomReady(zoom) {
                                    let clusters = owner.clusteringEngine.getClusters(bbox: bbox, zoom: zoom)
                                    let annotations: [MKAnnotation] = clusters.map { EstateClusterAnnotation(cluster: $0) }
                                    annotationsRelay.accept(annotations)
                                    Logger.map.notice("Initial clustering complete - found \(annotations.count) annotations")
                                } else {
                                    owner.clusteringEngine.buildTreeLazyIfNeeded(zoom: zoom) {
                                        let clusters = owner.clusteringEngine.getClusters(bbox: bbox, zoom: zoom)
                                        let annotations: [MKAnnotation] = clusters.map { EstateClusterAnnotation(cluster: $0) }
                                        annotationsRelay.accept(annotations)
                                        Logger.map.notice("Initial lazy clustering complete - found \(annotations.count) annotations")
                                    }
                                }
                            }
                        })
                        .disposed(by: owner.disposeBag)
                },
                onError: { error in
                    isLoadingInitialEstatesRelay.accept(false)
                    Logger.map.error("Failed to load nationwide estates - \(error.localizedDescription)")
                    errorRelay.accept("전국 매물 정보를 불러올 수 없습니다")
                }
            )
            .disposed(by: disposeBag)

        input.viewDidLoad
            .take(1)
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.geocodeService.reverseGeocodeForLocationTitle(
                    latitude: LocationManager.defaultCoordinate.latitude,
                    longitude: LocationManager.defaultCoordinate.longitude
                )
                .asObservable()
                .catch { error in
                    Logger.location.error("Initial geocode failed, using default address")
                    return .just(LocationManager.defaultAddress)
                }
            }
            .bind(to: locationTitleRelay)
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

        initialRegionRelay
            .asObservable()
            .withUnretained(self)
            .flatMap { owner, region in
                owner.geocodeService.reverseGeocodeForLocationTitle(
                    latitude: region.center.latitude,
                    longitude: region.center.longitude
                )
                .asObservable()
                .catch { error in
                    Logger.location.error("Initial geocode failed, using default address")
                    return .just(LocationManager.defaultAddress)
                }
            }
            .bind(to: locationTitleRelay)
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
                let isSidoMode = zoom <= Self.sidoModeZoomThreshold
                showSidoModeRelay.accept(isSidoMode)

                Logger.map.notice("맵 이동 - zoom: \(zoom, privacy: .public), sidoMode: \(isSidoMode, privacy: .public), center: (\(region.center.latitude, privacy: .public), \(region.center.longitude, privacy: .public))")

                if isSidoMode {
                    if owner.cachedSidoCounts.isEmpty {
                        owner.cachedSidoCounts = owner.sidoBoundaryService.countEstates(estates: owner.loadedEstates)
                    }

                    let sidoAnnotations = owner.cachedSidoCounts.values
                        .filter { $0.count > 0 }
                        .map { SidoAnnotation(sido: $0.sido, estateCount: $0.count) }

                    sidoAnnotationsRelay.accept(sidoAnnotations)
                    annotationsRelay.accept([])

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
                    return
                }

                sidoAnnotationsRelay.accept([])

                let bbox = (
                    minLon: region.center.longitude - region.span.longitudeDelta / 2,
                    minLat: region.center.latitude - region.span.latitudeDelta / 2,
                    maxLon: region.center.longitude + region.span.longitudeDelta / 2,
                    maxLat: region.center.latitude + region.span.latitudeDelta / 2
                )

                if !owner.clusteringEngine.isZoomReady(zoom) {
                    Logger.map.notice("Zoom \(zoom) not ready - triggering lazy build")
                    owner.clusteringEngine.buildTreeLazyIfNeeded(zoom: zoom) {
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

                        let annotations: [MKAnnotation] = clusters.map { EstateClusterAnnotation(cluster: $0) }
                        annotationsRelay.accept(annotations)
                        Logger.map.notice("Lazy build complete - found \(annotations.count) annotations")
                    }
                    return
                }

                Logger.map.debug("Fast clustering query - zoom: \(zoom, privacy: .public) (NO network, NO tree rebuild)")

                var clusters = owner.clusteringEngine.getClusters(bbox: bbox, zoom: zoom)
                Logger.map.notice("getClusters 결과 - 클러스터 개수: \(clusters.count, privacy: .public)")

                if owner.currentFilter.isActive {
                    let originalCount = clusters.count
                    let originalTotalPoints = clusters.reduce(0) { $0 + $1.actualCount }
                    Logger.mapFilter.notice("필터 활성화 - 필터 적용 전: 클러스터 \(originalCount, privacy: .public)개, 총 매물 \(originalTotalPoints, privacy: .public)개")

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

                    let filteredCount = clusters.count
                    let filteredTotalPoints = clusters.reduce(0) { $0 + $1.actualCount }
                    Logger.mapFilter.notice("필터 적용 후: 클러스터 \(filteredCount, privacy: .public)개, 총 매물 \(filteredTotalPoints, privacy: .public)개")
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
                let isDefault = (range.min == 0 && range.max == 100)
                owner.currentFilter.areaRange = isDefault ? nil : range
                updateAreaFilterButtonRelay.accept(!isDefault)

                if let regionData = owner.pendingRegionData {
                    let region = regionData.region
                    let zoom = regionData.zoom

                    guard zoom > Self.sidoModeZoomThreshold else { return }

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
                Logger.mapFilter.notice("평수 필터 해제")
                owner.currentFilter.areaRange = nil

                if let regionData = owner.pendingRegionData {
                    let region = regionData.region
                    let zoom = regionData.zoom

                    guard zoom > Self.sidoModeZoomThreshold else { return }

                    let bbox = (
                        minLon: region.center.longitude - region.span.longitudeDelta / 2,
                        minLat: region.center.latitude - region.span.latitudeDelta / 2,
                        maxLon: region.center.longitude + region.span.longitudeDelta / 2,
                        maxLat: region.center.latitude + region.span.latitudeDelta / 2
                    )

                    Logger.mapFilter.notice("필터 해제 - zoom: \(zoom, privacy: .public)")
                    let clusters = owner.clusteringEngine.getClusters(bbox: bbox, zoom: zoom)
                    let totalBeforeFilter = clusters.reduce(0) { $0 + $1.actualCount }
                    Logger.mapFilter.notice("필터 해제 후 클러스터 개수: \(clusters.count, privacy: .public), 총 매물: \(totalBeforeFilter, privacy: .public)")

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

                    let totalAfterFilter = filteredClusters.reduce(0) { $0 + $1.actualCount }
                    Logger.mapFilter.notice("다른 필터 적용 후: 클러스터 \(filteredClusters.count, privacy: .public)개, 총 매물 \(totalAfterFilter, privacy: .public)개")

                    let annotations: [MKAnnotation] = filteredClusters.map { cluster in
                        EstateClusterAnnotation(cluster: cluster)
                    }
                    annotationsRelay.accept(annotations)
                }
            })
            .disposed(by: disposeBag)

        input.depositFilterTapped
            .withUnretained(self)
            .map { owner, _ in owner.currentFilter.depositRange ?? (min: 0, max: 100000) }
            .bind(to: showDepositFilterRelay)
            .disposed(by: disposeBag)

        input.depositFilterApplied
            .withUnretained(self)
            .subscribe(onNext: { owner, range in
                Logger.mapFilter.notice("보증금 필터 적용 - min: \(range.min, privacy: .public)만원, max: \(range.max, privacy: .public)만원")
                let isDefault = (range.min == 0 && range.max == 100000)
                owner.currentFilter.depositRange = isDefault ? nil : range
                updateDepositFilterButtonRelay.accept(!isDefault)

                if let regionData = owner.pendingRegionData {
                    let region = regionData.region
                    let zoom = regionData.zoom

                    guard zoom > Self.sidoModeZoomThreshold else { return }

                    let bbox = (
                        minLon: region.center.longitude - region.span.longitudeDelta / 2,
                        minLat: region.center.latitude - region.span.latitudeDelta / 2,
                        maxLon: region.center.longitude + region.span.longitudeDelta / 2,
                        maxLat: region.center.latitude + region.span.latitudeDelta / 2
                    )

                    let clusters = owner.clusteringEngine.getClusters(bbox: bbox, zoom: zoom)
                    Logger.mapFilter.notice("필터 전 클러스터 개수: \(clusters.count, privacy: .public)")

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

                    Logger.mapFilter.notice("필터 후 클러스터 개수: \(filteredClusters.count, privacy: .public)")

                    let annotations: [MKAnnotation] = filteredClusters.map { cluster in
                        EstateClusterAnnotation(cluster: cluster)
                    }
                    annotationsRelay.accept(annotations)
                }
            })
            .disposed(by: disposeBag)

        input.depositFilterReset
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                Logger.mapFilter.notice("보증금 필터 해제")
                owner.currentFilter.depositRange = nil

                if let regionData = owner.pendingRegionData {
                    let region = regionData.region
                    let zoom = regionData.zoom

                    guard zoom > Self.sidoModeZoomThreshold else { return }

                    let bbox = (
                        minLon: region.center.longitude - region.span.longitudeDelta / 2,
                        minLat: region.center.latitude - region.span.latitudeDelta / 2,
                        maxLon: region.center.longitude + region.span.longitudeDelta / 2,
                        maxLat: region.center.latitude + region.span.latitudeDelta / 2
                    )

                    Logger.mapFilter.notice("필터 해제 - zoom: \(zoom, privacy: .public)")
                    let clusters = owner.clusteringEngine.getClusters(bbox: bbox, zoom: zoom)
                    let totalBeforeFilter = clusters.reduce(0) { $0 + $1.actualCount }
                    Logger.mapFilter.notice("필터 해제 후 클러스터 개수: \(clusters.count, privacy: .public), 총 매물: \(totalBeforeFilter, privacy: .public)")

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

                    let totalAfterFilter = filteredClusters.reduce(0) { $0 + $1.actualCount }
                    Logger.mapFilter.notice("다른 필터 적용 후: 클러스터 \(filteredClusters.count, privacy: .public)개, 총 매물 \(totalAfterFilter, privacy: .public)개")

                    let annotations: [MKAnnotation] = filteredClusters.map { cluster in
                        EstateClusterAnnotation(cluster: cluster)
                    }
                    annotationsRelay.accept(annotations)
                }
            })
            .disposed(by: disposeBag)

        input.rentFilterTapped
            .withUnretained(self)
            .map { owner, _ in owner.currentFilter.rentRange ?? (min: 0, max: 10000) }
            .bind(to: showRentFilterRelay)
            .disposed(by: disposeBag)

        input.rentFilterApplied
            .withUnretained(self)
            .subscribe(onNext: { owner, range in
                let isDefault = (range.min == 0 && range.max == 10000)
                owner.currentFilter.rentRange = isDefault ? nil : range
                updateRentFilterButtonRelay.accept(!isDefault)

                if let regionData = owner.pendingRegionData {
                    let region = regionData.region
                    let zoom = regionData.zoom

                    guard zoom > Self.sidoModeZoomThreshold else { return }

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

        input.rentFilterReset
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                Logger.mapFilter.notice("월세 필터 해제")
                owner.currentFilter.rentRange = nil

                if let regionData = owner.pendingRegionData {
                    let region = regionData.region
                    let zoom = regionData.zoom

                    guard zoom > Self.sidoModeZoomThreshold else { return }

                    let bbox = (
                        minLon: region.center.longitude - region.span.longitudeDelta / 2,
                        minLat: region.center.latitude - region.span.latitudeDelta / 2,
                        maxLon: region.center.longitude + region.span.longitudeDelta / 2,
                        maxLat: region.center.latitude + region.span.latitudeDelta / 2
                    )

                    Logger.mapFilter.notice("필터 해제 - zoom: \(zoom, privacy: .public)")
                    let clusters = owner.clusteringEngine.getClusters(bbox: bbox, zoom: zoom)
                    let totalBeforeFilter = clusters.reduce(0) { $0 + $1.actualCount }
                    Logger.mapFilter.notice("필터 해제 후 클러스터 개수: \(clusters.count, privacy: .public), 총 매물: \(totalBeforeFilter, privacy: .public)")

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

                    let totalAfterFilter = filteredClusters.reduce(0) { $0 + $1.actualCount }
                    Logger.mapFilter.notice("다른 필터 적용 후: 클러스터 \(filteredClusters.count, privacy: .public)개, 총 매물 \(totalAfterFilter, privacy: .public)개")

                    let annotations: [MKAnnotation] = filteredClusters.map { cluster in
                        EstateClusterAnnotation(cluster: cluster)
                    }
                    annotationsRelay.accept(annotations)
                }
            })
            .disposed(by: disposeBag)

        input.sidoAnnotationSelected
            .map { sidoAnnotation in
                let targetZoom = Self.sidoModeZoomThreshold + 2
                let newSpan = MKCoordinateSpan(
                    latitudeDelta: 360.0 / pow(2.0, Double(targetZoom)),
                    longitudeDelta: 360.0 / pow(2.0, Double(targetZoom))
                )
                return MKCoordinateRegion(
                    center: sidoAnnotation.sido.center,
                    span: newSpan
                )
            }
            .bind(to: zoomToClusterRelay)
            .disposed(by: disposeBag)

        return Output(
            annotations: annotationsRelay.asDriver(onErrorDriveWith: .empty()),
            sidoAnnotations: sidoAnnotationsRelay.asDriver(onErrorDriveWith: .empty()),
            showSidoMode: showSidoModeRelay.asDriver(onErrorJustReturn: false),
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
            showAreaFilter: showAreaFilterRelay.asDriver(onErrorJustReturn: (min: 0, max: 100)),
            showDepositFilter: showDepositFilterRelay.asDriver(onErrorJustReturn: (min: 0, max: 100000)),
            showRentFilter: showRentFilterRelay.asDriver(onErrorJustReturn: (min: 0, max: 10000)),
            updateAreaFilterButton: updateAreaFilterButtonRelay.asDriver(onErrorJustReturn: false),
            updateDepositFilterButton: updateDepositFilterButtonRelay.asDriver(onErrorJustReturn: false),
            updateRentFilterButton: updateRentFilterButtonRelay.asDriver(onErrorJustReturn: false)
        )
    }
}
