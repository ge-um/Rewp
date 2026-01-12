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
    func setImage(from urlString: String?, placeholder: UIImage? = nil) {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            self.image = placeholder
            return
        }

        let accessToken: String?
        do {
            accessToken = try KeychainManager.shared.loadAccessToken()
        } catch {
            Logger.auth.error("Failed to load access token for image request - \(error.localizedDescription)")
            accessToken = nil
        }

        self.kf.setImage(
            with: .network(KF.ImageResource(downloadURL: url, cacheKey: url.absoluteString)),
            placeholder: placeholder,
            options: [
                .transition(.fade(0.2)),
                .cacheMemoryOnly,
                .backgroundDecode,
                .requestModifier(RewpImageRequestModifier(accessToken: accessToken))
            ],
            completionHandler: { result in
                switch result {
                case .success(let value):
                    Logger.network.info("Image loaded successfully - \(url.absoluteString)")
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
