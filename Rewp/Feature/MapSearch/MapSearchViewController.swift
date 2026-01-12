//
//  MapSearchViewController.swift
//  Rewp
//
//  Created by 금가경 on 01/08/26.
//

import UIKit
import MapKit
import RxSwift
import RxCocoa

final class MapSearchViewController: UIViewController {
    var presenter: MapSearchPresenter!
    var container: AppContainer!
    private var navigationBar: CustomNavigationBar!

    private let mapView = MKMapView().then {
        $0.showsUserLocation = true
    }

    private let currentLocationButton = UIButton(type: .system).then {
        $0.setImage(UIImage(named: "Focus")?.withRenderingMode(.alwaysTemplate), for: .normal)
        $0.tintColor = ColorSystem.gray90
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.cornerRadius = 24
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.1
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    private let estateCardScrollView = EstateCardScrollView().then {
        $0.backgroundColor = .clear
        $0.isHidden = true
        $0.alpha = 0
    }

    private let filterButtonContainer = UIView().then {
        $0.backgroundColor = .clear
    }

    private let areaFilterButton = FilterButton(title: "평수 선택")
    private let depositFilterButton = FilterButton(title: "보증금 선택")
    private let rentFilterButton = FilterButton(title: "월세 선택")

    private let viewDidLoadTrigger = PublishSubject<Void>()
    private let mapRegionChangedTrigger = PublishSubject<(region: MKCoordinateRegion, zoom: Int)>()
    private let searchBarTappedTrigger = PublishSubject<Void>()
    private let searchLocationSelectedTrigger = PublishSubject<CLLocationCoordinate2D>()
    private let currentLocationTappedTrigger = PublishSubject<Void>()
    private let annotationSelectedTrigger = PublishSubject<(annotation: MKAnnotation, zoom: Int)>()
    private let estateCardTappedTrigger = PublishSubject<String>()
    private let mapTappedTrigger = PublishSubject<Void>()
    private let areaFilterTappedTrigger = PublishSubject<Void>()
    private let areaFilterAppliedTrigger = PublishSubject<(min: Int, max: Int)>()
    private let areaFilterResetTrigger = PublishSubject<Void>()
    private let depositFilterTappedTrigger = PublishSubject<Void>()
    private let depositFilterAppliedTrigger = PublishSubject<(min: Int, max: Int)>()
    private let depositFilterResetTrigger = PublishSubject<Void>()
    private let rentFilterTappedTrigger = PublishSubject<Void>()
    private let rentFilterAppliedTrigger = PublishSubject<(min: Int, max: Int)>()
    private let rentFilterResetTrigger = PublishSubject<Void>()

    private var currentFilterOverlay: RangeFilterOverlay?
    private var currentFilterType: FilterType?

    private let disposeBag = DisposeBag()

    private var currentZoom: Int = 16

    enum FilterType {
        case area
        case deposit
        case rent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        setupMap()
        bind()
        viewDidLoadTrigger.onNext(())
    }


    private func setupUI() {
        view.backgroundColor = ColorSystem.gray0
        navigationBar = addCustomNavigationBar(title: LocationManager.defaultAddress, showSearchBar: true, useLocationTitle: true)
        enableSwipeBackGesture()

        view.addSubview(mapView)
        view.addSubview(navigationBar)
        view.addSubview(filterButtonContainer)
        view.addSubview(currentLocationButton)
        view.addSubview(estateCardScrollView)

        filterButtonContainer.addSubview(areaFilterButton)
        filterButtonContainer.addSubview(depositFilterButton)
        filterButtonContainer.addSubview(rentFilterButton)

        navigationBar.onSearchBarTap = { [weak self] in
            self?.searchBarTappedTrigger.onNext(())
        }

        areaFilterButton.onTap = { [weak self] in
            self?.areaFilterTappedTrigger.onNext(())
        }

        depositFilterButton.onTap = { [weak self] in
            self?.depositFilterTappedTrigger.onNext(())
        }

        rentFilterButton.onTap = { [weak self] in
            self?.rentFilterTappedTrigger.onNext(())
        }

        currentLocationButton.addTarget(self, action: #selector(currentLocationButtonTapped), for: .touchUpInside)
        setupMapTapGesture()
    }


    @objc private func currentLocationButtonTapped() {
        currentLocationTappedTrigger.onNext(())
    }

    private func setupMapTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped))
        tapGesture.delegate = self
        mapView.addGestureRecognizer(tapGesture)
    }

    @objc private func mapTapped() {
        mapTappedTrigger.onNext(())
    }

    private func setupMap() {
        mapView.delegate = self

        mapView.register(
            EstateAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: EstateAnnotationView.identifier
        )

        mapView.register(
            EstateClusterAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: EstateClusterAnnotationView.identifier
        )

        let defaultRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5176577, longitude: 126.8864088),
            span: MKCoordinateSpan(latitudeDelta: 0.0055, longitudeDelta: 0.0055)
        )
        mapView.setRegion(defaultRegion, animated: false)
    }

    private func getOrCreateFilterOverlay() -> RangeFilterOverlay {
        if let existing = currentFilterOverlay {
            return existing
        }

        let overlay = RangeFilterOverlay(
            unit: "",
            minValue: 0,
            maxValue: 100,
            minLabelText: "",
            maxLabelText: ""
        )
        return overlay
    }

    private func hideCurrentFilterOverlay(applyFilter: Bool = false) {
        guard let overlay = currentFilterOverlay, overlay.isVisible() else {
            return
        }

        if applyFilter {
            overlay.onDismiss?()
        }

        overlay.layer.removeAllAnimations()
        overlay.containerView.layer.removeAllAnimations()
        overlay.removeFromSuperview()
    }

    private func bind() {
        let input = MapSearchPresenter.Input(
            viewDidLoad: viewDidLoadTrigger.asObservable(),
            mapRegionChanged: mapRegionChangedTrigger.asObservable(),
            searchLocationSelected: searchLocationSelectedTrigger.asObservable(),
            currentLocationTapped: currentLocationTappedTrigger.asObservable(),
            annotationSelected: annotationSelectedTrigger.asObservable(),
            estateCardTapped: estateCardTappedTrigger.asObservable(),
            mapTapped: mapTappedTrigger.asObservable(),
            areaFilterTapped: areaFilterTappedTrigger.asObservable(),
            areaFilterApplied: areaFilterAppliedTrigger.asObservable(),
            areaFilterReset: areaFilterResetTrigger.asObservable(),
            depositFilterTapped: depositFilterTappedTrigger.asObservable(),
            depositFilterApplied: depositFilterAppliedTrigger.asObservable(),
            depositFilterReset: depositFilterResetTrigger.asObservable(),
            rentFilterTapped: rentFilterTappedTrigger.asObservable(),
            rentFilterApplied: rentFilterAppliedTrigger.asObservable(),
            rentFilterReset: rentFilterResetTrigger.asObservable()
        )

        let output = presenter.transform(input: input)

        output.annotations
            .drive(with: self) { owner, annotations in
                owner.updateAnnotations(annotations: annotations)
            }
            .disposed(by: disposeBag)

        output.error
            .filter { !$0.isEmpty }
            .drive(with: self) { owner, message in
                let alert = UIAlertController(
                    title: "오류",
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                owner.present(alert, animated: true)
            }
            .disposed(by: disposeBag)

        output.moveToLocation
            .drive(with: self) { owner, region in
                owner.mapView.setRegion(region, animated: true)
            }
            .disposed(by: disposeBag)

        output.locationTitle
            .drive(with: self) { owner, locationTitle in
                owner.navigationBar.updateLocationTitle(locationTitle)
            }
            .disposed(by: disposeBag)

        output.initialRegion
            .drive(with: self) { owner, region in
                owner.mapView.setRegion(region, animated: true)
            }
            .disposed(by: disposeBag)

        output.showLocationPermissionDeniedAlert
            .drive(with: self) { owner, _ in
                owner.showLocationPermissionAlert()
            }
            .disposed(by: disposeBag)

        output.showEstateCards
            .drive(with: self) { owner, estates in
                owner.estateCardScrollView.configure(estates: estates)
                owner.estateCardScrollView.onCardTapped = { estateId in
                    owner.estateCardTappedTrigger.onNext(estateId)
                }
                owner.showEstateCardScrollView()
            }
            .disposed(by: disposeBag)

        output.navigateToDetail
            .drive(with: self) { owner, estateId in
                let detailVC = owner.container.makeEstateDetailViewController(estateId: estateId)
                owner.navigationController?.pushViewController(detailVC, animated: true)
            }
            .disposed(by: disposeBag)

        output.zoomToCluster
            .drive(with: self) { owner, region in
                owner.mapView.setRegion(region, animated: true)
            }
            .disposed(by: disposeBag)

        output.hideEstateCards
            .drive(with: self) { owner, _ in
                owner.hideEstateCardScrollView()
            }
            .disposed(by: disposeBag)

        output.showAreaFilter
            .drive(with: self) { owner, range in
                owner.hideCurrentFilterOverlay(applyFilter: true)

                let overlay = owner.getOrCreateFilterOverlay()
                overlay.reconfigure(
                    unit: "평",
                    minValue: 0,
                    maxValue: 100,
                    minLabelText: "최소",
                    maxLabelText: "최대",
                    midLabelText: "50평"
                )
                overlay.configure(currentMin: range.min, currentMax: range.max)
                overlay.onDismiss = { [weak self] in
                    let currentRange = overlay.getCurrentRange()
                    self?.areaFilterAppliedTrigger.onNext(currentRange)
                }
                overlay.show(in: owner.view, below: owner.areaFilterButton)
                owner.currentFilterOverlay = overlay
                owner.currentFilterType = .area
            }
            .disposed(by: disposeBag)

        output.showDepositFilter
            .drive(with: self) { owner, range in
                owner.hideCurrentFilterOverlay(applyFilter: true)

                let overlay = owner.getOrCreateFilterOverlay()
                overlay.reconfigure(
                    unit: "만원",
                    minValue: 0,
                    maxValue: 100000,
                    minLabelText: "최소",
                    maxLabelText: "최대",
                    midLabelText: "5억"
                )
                overlay.configure(currentMin: range.min, currentMax: range.max)
                overlay.onDismiss = { [weak self] in
                    let currentRange = overlay.getCurrentRange()
                    self?.depositFilterAppliedTrigger.onNext(currentRange)
                }
                overlay.show(in: owner.view, below: owner.depositFilterButton)
                owner.currentFilterOverlay = overlay
                owner.currentFilterType = .deposit
            }
            .disposed(by: disposeBag)

        output.showRentFilter
            .drive(with: self) { owner, range in
                owner.hideCurrentFilterOverlay(applyFilter: true)

                let overlay = owner.getOrCreateFilterOverlay()
                overlay.reconfigure(
                    unit: "만원",
                    minValue: 0,
                    maxValue: 10000,
                    minLabelText: "최소",
                    maxLabelText: "최대",
                    midLabelText: "5천만원"
                )
                overlay.configure(currentMin: range.min, currentMax: range.max)
                overlay.onDismiss = { [weak self] in
                    let currentRange = overlay.getCurrentRange()
                    self?.rentFilterAppliedTrigger.onNext(currentRange)
                }
                overlay.show(in: owner.view, below: owner.rentFilterButton)
                owner.currentFilterOverlay = overlay
                owner.currentFilterType = .rent
            }
            .disposed(by: disposeBag)

        output.updateAreaFilterButton
            .drive(with: self) { owner, isActive in
                owner.areaFilterButton.setActive(isActive)
            }
            .disposed(by: disposeBag)

        output.updateDepositFilterButton
            .drive(with: self) { owner, isActive in
                owner.depositFilterButton.setActive(isActive)
            }
            .disposed(by: disposeBag)

        output.updateRentFilterButton
            .drive(with: self) { owner, isActive in
                owner.rentFilterButton.setActive(isActive)
            }
            .disposed(by: disposeBag)

        mapTappedTrigger
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.hideCurrentFilterOverlay(applyFilter: true)
            })
            .disposed(by: disposeBag)

        searchBarTappedTrigger
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let locationSearchVC = LocationSearchFactory.create()

                locationSearchVC.onLocationSelected = { [weak self] coordinate in
                    self?.searchLocationSelectedTrigger.onNext(coordinate)
                }

                locationSearchVC.modalPresentationStyle = .pageSheet
                if let sheet = locationSearchVC.sheetPresentationController {
                    sheet.detents = [.large()]
                    sheet.prefersGrabberVisible = true
                }

                owner.present(locationSearchVC, animated: true)
            })
            .disposed(by: disposeBag)
    }

    private func updateAnnotations(annotations: [MKAnnotation]) {
        let currentAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(currentAnnotations)
        mapView.addAnnotations(annotations)
    }

    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "위치 권한 필요",
            message: "현재 위치를 사용하려면 설정에서 위치 권한을 허용해주세요.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }

    private func showEstateCardScrollView() {
        estateCardScrollView.isHidden = false

        UIView.animate(withDuration: 0.3) {
            self.estateCardScrollView.alpha = 1
        }
    }

    private func hideEstateCardScrollView() {
        UIView.animate(withDuration: 0.3) {
            self.estateCardScrollView.alpha = 0
        } completion: { _ in
            self.estateCardScrollView.isHidden = true
        }
    }

    private func calculateZoomLevel(for region: MKCoordinateRegion) -> Int {
        let longitudeDelta = region.span.longitudeDelta
        let zoom = Int(round(log2(360.0 / longitudeDelta)))
        return min(max(zoom, 0), 16)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let navigationBarHeight: CGFloat = 112

        navigationBar.pin
            .top(view.pin.safeArea.top)
            .horizontally()
            .height(navigationBarHeight)

        mapView.pin
            .below(of: navigationBar)
            .horizontally()
            .bottom()

        filterButtonContainer.pin
            .below(of: navigationBar)
            .marginTop(8)
            .left(20)
            .height(32)
            .sizeToFit(.height)

        areaFilterButton.pin
            .left()
            .width(78)
            .height(32)

        depositFilterButton.pin
            .after(of: areaFilterButton)
            .marginLeft(8)
            .width(78)
            .height(32)

        rentFilterButton.pin
            .after(of: depositFilterButton)
            .marginLeft(8)
            .width(78)
            .height(32)

        filterButtonContainer.pin
            .wrapContent()

        currentLocationButton.pin
            .right(20)
            .bottom(view.pin.safeArea.bottom + 20)
            .size(48)

        estateCardScrollView.pin
            .bottom(view.pin.safeArea.bottom + 20)
            .horizontally()
            .height(166)
    }
}

