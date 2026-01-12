//
//  PostDetailViewController.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import UIKit
import RxSwift
import RxCocoa
import PinLayout
import Kingfisher

final class PostDetailViewController: UIViewController {
    var presenter: PostDetailPresenter!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
}
