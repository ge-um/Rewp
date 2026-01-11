//
//  EstateAnnotationView.swift
//  Rewp
//
//  Created by 금가경 on 01/08/26.
//

import MapKit

final class EstateAnnotationView: MKAnnotationView, IsIdentifiable {

    private let bubbleButton = MapBubbleButton(count: 1, subNumbers: (deposit: 0, rent: 0))

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        frame = CGRect(x: 0, y: 0, width: 72, height: 100)
        backgroundColor = .clear
        addSubview(bubbleButton)
        bubbleButton.frame = bounds
    }

    func configure(with estate: EstateDTO, count: Int = 1) {
        let depositInManWon = estate.deposit / 10000
        let rentInManWon = estate.monthly_rent / 10000

        let imageURL: URL? = {
            guard let thumbnailPath = estate.thumbnails.first else { return nil }
            return URL(string: NetworkConfig.baseURL + thumbnailPath)
        }()

        bubbleButton.configure(
            count: count,
            subNumbers: (deposit: depositInManWon, rent: rentInManWon),
            imageURL: imageURL
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bubbleButton.propertyImage = nil
    }
}

@available(iOS 17.0, *)
#Preview("기본 매물") {
    let view = EstateAnnotationView(annotation: nil, reuseIdentifier: EstateAnnotationView.identifier)
    let mockEstate = EstateDTO(
        estate_id: "1",
        category: "아파트",
        title: "한강뷰 아파트",
        introduction: "풀옵션",
        thumbnails: [],
        deposit: 30000000,
        monthly_rent: 1200000,
        built_year: "2020-01-01",
        area: 25.5,
        floors: 5,
        geolocation: Geolocation(longitude: 126.9, latitude: 37.5),
        distance: nil,
        like_count: 5,
        is_safe_estate: true,
        is_recommended: false,
        created_at: "",
        updated_at: ""
    )
    view.configure(with: mockEstate)
    return view
}

@available(iOS 17.0, *)
#Preview("고가 매물") {
    let view = EstateAnnotationView(annotation: nil, reuseIdentifier: EstateAnnotationView.identifier)
    let mockEstate = EstateDTO(
        estate_id: "2",
        category: "빌라",
        title: "역세권 빌라",
        introduction: "즉시입주",
        thumbnails: [],
        deposit: 50000000,
        monthly_rent: 2500000,
        built_year: "2021-05-01",
        area: 35.0,
        floors: 3,
        geolocation: Geolocation(longitude: 127.0, latitude: 37.6),
        distance: nil,
        like_count: 10,
        is_safe_estate: false,
        is_recommended: true,
        created_at: "",
        updated_at: ""
    )
    view.configure(with: mockEstate)
    return view
}
