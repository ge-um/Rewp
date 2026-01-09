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

    private let viewDidLoadTrigger = PublishSubject<Void>()
    private let mapRegionChangedTrigger = PublishSubject<(region: MKCoordinateRegion, zoom: Int)>()
    private let searchBarTappedTrigger = PublishSubject<Void>()
    private let searchLocationSelectedTrigger = PublishSubject<CLLocationCoordinate2D>()
    private let disposeBag = DisposeBag()

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
        navigationBar = addCustomNavigationBar(title: "위치 확인 중...", showSearchBar: true, useLocationTitle: true)
        enableSwipeBackGesture()

        view.addSubview(mapView)
        view.addSubview(navigationBar)

        navigationBar.onSearchBarTap = { [weak self] in
            self?.searchBarTappedTrigger.onNext(())
        }
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

    private func bind() {
        let input = MapSearchPresenter.Input(
            viewDidLoad: viewDidLoadTrigger.asObservable(),
            mapRegionChanged: mapRegionChangedTrigger.asObservable(),
            searchLocationSelected: searchLocationSelectedTrigger.asObservable()
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

    private func calculateZoomLevel(for region: MKCoordinateRegion) -> Int {
        let longitudeDelta = region.span.longitudeDelta
        let zoom = Int(round(log2(360.0 / longitudeDelta)))
        return min(max(zoom, 0), 16)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let navigationBarHeight: CGFloat = 108

        navigationBar.pin
            .top(view.pin.safeArea.top)
            .horizontally()
            .height(navigationBarHeight)

        mapView.pin
            .below(of: navigationBar)
            .horizontally()
            .bottom()
    }
}

extension MapSearchViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        if let clusterAnnotation = annotation as? EstateClusterAnnotation {
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: EstateClusterAnnotationView.identifier,
                for: annotation
            ) as? EstateClusterAnnotationView

            annotationView?.configure(with: clusterAnnotation)
            return annotationView
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
        if let estateAnnotation = view.annotation as? EstateAnnotation {
            let detailVC = container.makeEstateDetailViewController(estateId: estateAnnotation.estate.estate_id)
            navigationController?.pushViewController(detailVC, animated: true)
        } else if let clusterAnnotation = view.annotation as? EstateClusterAnnotation {
            if let expansionZoom = clusterAnnotation.cluster.expansionZoom {
                let newSpan = MKCoordinateSpan(
                    latitudeDelta: 360.0 / pow(2.0, Double(expansionZoom)),
                    longitudeDelta: 360.0 / pow(2.0, Double(expansionZoom))
                )
                let newRegion = MKCoordinateRegion(
                    center: clusterAnnotation.coordinate,
                    span: newSpan
                )
                mapView.setRegion(newRegion, animated: true)
            }
        }
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let region = mapView.region
        let zoom = calculateZoomLevel(for: region)
        mapRegionChangedTrigger.onNext((region, zoom))
    }
}
