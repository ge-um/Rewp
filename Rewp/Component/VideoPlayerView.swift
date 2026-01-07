//
//  VideoPlayerView.swift
//  Rewp
//
//  Created by 금가경 on 01/06/26.
//

import UIKit
import AVFoundation
import OSLog

final class VideoPlayerView: UIView {
    private var playerLayer: AVPlayerLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    func configure(with playerService: VideoPlayerService) {
        if playerLayer != nil {
            Logger.video.debug("Player layer already configured, skipping")
            return
        }

        Logger.video.notice("Configuring player layer - bounds: \(self.bounds.size.width)x\(self.bounds.size.height)")
        let layer = playerService.playerLayer
        layer.frame = bounds
        self.layer.addSublayer(layer)
        self.playerLayer = layer
        Logger.video.notice("Player layer added to view")
    }
}
