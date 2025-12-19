import Foundation
import RxSwift

protocol HomeView: AnyObject {}

class HomePresenter {
    weak var view: HomeView?

    func viewDidLoad() {

    }
}
