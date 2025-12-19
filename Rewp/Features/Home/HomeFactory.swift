import UIKit

class HomeFactory {
    static func create() -> HomeViewController {
        let presenter = HomePresenter()
        let viewController = HomeViewController()

        presenter.view = viewController
        viewController.presenter = presenter

        return viewController
    }
}
