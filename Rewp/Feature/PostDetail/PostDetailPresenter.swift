//
//  PostDetailPresenter.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import Foundation
import RxSwift
import RxCocoa
import OSLog

final class PostDetailPresenter {
    private let postRepository: PostRepository
    private let postId: String
    private let disposeBag = DisposeBag()

    init(postRepository: PostRepository, postId: String) {
        self.postRepository = postRepository
        self.postId = postId
    }

    struct Input {
        let viewDidLoad: Observable<Void>
        let likeTapped: Observable<Void>
        let sendComment: Observable<String>
        let replyToComment: Observable<(commentId: String, content: String)>
    }

    struct Output {
        let post: Driver<Post>
        let error: Driver<String>
        let isLiked: Driver<Bool>
        let likeCount: Driver<Int>
        let commentPosted: Driver<Void>
    }

    func transform(input: Input) -> Output {
        let postRelay = PublishRelay<Post>()
        let errorRelay = PublishRelay<String>()
        let isLikedRelay = BehaviorRelay<Bool>(value: false)
        let likeCountRelay = BehaviorRelay<Int>(value: 0)
        let commentPostedRelay = PublishRelay<Void>()

        let refreshPostTrigger = PublishRelay<Void>()

        let loadTrigger = Observable.merge(
            input.viewDidLoad,
            refreshPostTrigger.asObservable()
        )

        loadTrigger
            .withUnretained(self)
            .do(onNext: { owner, _ in
            })
            .flatMapLatest { owner, _ in
                owner.postRepository
                    .fetchPostDetail(postId: owner.postId)
                    .asObservable()
                    .catch { error in
                        Logger.community.error("Failed to fetch post detail - \(error.localizedDescription)")
                        errorRelay.accept("게시글을 불러올 수 없습니다")
                        return .empty()
                    }
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, postDTO in
                let post = postDTO.toDomain()
                postRelay.accept(post)
                isLikedRelay.accept(post.isLiked)
                likeCountRelay.accept(post.likesCount)
            })
            .disposed(by: disposeBag)

        input.likeTapped
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let currentState = isLikedRelay.value
                let currentCount = likeCountRelay.value
                let newLikedState = !currentState
                let newCount = newLikedState ? currentCount + 1 : currentCount - 1

                isLikedRelay.accept(newLikedState)
                likeCountRelay.accept(newCount)

                owner.postRepository
                    .toggleLike(postId: owner.postId, likeStatus: newLikedState)
                    .asObservable()
                    .catch { error in
                        Logger.community.error("Failed to toggle like - \(error.localizedDescription)")
                        isLikedRelay.accept(currentState)
                        likeCountRelay.accept(currentCount)
                        return .empty()
                    }
                    .subscribe()
                    .disposed(by: owner.disposeBag)
            })
            .disposed(by: disposeBag)

        input.sendComment
            .withUnretained(self)
            .flatMapLatest { owner, content in
                owner.postRepository
                    .createComment(postId: owner.postId, content: content, parentCommentId: nil)
                    .asObservable()
                    .catch { error in
                        Logger.community.error("Failed to create comment - \(error.localizedDescription)")
                        errorRelay.accept("댓글 작성에 실패했습니다")
                        return .empty()
                    }
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                commentPostedRelay.accept(())
                refreshPostTrigger.accept(())
            })
            .disposed(by: disposeBag)

        input.replyToComment
            .withUnretained(self)
            .flatMapLatest { owner, data in
                owner.postRepository
                    .createComment(postId: owner.postId, content: data.content, parentCommentId: data.commentId)
                    .asObservable()
                    .catch { error in
                        Logger.community.error("Failed to create reply - \(error.localizedDescription)")
                        errorRelay.accept("답글 작성에 실패했습니다")
                        return .empty()
                    }
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                commentPostedRelay.accept(())
                refreshPostTrigger.accept(())
            })
            .disposed(by: disposeBag)

        return Output(
            post: postRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorJustReturn: ""),
            isLiked: isLikedRelay.asDriver(),
            likeCount: likeCountRelay.asDriver(),
            commentPosted: commentPostedRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
