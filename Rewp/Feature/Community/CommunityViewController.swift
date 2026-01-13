//
//  CommunityViewController.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import UIKit
import RxSwift
import RxCocoa
import PinLayout

final class CommunityViewController: UIViewController {
    var presenter: CommunityPresenter!
    var container: AppContainer!

    private let titleLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.title1Bold, text: "커뮤니티")
        $0.textColor = ColorSystem.gray90
    }

    private let categoryScrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
        $0.backgroundColor = .clear
    }

    private let categoryContainerView = UIView()

    private lazy var categoryButtons: [UIButton] = {
        return PostCategory.allCases.enumerated().map { index, category in
            var config = UIButton.Configuration.filled()
            config.title = category.displayName
            config.baseForegroundColor = index == 0 ? ColorSystem.gray0 : ColorSystem.gray60
            config.baseBackgroundColor = index == 0 ? ColorSystem.deepCoast : ColorSystem.gray0
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

            var background = UIButton.Configuration.filled().background
            background.strokeColor = index == 0 ? .clear : ColorSystem.gray30
            background.strokeWidth = 1
            config.background = background

            let button = UIButton(configuration: config)
            button.configurationUpdateHandler = { btn in
                var config = btn.configuration
                config?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                    var outgoing = incoming
                    outgoing.font = FontSystem.Pretendard.body2.font
                    return outgoing
                }
                btn.configuration = config
            }
            button.tag = index

            return button
        }
    }()

    private let tableView = UITableView().then {
        $0.backgroundColor = ColorSystem.gray15
        $0.separatorStyle = .none
        $0.register(PostCell.self, forCellReuseIdentifier: PostCell.identifier)
    }

    private let refreshControl = UIRefreshControl()

    private lazy var writeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "plus")
        config.baseBackgroundColor = ColorSystem.deepCoast
        config.baseForegroundColor = ColorSystem.gray0
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

        let button = UIButton(configuration: config)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 8

        return button
    }()

    private let loadingFooterView = UIView().then {
        $0.frame = CGRect(x: 0, y: 0, width: 0, height: 60)
        $0.backgroundColor = ColorSystem.gray15
    }

    private let footerActivityIndicator = UIActivityIndicatorView(style: .medium).then {
        $0.color = ColorSystem.gray60
        $0.hidesWhenStopped = true
    }

    private let viewDidLoadTrigger = PublishSubject<Void>()
    private let viewWillAppearTrigger = PublishSubject<Void>()
    private let refreshTriggered = PublishSubject<Void>()
    private let postSelectedTrigger = PublishSubject<String>()
    private let categorySelectedTrigger = PublishSubject<PostCategory>()
    private let cellWillDisplayTrigger = PublishSubject<Int>()
    private let loadMoreTrigger = PublishSubject<Void>()

    private var posts: [Post] = []
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray15
        setupUI()
        bind()
        viewDidLoadTrigger.onNext(())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearTrigger.onNext(())
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(categoryScrollView)
        view.addSubview(tableView)

        categoryScrollView.addSubview(categoryContainerView)
        categoryButtons.forEach { button in
            categoryContainerView.addSubview(button)
        }

        loadingFooterView.addSubview(footerActivityIndicator)

        tableView.refreshControl = refreshControl
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(writeButton)
    }

    private func bind() {
        categoryButtons.enumerated().forEach { index, button in
            button.rx.tap
                .map { PostCategory.allCases[index] }
                .bind(to: categorySelectedTrigger)
                .disposed(by: disposeBag)
        }

        let input = CommunityPresenter.Input(
            viewDidLoad: viewDidLoadTrigger.asObservable(),
            viewWillAppear: viewWillAppearTrigger.asObservable(),
            refreshTriggered: refreshControl.rx.controlEvent(.valueChanged).asObservable(),
            postSelected: postSelectedTrigger.asObservable(),
            categorySelected: categorySelectedTrigger.asObservable(),
            cellWillDisplay: cellWillDisplayTrigger.asObservable(),
            loadMore: loadMoreTrigger.asObservable()
        )

        let output = presenter.transform(input: input)

        output.postUpdate
            .drive(with: self) { owner, updateType in
                switch updateType {
                case .reload(let posts):
                    owner.posts = posts
                    owner.tableView.reloadData()

                case .append(let newPosts, let startIndex):
                    owner.posts.append(contentsOf: newPosts)
                    let indexPaths = (startIndex..<owner.posts.count).map {
                        IndexPath(row: $0, section: 0)
                    }
                    owner.tableView.performBatchUpdates {
                        owner.tableView.insertRows(at: indexPaths, with: .none)
                    }

                case .filter(let posts, let previousCount):
                    let oldCount = previousCount
                    let newCount = posts.count
                    owner.posts = posts

                    if oldCount == newCount {
                        owner.tableView.reloadData()
                    } else {
                        owner.tableView.performBatchUpdates {
                            if oldCount > newCount {
                                let deleteIndexPaths = (newCount..<oldCount).map {
                                    IndexPath(row: $0, section: 0)
                                }
                                owner.tableView.deleteRows(at: deleteIndexPaths, with: .fade)
                            } else {
                                let insertIndexPaths = (oldCount..<newCount).map {
                                    IndexPath(row: $0, section: 0)
                                }
                                owner.tableView.insertRows(at: insertIndexPaths, with: .fade)
                            }
                        }
                    }

                case .update(let post, let index):
                    guard index < owner.posts.count else { return }
                    owner.posts[index] = post
                    let indexPath = IndexPath(row: index, section: 0)
                    if owner.tableView.indexPathsForVisibleRows?.contains(indexPath) == true {
                        owner.tableView.reloadRows(at: [indexPath], with: .none)
                    }
                }
            }
            .disposed(by: disposeBag)

        output.isLoading
            .filter { !$0 }
            .drive(with: self) { owner, _ in
                owner.refreshControl.endRefreshing()
            }
            .disposed(by: disposeBag)

        output.isLoadingMore
            .drive(with: self) { owner, isLoadingMore in
                if isLoadingMore {
                    owner.tableView.tableFooterView = owner.loadingFooterView
                    owner.footerActivityIndicator.pin.center()
                    owner.footerActivityIndicator.startAnimating()
                } else {
                    owner.footerActivityIndicator.stopAnimating()
                    owner.tableView.tableFooterView = nil
                }
            }
            .disposed(by: disposeBag)

        output.error
            .filter { !$0.isEmpty }
            .drive(with: self) { owner, message in
                let alert = UIAlertController(
                    title: "오류",
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                owner.present(alert, animated: true)
            }
            .disposed(by: disposeBag)

        output.navigateToDetail
            .drive(with: self) { owner, postId in
                let detailVC = owner.container.makePostDetailViewController(postId: postId)
                owner.navigationController?.pushViewController(detailVC, animated: true)
            }
            .disposed(by: disposeBag)

        output.selectedCategory
            .drive(with: self) { owner, category in
                owner.updateCategoryButtons(selectedCategory: category)
            }
            .disposed(by: disposeBag)

        writeButton.rx.tap
            .subscribe(with: self) { owner, _ in
                let createPostVC = owner.container.makeCreatePostViewController()
                owner.present(createPostVC, animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func updateCategoryButtons(selectedCategory: PostCategory) {
        categoryButtons.enumerated().forEach { index, button in
            let category = PostCategory.allCases[index]
            let isSelected = category == selectedCategory

            var config = button.configuration
            config?.baseForegroundColor = isSelected ? ColorSystem.gray0 : ColorSystem.gray60
            config?.baseBackgroundColor = isSelected ? ColorSystem.deepCoast : ColorSystem.gray0
            config?.background.strokeColor = isSelected ? .clear : ColorSystem.gray30
            button.configuration = config
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        titleLabel.pin
            .top(view.pin.safeArea.top + 16)
            .left(20)
            .sizeToFit()

        categoryScrollView.pin
            .below(of: titleLabel)
            .marginTop(16)
            .horizontally()
            .height(48)

        categoryContainerView.pin
            .top()
            .left(20)
            .height(48)

        var xOffset: CGFloat = 0
        categoryButtons.forEach { button in
            button.sizeToFit()
            button.pin
                .left(xOffset)
                .vCenter()

            xOffset += button.frame.width + 8
        }

        categoryContainerView.pin.width(xOffset - 8)
        categoryScrollView.contentSize = CGSize(width: categoryContainerView.frame.width + 40, height: 48)

        tableView.pin
            .below(of: categoryScrollView)
            .marginTop(8)
            .horizontally()
            .bottom()

        writeButton.pin
            .bottom(view.pin.safeArea.bottom + 24)
            .right(24)
            .size(56)
    }
}

extension CommunityViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PostCell.identifier,
            for: indexPath
        ) as? PostCell else {
            return UITableViewCell()
        }

        let post = posts[indexPath.row]
        cell.configure(with: post)
        return cell
    }
}

extension CommunityViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        postSelectedTrigger.onNext(post.postId)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 132
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellWillDisplayTrigger.onNext(indexPath.row)

        if posts.count >= 20 && indexPath.row >= posts.count - 5 {
            loadMoreTrigger.onNext(())
        }
    }
}
