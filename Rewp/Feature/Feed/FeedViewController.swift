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
import OSLog

class FeedViewController: UIViewController {
    var presenter: FeedPresenter!
    var container: AppContainer!

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.contentInsetAdjustmentBehavior = .never
        $0.keyboardDismissMode = .onDrag
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

    private var recentSearchItems: [RecentSearchItem] = []

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

    private let viewDidLoadTrigger = PublishSubject<Void>()
    private let viewWillAppearTrigger = PublishSubject<Void>()
    private let topicTapRelay = PublishRelay<TopicItem>()
    private let bannerTapRelay = PublishRelay<String>()
    private let hotEstateTapRelay = PublishRelay<String>()
    private let newsAdTapRelay = PublishRelay<(String, String)>()
    private let recentlyViewedEstateTappedRelay = PublishRelay<String>()
    private var currentNewsAds: [BannerAdItem] = []
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearTrigger.onNext(())
    }

    private func setupUI() {
        view.addSubview(scrollView)

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

        searchBar.onTap = { [weak self] in
            guard let self = self else { return }
            let mapSearchVC = self.container.makeMapSearchViewController()
            self.navigationController?.pushViewController(mapSearchVC, animated: true)
        }

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

        hotScrollView.addSubview(hotContainerView)

        newsContainerView.flex
            .direction(.column)
            .define { flex in
                newsItems.forEach { item in
                    if item is ItemDivider {
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
        bannerCarousel.onBannerTapped = { [weak self] estateId in
            self?.bannerTapRelay.accept(estateId)
        }

        let input = FeedPresenter.Input(
            viewDidLoad: viewDidLoadTrigger.asObservable(),
            viewWillAppear: viewWillAppearTrigger.asObservable(),
            topicTapped: topicTapRelay.asObservable(),
            bannerTapped: bannerTapRelay.asObservable(),
            hotEstateTapped: hotEstateTapRelay.asObservable(),
            newsAdTapped: newsAdTapRelay.asObservable(),
            recentlyViewedEstateTapped: recentlyViewedEstateTappedRelay.asObservable()
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
                owner.hotItems = hotEstates.enumerated().map { index, item in
                    let hotItem = HotItem(
                        estateId: item.id,
                        imageURL: item.imageURL,
                        title: item.title,
                        price: item.price,
                        info: item.info
                    )
                    hotItem.onTap = { [weak owner] in
                        owner?.hotEstateTapRelay.accept(item.id)
                    }
                    return hotItem
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
            }
            .disposed(by: disposeBag)

        output.newsAds
            .drive(with: self) { owner, newsAds in
                owner.currentNewsAds = newsAds
            }
            .disposed(by: disposeBag)

        Observable.combineLatest(
            output.topics.asObservable(),
            output.newsAds.asObservable()
        )
        .withUnretained(self)
        .subscribe(onNext: { owner, data in
            let (topics, newsAds) = data
            owner.updateNewsItems(topics: topics, newsAds: newsAds)
        })
        .disposed(by: disposeBag)

        output.openAttendanceWebView
            .drive(with: self) { owner, urlPath in
                owner.openAttendanceWebView(urlPath: urlPath)
            }
            .disposed(by: disposeBag)

        output.openTopicLink
            .drive(with: self) { owner, urlString in
                owner.openWebView(urlString: urlString)
            }
            .disposed(by: disposeBag)

        output.recentlyViewedEstates
            .drive(with: self) { owner, items in
                owner.updateRecentlyViewedEstates(items: items)
            }
            .disposed(by: disposeBag)

        output.navigateToDetail
            .drive(with: self) { owner, estateId in
                let detailVC = owner.container.makeEstateDetailViewController(estateId: estateId)
                owner.navigationController?.pushViewController(detailVC, animated: true)
            }
            .disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        scrollView.pin
            .top(0)
            .horizontally()
            .bottom()

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
            .height(104)

        recentSearchContainerView.pin
            .top()
            .left()
            .height(104)

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
            .marginTop(8)
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
    }

    private func updateNewsItems(topics: [TopicItem], newsAds: [BannerAdItem]) {
        newsContainerView.subviews.forEach { $0.removeFromSuperview() }

        let mixedItems = mixTopicsWithAds(topics: topics, newsAds: newsAds)
        newsItems = mixedItems

        newsContainerView.flex
            .direction(.column)
            .define { flex in
                newsItems.forEach { item in
                    if item is ItemDivider {
                        flex.addItem(item)
                            .height(11)
                            .width(100%)
                    } else if item is NewsAdItem {
                        flex.addItem(item)
                            .height(96)
                            .marginHorizontal(20)
                    } else {
                        flex.addItem(item)
                            .height(66)
                            .width(100%)
                    }
                }
            }
        view.setNeedsLayout()
    }

    private func mixTopicsWithAds(topics: [TopicItem], newsAds: [BannerAdItem]) -> [UIView] {
        let adPositions = [1]

        var result: [UIView] = []

        for (index, topic) in topics.enumerated() {
            let hashtagItem = createTappableNewsItem(from: topic)
            result.append(hashtagItem)

            if let adIndex = adPositions.firstIndex(of: index),
               adIndex < newsAds.count {
                result.append(ItemDivider())

                let bannerAd = newsAds[adIndex]
                let adData = bannerAd.toNewsAdItem()
                let newsAdItem = NewsAdItem(
                    title: adData.title,
                    description: adData.description,
                    payloadType: adData.payloadType,
                    payloadValue: adData.payloadValue
                )

                newsAdItem.onTap = { [weak self] in
                    self?.newsAdTapRelay.accept((bannerAd.payloadType, bannerAd.payloadValue))
                }

                result.append(newsAdItem)
            }

            if index < topics.count - 1 {
                result.append(ItemDivider())
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

    private func updateRecentlyViewedEstates(items: [RecentlyViewedEstateItem]) {
        recentSearchItems.forEach { $0.removeFromSuperview() }
        recentSearchItems.removeAll()

        recentSearchContainerView.flex.define { flex in
            items.forEach { item in
                let searchItem = RecentSearchItem(
                    recommend: item.recommend,
                    category: item.category,
                    price: item.price,
                    area: item.area
                )
                searchItem.setImage(from: item.imageURL)
                searchItem.onTap = { [weak self] in
                    self?.recentlyViewedEstateTappedRelay.accept(item.estateId)
                }
                recentSearchContainerView.addSubview(searchItem)
                recentSearchItems.append(searchItem)

                flex.addItem(searchItem)
                    .width(190)
                    .height(88)
                    .marginRight(12)
            }
        }

        recentSearchContainerView.flex.markDirty()
        view.setNeedsLayout()
    }

    private func openWebView(urlString: String) {
        guard let url = URL(string: urlString) else { return }

        let webVC = WebViewController(url: url)
        navigationController?.pushViewController(webVC, animated: true)
    }

    private func openAttendanceWebView(urlPath: String) {
        let webVC = container.makeAttendanceWebViewController(urlPath: urlPath)
        navigationController?.pushViewController(webVC, animated: true)
    }
}
