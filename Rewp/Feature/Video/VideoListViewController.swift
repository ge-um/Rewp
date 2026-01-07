//
//  VideoListViewController.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import UIKit
import PinLayout
import RxSwift
import RxCocoa
import Then
import OSLog

final class VideoListViewController: UIViewController {
    var presenter: VideoListPresenter!

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsVerticalScrollIndicator = false
        cv.backgroundColor = .black
        cv.contentInsetAdjustmentBehavior = .never
        return cv
    }()

    private var videos: [Video] = []
    private var currentVideoIndex = 0

    private let viewDidLoadTrigger = PublishSubject<Void>()
    private let scrolledToVideoRelay = PublishRelay<Int>()
    private let likeButtonTappedRelay = PublishRelay<(index: Int, isLiked: Bool)>()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        bind()
        viewDidLoadTrigger.onNext(())
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseCurrentVideo()
    }

    private func setupUI() {
        view.addSubview(collectionView)

        collectionView.register(VideoPlayerCell.self, forCellWithReuseIdentifier: VideoPlayerCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    private func bind() {
        let input = VideoListPresenter.Input(
            viewDidLoad: viewDidLoadTrigger.asObservable(),
            scrolledToVideo: scrolledToVideoRelay.asObservable(),
            likeButtonTapped: likeButtonTappedRelay.asObservable(),
            qualitySelected: .empty(),
            subtitleSelected: .empty()
        )

        let output = presenter.transform(input: input)

        output.videos
            .drive(with: self) { owner, videos in
                owner.videos = videos
                owner.collectionView.reloadData()
            }
            .disposed(by: disposeBag)

        output.currentVideoIndex
            .drive(with: self) { owner, index in
                owner.currentVideoIndex = index
                owner.playVideoAtIndex(index)
            }
            .disposed(by: disposeBag)

        output.streamInfo
            .drive(with: self) { owner, result in
                let (index, streamInfo) = result
                owner.setupPlayer(at: index, streamInfo: streamInfo)
            }
            .disposed(by: disposeBag)

        output.likeUpdated
            .drive(with: self) { owner, result in
                let (index, likeCount, isLiked) = result
                if let cell = owner.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? VideoPlayerCell {
                    cell.updateLike(count: likeCount, isLiked: isLiked)
                }
            }
            .disposed(by: disposeBag)

        output.error
            .drive(with: self) { owner, message in
                let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                owner.present(alert, animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func setupPlayer(at index: Int, streamInfo: VideoStreamInfo) {
        Logger.video.notice("Setting up player at index \(index)")

        let videoUrl = selectVideoUrl(from: streamInfo)
        let subtitleUrl = streamInfo.subtitles.first?.url

        Logger.video.notice("Video URL: \(videoUrl, privacy: .public)")
        Logger.video.notice("Subtitle URL: \(subtitleUrl ?? "nil", privacy: .public)")

        if let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? VideoPlayerCell {
            cell.loadVideo(url: videoUrl, subtitleUrl: subtitleUrl)

            if index == currentVideoIndex {
                cell.play()
            }
        }
    }

    private func selectVideoUrl(from streamInfo: VideoStreamInfo) -> String {
        return streamInfo.qualities.first?.url ?? streamInfo.masterPlaylistUrl
    }

    private func playVideoAtIndex(_ index: Int) {
        for i in 0..<videos.count {
            if let cell = collectionView.cellForItem(at: IndexPath(item: i, section: 0)) as? VideoPlayerCell {
                if i != index {
                    cell.pause()
                }
            }
        }

        if let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? VideoPlayerCell {
            cell.play()
        }
    }

    private func pauseCurrentVideo() {
        if let cell = collectionView.cellForItem(at: IndexPath(item: currentVideoIndex, section: 0)) as? VideoPlayerCell {
            cell.pause()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.pin.all()
    }
}

extension VideoListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VideoPlayerCell.identifier,
            for: indexPath
        ) as? VideoPlayerCell else {
            return UICollectionViewCell()
        }

        let video = videos[indexPath.item]
        cell.configure(video: video)

        cell.onLikeTapped = { [weak self] in
            self?.likeButtonTappedRelay.accept((index: indexPath.item, isLiked: video.isLiked))
        }

        return cell
    }
}

extension VideoListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return view.frame.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.y / scrollView.bounds.height)
        scrolledToVideoRelay.accept(index)
    }
}
