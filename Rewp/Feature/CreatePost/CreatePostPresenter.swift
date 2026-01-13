//
//  CreatePostPresenter.swift
//  Rewp
//
//  Created by 금가경 on 01/13/26.
//

import Foundation
import RxSwift
import RxCocoa
import OSLog

final class CreatePostPresenter {
    private let postRepository: PostRepository
    private let disposeBag = DisposeBag()

    init(postRepository: PostRepository) {
        self.postRepository = postRepository
    }

    struct Input {
        let categorySelected: Observable<PostCategory>
        let titleText: Observable<String>
        let contentText: Observable<String>
        let submitTapped: Observable<Void>
        let cancelTapped: Observable<Void>
    }

    struct Output {
        let selectedCategory: Driver<PostCategory>
        let isSubmitEnabled: Driver<Bool>
        let isLoading: Driver<Bool>
        let error: Driver<String>
        let dismiss: Driver<Void>
        let success: Driver<Void>
    }

    func transform(input: Input) -> Output {
        let selectedCategoryRelay = BehaviorRelay<PostCategory>(value: .free)
        let isLoadingRelay = PublishRelay<Bool>()
        let errorRelay = PublishRelay<String>()
        let dismissRelay = PublishRelay<Void>()
        let successRelay = PublishRelay<Void>()

        input.categorySelected
            .bind(to: selectedCategoryRelay)
            .disposed(by: disposeBag)

        let isSubmitEnabled = Observable.combineLatest(
            input.titleText,
            input.contentText
        )
        .map { title, content in
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        input.submitTapped
            .withLatestFrom(Observable.combineLatest(
                selectedCategoryRelay.asObservable(),
                input.titleText,
                input.contentText
            ))
            .do(onNext: { _ in
                isLoadingRelay.accept(true)
            })
            .flatMapLatest { [weak self] category, title, content -> Observable<Void> in
                guard let self = self else { return .empty() }

                let categoryString = category.rawValue

                return self.postRepository
                    .createPost(
                        category: categoryString,
                        title: title,
                        content: content,
                        latitude: 37.654215,
                        longitude: 127.049914,
                        files: []
                    )
                    .asObservable()
                    .do(onNext: { _ in
                        isLoadingRelay.accept(false)
                        successRelay.accept(())
                        dismissRelay.accept(())
                        Logger.community.info("Post created successfully")
                    }, onError: { error in
                        isLoadingRelay.accept(false)
                        errorRelay.accept("게시글 작성에 실패했습니다")
                        Logger.community.error("Failed to create post - \(error.localizedDescription)")
                    })
                    .map { _ in }
                    .catch { _ in .empty() }
            }
            .subscribe()
            .disposed(by: disposeBag)

        input.cancelTapped
            .bind(to: dismissRelay)
            .disposed(by: disposeBag)

        return Output(
            selectedCategory: selectedCategoryRelay.asDriver(),
            isSubmitEnabled: isSubmitEnabled.asDriver(onErrorJustReturn: false),
            isLoading: isLoadingRelay.asDriver(onErrorJustReturn: false),
            error: errorRelay.asDriver(onErrorJustReturn: ""),
            dismiss: dismissRelay.asDriver(onErrorDriveWith: .empty()),
            success: successRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
