//
//  EstateClusterAnnotationView.swift
//  Rewp
//
//  Created by 금가경 on 01/08/26.
//

import MapKit

final class EstateClusterAnnotationView: MKAnnotationView, IsIdentifiable {
    private var clusterPin: ClusterPin?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
    }

    func configure(with cluster: EstateClusterAnnotation) {
        clusterPin?.removeFromSuperview()

        let newPin = ClusterPin(count: cluster.count, amenityInfo: cluster.amenityInfo)
        addSubview(newPin)
        clusterPin = newPin

        let size = newPin.intrinsicContentSize
        frame = CGRect(origin: .zero, size: size)
        newPin.frame = bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        clusterPin?.removeFromSuperview()
        clusterPin = nil
    }
}
