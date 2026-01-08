//
//  EstateClusterAnnotationView.swift
//  Rewp
//
//  Created by 금가경 on 01/08/26.
//

import MapKit

final class EstateClusterAnnotationView: MKAnnotationView, IsIdentifiable {
    private let clusterPin = ClusterPin(count: 0)

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(clusterPin)
    }

    func configure(with count: Int) {
        clusterPin.count = count
        let size = clusterPin.intrinsicContentSize
        frame = CGRect(origin: .zero, size: size)
        clusterPin.frame = bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        clusterPin.count = 0
    }
}

@available(iOS 17.0, *)
#Preview("소규모 클러스터") {
    let view = EstateClusterAnnotationView(annotation: nil, reuseIdentifier: EstateClusterAnnotationView.identifier)
    view.configure(with: 5)
    return view
}

@available(iOS 17.0, *)
#Preview("중규모 클러스터") {
    let view = EstateClusterAnnotationView(annotation: nil, reuseIdentifier: EstateClusterAnnotationView.identifier)
    view.configure(with: 42)
    return view
}

@available(iOS 17.0, *)
#Preview("대규모 클러스터") {
    let view = EstateClusterAnnotationView(annotation: nil, reuseIdentifier: EstateClusterAnnotationView.identifier)
    view.configure(with: 128)
    return view
}
