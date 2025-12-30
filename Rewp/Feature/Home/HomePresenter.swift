//
//  HomePresenter.swift
//  Rewp
//
//  Created by 금가경 on 12/25/25.
//

import Foundation
import RxSwift
import RxCocoa

class HomePresenter {
    private let disposeBag = DisposeBag()

    struct Input {
        let viewDidLoad: Observable<Void>
        let tabSelected: Observable<Int>
    }

    struct Output {
        let banners: Driver<[BannerItem]>
        let navigateToSettings: Driver<Void>
    }

    func transform(input: Input) -> Output {
        let banners = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                return owner.fetchBanners()
            }
            .asDriver(onErrorJustReturn: [])

        let navigateToSettings = input.tabSelected
            .filter { $0 == 2 }
            .map { _ in () }
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            banners: banners,
            navigateToSettings: navigateToSettings
        )
    }

    private func fetchBanners() -> Observable<[BannerItem]> {
        return Observable.just([
            BannerItem(
                id: "1",
                imageURL: nil,
                location: "서울 반포동",
                title: "한강 파노라마 뷰\n역세권 아파트",
                description: "외국 무료 사진 퍼온 것 같겠지만 한강입니다."
            ),
            BannerItem(
                id: "2",
                imageURL: nil,
                location: "서울 강남구",
                title: "신축 오피스텔\n특별 분양",
                description: "강남역 도보 5분 거리"
            ),
            BannerItem(
                id: "3",
                imageURL: nil,
                location: "서울 마포구",
                title: "홍대 원룸\n즉시 입주 가능",
                description: "홍대입구역 3분"
            )
        ])
    }
}
