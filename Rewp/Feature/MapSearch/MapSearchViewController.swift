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
        navigationBar = addCustomNavigationBar(title: "지도 검색")
        enableSwipeBackGesture()

        view.addSubview(navigationBar)
        view.addSubview(mapView)
    }

    private func setupMap() {
        mapView.delegate = self

        mapView.register(
            EstateAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: EstateAnnotationView.identifier
        )

        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapView.setRegion(initialRegion, animated: false)
    }

    private func bind() {
        let input = MapSearchPresenter.Input(
            viewDidLoad: viewDidLoadTrigger.asObservable()
        )

        let output = presenter.transform(input: input)

        output.estates
            .drive(with: self) { owner, estates in
                owner.updateAnnotations(estates: estates)
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
    }

    private func updateAnnotations(estates: [EstateDTO]) {
        mapView.removeAnnotations(mapView.annotations)

        let annotations = estates.map { EstateAnnotation(estate: $0) }
        mapView.addAnnotations(annotations)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        navigationBar.pin
            .top(view.pin.safeArea.top)
            .horizontally()
            .height(56)

        mapView.pin
            .below(of: navigationBar)
            .horizontally()
            .bottom()
    }
}

extension MapSearchViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let estateAnnotation = annotation as? EstateAnnotation else {
            return nil
        }

        let annotationView = mapView.dequeueReusableAnnotationView(
            withIdentifier: EstateAnnotationView.identifier,
            for: annotation
        ) as? EstateAnnotationView

        annotationView?.configure(with: estateAnnotation.estate)

        return annotationView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let estateAnnotation = view.annotation as? EstateAnnotation else { return }
        let detailVC = container.makeEstateDetailViewController(estateId: estateAnnotation.estate.estate_id)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
