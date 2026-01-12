//
//  PostRepository.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import Foundation
import RxSwift

protocol PostRepository {
    func fetchPostsByLocation(longitude: Double?, latitude: Double?, limit: String?, productId: String?) -> Single<[PostDTO]>
    func fetchPostDetail(postId: String) -> Single<PostDTO>
}

final class PostRepositoryImpl: PostRepository {
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func fetchPostsByLocation(longitude: Double?, latitude: Double?, limit: String?, productId: String?) -> Single<[PostDTO]> {
        return authService.authenticatedRequest(
            PostRouter.geolocationPosts(
                longitude: longitude,
                latitude: latitude,
                limit: limit,
                product_id: productId
            )
        )
        .map { (response: PostsResponse) in
            return response.data
        }
    }

    func fetchPostDetail(postId: String) -> Single<PostDTO> {
        return authService.authenticatedRequest(PostRouter.postDetail(postId: postId))
    }
}
