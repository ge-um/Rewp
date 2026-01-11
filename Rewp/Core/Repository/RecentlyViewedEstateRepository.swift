//
//  RecentlyViewedEstateRepository.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import Foundation
import RxSwift

protocol RecentlyViewedEstateRepository {
    func saveRecentlyViewedEstate(_ item: RecentlyViewedEstateItem) -> Completable
    func fetchRecentlyViewedEstates() -> Observable<[RecentlyViewedEstateItem]>
    func deleteAllRecentlyViewedEstates() -> Completable
}

final class RecentlyViewedEstateRepositoryImpl: RecentlyViewedEstateRepository {
    private let localStorage: RecentlyViewedEstateLocalStorage

    init(localStorage: RecentlyViewedEstateLocalStorage) {
        self.localStorage = localStorage
    }

    func saveRecentlyViewedEstate(_ item: RecentlyViewedEstateItem) -> Completable {
        return localStorage.saveRecentlyViewedEstate(item)
    }

    func fetchRecentlyViewedEstates() -> Observable<[RecentlyViewedEstateItem]> {
        return localStorage.fetchRecentlyViewedEstates()
    }

    func deleteAllRecentlyViewedEstates() -> Completable {
        return localStorage.deleteAllRecentlyViewedEstates()
    }
}
