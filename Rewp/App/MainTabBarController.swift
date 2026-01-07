//
//  MainTabBarController.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import UIKit
import RxSwift
import RxCocoa

final class MainTabBarController: UIViewController {
    private let container: AppContainer
    private let disposeBag = DisposeBag()

    private let tabBar = TabBar()
    private let containerView = UIView()

    private lazy var feedViewController: UIViewController = {
        return container.makeFeedViewController()
    }()

    private lazy var videoListViewController: UIViewController = {
        return container.makeVideoListViewController()
    }()

    private lazy var chatListViewController: UIViewController = {
        return container.makeChatListViewController()
    }()

    private lazy var settingsViewController: UIViewController = {
        return container.makeSettingsViewController()
    }()

    private var currentViewController: UIViewController?

    init(container: AppContainer, initialTab: Int = 0) {
        self.container = container
        super.init(nibName: nil, bundle: nil)
        tabBar.selectTab(at: initialTab)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray0
        setupUI()
        bind()
        showViewController(at: 0)
    }

    private func setupUI() {
        view.addSubview(containerView)
        view.addSubview(tabBar)
    }

    private func bind() {
        tabBar.selectedIndexRelay
            .withUnretained(self)
            .subscribe(onNext: { owner, index in
                owner.showViewController(at: index)
            })
            .disposed(by: disposeBag)
    }

    private func showViewController(at index: Int) {
        let newViewController: UIViewController

        switch index {
        case 0:
            newViewController = feedViewController
        case 1:
            newViewController = videoListViewController
        case 2:
            newViewController = chatListViewController
        case 3:
            newViewController = settingsViewController
        default:
            return
        }

        if let current = currentViewController {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        addChild(newViewController)
        containerView.addSubview(newViewController.view)
        newViewController.view.frame = containerView.bounds
        newViewController.didMove(toParent: self)

        currentViewController = newViewController

        view.setNeedsLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tabBar.pin
            .bottom()
            .horizontally()
            .height(80)

        containerView.pin
            .top()
            .horizontally()
            .above(of: tabBar)

        currentViewController?.view.frame = containerView.bounds
    }

    /// 특정 탭으로 이동
    /// - Parameter index: 탭 인덱스 (0: Feed, 1: Video, 2: ChatList, 3: Settings)
    func selectTab(at index: Int) {
        tabBar.selectTab(at: index)
    }

    /// 채팅방으로 네비게이션
    /// - Parameter chatRoom: 이동할 채팅방
    func navigateToChatRoom(chatRoom: ChatRoom) {
        selectTab(at: 2)
        let chatRoomVC = container.makeChatRoomViewController(chatRoom: chatRoom)
        navigationController?.pushViewController(chatRoomVC, animated: true)
    }
}

