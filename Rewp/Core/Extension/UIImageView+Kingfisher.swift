//
//  UIImageView+Kingfisher.swift
//  Rewp
//
//  Created by 금가경 on 12/30/25.
//

import UIKit
import Kingfisher
import OSLog

extension UIImageView {
    func setImage(from urlString: String?, placeholder: UIImage? = nil, targetSize: CGSize? = nil) {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            self.image = placeholder
            return
        }

        let accessToken = try? KeychainManager.shared.loadAccessToken()

        var options: KingfisherOptionsInfo = [
            .transition(.fade(0.2)),
            .requestModifier(RewpImageRequestModifier(accessToken: accessToken))
        ]

        if let size = targetSize {
            let processor = DownsamplingImageProcessor(size: size)
            options.append(.processor(processor))
        } else {
            options.append(.backgroundDecode)
        }

        self.kf.setImage(
            with: .network(KF.ImageResource(downloadURL: url, cacheKey: url.absoluteString)),
            placeholder: placeholder,
            options: options,
            completionHandler: { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    Logger.network.error("Image loading failed - \(url.absoluteString) - error: \(error.localizedDescription)")
                }
            }
        )
    }
}

private struct RewpImageRequestModifier: ImageDownloadRequestModifier {
    let accessToken: String?

    func modified(for request: URLRequest) -> URLRequest? {
        var modifiedRequest = request
        modifiedRequest.setValue(NetworkConfig.rewpKey, forHTTPHeaderField: "SesacKey")

        if let token = accessToken {
            modifiedRequest.setValue(token, forHTTPHeaderField: "Authorization")
        }

        return modifiedRequest
    }
}
