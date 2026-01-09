//
//  LocationSearchPresenter.swift
//  Rewp
//
//  Created by 금가경 on 01/09/26.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation
import OSLog

final class LocationSearchPresenter {
    private let disposeBag = DisposeBag()

    struct Input {
        let searchText: Observable<String>
        let searchButtonTapped: Observable<Void>
        let resultSelected: Observable<SearchResult>
    }

    struct Output {
        let searchResults: Driver<[SearchResult]>
        let isLoading: Driver<Bool>
        let error: Driver<String>
        let dismissWithLocation: Driver<CLLocationCoordinate2D>
    }

    func transform(input: Input) -> Output {
        let loadingRelay = PublishRelay<Bool>()
        let searchResultsRelay = PublishRelay<[SearchResult]>()
        let errorRelay = PublishRelay<String>()
        let dismissWithLocationRelay = PublishRelay<CLLocationCoordinate2D>()

        let searchTrigger = Observable.merge(
            input.searchText
                .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                .distinctUntilChanged(),
            input.searchButtonTapped.withLatestFrom(input.searchText)
        )
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }

        searchTrigger
            .do(onNext: { query in
                Logger.map.notice("Location search started - query: \(query, privacy: .public)")
                loadingRelay.accept(true)
            })
            .flatMapLatest { query -> Observable<[SearchResult]> in
                GeocodeService.shared.searchLocations(query: query)
                    .asObservable()
                    .map { locations in
                        Logger.map.notice("Found \(locations.count) location(s)")
                        return locations.map { SearchResult(address: $0.address, coordinate: $0.coordinate) }
                    }
                    .catch { error in
                        Logger.map.error("Location search failed - \(error.localizedDescription)")
                        loadingRelay.accept(false)
                        errorRelay.accept("검색 결과가 없습니다")
                        return .just([])
                    }
            }
            .subscribe(onNext: { results in
                loadingRelay.accept(false)
                searchResultsRelay.accept(results)
            })
            .disposed(by: disposeBag)

        input.resultSelected
            .map { $0.coordinate }
            .bind(to: dismissWithLocationRelay)
            .disposed(by: disposeBag)

        return Output(
            searchResults: searchResultsRelay.asDriver(onErrorDriveWith: .empty()),
            isLoading: loadingRelay.asDriver(onErrorJustReturn: false),
            error: errorRelay.asDriver(onErrorJustReturn: ""),
            dismissWithLocation: dismissWithLocationRelay.asDriver(onErrorDriveWith: .empty())
        )
    }
}
