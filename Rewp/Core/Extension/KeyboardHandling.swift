//
//  KeyboardHandling.swift
//  Rewp
//
//  Created by 금가경 on 01/13/26.
//

import UIKit
import RxSwift

protocol KeyboardHandling: AnyObject {
    var keyboardHeight: CGFloat { get set }
    var disposeBag: DisposeBag { get }

    func setupKeyboardHandling()
    func dismissKeyboard()
}

extension KeyboardHandling where Self: UIViewController {
    func setupKeyboardHandling() {
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .withUnretained(self)
            .subscribe(onNext: { owner, notification in
                guard let userInfo = notification.userInfo,
                      let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                    return
                }

                owner.keyboardHeight = keyboardFrame.height - owner.view.pin.safeArea.bottom
                owner.view.setNeedsLayout()

                UIView.animate(withDuration: duration) {
                    owner.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillHideNotification)
            .withUnretained(self)
            .subscribe(onNext: { owner, notification in
                guard let userInfo = notification.userInfo,
                      let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                    return
                }

                owner.keyboardHeight = 0
                owner.view.setNeedsLayout()

                UIView.animate(withDuration: duration) {
                    owner.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)

        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        tapGesture.rx.event
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.dismissKeyboard()
            })
            .disposed(by: disposeBag)
        view.addGestureRecognizer(tapGesture)
    }
}
