//
//  PostRepository.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import Foundation
import RxSwift

protocol PostRepository {
    func fetchPostsByLocation(longitude: Double?, latitude: Double?, limit: String?, productId: String?, nextCursor: String?) -> Single<PostsResponse>
    func fetchPostDetail(postId: String) -> Single<PostDetailDTO>
    func createPost(category: String, title: String, content: String, latitude: Double, longitude: Double, files: [String]) -> Single<PostDetailDTO>
    func deletePost(postId: String) -> Single<Void>
    func toggleLike(postId: String, likeStatus: Bool) -> Single<Bool>
    func createComment(postId: String, content: String, parentCommentId: String?) -> Single<CommentResponse>
    func updateComment(postId: String, commentId: String, content: String) -> Single<CommentResponse>
    func deleteComment(postId: String, commentId: String) -> Single<Void>
}

final class PostRepositoryImpl: PostRepository {
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func fetchPostsByLocation(longitude: Double?, latitude: Double?, limit: String?, productId: String?, nextCursor: String?) -> Single<PostsResponse> {
        return authService.authenticatedRequest(
            PostRouter.geolocationPosts(
                longitude: longitude,
                latitude: latitude,
                limit: limit,
                product_id: productId,
                next_cursor: nextCursor
            )
        )
    }

    func fetchPostDetail(postId: String) -> Single<PostDetailDTO> {
        return authService.authenticatedRequest(PostRouter.postDetail(postId: postId))
    }

    func createPost(category: String, title: String, content: String, latitude: Double, longitude: Double, files: [String]) -> Single<PostDetailDTO> {
        return authService.authenticatedRequest(PostRouter.createPost(category: category, title: title, content: content, latitude: latitude, longitude: longitude, files: files))
    }

    func deletePost(postId: String) -> Single<Void> {
        return authService.authenticatedRequestEmpty(PostRouter.deletePost(postId: postId))
    }

    func toggleLike(postId: String, likeStatus: Bool) -> Single<Bool> {
        return authService.authenticatedRequest(PostRouter.toggleLike(postId: postId, likeStatus: likeStatus))
            .map { (response: LikeResponse) in
                return response.like_status
            }
    }

    func createComment(postId: String, content: String, parentCommentId: String?) -> Single<CommentResponse> {
        return authService.authenticatedRequest(PostRouter.createComment(postId: postId, content: content, parentCommentId: parentCommentId))
    }

    func updateComment(postId: String, commentId: String, content: String) -> Single<CommentResponse> {
        return authService.authenticatedRequest(PostRouter.updateComment(postId: postId, commentId: commentId, content: content))
    }

    func deleteComment(postId: String, commentId: String) -> Single<Void> {
        return authService.authenticatedRequestEmpty(PostRouter.deleteComment(postId: postId, commentId: commentId))
    }
}

