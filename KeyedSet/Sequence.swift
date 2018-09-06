//
//  Sequence.swift
//  KeyedSet
//
//  Created by Gregory Higley on 9/6/18.
//  Copyright © 2018 Prosumma LLC. All rights reserved.
//

import Foundation

public extension Sequence where Element: Keyed {
    /// Returns the first element in the sequence whose key
    /// matches `key`.
    subscript(key key: Element.KeyedSetKey) -> Element? {
        return first { $0.keyedSetKey == key }
    }
}
