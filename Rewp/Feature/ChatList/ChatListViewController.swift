//
//  ChatListViewController.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import UIKit
import PinLayout
import RxSwift
import RxCocoa
import Then

final class ChatListViewController: UIViewController {
    var presenter: ChatListPresenter!
    var container: AppContainer!

    private let titleLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.title1Bold, text: "채팅")
        $0.textColor = ColorSystem.gray90
    }

    private let tableView = UITableView().then {
        $0.backgroundColor = ColorSystem.gray15
        $0.separatorStyle = .singleLine
        $0.separatorColor = ColorSystem.gray30
        $0.separatorInset = UIEdgeInsets(top: 0, left: 88, bottom: 0, right: 20)
    }

    private let emptyLabel = UILabel().then {
        $0.textColor = ColorSystem.gray60
        $0.textAlignment = .center
        $0.isHidden = true
    }

    private var chatRooms: [ChatRoom] = []
    private let viewDidLoadTrigger = PublishSubject<Void>()
    private let viewWillAppearRelay = PublishRelay<Void>()
    private let chatRoomTappedRelay = PublishRelay<ChatRoom>()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray15
        setupUI()
        bind()
        viewDidLoadTrigger.onNext(())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        emptyLabel.typography(FontSystem.Pretendard.body2, text: "채팅 내역이 없습니다")

        tableView.register(ChatRoomCell.self, forCellReuseIdentifier: ChatRoomCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func bind() {
        let foregroundRefresh = NotificationCenter.default.rx
            .notification(.chatListNeedsRefresh)
            .map { _ in () }
            .asObservable()

        let input = ChatListPresenter.Input(
            viewDidLoad: viewDidLoadTrigger.asObservable(),
            viewWillAppear: viewWillAppearRelay.asObservable(),
            chatRoomTapped: chatRoomTappedRelay.asObservable(),
            foregroundRefresh: foregroundRefresh
        )

        let output = presenter.transform(input: input)

        output.chatRooms
            .drive(with: self) { owner, chatRooms in
                owner.chatRooms = chatRooms
                owner.tableView.reloadData()
                owner.emptyLabel.isHidden = !chatRooms.isEmpty
            }
            .disposed(by: disposeBag)

        output.navigateToChatRoom
            .drive(with: self) { owner, chatRoom in
                let chatRoomVC = owner.container.makeChatRoomViewController(chatRoom: chatRoom)
                owner.navigationController?.pushViewController(chatRoomVC, animated: true)
            }
            .disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        titleLabel.pin
            .top(view.pin.safeArea.top + 24)
            .horizontally(20)
            .sizeToFit(.width)

        tableView.pin
            .below(of: titleLabel)
            .marginTop(16)
            .horizontally()
            .bottom()

        emptyLabel.pin
            .center()
            .sizeToFit()
    }
}

extension ChatListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatRooms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ChatRoomCell.identifier,
            for: indexPath
        ) as? ChatRoomCell else {
            return UITableViewCell()
        }

        cell.configure(with: chatRooms[indexPath.row])
        return cell
    }
}

extension ChatListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chatRoomTappedRelay.accept(chatRooms[indexPath.row])
    }
}
