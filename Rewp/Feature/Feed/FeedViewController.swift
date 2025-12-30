//
//  FeedViewController.swift
//  Rewp
//
//  Created by 금가경 on 12/26/25.
//

import UIKit
import PinLayout
import FlexLayout
import RxSwift
import RxCocoa
import Then
import Moya
import RxMoya

class FeedViewController: UIViewController {
    var presenter: FeedPresenter!
    var container: AppContainer!

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.contentInsetAdjustmentBehavior = .never
    }

    private let contentView = UIView()

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

    private var hotItems: [HotItem] = []

    private let newsTitleLabel = SectionTitleLabel(title: "오늘의 부동산 TOPIC", showViewAll: false)

    private let newsContainerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
    }

    private var newsItems: [UIView] = []

    private let tabBar = TabBar().then {
        $0.selectTab(at: 0)
    }

    private let viewDidLoadTrigger = PublishSubject<Void>()
    private let topicTapRelay = PublishRelay<TopicItem>()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray15
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        setupUI()
        bind()
        viewDidLoadTrigger.onNext(())
    }

    private func setupUI() {
        view.addSubview(scrollView)
        view.addSubview(tabBar)

        scrollView.addSubview(contentView)

        contentView.addSubview(bannerCarousel)
        contentView.addSubview(searchBar)
        contentView.addSubview(categoryScrollView)
        contentView.addSubview(recentSearchTitleLabel)
        contentView.addSubview(recentSearchScrollView)
        contentView.addSubview(hotTitleLabel)
        contentView.addSubview(hotScrollView)
        contentView.addSubview(newsTitleLabel)
        contentView.addSubview(newsContainerView)

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

        newsContainerView.flex
            .direction(.column)
            .define { flex in
                newsItems.forEach { item in
                    if item is NewsItemDivider {
                        flex.addItem(item)
                            .height(11)
                            .width(100%)
                    } else if item is NewsAdItem {
                        flex.addItem(item)
                            .height(66)
                            .marginHorizontal(20)
                    } else {
                        flex.addItem(item)
                            .height(66)
                            .width(100%)
                    }
                }
            }
    }

    private func bind() {
        let input = FeedPresenter.Input(
            viewDidLoad: viewDidLoadTrigger.asObservable(),
            tabSelected: tabBar.selectedIndexRelay.skip(1).asObservable(),
            topicTapped: topicTapRelay.asObservable()
        )

        let output = presenter.transform(input: input)

        output.banners
            .drive(with: self) { owner, banners in
                owner.bannerCarousel.configure(with: banners)
            }
            .disposed(by: disposeBag)

        output.hotEstates
            .drive(with: self) { owner, hotEstates in
                owner.hotContainerView.subviews.forEach { $0.removeFromSuperview() }
                owner.hotItems = hotEstates.map { item in
                    HotItem(
                        imageURL: item.imageURL,
                        title: item.title,
                        price: item.price,
                        info: item.info
                    )
                }
                owner.hotContainerView.flex
                    .direction(.row)
                    .alignItems(.center)
                    .define { flex in
                        owner.hotItems.forEach { item in
                            flex.addItem(item)
                                .width(240)
                                .height(88)
                                .marginRight(12)
                        }
                    }
                owner.view.setNeedsLayout()
                owner.view.layoutIfNeeded()
            }
            .disposed(by: disposeBag)

        output.topics
            .drive(with: self) { owner, topics in
                owner.updateNewsItems(with: topics)
            }
            .disposed(by: disposeBag)

        output.openTopicLink
            .drive(with: self) { owner, urlString in
                owner.openWebView(urlString: urlString)
            }
            .disposed(by: disposeBag)

        output.navigateToSettings
            .drive(with: self) { owner, _ in
                let settingsVC = owner.container.makeSettingsViewController()
                let nav = UINavigationController(rootViewController: settingsVC)
                nav.navigationBar.isHidden = true
                owner.view.window?.rootViewController = nav
                owner.view.window?.makeKeyAndVisible()
            }
            .disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        scrollView.pin
            .top(0)
            .horizontally()
            .bottom(80)

        contentView.pin
            .top()
            .horizontally()

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

        newsTitleLabel.pin
            .below(of: hotScrollView)
            .marginTop(16)
            .horizontally(20)
            .height(32)

        newsContainerView.pin
            .below(of: newsTitleLabel)
            .marginTop(8)
            .horizontally()

        newsContainerView.flex.layout(mode: .adjustHeight)

        contentView.pin.height(
            newsContainerView.frame.maxY + 20
        )

        scrollView.contentSize = contentView.frame.size

        tabBar.pin
            .bottom()
            .horizontally()
            .height(80)
    }

    private func updateNewsItems(with topics: [TopicItem]) {
        newsContainerView.subviews.forEach { $0.removeFromSuperview() }

        let mixedItems = mixTopicsWithAds(topics: topics)
        newsItems = mixedItems

        newsContainerView.flex
            .direction(.column)
            .define { flex in
                newsItems.forEach { item in
                    if item is NewsItemDivider {
                        flex.addItem(item)
                            .height(11)
                            .width(100%)
                    } else if item is NewsAdItem {
                        flex.addItem(item)
                            .height(66)
                            .marginHorizontal(20)
                    } else {
                        flex.addItem(item)
                            .height(66)
                            .width(100%)
                    }
                }
            }

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    private func mixTopicsWithAds(topics: [TopicItem]) -> [UIView] {
        let adConfigs: [(afterTopicIndex: Int, item: NewsAdItem)] = [
            (1, NewsAdItem(title: "신혼집에는 새 설렘을!", description: "필요한 알뜰 가구 모아보기")),
            (4, NewsAdItem(title: "내일 도착하는 감성소품!", description: "하우스 내 감성 가득 채우기"))
        ]

        var result: [UIView] = []

        for (index, topic) in topics.enumerated() {
            let hashtagItem = createTappableNewsItem(from: topic)
            result.append(hashtagItem)

            if let adConfig = adConfigs.first(where: { $0.afterTopicIndex == index }) {
                result.append(NewsItemDivider())
                result.append(adConfig.item)
            }

            if index < topics.count - 1 {
                result.append(NewsItemDivider())
            }
        }

        return result
    }

    private func createTappableNewsItem(from topic: TopicItem) -> NewsHashTagItem {
        let item = NewsHashTagItem(
            hashtag: topic.hashtag,
            description: topic.description,
            date: topic.date
        )

        item.onTap = { [weak self] in
            self?.topicTapRelay.accept(topic)
        }

        return item
    }

    private func openWebView(urlString: String) {
        guard let url = URL(string: urlString) else { return }

        let webVC = WebViewController(url: url)
        navigationController?.pushViewController(webVC, animated: true)
    }
}
