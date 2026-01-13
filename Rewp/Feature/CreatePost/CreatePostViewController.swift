//
//  CreatePostViewController.swift
//  Rewp
//
//  Created by 금가경 on 01/13/26.
//

import UIKit
import RxSwift
import RxCocoa
import PinLayout
import FlexLayout
import PhotosUI

final class CreatePostViewController: UIViewController, KeyboardHandling {
    var presenter: CreatePostPresenter!
    var keyboardHeight: CGFloat = 0

    private let scrollView = UIScrollView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.keyboardDismissMode = .interactive
    }

    private let contentView = UIView()

    private let navigationBar = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
    }

    private lazy var cancelButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "취소"
        config.baseForegroundColor = ColorSystem.gray60
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        let button = UIButton(configuration: config)
        button.configurationUpdateHandler = { btn in
            var config = btn.configuration
            config?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = FontSystem.Pretendard.body1.font
                return outgoing
            }
            btn.configuration = config
        }
        return button
    }()
 
    private lazy var submitButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "완료"
        config.baseForegroundColor = ColorSystem.deepCoast
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        let button = UIButton(configuration: config)
        button.configurationUpdateHandler = { btn in
            var config = btn.configuration
            config?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = FontSystem.Pretendard.body1Bold.font
                return outgoing
            }
            btn.configuration = config
        }
        return button
    }()

    private let categoryLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.caption1Semibold, text: "카테고리")
        $0.textColor = ColorSystem.gray60
    }

    private lazy var categoryButtons: [UIButton] = {
        return PostCategory.allCases.filter { $0 != .all }.enumerated().map { index, category in
            var config = UIButton.Configuration.filled()
            config.title = category.displayName
            config.baseForegroundColor = index == 0 ? ColorSystem.gray0 : ColorSystem.gray60
            config.baseBackgroundColor = index == 0 ? ColorSystem.deepCoast : ColorSystem.gray0
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

            var background = UIButton.Configuration.filled().background
            background.strokeColor = index == 0 ? .clear : ColorSystem.gray30
            background.strokeWidth = 1
            config.background = background

            let button = UIButton(configuration: config)
            button.configurationUpdateHandler = { btn in
                var config = btn.configuration
                config?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                    var outgoing = incoming
                    outgoing.font = FontSystem.Pretendard.body2.font
                    return outgoing
                }
                btn.configuration = config
            }
            button.tag = index

            return button
        }
    }()

    private let titleTextField = UITextField().then {
        $0.typography(FontSystem.Pretendard.body1, placeholder: "제목을 입력하세요")
        $0.textColor = ColorSystem.gray90
        $0.backgroundColor = ColorSystem.gray15
        $0.layer.cornerRadius = 8
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        $0.leftViewMode = .always
        $0.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        $0.rightViewMode = .always
    }

    private let contentTextView = UITextView().then {
        $0.typography(FontSystem.Pretendard.body2)
        $0.textColor = ColorSystem.gray90
        $0.backgroundColor = ColorSystem.gray15
        $0.layer.cornerRadius = 8
        $0.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        $0.isScrollEnabled = false
    }

    private let placeholderLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.body2, text: "내용을 입력하세요")
        $0.textColor = ColorSystem.gray45
    }

    private let imageScrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
        $0.isHidden = true
    }

    private let imageContainerView = UIView()

    private var imageItemViews: [ImageItemView] = []

    private lazy var addImageButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = ColorSystem.gray15
        config.baseForegroundColor = ColorSystem.gray60
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)

        var attributedTitle = AttributedString("사진 추가")
        attributedTitle.font = FontSystem.Pretendard.body2.font
        config.attributedTitle = attributedTitle

        let button = UIButton(configuration: config)
        return button
    }()

    private let loadingIndicator = UIActivityIndicatorView(style: .medium).then {
        $0.hidesWhenStopped = true
        $0.color = ColorSystem.gray60
    }

    private let categorySelectedTrigger = PublishSubject<PostCategory>()
    private let selectedImages = BehaviorRelay<[UIImage]>(value: [])
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray0
        setupUI()
        setupImageViews()
        setupKeyboardHandling()
        bind()
    }

    private func setupUI() {
        view.addSubview(navigationBar)
        navigationBar.addSubview(cancelButton)
        navigationBar.addSubview(submitButton)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(categoryLabel)
        categoryButtons.forEach { button in
            contentView.addSubview(button)
        }
        contentView.addSubview(titleTextField)
        contentView.addSubview(contentTextView)
        contentTextView.addSubview(placeholderLabel)
        contentView.addSubview(addImageButton)
        contentView.addSubview(imageScrollView)
        imageScrollView.addSubview(imageContainerView)

        view.addSubview(loadingIndicator)
    }

    private func setupImageViews() {
        imageContainerView.flex
            .direction(.row)
            .define { flex in
                for _ in 0..<5 {
                    let imageItemView = ImageItemView()
                    imageItemView.isHidden = true
                    imageItemViews.append(imageItemView)

                    flex.addItem(imageItemView)
                        .width(80)
                        .height(80)
                        .marginRight(8)
                }
            }
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

    private func bind() {
        categoryButtons.enumerated().forEach { index, button in
            button.rx.tap
                .map { PostCategory.allCases.filter { $0 != .all }[index] }
                .bind(to: categorySelectedTrigger)
                .disposed(by: disposeBag)
        }

        contentTextView.rx.text.orEmpty
            .map { !$0.isEmpty }
            .bind(to: placeholderLabel.rx.isHidden)
            .disposed(by: disposeBag)

        addImageButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.presentImagePicker()
            })
            .disposed(by: disposeBag)

        selectedImages
            .withUnretained(self)
            .subscribe(onNext: { owner, images in
                owner.updateImageStackView(with: images)
            })
            .disposed(by: disposeBag)

        let input = CreatePostPresenter.Input(
            categorySelected: categorySelectedTrigger.asObservable(),
            titleText: titleTextField.rx.text.orEmpty.asObservable(),
            contentText: contentTextView.rx.text.orEmpty.asObservable(),
            selectedImages: selectedImages.asObservable(),
            submitTapped: submitButton.rx.tap.asObservable(),
            cancelTapped: cancelButton.rx.tap.asObservable()
        )

        let output = presenter.transform(input: input)

        output.selectedCategory
            .drive(with: self) { owner, category in
                owner.updateCategoryButtons(selectedCategory: category)
            }
            .disposed(by: disposeBag)

        output.isSubmitEnabled
            .drive(submitButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.isSubmitEnabled
            .drive(with: self) { owner, isEnabled in
                owner.submitButton.configuration?.baseForegroundColor = isEnabled ? ColorSystem.deepCoast : ColorSystem.gray45
            }
            .disposed(by: disposeBag)

        output.isLoading
            .drive(with: self) { owner, isLoading in
                if isLoading {
                    owner.loadingIndicator.startAnimating()
                    owner.view.isUserInteractionEnabled = false
                } else {
                    owner.loadingIndicator.stopAnimating()
                    owner.view.isUserInteractionEnabled = true
                }
            }
            .disposed(by: disposeBag)

        output.error
            .filter { !$0.isEmpty }
            .drive(with: self) { owner, message in
                let alert = UIAlertController(
                    title: "오류",
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                owner.present(alert, animated: true)
            }
            .disposed(by: disposeBag)

        output.dismiss
            .drive(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func updateCategoryButtons(selectedCategory: PostCategory) {
        let categories = PostCategory.allCases.filter { $0 != .all }
        categoryButtons.enumerated().forEach { index, button in
            let category = categories[index]
            let isSelected = category == selectedCategory

            var config = button.configuration
            config?.baseForegroundColor = isSelected ? ColorSystem.gray0 : ColorSystem.gray60
            config?.baseBackgroundColor = isSelected ? ColorSystem.deepCoast : ColorSystem.gray0
            config?.background.strokeColor = isSelected ? .clear : ColorSystem.gray30
            button.configuration = config
        }
    }

    private func presentImagePicker() {
        let currentCount = selectedImages.value.count
        let remainingCount = 5 - currentCount

        guard remainingCount > 0 else {
            let alert = UIAlertController(
                title: "최대 5장",
                message: "사진은 최대 5장까지 선택할 수 있습니다.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }

        var config = PHPickerConfiguration()
        config.selectionLimit = remainingCount
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func updateImageStackView(with images: [UIImage]) {
        imageScrollView.isHidden = images.isEmpty

        for (index, imageItemView) in imageItemViews.enumerated() {
            if index < images.count {
                imageItemView.isHidden = false
                imageItemView.configure(image: images[index]) { [weak self] in
                    guard let self = self else { return }
                    var current = self.selectedImages.value
                    current.remove(at: index)
                    self.selectedImages.accept(current)
                }
            } else {
                imageItemView.isHidden = true
            }
        }

        if !images.isEmpty {
            imageScrollView.pin
                .below(of: addImageButton)
                .marginTop(12)
                .horizontally(20)
                .height(80)

            imageContainerView.flex.layout(mode: .adjustWidth)
            imageScrollView.contentSize = imageContainerView.frame.size

            contentView.pin.wrapContent(.vertically, padding: 24)
            scrollView.contentSize = contentView.frame.size
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        navigationBar.pin
            .top(view.pin.safeArea.top)
            .horizontally()
            .height(56)

        cancelButton.pin
            .left(20)
            .vCenter()
            .sizeToFit()

        submitButton.pin
            .right(20)
            .vCenter()
            .sizeToFit()

        scrollView.pin
            .below(of: navigationBar)
            .horizontally()
            .bottom()

        contentView.pin
            .top()
            .horizontally()

        categoryLabel.pin
            .top(24)
            .left(20)
            .sizeToFit()

        var xOffset: CGFloat = 0
        categoryButtons.forEach { button in
            button.sizeToFit()
            button.pin
                .below(of: categoryLabel)
                .marginTop(12)
                .left(20 + xOffset)

            xOffset += button.frame.width + 8
        }

        titleTextField.pin
            .below(of: categoryButtons[0])
            .marginTop(24)
            .horizontally(20)
            .height(48)

        contentTextView.pin
            .below(of: titleTextField)
            .marginTop(16)
            .horizontally(20)
            .height(300)

        placeholderLabel.pin
            .top(16)
            .left(16)
            .sizeToFit()

        addImageButton.pin
            .below(of: contentTextView)
            .marginTop(16)
            .left(20)
            .sizeToFit()

        if !imageScrollView.isHidden {
            imageScrollView.pin
                .below(of: addImageButton)
                .marginTop(12)
                .horizontally(20)
                .height(80)

            imageContainerView.flex.layout(mode: .adjustWidth)
            imageScrollView.contentSize = imageContainerView.frame.size
        }

        contentView.pin
            .wrapContent(.vertically, padding: 24)

        scrollView.contentSize = contentView.frame.size

        loadingIndicator.pin
            .center()
    }
}

extension CreatePostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard !results.isEmpty else { return }

        var newImages: [UIImage] = []

        let group = DispatchGroup()

        for result in results {
            group.enter()

            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                defer { group.leave() }

                if let image = object as? UIImage {
                    newImages.append(image)
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            var current = self.selectedImages.value
            current.append(contentsOf: newImages)
            self.selectedImages.accept(current)
        }
    }
}
