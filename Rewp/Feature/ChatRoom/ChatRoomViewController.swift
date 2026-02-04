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
import PhotosUI

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

    private let networkStatusBanner = NetworkStatusBanner().then {
        $0.isHidden = true
    }

    private var messages: [ChatMessage] = []
    private let viewDidLoadTrigger = PublishSubject<Void>()
    private let viewWillDisappearTrigger = PublishSubject<Void>()
    private let retryMessageRelay = PublishRelay<String>()
    private let deleteMessageRelay = PublishRelay<String>()
    private let filesSelectedRelay = PublishRelay<[UIImage]>()
    private let photoSendConfirmedRelay = PublishRelay<(images: [UIImage], text: String)>()
    private let loadMoreTrigger = PublishRelay<Void>()
    private let disposeBag = DisposeBag()
    private lazy var offscreenSentCell = ChatMessageCell(style: .default, reuseIdentifier: nil)
    private lazy var offscreenReceivedCell = ChatMessageReceivedCell(style: .default, reuseIdentifier: nil)

    private let loadingIndicator = UIActivityIndicatorView(style: .medium).then {
        $0.hidesWhenStopped = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray15
        setupUI()
        bind()
        viewDidLoadTrigger.onNext(())
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearTrigger.onNext(())
    }

    private func setupUI() {
        view.addSubview(navigationBar)
        view.addSubview(networkStatusBanner)
        view.addSubview(tableView)
        view.addSubview(bottomBackgroundView)
        view.addSubview(inputBar)
        view.addSubview(loadingIndicator)

        navigationBar.onBackButtonTap = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

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
            .do(onNext: { [weak self] _ in
                self?.inputBar.clearText()
            })

        let input = ChatRoomPresenter.Input(
            viewDidLoad: viewDidLoadTrigger.asObservable(),
            viewWillDisappear: viewWillDisappearTrigger.asObservable(),
            sendButtonTapped: sendMessage,
            retryMessageTapped: retryMessageRelay.asObservable(),
            deleteMessageTapped: deleteMessageRelay.asObservable(),
            attachButtonTapped: inputBar.attachButtonTapped,
            filesSelected: filesSelectedRelay.asObservable(),
            photoSendConfirmed: photoSendConfirmedRelay.asObservable(),
            loadMoreTrigger: loadMoreTrigger.asObservable()
        )

        let output = presenter.transform(input: input)

        output.title
            .drive(with: self) { owner, title in
                owner.navigationBar.setTitle(title)
            }
            .disposed(by: disposeBag)

        output.messages
            .drive(with: self) { owner, messages in
                let previousMessages = owner.messages
                let newMessages = Array(messages.reversed())

                let isLoadMore = !previousMessages.isEmpty
                    && newMessages.count > previousMessages.count
                    && previousMessages.last?.chatId != newMessages.last?.chatId

                if isLoadMore {
                    let currentOffset = owner.tableView.contentOffset

                    owner.messages = newMessages
                    owner.tableView.reloadData()
                    owner.tableView.layoutIfNeeded()

                    owner.tableView.contentOffset = currentOffset
                } else {
                    owner.messages = newMessages
                    owner.tableView.reloadData()
                }
            }
            .disposed(by: disposeBag)

        output.isLoadingMore
            .drive(with: self) { owner, isLoading in
                if isLoading {
                    owner.loadingIndicator.startAnimating()
                } else {
                    owner.loadingIndicator.stopAnimating()
                }
            }
            .disposed(by: disposeBag)

        output.messageSent
            .drive()
            .disposed(by: disposeBag)

        output.showAttachmentSheet
            .drive(with: self) { owner, _ in
                let bottomSheet = FileAttachmentBottomSheet()
                bottomSheet.onPhotoSelected = { [weak owner] in
                    owner?.showImagePicker()
                }
                owner.present(bottomSheet, animated: true)
            }
            .disposed(by: disposeBag)

        output.showPhotoPreview
            .drive(with: self) { owner, images in
                let previewSheet = PhotoPreviewBottomSheet(images: images)
                previewSheet.onSendTapped = { [weak owner] images, text in
                    owner?.photoSendConfirmedRelay.accept((images, text))
                }
                previewSheet.onCancelTapped = {
                }
                owner.present(previewSheet, animated: true)
            }
            .disposed(by: disposeBag)

        output.isNetworkConnected
            .drive(with: self) { owner, isConnected in
                let wasHidden = owner.networkStatusBanner.isHidden
                owner.networkStatusBanner.isHidden = isConnected

                if wasHidden != isConnected {
                    owner.view.setNeedsLayout()
                    UIView.animate(withDuration: 0.25) {
                        owner.view.layoutIfNeeded()
                    }
                }
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

        networkStatusBanner.pin
            .below(of: navigationBar)
            .horizontally()
            .height(networkStatusBanner.isHidden ? 0 : 36)

        inputBar.pin
            .left()
            .right()
            .bottom(view.pin.safeArea.bottom + keyboardHeight)
            .height(inputBar.intrinsicContentSize.height)

        tableView.pin
            .below(of: networkStatusBanner)
            .horizontally()
            .above(of: inputBar)
            .marginBottom(12)

        bottomBackgroundView.pin
            .top(inputBar.frame.maxY)
            .horizontally()
            .bottom()

        loadingIndicator.pin
            .below(of: networkStatusBanner)
            .hCenter()
            .marginTop(10)
            .sizeToFit()
    }

    private func calculateHeight(for message: ChatMessage) -> CGFloat {
        let width = view.bounds.width

        if message.isFromMe {
            offscreenSentCell.configure(with: message)
            return offscreenSentCell.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        } else {
            offscreenReceivedCell.configure(with: message)
            return offscreenReceivedCell.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        }
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
            cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
            cell.configure(with: message)
            cell.onRetryTapped = { [weak self] in
                guard let tempId = message.tempId else { return }
                self?.retryMessageRelay.accept(tempId)
            }
            cell.onDeleteTapped = { [weak self] in
                guard let tempId = message.tempId else { return }
                self?.deleteMessageRelay.accept(tempId)
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ChatMessageReceivedCell.identifier,
                for: indexPath
            ) as? ChatMessageReceivedCell else {
                return UITableViewCell()
            }
            cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
            cell.configure(with: message)
            return cell
        }
    }
}

extension ChatRoomViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let message = messages[indexPath.row]
        return calculateHeight(for: message)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.height
        let threshold: CGFloat = 50

        if contentHeight > frameHeight {
            let distanceFromBottom = contentHeight - offsetY - frameHeight
            if distanceFromBottom < threshold {
                loadMoreTrigger.accept(())
            }
        }
    }
}

extension ChatRoomViewController {
    private func showImagePicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 5
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension ChatRoomViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard !results.isEmpty else { return }

        let group = DispatchGroup()
        var images: [UIImage] = []

        for result in results {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                defer { group.leave() }

                if let image = object as? UIImage {
                    images.append(image)
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard !images.isEmpty else { return }
            self?.filesSelectedRelay.accept(images)
        }
    }
}
