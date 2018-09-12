//
//  Util.swift
//  KeyedSet
//
//  Created by Gregory Higley on 9/7/18.
//  Copyright © 2018 Prosumma LLC. All rights reserved.
//

import Foundation

extension Int {
    func times<T>(_ make: (Int) throws -> T) rethrows -> [T] {
        return try (0..<self).map(make)
    }
    func times<T>(_ make: () throws -> T) rethrows -> [T] {
        return try (0..<self).map{ _ in try make() }
    }
    func times(_ action: () throws -> Void) rethrows {
        for _ in 0..<self {
            try action()
        }
    }
}
