import Foundation
import RxSwift
import RxCocoa

class HomePresenter {
    private let bannersRelay = BehaviorRelay<[BannerItem]>(value: [])

    var banners: Observable<[BannerItem]> {
        return bannersRelay.asObservable()
    }

    func viewDidLoad() {
        loadBanners()
    }

    private func loadBanners() {
        let banners = [
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
        ]

        bannersRelay.accept(banners)
    }
}
