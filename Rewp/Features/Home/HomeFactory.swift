import UIKit

class HomeFactory {
    static func create() -> HomeViewController {
        let presenter = HomePresenter()
        let viewController = HomeViewController()

        viewController.presenter = presenter

        return viewController
    }
}
