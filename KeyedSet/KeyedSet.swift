//
//  KeyedSet.swift
//  KeyedSet
//
//  Created by Gregory Higley on 9/5/18.
//  Copyright © 2018 Prosumma LLC. All rights reserved.
//

import Foundation

public protocol Keyed: Hashable {
    associatedtype Key: Hashable
    static var keyAttribute: KeyPath<Self, Key> { get }
}



public struct KeyedSet<Element: Keyed> {
    private var elements: Set<Element>
}