extension MapSearchViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        if let clusterAnnotation = annotation as? EstateClusterAnnotation {
            if currentZoom >= 16 {
                let annotationView = mapView.dequeueReusableAnnotationView(
                    withIdentifier: EstateAnnotationView.identifier,
                    for: annotation
                ) as? EstateAnnotationView

                if let estate = clusterAnnotation.cluster.points.first {
                    annotationView?.configure(with: estate, count: clusterAnnotation.count)
                }
                return annotationView
            } else {
                let annotationView = mapView.dequeueReusableAnnotationView(
                    withIdentifier: EstateClusterAnnotationView.identifier,
                    for: annotation
                ) as? EstateClusterAnnotationView

                annotationView?.configure(with: clusterAnnotation)
                return annotationView
            }
        }

        if let estateAnnotation = annotation as? EstateAnnotation {
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: EstateAnnotationView.identifier,
                for: annotation
            ) as? EstateAnnotationView

            annotationView?.configure(with: estateAnnotation.estate)
            return annotationView
        }

        return nil
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }

        if annotation is MKUserLocation {
            return
        }

        annotationSelectedTrigger.onNext((annotation: annotation, zoom: currentZoom))
        mapView.deselectAnnotation(annotation, animated: false)
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let region = mapView.region
        let zoom = calculateZoomLevel(for: region)
        currentZoom = zoom
        mapRegionChangedTrigger.onNext((region, zoom))
    }
}

extension MapSearchViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is MKAnnotationView)
    }
}
