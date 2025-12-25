import UIKit
import PinLayout
import RxSwift
import Then

class HomeViewController: UIViewController {
    var presenter: HomePresenter!

    private let searchBar = SearchBar()
    private let bannerCarousel = BannerCarousel()

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray0
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        setupUI()
        bind()
        presenter.viewDidLoad()
    }

    private func setupUI() {
        view.addSubview(bannerCarousel)
        view.addSubview(searchBar)
    }

    private func bind() {
        presenter.banners
            .withUnretained(self)
            .subscribe(onNext: { owner, banners in
                owner.bannerCarousel.configure(with: banners)
            })
            .disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        bannerCarousel.pin
            .top()
            .left()
            .right()
            .height(335)

        searchBar.pin
            .top(view.pin.safeArea.top + 16)
            .hCenter()
            .width(350)
            .height(40)
    }
}
