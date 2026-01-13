//
//  PostDetailViewController.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import UIKit
import RxSwift
import RxCocoa
import PinLayout
import FlexLayout
import Kingfisher
import OSLog

final class PostDetailViewController: UIViewController {
    var presenter: PostDetailPresenter!

    private var navigationBar: CustomNavigationBar!

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }
    private let contentContainer = UIView()

    private let profileImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = ColorSystem.gray30
        $0.layer.cornerRadius = 24
        $0.clipsToBounds = true
    }

    private let profileInfoContainer = UIView()

    private let nicknameLabel = UILabel().then {
        $0.textColor = ColorSystem.gray90
    }

    private let timeLabel = UILabel().then {
        $0.textColor = ColorSystem.gray45
    }

    private let titleLabel = UILabel().then {
        $0.textColor = ColorSystem.gray90
        $0.numberOfLines = 0
    }

    private let contentLabel = UILabel().then {
        $0.textColor = ColorSystem.gray90
        $0.numberOfLines = 0
    }

    private lazy var imageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.register(PostImageCell.self, forCellWithReuseIdentifier: PostImageCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isHidden = true
        return collectionView
    }()

    private var imageURLs: [String] = []

    private let likeButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(named: "Like_Empty")?.withTintColor(ColorSystem.gray75), for: .normal)
        $0.setImage(UIImage(named: "Like_Fill")?.withTintColor(ColorSystem.brightCoast), for: .selected)
    }

    private let likeCountLabel = UILabel().then {
        $0.textColor = ColorSystem.gray75
    }

    private let commentsSectionLabel = UILabel().then {
        $0.textColor = ColorSystem.gray90
    }

    private let commentsTableView = UITableView().then {
        $0.backgroundColor = .clear
        $0.separatorStyle = .none
        $0.isScrollEnabled = false
        $0.register(CommentCell.self, forCellReuseIdentifier: CommentCell.identifier)
    }

    private var comments: [Comment] = []

    private let viewDidLoadTrigger = PublishSubject<Void>()
    private let likeTappedTrigger = PublishSubject<Void>()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        bind()
        viewDidLoadTrigger.onNext(())
    }

    private func setupUI() {
        view.backgroundColor = ColorSystem.gray0
        navigationBar = addCustomNavigationBar()
        enableSwipeBackGesture()

        view.addSubview(scrollView)
        view.addSubview(navigationBar)
        scrollView.addSubview(contentContainer)

        contentContainer.addSubview(profileImageView)
        contentContainer.addSubview(profileInfoContainer)
        contentContainer.addSubview(titleLabel)
        contentContainer.addSubview(contentLabel)
        contentContainer.addSubview(imageCollectionView)
        contentContainer.addSubview(likeButton)
        contentContainer.addSubview(likeCountLabel)

        profileInfoContainer.flex
            .direction(.column)
            .define { flex in
                flex.addItem(nicknameLabel)
                flex.addItem(timeLabel)
            }

        contentContainer.addSubview(commentsSectionLabel)
        contentContainer.addSubview(commentsTableView)

        commentsTableView.dataSource = self
        commentsTableView.delegate = self
    }

    private func bind() {
        likeButton.rx.tap
            .bind(to: likeTappedTrigger)
            .disposed(by: disposeBag)

        let input = PostDetailPresenter.Input(
            viewDidLoad: viewDidLoadTrigger.asObservable(),
            likeTapped: likeTappedTrigger.asObservable()
        )

        let output = presenter.transform(input: input)

        output.post
            .drive(with: self) { owner, post in
                owner.configurePost(post)
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
                alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                    owner.navigationController?.popViewController(animated: true)
                })
                owner.present(alert, animated: true)
            }
            .disposed(by: disposeBag)

        output.isLiked
            .drive(with: self) { owner, isLiked in
                owner.likeButton.isSelected = isLiked
            }
            .disposed(by: disposeBag)

        output.likeCount
            .drive(with: self) { owner, count in
                owner.likeCountLabel.typography(FontSystem.Pretendard.body2, text: "\(count)")
            }
            .disposed(by: disposeBag)
    }

    private func configurePost(_ post: Post) {
        nicknameLabel.typography(FontSystem.Pretendard.body2Bold, text: post.creatorNickname)
        timeLabel.typography(FontSystem.Pretendard.caption1Regular, text: post.relativeTime)
        titleLabel.typography(FontSystem.Pretendard.title1Bold, text: post.title)
        contentLabel.typography(FontSystem.Pretendard.body2, text: post.content)

        comments = post.comments
        commentsSectionLabel.typography(FontSystem.Pretendard.body1, text: "댓글 \(post.commentsCount)")
        commentsTableView.reloadData()

        profileImageView.setImage(from: post.creatorProfileImage, targetSize: CGSize(width: 48, height: 48))

        imageURLs = post.imageURLs
        if !imageURLs.isEmpty {
            imageCollectionView.isHidden = false
            imageCollectionView.reloadData()
        } else {
            imageCollectionView.isHidden = true
        }

        view.setNeedsLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        navigationBar.pin
            .top(view.pin.safeArea.top)
            .horizontally()
            .height(56)

        scrollView.pin
            .below(of: navigationBar)
            .horizontally()
            .bottom()

        profileImageView.pin
            .top()
            .left(20)
            .size(48)

        profileInfoContainer.pin
            .after(of: profileImageView)
            .marginLeft(12)
            .right(20)

        profileInfoContainer.flex.layout(mode: .adjustHeight)

        profileInfoContainer.pin
            .vCenter(to: profileImageView.edge.vCenter)

        titleLabel.pin
            .below(of: profileImageView)
            .marginTop(16)
            .left(20)
            .right(20)
            .sizeToFit(.width)

        contentLabel.pin
            .below(of: titleLabel)
            .marginTop(12)
            .left(20)
            .right(20)
            .sizeToFit(.width)

        if !imageCollectionView.isHidden {
            let collectionViewHeight = CGFloat(imageURLs.count) * 300 + CGFloat(max(0, imageURLs.count - 1)) * 12

            imageCollectionView.pin
                .below(of: contentLabel)
                .marginTop(12)
                .horizontally(20)
                .height(collectionViewHeight)

            likeButton.pin
                .below(of: imageCollectionView)
                .marginTop(12)
                .left(20)
                .size(28)
        } else {
            likeButton.pin
                .below(of: contentLabel)
                .marginTop(12)
                .left(20)
                .size(32)
        }

        likeCountLabel.pin
            .after(of: likeButton)
            .marginLeft(6)
            .right()
            .height(20)
            .vCenter(to: likeButton.edge.vCenter)

        if !comments.isEmpty {
            commentsSectionLabel.pin
                .below(of: likeCountLabel)
                .marginTop(20)
                .left(20)
                .sizeToFit()

            let tableHeight = calculateCommentsTableHeight()
            commentsTableView.pin
                .below(of: commentsSectionLabel)
                .marginTop(8)
                .horizontally()
                .height(tableHeight)

            contentContainer.pin
                .top()
                .horizontally()
                .height(commentsTableView.frame.maxY + 40)
        } else {
            contentContainer.pin
                .top()
                .horizontally()
                .height(likeCountLabel.frame.maxY + 40)
        }

        scrollView.contentSize = contentContainer.frame.size
    }

    private func calculateCommentsTableHeight() -> CGFloat {
        var totalHeight: CGFloat = 0
        for (_, comment) in comments.enumerated() {
            let cell = CommentCell()
            cell.configure(with: comment)
            let size = cell.sizeThatFits(CGSize(width: view.bounds.width, height: .greatestFiniteMagnitude))
            totalHeight += size.height
        }
        return totalHeight
    }
}

extension PostDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.identifier, for: indexPath) as! CommentCell
        cell.configure(with: comments[indexPath.row])
        return cell
    }
}

extension PostDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension PostDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostImageCell.identifier, for: indexPath) as! PostImageCell

        let scale = UIScreen.main.scale
        let imageWidth = (view.bounds.width - 40) * scale
        let imageHeight: CGFloat = 300 * scale
        let targetSize = CGSize(width: imageWidth, height: imageHeight)

        cell.configure(with: imageURLs[indexPath.item], targetSize: targetSize)
        return cell
    }
}

extension PostDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let imageWidth = view.bounds.width - 40
        let imageHeight: CGFloat = 300
        return CGSize(width: imageWidth, height: imageHeight)
    }
}
