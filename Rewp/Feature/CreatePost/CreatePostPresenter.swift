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
import UIKit

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
        let selectedImages: Observable<[UIImage]>
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
                input.contentText,
                input.selectedImages
            ))
            .do(onNext: { _ in
                isLoadingRelay.accept(true)
            })
            .flatMapLatest { [weak self] category, title, content, images -> Observable<Void> in
                guard let self = self else { return .empty() }

                let categoryString = category.rawValue

                let validatedImages = self.validateImages(images)
                guard validatedImages.errors.isEmpty else {
                    isLoadingRelay.accept(false)
                    errorRelay.accept(validatedImages.errors.first ?? "이미지 검증 실패")
                    return .empty()
                }

                let imageDataArray = validatedImages.validImages.compactMap { $0.jpegData(compressionQuality: 0.8) }

                if imageDataArray.isEmpty {
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

                return self.postRepository
                    .uploadPostFiles(files: imageDataArray)
                    .asObservable()
                    .flatMap { uploadResponse -> Observable<Void> in
                        return self.postRepository
                            .createPost(
                                category: categoryString,
                                title: title,
                                content: content,
                                latitude: 37.654215,
                                longitude: 127.049914,
                                files: uploadResponse.files
                            )
                            .asObservable()
                            .map { _ in }
                    }
                    .do(onNext: { _ in
                        isLoadingRelay.accept(false)
                        successRelay.accept(())
                        dismissRelay.accept(())
                        Logger.community.info("Post created successfully with images")
                    }, onError: { error in
                        isLoadingRelay.accept(false)
                        errorRelay.accept("게시글 작성에 실패했습니다")
                        Logger.community.error("Failed to create post with images - \(error.localizedDescription)")
                    })
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

    private func validateImages(_ images: [UIImage]) -> (validImages: [UIImage], errors: [String]) {
        var validImages: [UIImage] = []
        var errors: [String] = []

        if images.count > 5 {
            errors.append("이미지는 최대 5개까지 첨부할 수 있습니다.")
            return ([], errors)
        }

        for image in images {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                errors.append("이미지 변환에 실패했습니다.")
                continue
            }

            let sizeInMB = Double(imageData.count) / (1024 * 1024)
            if sizeInMB > 5 {
                errors.append("이미지 크기는 5MB를 초과할 수 없습니다.")
                continue
            }

            validImages.append(image)
        }

        return (validImages, errors)
    }
}
