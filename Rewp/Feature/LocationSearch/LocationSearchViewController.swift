//
//  LocationSearchViewController.swift
//  Rewp
//
//  Created by 금가경 on 01/09/26.
//

import UIKit
import RxSwift
import RxCocoa
import PinLayout
import FlexLayout
import Then
import CoreLocation

final class LocationSearchViewController: UIViewController {
    var presenter: LocationSearchPresenter!
    var onLocationSelected: ((CLLocationCoordinate2D) -> Void)?

    private let disposeBag = DisposeBag()

    private let searchContainer = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
    }

    private let searchTextField = UITextField().then {
        $0.typography(FontSystem.Pretendard.body2, placeholder: "동, 지하철역, 대학교, 매물번호 검색")
        $0.textColor = ColorSystem.gray90
        $0.returnKeyType = .search
        $0.clearButtonMode = .never
    }

    private let clearButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        $0.tintColor = ColorSystem.gray45
        $0.isHidden = true
    }

    private let searchButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        $0.tintColor = ColorSystem.gray90
    }

    private let tableView = UITableView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.separatorStyle = .singleLine
        $0.separatorColor = ColorSystem.gray30
        $0.register(LocationSearchResultCell.self, forCellReuseIdentifier: LocationSearchResultCell.identifier)
        $0.keyboardDismissMode = .onDrag
    }

    private let emptyStateContainer = UIView()

    private let emptyIconView = UIImageView().then {
        $0.image = UIImage(systemName: "house.fill")
        $0.tintColor = ColorSystem.gray45
        $0.contentMode = .scaleAspectFit
    }

    private let emptyLabel1 = UILabel().then {
        $0.textColor = ColorSystem.gray60
        $0.textAlignment = .center
    }

    private let emptyLabel2 = UILabel().then {
        $0.textColor = ColorSystem.gray60
        $0.textAlignment = .center
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        searchContainer.pin
            .top(view.pin.safeArea.top)
            .horizontally()
            .height(56)

        searchTextField.pin
            .left(20)
            .vCenter()
            .right(80)
            .height(40)

        clearButton.pin
            .right(to: searchButton.edge.left)
            .marginRight(8)
            .vCenter()
            .size(24)

        searchButton.pin
            .right(20)
            .vCenter()
            .size(24)

        tableView.pin
            .below(of: searchContainer)
            .horizontally()
            .bottom()

        emptyStateContainer.pin
            .below(of: searchContainer)
            .horizontally()
            .bottom()

        emptyStateContainer.flex.layout()
    }

    private func setupUI() {
        view.backgroundColor = ColorSystem.gray0

        view.addSubview(searchContainer)
        searchContainer.addSubview(searchTextField)
        searchContainer.addSubview(clearButton)
        searchContainer.addSubview(searchButton)

        view.addSubview(tableView)
        view.addSubview(emptyStateContainer)

        emptyLabel1.typography(FontSystem.Pretendard.body1, text: "동, 지하철역, 대학교, 매물번호로")
        emptyLabel2.typography(FontSystem.Pretendard.body1, text: "빠르게 검색해 보세요!")

        emptyStateContainer.flex
            .justifyContent(.center)
            .alignItems(.center)
            .define { flex in
                flex.addItem(emptyIconView)
                    .size(80)
                    .marginBottom(20)

                flex.addItem(emptyLabel1)

                flex.addItem(emptyLabel2)
                    .marginTop(4)
            }

        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)

        searchTextField.delegate = self
    }

    @objc private func clearButtonTapped() {
        searchTextField.text = ""
        clearButton.isHidden = true
        searchTextField.becomeFirstResponder()
    }

    private func bind() {
        let input = LocationSearchPresenter.Input(
            searchText: searchTextField.rx.text.orEmpty.asObservable(),
            searchButtonTapped: searchTextField.rx.controlEvent(.editingDidEndOnExit).asObservable(),
            resultSelected: tableView.rx.modelSelected(SearchResult.self).asObservable()
        )

        let output = presenter.transform(input: input)

        searchTextField.rx.text.orEmpty
            .withUnretained(self)
            .subscribe(onNext: { owner, text in
                owner.clearButton.isHidden = text.isEmpty
            })
            .disposed(by: disposeBag)

        output.searchResults
            .drive(tableView.rx.items(
                cellIdentifier: LocationSearchResultCell.identifier,
                cellType: LocationSearchResultCell.self
            )) { index, result, cell in
                cell.configure(with: result)
            }
            .disposed(by: disposeBag)

        output.searchResults
            .drive(with: self) { owner, results in
                let hasText = !(owner.searchTextField.text?.isEmpty ?? true)
                owner.emptyStateContainer.isHidden = hasText
                owner.tableView.isHidden = !hasText
            }
            .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .withUnretained(self)
            .subscribe(onNext: { owner, indexPath in
                owner.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)

        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)

        output.isLoading
            .drive(with: self) { owner, isLoading in
                if isLoading {
                    owner.emptyStateContainer.isHidden = true
                }
            }
            .disposed(by: disposeBag)

        output.error
            .filter { !$0.isEmpty }
            .drive(with: self) { owner, message in
                let alert = UIAlertController(
                    title: "오류",
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                owner.present(alert, animated: true)
            }
            .disposed(by: disposeBag)

        output.dismissWithLocation
            .drive(with: self) { owner, coordinate in
                owner.view.endEditing(true)
                owner.dismiss(animated: true) {
                    owner.onLocationSelected?(coordinate)
                }
            }
            .disposed(by: disposeBag)
    }
}

extension LocationSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}

extension LocationSearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}
