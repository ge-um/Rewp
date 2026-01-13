//
//  CreatePostFactory.swift
//  Rewp
//
//  Created by 금가경 on 01/13/26.
//

import UIKit

final class CreatePostFactory {
    static func make(postRepository: PostRepository) -> CreatePostViewController {
        let viewController = CreatePostViewController()
        let presenter = CreatePostPresenter(postRepository: postRepository)
        viewController.presenter = presenter
        viewController.modalPresentationStyle = .fullScreen

        return viewController
    }
}
