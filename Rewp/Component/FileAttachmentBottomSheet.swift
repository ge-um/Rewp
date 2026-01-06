//
//  FileAttachmentBottomSheet.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import UIKit
import FlexLayout
import PinLayout
import Then

final class FileAttachmentBottomSheet: UIViewController {
    var onPhotoSelected: (() -> Void)?

    private let containerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
    }

    private let titleLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.body2, text: "첨부파일")
        $0.textColor = ColorSystem.gray90
    }

    private let photoButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "photo")
        config.imagePlacement = .leading
        config.imagePadding = 12
        config.title = "사진"
        config.baseForegroundColor = ColorSystem.gray90
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

        $0.configuration = config
        $0.backgroundColor = ColorSystem.gray15
        $0.layer.cornerRadius = 12
        $0.contentHorizontalAlignment = .leading
        $0.titleLabel?.font = FontSystem.Pretendard.body1.font
        $0.tintColor = ColorSystem.brightCoast
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBottomSheet()
        setupUI()
        bind()
    }

    private func setupBottomSheet() {
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
    }

    private func setupUI() {
        view.backgroundColor = ColorSystem.gray0

        view.addSubview(containerView)

        containerView.flex
            .padding(24)
            .define { flex in
                flex.addItem(titleLabel).marginBottom(24)
                flex.addItem(photoButton).height(56)
            }
    }

    private func bind() {
        photoButton.addTarget(self, action: #selector(photoButtonTapped), for: .touchUpInside)
    }

    @objc private func photoButtonTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onPhotoSelected?()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        containerView.pin.all()
        containerView.flex.layout()
    }
}
