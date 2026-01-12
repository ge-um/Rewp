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

    private let backButton = UIButton(type: .system).then {
        let image = UIImage(named: "chevron")
        $0.setImage(image, for: .normal)
        $0.tintColor = ColorSystem.gray75
        $0.contentMode = .center
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
        $0.numberOfLines = 0
    }

    private let emptyLabel2 = UILabel().then {
        $0.textColor = ColorSystem.gray60
        $0.textAlignment = .center
        $0.numberOfLines = 0
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

        backButton.pin
            .left(12)
            .vCenter()
            .size(32)

        searchTextField.pin
            .after(of: backButton)
            .marginLeft(8)
            .vCenter()
            .right(20)
            .height(40)

        clearButton.pin
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
        searchContainer.addSubview(backButton)
        searchContainer.addSubview(searchTextField)
        searchContainer.addSubview(clearButton)

        view.addSubview(tableView)
        view.addSubview(emptyStateContainer)

        emptyLabel1.typography(FontSystem.Pretendard.body1, text: "동, 지하철역, 대학교, 매물번호로")
        emptyLabel2.typography(FontSystem.Pretendard.body1, text: "빠르게 검색해 보세요!")

        emptyStateContainer.flex
            .justifyContent(.center)
            .alignItems(.center)
            .paddingHorizontal(20)
            .define { flex in
                flex.addItem(emptyIconView)
                    .size(80)
                    .marginBottom(20)

                flex.addItem(emptyLabel1)
                    .width(100%)

                flex.addItem(emptyLabel2)
                    .marginTop(4)
                    .width(100%)
            }

        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        searchTextField.delegate = self
    }

    @objc private func backButtonTapped() {
        view.endEditing(true)
        dismiss(animated: true)
    }

    @objc private func clearButtonTapped() {
        searchTextField.text = ""
        clearButton.isHidden = true
        searchTextField.becomeFirstResponder()
    }

    @objc private func viewTapped() {
        view.endEditing(true)
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
                let hasResults = !results.isEmpty

                if hasText && !hasResults {
                    owner.emptyLabel1.typography(FontSystem.Pretendard.body1, text: "검색 결과가 없습니다")
                    owner.emptyLabel2.typography(FontSystem.Pretendard.body1, text: "다른 키워드로 검색해보세요")
                    owner.emptyStateContainer.isHidden = false
                    owner.tableView.isHidden = true
                } else if !hasText {
                    owner.emptyLabel1.typography(FontSystem.Pretendard.body1, text: "동, 지하철역, 대학교, 매물번호로")
                    owner.emptyLabel2.typography(FontSystem.Pretendard.body1, text: "빠르게 검색해 보세요!")
                    owner.emptyStateContainer.isHidden = false
                    owner.tableView.isHidden = true
                } else {
                    owner.emptyStateContainer.isHidden = true
                    owner.tableView.isHidden = false
                }
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
