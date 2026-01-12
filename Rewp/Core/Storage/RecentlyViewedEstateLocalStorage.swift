//
//  RecentlyViewedEstateLocalStorage.swift
//  Rewp
//
//  Created by 금가경 on 01/12/26.
//

import Foundation
import OSLog
import RxSwift

final class RecentlyViewedEstateLocalStorage {
    private let userDefaultsKey = "recentlyViewedEstates"
    private let maxCount = 10

    func saveRecentlyViewedEstate(_ item: RecentlyViewedEstateItem) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError(domain: "RecentlyViewedEstateLocalStorage", code: -1)))
                return Disposables.create()
            }

            do {
                // 1. 기존 데이터 로드
                var items = try self.loadItems()

                // 2. 중복 제거 (동일 estateId)
                items.removeAll { $0.estateId == item.estateId }

                // 3. 최상단에 추가
                items.insert(item, at: 0)

                // 4. FIFO: 10개 초과 시 가장 오래된 항목 제거
                if items.count > self.maxCount {
                    items = Array(items.prefix(self.maxCount))
                }

                // 5. JSON 직렬화 및 저장
                let data = try JSONEncoder().encode(items)
                UserDefaults.standard.set(data, forKey: self.userDefaultsKey)

                Logger.storage.notice("Recently viewed estate saved")
                completable(.completed)
            } catch {
                Logger.storage.error("Save failed: \(error.localizedDescription)")
                completable(.error(error))
            }

            return Disposables.create()
        }
    }

    func fetchRecentlyViewedEstates() -> Observable<[RecentlyViewedEstateItem]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NSError(domain: "RecentlyViewedEstateLocalStorage", code: -1))
                return Disposables.create()
            }

            do {
                let items = try self.loadItems()
                observer.onNext(items)
                observer.onCompleted()
            } catch {
                Logger.storage.error("Fetch failed: \(error.localizedDescription)")
                observer.onNext([])
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    func deleteAllRecentlyViewedEstates() -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(NSError(domain: "RecentlyViewedEstateLocalStorage", code: -1)))
                return Disposables.create()
            }

            UserDefaults.standard.removeObject(forKey: self.userDefaultsKey)
            Logger.storage.notice("All recently viewed estates deleted")
            completable(.completed)

            return Disposables.create()
        }
    }

    private func loadItems() throws -> [RecentlyViewedEstateItem] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return []
        }
        return try JSONDecoder().decode([RecentlyViewedEstateItem].self, from: data)
    }
}
