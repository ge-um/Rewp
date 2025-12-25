import UIKit
import PinLayout
import FlexLayout
import RxSwift
import RxCocoa
import Then

class HomeViewController: UIViewController {
    var presenter: HomePresenter!

    private let searchBar = SearchBar()
    private let bannerCarousel = BannerCarousel()

    private let categoryScrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
    }

    private lazy var categoryButtons: [CategoryButton] = [
        CategoryButton(icon: UIImage(named: "OneRoom"), title: "원룸"),
        CategoryButton(icon: UIImage(named: "Officetel"), title: "오피스텔"),
        CategoryButton(icon: UIImage(named: "Apartment"), title: "아파트"),
        CategoryButton(icon: UIImage(named: "Villa"), title: "빌라"),
        CategoryButton(icon: UIImage(named: "Storefront"), title: "상가")
    ]

    private let recentSearchTitleLabel = SectionTitleLabel(title: "최근검색 매물")

    private let viewDidLoadTrigger = PublishSubject<Void>()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray0
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        setupUI()
        bind()
        viewDidLoadTrigger.onNext(())
    }

    private func setupUI() {
        view.addSubview(bannerCarousel)
        view.addSubview(searchBar)
        view.addSubview(categoryScrollView)
        view.addSubview(recentSearchTitleLabel)

        categoryScrollView.flex
            .direction(.row)
            .alignItems(.center)
            .define { flex in
                categoryButtons.enumerated().forEach { index, button in
                    flex.addItem(button)
                        .width(56)
                        .height(76)
                        .marginRight(17.5)
                }
            }
    }

    private func bind() {
        let input = HomePresenter.Input(
            viewDidLoad: viewDidLoadTrigger.asObservable()
        )

        let output = presenter.transform(input: input)

        output.banners
            .drive(onNext: { [weak self] banners in
                self?.bannerCarousel.configure(with: banners)
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

        categoryScrollView.pin
            .below(of: bannerCarousel)
            .horizontally(20)
            .height(116)

        categoryScrollView.flex.layout(mode: .adjustWidth)
        categoryScrollView.contentSize = categoryScrollView.flex.intrinsicSize

        recentSearchTitleLabel.pin
            .below(of: categoryScrollView)
            .marginTop(16)
            .horizontally(20)
            .height(32)
    }
}
