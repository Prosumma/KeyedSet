//
//  Sequence.swift
//  KeyedSet
//
//  Created by Gregory Higley on 9/6/18.
//  Copyright © 2018 Prosumma LLC. All rights reserved.
//

import Foundation

public extension Sequence where Element: Keyed {
    subscript(key key: Element.KeyedSetKey) -> Element? {
        return first { $0.keyedSetKey == key }
    }
}
