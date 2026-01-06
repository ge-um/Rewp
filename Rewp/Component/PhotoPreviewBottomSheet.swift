//
//  PhotoPreviewBottomSheet.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import UIKit
import RxSwift
import RxCocoa
import PinLayout
import FlexLayout
import Then

final class PhotoPreviewBottomSheet: UIViewController {
    var onSendTapped: (([UIImage], String) -> Void)?
    var onCancelTapped: (() -> Void)?

    private let images: [UIImage]
    private let disposeBag = DisposeBag()

    private let containerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
    }

    private let headerContainer = UIView()

    private let thumbnailStackView = UIView()

    private let textViewContainer = UIView().then {
        $0.backgroundColor = ColorSystem.gray15
        $0.layer.cornerRadius = 12
    }

    private let textView = UITextView().then {
        $0.font = FontSystem.Pretendard.body2.font
        $0.textColor = ColorSystem.gray90
        $0.backgroundColor = .clear
        $0.textContainerInset = UIEdgeInsets(top: 15, left: 8, bottom: 8, right: 8)
        $0.textContainer.lineFragmentPadding = 0
    }

    private let placeholderLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.body2, text: "메시지를 입력하세요")
        $0.textColor = ColorSystem.gray60
    }

    private let cancelButton = UIButton().then {
        $0.setTitle("취소", for: .normal)
        $0.setTitleColor(ColorSystem.gray90, for: .normal)
        $0.titleLabel?.font = FontSystem.Pretendard.body2.font
    }

    private let sendButton = UIButton().then {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        $0.setImage(UIImage(systemName: "paperplane.fill", withConfiguration: config), for: .normal)
        $0.tintColor = ColorSystem.brightCoast
        $0.isEnabled = false
    }

    init(images: [UIImage]) {
        self.images = images
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray0
        setupBottomSheet()
        setupUI()
        setupThumbnails()
        bindActions()
    }

    private func setupBottomSheet() {
        if let sheet = sheetPresentationController {
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                return 280
            }
            sheet.detents = [customDetent]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
    }

    private func setupUI() {
        view.addSubview(containerView)

        headerContainer.addSubview(cancelButton)
        headerContainer.addSubview(sendButton)
        textViewContainer.addSubview(textView)
        textViewContainer.addSubview(placeholderLabel)

        containerView.flex
            .padding(24)
            .define { flex in
                flex.addItem(headerContainer)
                    .height(40)
                    .marginBottom(16)

                flex.addItem(thumbnailStackView)
                    .height(60)
                    .marginBottom(20)

                flex.addItem(textViewContainer)
                    .height(50)
            }
    }

    private func setupThumbnails() {
        thumbnailStackView.flex
            .direction(.row)
            .define { flex in
                for (index, image) in images.enumerated() {
                    let imageView = UIImageView().then {
                        $0.image = image
                        $0.contentMode = .scaleAspectFill
                        $0.clipsToBounds = true
                        $0.layer.cornerRadius = 8
                        $0.backgroundColor = ColorSystem.gray15
                    }
                    flex.addItem(imageView)
                        .size(60)
                        .marginRight(index < images.count - 1 ? 8 : 0)
                }
            }
    }

    private func bindActions() {
        textView.rx.text.orEmpty
            .withUnretained(self)
            .subscribe(onNext: { owner, text in
                owner.placeholderLabel.isHidden = !text.isEmpty
            })
            .disposed(by: disposeBag)

        textView.rx.text.orEmpty
            .map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .withUnretained(self)
            .subscribe(onNext: { owner, isEnabled in
                owner.sendButton.isEnabled = isEnabled
                owner.sendButton.tintColor = isEnabled ? ColorSystem.brightCoast : ColorSystem.gray30
            })
            .disposed(by: disposeBag)

        cancelButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.dismiss(animated: true) {
                    owner.onCancelTapped?()
                }
            })
            .disposed(by: disposeBag)

        sendButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let text = owner.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
                owner.dismiss(animated: true) {
                    owner.onSendTapped?(owner.images, text)
                }
            })
            .disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        containerView.pin
            .all(view.pin.safeArea)
            .margin(8)
        containerView.flex.layout()

        cancelButton.pin
            .left()
            .vCenter()
            .sizeToFit()

        sendButton.pin
            .right()
            .vCenter()
            .size(32)

        textView.pin.all()

        placeholderLabel.pin
            .top(15)
            .left(8)
            .sizeToFit()

        thumbnailStackView.flex.layout()
    }
}
