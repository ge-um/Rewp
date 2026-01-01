//
//  EstateDetailViewController.swift
//  Rewp
//
//  Created by 금가경 on 12/31/25.
//

import UIKit
import PinLayout
import RxSwift
import Then

final class EstateDetailViewController: UIViewController {
    var presenter: EstateDetailPresenter!
    var container: AppContainer!

    private let estateId: String
    private let disposeBag = DisposeBag()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private lazy var navigationBar = CustomNavigationBar(title: "문래동 롯데캐슬", showBackButton: true, showRightButton: true)

    private let imageCarousel = ImageCarousel()

    init(estateId: String) {
        self.estateId = estateId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray0
        setupUI()
        bind()
    }

    private func setupUI() {
        view.addSubview(navigationBar)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(imageCarousel)
    }

    private func bind() {
        navigationBar.onBackButtonTap = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

        navigationBar.onRightButtonTapped = {
            print("찜하기 버튼 탭")
        }

        imageCarousel.onImageTapped = { index in
            print("이미지 탭: \(index)")
        }

        imageCarousel.configure(with: [
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        navigationBar.pin
            .top(view.pin.safeArea.top)
            .horizontally()
            .height(56)

        scrollView.pin
            .below(of: navigationBar)
            .horizontally()
            .bottom()

        contentView.pin
            .top()
            .horizontally()
            .minHeight(scrollView.frame.height)

        imageCarousel.pin
            .top()
            .horizontally()
            .height(250)

        contentView.pin
            .horizontally()
            .height(imageCarousel.frame.maxY)

        scrollView.contentSize = contentView.frame.size
    }
}
