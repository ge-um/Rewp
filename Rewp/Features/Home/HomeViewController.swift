import UIKit
import PinLayout
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

    private let categoryStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 17.5
        $0.distribution = .equalSpacing
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private lazy var categoryButtons: [CategoryButton] = [
        CategoryButton(icon: UIImage(named: "OneRoom"), title: "원룸"),
        CategoryButton(icon: UIImage(named: "Officetel"), title: "오피스텔"),
        CategoryButton(icon: UIImage(named: "Apartment"), title: "아파트"),
        CategoryButton(icon: UIImage(named: "Villa"), title: "빌라"),
        CategoryButton(icon: UIImage(named: "Storefront"), title: "상가")
    ]

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

        categoryScrollView.addSubview(categoryStackView)

        categoryButtons.forEach { categoryStackView.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            categoryStackView.leadingAnchor.constraint(equalTo: categoryScrollView.leadingAnchor),
            categoryStackView.trailingAnchor.constraint(equalTo: categoryScrollView.trailingAnchor),
            categoryStackView.topAnchor.constraint(equalTo: categoryScrollView.topAnchor),
            categoryStackView.bottomAnchor.constraint(equalTo: categoryScrollView.bottomAnchor),
            categoryStackView.heightAnchor.constraint(equalTo: categoryScrollView.heightAnchor)
        ])
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
            .marginTop(24)
            .horizontally(20)
            .height(116)
    }
}
