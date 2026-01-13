//
//  CommunityPresenter.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import Foundation
import RxSwift
import RxCocoa
import OSLog

final class CommunityPresenter {
    private let postRepository: PostRepository
    private let locationManager: LocationManager
    private let disposeBag = DisposeBag()
    private var selectedCategory: PostCategory = .all
    private var nextCursor: String?
    private var isLoadingMore = false
    private var fetchedPostIds: Set<String> = []

    init(postRepository: PostRepository, locationManager: LocationManager = .shared) {
        self.postRepository = postRepository
        self.locationManager = locationManager
    }

    enum PostUpdateType {
        case reload([Post])
        case append([Post], startIndex: Int)
        case filter([Post], previousCount: Int)
        case update(Post, at: Int)
    }

    struct Input {
        let viewDidLoad: Observable<Void>
        let viewWillAppear: Observable<Void>
        let refreshTriggered: Observable<Void>
        let postSelected: Observable<String>
        let categorySelected: Observable<PostCategory>
        let cellWillDisplay: Observable<Int>
        let loadMore: Observable<Void>
    }

    struct Output {
        let postUpdate: Driver<PostUpdateType>
        let isLoading: Driver<Bool>
        let isLoadingMore: Driver<Bool>
        let error: Driver<String>
        let navigateToDetail: Driver<String>
        let selectedCategory: Driver<PostCategory>
    }

    func transform(input: Input) -> Output {
        let postsRelay = BehaviorRelay<[Post]>(value: [])
        let postUpdateRelay = PublishRelay<PostUpdateType>()
        let isLoadingRelay = PublishRelay<Bool>()
        let isLoadingMoreRelay = PublishRelay<Bool>()
        let errorRelay = PublishRelay<String>()
        let navigateToDetailRelay = PublishRelay<String>()
        let selectedCategoryRelay = BehaviorRelay<PostCategory>(value: .all)
        let allPosts = BehaviorRelay<[Post]>(value: [])

        let loadTrigger = Observable.merge(
            input.viewDidLoad,
            input.viewWillAppear.skip(1),
            input.refreshTriggered
        )

        input.categorySelected
            .withUnretained(self)
            .subscribe(onNext: { owner, category in
                owner.selectedCategory = category
                selectedCategoryRelay.accept(category)

                let previousCount = postsRelay.value.count
                let filteredPosts = owner.filterPosts(allPosts.value, by: category)
                postsRelay.accept(filteredPosts)
                postUpdateRelay.accept(.filter(filteredPosts, previousCount: previousCount))
            })
            .disposed(by: disposeBag)

        loadTrigger
            .withUnretained(self)
            .do(onNext: { owner, _ in
                isLoadingRelay.accept(true)
                owner.nextCursor = nil
                owner.fetchedPostIds.removeAll()
            })
            .flatMapLatest { owner, _ -> Observable<PostsResponse> in
                return owner.locationManager.currentLocation
                    .take(1)
                    .timeout(.seconds(2), scheduler: MainScheduler.instance)
                    .map { location -> (Double?, Double?) in
                        (location.coordinate.longitude, location.coordinate.latitude)
                    }
                    .catchAndReturn((nil, nil))
                    .flatMap { longitude, latitude in
                        owner.postRepository
                            .fetchPostsByLocation(
                                longitude: longitude,
                                latitude: latitude,
                                limit: "20",
                                productId: NetworkConfig.productId,
                                nextCursor: nil
                            )
                            .asObservable()
                            .catch { error in
                                Logger.community.error("Failed to fetch posts - \(error.localizedDescription)")
                                isLoadingRelay.accept(false)
                                errorRelay.accept("게시글을 불러올 수 없습니다")
                                return .empty()
                            }
                    }
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, response in
                isLoadingRelay.accept(false)
                owner.nextCursor = response.next_cursor == "0" ? nil : response.next_cursor
                let posts = response.data.map { $0.toDomain() }
                allPosts.accept(posts)

                let filteredPosts = owner.filterPosts(posts, by: owner.selectedCategory)
                postsRelay.accept(filteredPosts)
                postUpdateRelay.accept(.reload(filteredPosts))
            })
            .disposed(by: disposeBag)

