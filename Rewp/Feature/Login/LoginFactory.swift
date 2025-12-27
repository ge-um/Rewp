import UIKit

final class LoginFactory {
    static func create(container: AppContainer) -> LoginViewController {
        let presenter = LoginPresenter(userRepository: container.userRepository)
        let viewController = LoginViewController()

        viewController.presenter = presenter
        viewController.container = container

        return viewController
    }
}
