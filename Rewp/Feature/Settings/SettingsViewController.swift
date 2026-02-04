//
//  SettingsViewController.swift
//  Rewp
//
//  Created by 금가경 on 12/28/25.
//

import UIKit
import PinLayout
import FlexLayout
import RxSwift
import RxCocoa
import Then

final class SettingsViewController: UIViewController {
    var presenter: SettingsPresenter!
    var container: AppContainer!

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let contentView = UIView()

    private let titleLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.title1Bold, text: "설정")
        $0.textColor = ColorSystem.gray90
    }

    private let logoutButton = UIButton().then {
        $0.setTitle("로그아웃", for: .normal)
        $0.setTitleColor(ColorSystem.gray0, for: .normal)
        $0.backgroundColor = ColorSystem.deepCream
        $0.layer.cornerRadius = 8
        $0.titleLabel?.font = FontSystem.Pretendard.body2.font
    }

    private let loadingIndicator = UIActivityIndicatorView(style: .medium).then {
        $0.hidesWhenStopped = true
        $0.color = ColorSystem.gray90
    }

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray15
        setupUI()
        bind()
    }

    private func setupUI() {
        view.addSubview(scrollView)

        scrollView.addSubview(contentView)

        contentView.addSubview(titleLabel)
        contentView.addSubview(logoutButton)
        contentView.addSubview(loadingIndicator)
    }

    private func bind() {
        let input = SettingsPresenter.Input(
            logoutTapped: logoutButton.rx.tap.asObservable()
        )

        let output = presenter.transform(input: input)

        output.isLoading
            .drive(with: self) { owner, isLoading in
                if isLoading {
                    owner.loadingIndicator.startAnimating()
                    owner.logoutButton.isEnabled = false
                } else {
                    owner.loadingIndicator.stopAnimating()
                    owner.logoutButton.isEnabled = true
                }
            }
            .disposed(by: disposeBag)

        output.shouldLogout
            .drive(with: self) { owner, _ in
                let loginVC = owner.container.makeLoginViewController()
                let nav = UINavigationController(rootViewController: loginVC)
                nav.navigationBar.isHidden = true
                owner.view.window?.rootViewController = nav
                owner.view.window?.makeKeyAndVisible()
            }
            .disposed(by: disposeBag)

        output.logoutError
            .drive(with: self) { owner, message in
                let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                owner.present(alert, animated: true)
            }
            .disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        scrollView.pin
            .top(view.pin.safeArea.top)
            .horizontally()
            .bottom()

        contentView.pin
            .top()
            .horizontally()

        titleLabel.pin
            .top(24)
            .horizontally(20)
            .sizeToFit(.width)

        logoutButton.pin
            .below(of: titleLabel)
            .marginTop(32)
            .horizontally(20)
            .height(48)

        loadingIndicator.pin
            .center(to: logoutButton.anchor.center)

        contentView.pin.height(
            logoutButton.frame.maxY + 20
        )

        scrollView.contentSize = contentView.frame.size
    }
}