        input.loadMore
            .withUnretained(self)
            .filter { owner, _ in
                !owner.isLoadingMore && owner.nextCursor != nil
            }
            .do(onNext: { owner, _ in
                owner.isLoadingMore = true
                isLoadingMoreRelay.accept(true)
            })
            .flatMapLatest { owner, _ -> Observable<PostsResponse> in
                return owner.locationManager.currentLocation
                    .take(1)
                    .timeout(.seconds(2), scheduler: MainScheduler.instance)
                    .map { location -> (Double?, Double?) in
                        (location.coordinate.longitude, location.coordinate.latitude)
                    }
                    .catchAndReturn((nil, nil))
                    .flatMap { longitude, latitude in
                        owner.postRepository
                            .fetchPostsByLocation(
                                longitude: longitude,
                                latitude: latitude,
                                limit: "20",
                                productId: NetworkConfig.productId,
                                nextCursor: owner.nextCursor
                            )
                            .asObservable()
                            .catch { error in
                                Logger.community.error("Failed to load more posts - \(error.localizedDescription)")
                                owner.isLoadingMore = false
                                isLoadingMoreRelay.accept(false)
                                return .empty()
                            }
                    }
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, response in
                owner.isLoadingMore = false
                isLoadingMoreRelay.accept(false)
                owner.nextCursor = response.next_cursor == "0" ? nil : response.next_cursor
                let newPosts = response.data.map { $0.toDomain() }
                let updatedPosts = allPosts.value + newPosts
                allPosts.accept(updatedPosts)

                let previousCount = postsRelay.value.count
                let filteredPosts = owner.filterPosts(updatedPosts, by: owner.selectedCategory)
                postsRelay.accept(filteredPosts)

                let newFilteredPosts = Array(filteredPosts[previousCount...])
                postUpdateRelay.accept(.append(newFilteredPosts, startIndex: previousCount))
            })
            .disposed(by: disposeBag)

        input.cellWillDisplay
            .withUnretained(self)
            .filter { owner, index in
                let posts = postsRelay.value
                guard index < posts.count else { return false }
                let post = posts[index]
                return !owner.fetchedPostIds.contains(post.postId)
            }
            .flatMap { owner, index -> Observable<(Int, PostDetailDTO)> in
                let posts = postsRelay.value
                guard index < posts.count else { return .empty() }
                let post = posts[index]

                return owner.postRepository
                    .fetchPostDetail(postId: post.postId)
                    .asObservable()
                    .map { (index, $0) }
                    .catch { error in
                        Logger.community.error("Failed to fetch post detail - \(error.localizedDescription)")
                        return .empty()
                    }
            }
            .withUnretained(self)
            .subscribe(onNext: { owner, result in
                let (index, postDetailDTO) = result
                var posts = postsRelay.value
                guard index < posts.count else { return }

                let updatedPost = postDetailDTO.toDomain()
                owner.fetchedPostIds.insert(updatedPost.postId)
                posts[index] = updatedPost
                postsRelay.accept(posts)
                postUpdateRelay.accept(.update(updatedPost, at: index))

                var all = allPosts.value
                if let allIndex = all.firstIndex(where: { $0.postId == updatedPost.postId }) {
                    all[allIndex] = updatedPost
                    allPosts.accept(all)
                }
            })
            .disposed(by: disposeBag)

        input.postSelected
            .bind(to: navigateToDetailRelay)
            .disposed(by: disposeBag)

        return Output(
            postUpdate: postUpdateRelay.asDriver(onErrorDriveWith: .empty()),
            isLoading: isLoadingRelay.asDriver(onErrorJustReturn: false),
            isLoadingMore: isLoadingMoreRelay.asDriver(onErrorJustReturn: false),
            error: errorRelay.asDriver(onErrorJustReturn: ""),
            navigateToDetail: navigateToDetailRelay.asDriver(onErrorDriveWith: .empty()),
            selectedCategory: selectedCategoryRelay.asDriver()
        )
    }

    private func filterPosts(_ posts: [Post], by category: PostCategory) -> [Post] {
        guard category != .all else { return posts }
        return posts.filter { $0.category == category }
    }
}
