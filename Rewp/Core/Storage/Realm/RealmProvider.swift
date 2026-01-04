//
//  RealmProvider.swift
//  Rewp
//
//  Created by 금가경 on 01/04/26.
//

import Foundation
import RealmSwift

final class RealmProvider {
    static let shared = RealmProvider()

    private init() {}

    private var configuration: Realm.Configuration {
        var config = Realm.Configuration()

        config.schemaVersion = 1

        config.migrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < 1 {}
        }

        return config
    }

    func realm() throws -> Realm {
        return try Realm(configuration: configuration)
    }
}
