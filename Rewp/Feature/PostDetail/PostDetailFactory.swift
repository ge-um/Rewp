//
//  PostDetailFactory.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import Foundation

final class PostDetailFactory {
    static func create(postRepository: PostRepository, postId: String) -> PostDetailViewController {
        let presenter = PostDetailPresenter(postRepository: postRepository, postId: postId)
        let viewController = PostDetailViewController()

        viewController.presenter = presenter

        return viewController
    }
}
