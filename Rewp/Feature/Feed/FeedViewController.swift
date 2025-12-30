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

    private lazy var hotItems: [HotItem] = [
        HotItem(title: "고즈넉 매물, 여기가 천국", price: "월세 7,000/50", status: "34명이 함께 보는 중", info: "면적 152.4m²"),
        HotItem(title: "따끈따끈 새 매물", price: "전세 3,000/20", status: "12명이 함께 보는 중", info: "면적 89.5m²")
    ]

    private let newsTitleLabel = SectionTitleLabel(title: "오늘의 부동산 TOPIC", showViewAll: false)

    private let newsContainerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
    }

    private lazy var newsItems: [UIView] = {
        let items: [UIView] = [
            NewsHashTagItem(hashtag: "#4월 분양소식", description: "오늘 4월 4일, 전국 2만 3,720세대 분양 예정", date: "25. 4. 4"),
            NewsHashTagItem(hashtag: "#아파트실거래가", description: "2월 서울 국평아파트 평균 14억 3,360만원에 거래", date: "25. 4. 3"),
            NewsAdItem(title: "신혼집에는 새 설렘을!", description: "필요한 알뜰 가구 모아보기"),
            NewsHashTagItem(hashtag: "#전국 분양 일정", description: "전국 올시 부동산 일정 공개, 5월중으로 큰 거 온다", date: "25. 4. 2"),
            NewsHashTagItem(hashtag: "#공실률증가분", description: "4월 입주율의 전월 대비 48% ↓, 수도권 지방 모...", date: "25. 4. 3"),
            NewsHashTagItem(hashtag: "#집값 고공행진", description: "행진, 행진, 행진... 가는거야~", date: "25. 4. 2"),
            NewsAdItem(title: "내일 도착하는 감성소품!", description: "하우스 내 감성 가득 채우기"),
            NewsHashTagItem(hashtag: "#집값 고공행진", description: "행진, 행진, 행진... 가는거야~", date: "25. 4. 2"),
        ]

        var result: [UIView] = []
        for (index, item) in items.enumerated() {
            result.append(item)
            if index < items.count - 1 {
                result.append(NewsItemDivider())
            }
        }
        return result
    }()

    private let tabBar = TabBar().then {
        $0.selectTab(at: 0)
    }

    private let viewDidLoadTrigger = PublishSubject<Void>()
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
            tabSelected: tabBar.selectedIndexRelay.skip(1).asObservable()
        )

        let output = presenter.transform(input: input)

        output.banners
            .drive(onNext: { [weak self] banners in
                self?.bannerCarousel.configure(with: banners)
            })
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
            .top()
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
}
