//
//  Order.swift
//  KeyedSet
//
//  Created by Gregory Higley on 9/7/18.
//  Copyright © 2018 Prosumma LLC. All rights reserved.
//

import Foundation
import KeyedSet

struct Order: Keyed {
    static let keyedSetKeyPath = \Order.id
    let id: UUID
    var name: String?
    init(id: UUID) {
        self.id = id
    }
    init() {
        self.init(id: UUID())
    }
}


