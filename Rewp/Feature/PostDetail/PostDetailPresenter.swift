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
    }

    struct Output {
        let post: Driver<Post>
        let error: Driver<String>
        let isLiked: Driver<Bool>
    }

    func transform(input: Input) -> Output {
        let postRelay = PublishRelay<Post>()
        let errorRelay = PublishRelay<String>()
        let isLikedRelay = BehaviorRelay<Bool>(value: false)

        input.viewDidLoad
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
            })
            .disposed(by: disposeBag)

        input.likeTapped
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let newLikedState = !isLikedRelay.value
                isLikedRelay.accept(newLikedState)
            })
            .disposed(by: disposeBag)

        return Output(
            post: postRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorJustReturn: ""),
            isLiked: isLikedRelay.asDriver()
        )
    }
}
