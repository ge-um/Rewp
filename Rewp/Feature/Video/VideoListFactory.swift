//
//  VideoListFactory.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import UIKit

final class VideoListFactory {
    static func create(container: AppContainer) -> VideoListViewController {
        let presenter = VideoListPresenter(repository: container.videoRepository)
        let viewController = VideoListViewController()

        viewController.presenter = presenter

        VideoPlayerCell.subtitleService = container.subtitleService

        return viewController
    }
}
