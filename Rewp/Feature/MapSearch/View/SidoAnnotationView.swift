//
//  SidoAnnotationView.swift
//  Rewp
//
//  Created by 금가경 on 01/20/26.
//

import MapKit

final class SidoAnnotationView: MKAnnotationView, IsIdentifiable {
    private var sidoPin: SidoPin?

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

    func configure(with annotation: SidoAnnotation) {
        sidoPin?.removeFromSuperview()

        let newPin = SidoPin(name: annotation.sido.name, count: annotation.estateCount)
        addSubview(newPin)
        sidoPin = newPin

        let size = newPin.intrinsicContentSize
        frame = CGRect(origin: .zero, size: size)
        newPin.frame = bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        sidoPin?.removeFromSuperview()
        sidoPin = nil
    }
}
