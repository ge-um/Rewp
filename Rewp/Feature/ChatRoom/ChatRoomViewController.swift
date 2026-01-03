//
//  ChatRoomViewController.swift
//  Rewp
//
//  Created by 금가경 on 01/03/26.
//

import UIKit
import PinLayout
import RxSwift
import RxCocoa
import Then

final class ChatRoomViewController: UIViewController {
    var presenter: ChatRoomPresenter!

    private let navigationBar = CustomNavigationBar(title: "").then {
        $0.backgroundColor = ColorSystem.gray0
    }

    private let tableView = UITableView().then {
        $0.backgroundColor = ColorSystem.gray15
        $0.separatorStyle = .none
        $0.keyboardDismissMode = .onDrag
        $0.allowsSelection = false
        $0.transform = CGAffineTransform(scaleX: 1, y: -1)
    }

    private let inputBar = ChatInputBar()

    private let bottomBackgroundView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
    }

    private var messages: [ChatMessage] = []
    private let viewDidLoadTrigger = PublishSubject<Void>()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray15
        setupUI()
        bind()
        viewDidLoadTrigger.onNext(())
    }

    private func setupUI() {
        view.addSubview(navigationBar)
        view.addSubview(tableView)
        view.addSubview(bottomBackgroundView)
        view.addSubview(inputBar)

        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.identifier)
        tableView.register(ChatMessageReceivedCell.self, forCellReuseIdentifier: ChatMessageReceivedCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func bind() {
        let sendMessage = inputBar.sendButtonTapped
            .withLatestFrom(inputBar.textInput)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        let input = ChatRoomPresenter.Input(
            viewDidLoad: viewDidLoadTrigger.asObservable(),
            sendButtonTapped: sendMessage,
        )

        let output = presenter.transform(input: input)

        output.title
            .drive(with: self) { owner, title in
                owner.navigationBar.setTitle(title)
            }
            .disposed(by: disposeBag)

        output.messages
            .drive(with: self) { owner, messages in
                owner.messages = messages.reversed()
                owner.tableView.reloadData()
            }
            .disposed(by: disposeBag)

        output.messageSent
            .drive(with: self) { owner, _ in
                owner.inputBar.clearText()
            }
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .withUnretained(self)
            .subscribe(onNext: { owner, notification in
                owner.handleKeyboardNotification(notification, isShowing: true)
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .withUnretained(self)
            .subscribe(onNext: { owner, notification in
                owner.handleKeyboardNotification(notification, isShowing: false)
            })
            .disposed(by: disposeBag)
    }

    private var keyboardHeight: CGFloat = 0

    private func handleKeyboardNotification(_ notification: Notification, isShowing: Bool) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        keyboardHeight = isShowing ? keyboardFrame.height - view.pin.safeArea.bottom : 0
        view.setNeedsLayout()

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        navigationBar.pin
            .top(view.pin.safeArea.top)
            .horizontally()
            .height(56)

        inputBar.pin
            .left()
            .right()
            .bottom(view.pin.safeArea.bottom + keyboardHeight)
            .height(inputBar.intrinsicContentSize.height)

        tableView.pin
            .below(of: navigationBar)
            .horizontally()
            .above(of: inputBar)
            .marginBottom(12)

        bottomBackgroundView.pin
            .top(inputBar.frame.minY)
            .horizontally()
            .bottom()
    }
}

extension ChatRoomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]

        if message.isFromMe {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ChatMessageCell.identifier,
                for: indexPath
            ) as? ChatMessageCell else {
                return UITableViewCell()
            }
            cell.configure(with: message)
            cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ChatMessageReceivedCell.identifier,
                for: indexPath
            ) as? ChatMessageReceivedCell else {
                return UITableViewCell()
            }
            cell.configure(with: message)
            cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
            return cell
        }
    }
}

extension ChatRoomViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
