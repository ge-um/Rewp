import UIKit
import PinLayout
import RxSwift
import Then

class HomeViewController: UIViewController, HomeView {
    var presenter: HomePresenter!

    private let searchBar = SearchBar()

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorSystem.gray0
        setupUI()
        presenter.viewDidLoad()
    }

    private func setupUI() {
        view.addSubview(searchBar)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        searchBar.pin
            .top(view.pin.safeArea.top + 16)
            .hCenter()
            .width(350)
            .height(40)
    }
}
