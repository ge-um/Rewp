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
            background.strokeColor = index == 0 ? ColorSystem.deepCoast : ColorSystem.gray30
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

    private let viewDidLoadTrigger = PublishSubject<Void>()
    private let viewWillAppearTrigger = PublishSubject<Void>()
    private let refreshTriggered = PublishSubject<Void>()
    private let postSelectedTrigger = PublishSubject<String>()
    private let categorySelectedTrigger = PublishSubject<PostCategory>()

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

        tableView.refreshControl = refreshControl
        tableView.dataSource = self
        tableView.delegate = self
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
            categorySelected: categorySelectedTrigger.asObservable()
        )

        let output = presenter.transform(input: input)

        output.posts
            .drive(with: self) { owner, posts in
                owner.posts = posts
                owner.tableView.reloadData()
            }
            .disposed(by: disposeBag)

        output.isLoading
            .drive(with: self) { owner, isLoading in
                if isLoading {
                    owner.refreshControl.beginRefreshing()
                } else {
                    owner.refreshControl.endRefreshing()
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
    }

    private func updateCategoryButtons(selectedCategory: PostCategory) {
        categoryButtons.enumerated().forEach { index, button in
            let category = PostCategory.allCases[index]
            let isSelected = category == selectedCategory

            var config = button.configuration
            config?.baseForegroundColor = isSelected ? ColorSystem.gray0 : ColorSystem.gray60
            config?.baseBackgroundColor = isSelected ? ColorSystem.deepCoast : ColorSystem.gray0
            config?.background.strokeColor = isSelected ? ColorSystem.deepCoast : ColorSystem.gray30
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
}
