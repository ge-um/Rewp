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

    private let categoryContainerView = UIView()

    private lazy var categoryButtons: [CategoryButton] = [
        CategoryButton(icon: UIImage(named: "OneRoom"), title: "원룸"),
        CategoryButton(icon: UIImage(named: "Officetel"), title: "오피스텔"),
        CategoryButton(icon: UIImage(named: "Apartment"), title: "아파트"),
        CategoryButton(icon: UIImage(named: "Villa"), title: "빌라"),
        CategoryButton(icon: UIImage(named: "Storefront"), title: "상가")
    ]

    private let recentSearchTitleLabel = SectionTitleLabel(title: "최근검색 매물")

    private let recentSearchScrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
    }

    private let recentSearchContainerView = UIView()

    private lazy var recentSearchItems: [RecentSearchItem] = [
        RecentSearchItem(recommend: "추천", category: "원룸", price: "전세 3,000/20", area: "면적 112.4m²"),
        RecentSearchItem(category: "원룸", price: "월세 3,000/50", area: "면적 49.5m²")
    ]

    private let hotTitleLabel = SectionTitleLabel(title: "Hot 매물")

    private let hotScrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
    }

    private let hotContainerView = UIView()

    private lazy var hotItems: [HotItem] = [
        HotItem(title: "고즈넉 매물, 여기가 천국", price: "월세 7,000/50", status: "34명이 함께 보는 중", info: "면적 152.4m²"),
        HotItem(title: "따끈따끈 새 매물", price: "전세 3,000/20", status: "12명이 함께 보는 중", info: "면적 89.5m²")
    ]

    private let viewDidLoadTrigger = PublishSubject<Void>()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray5
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
        view.addSubview(recentSearchScrollView)
        view.addSubview(hotTitleLabel)
        view.addSubview(hotScrollView)

        categoryScrollView.addSubview(categoryContainerView)
        categoryContainerView.flex
            .direction(.row)
            .alignItems(.center)
            .define { flex in
                categoryButtons.forEach { button in
                    flex.addItem(button)
                        .width(56)
                        .height(76)
                        .marginRight(17.5)
                }
            }

        recentSearchScrollView.addSubview(recentSearchContainerView)
        recentSearchContainerView.flex
            .direction(.row)
            .alignItems(.center)
            .define { flex in
                recentSearchItems.forEach { item in
                    flex.addItem(item)
                        .width(190)
                        .height(88)
                        .marginRight(12)
                }
            }

        hotScrollView.addSubview(hotContainerView)
        hotContainerView.flex
            .direction(.row)
            .alignItems(.center)
            .define { flex in
                hotItems.forEach { item in
                    flex.addItem(item)
                        .width(240)
                        .height(88)
                        .marginRight(12)
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

        categoryContainerView.pin
            .top()
            .left()
            .height(116)

        categoryContainerView.flex.layout(mode: .adjustWidth)

        categoryScrollView.contentSize = categoryContainerView.frame.size

        recentSearchTitleLabel.pin
            .below(of: categoryScrollView)
            .marginTop(16)
            .horizontally(20)
            .height(32)

        recentSearchScrollView.pin
            .below(of: recentSearchTitleLabel)
            .horizontally(20)
            .height(96)

        recentSearchContainerView.pin
            .top()
            .left()
            .height(96)

        recentSearchContainerView.flex.layout(mode: .adjustWidth)

        recentSearchScrollView.contentSize = recentSearchContainerView.frame.size

        hotTitleLabel.pin
            .below(of: recentSearchScrollView)
            .marginTop(16)
            .horizontally(20)
            .height(32)

        hotScrollView.pin
            .below(of: hotTitleLabel)
            .horizontally(20)
            .height(96)

        hotContainerView.pin
            .top()
            .left()
            .height(96)

        hotContainerView.flex.layout(mode: .adjustWidth)

        hotScrollView.contentSize = hotContainerView.frame.size
    }
}
