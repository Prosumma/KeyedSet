//
//  KeyedSet.swift
//  KeyedSet
//
//  Created by Gregory Higley on 9/5/18.
//  Copyright © 2018 Prosumma LLC. All rights reserved.
//

import Foundation

public protocol Keyed: Hashable {
    associatedtype KeyedSetKey: Hashable
    static var keyedSetKeyAttribute: KeyPath<Self, KeyedSetKey> { get }
}

public extension Keyed {
    var keyedSetKey: KeyedSetKey {
        return self[keyPath: Self.keyedSetKeyAttribute]
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(keyedSetKey)
    }
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.keyedSetKey == rhs.keyedSetKey
    }
}

public extension Set where Element: Keyed {
    public func byKey() -> [Element.KeyedSetKey: Element] {
        return Dictionary(uniqueKeysWithValues: map{ ($0.keyedSetKey, $0) })
    }
}

public struct KeyedSet<Element: Keyed> {
    private var elements: Set<Element>
    private var elementsByKey: [Element.KeyedSetKey: Element]
    
    public init() {
        elements = []
        elementsByKey = [:]
    }
    
    public init<S: Sequence>(_ sequence: S) where S.Element == Element {
        elements = Set(sequence)
        elementsByKey = elements.byKey()
        assert(elements.count == elementsByKey.count)
    }
    
    public var isEmpty: Bool {
        return elements.isEmpty
    }
}

extension KeyedSet: Sequence {
    public func makeIterator() -> SetIterator<Element> {
        return elements.makeIterator()
    }
}

extension KeyedSet: Collection {
    public func index(after i: Set<Element>.Index) -> Set<Element>.Index {
        return elements.index(after: i)
    }
    
    public subscript(position: Set<Element>.Index) -> Element {
        return elements[position]
    }
    
    public var startIndex: Set<Element>.Index {
        return elements.startIndex
    }
    
    public var endIndex: Set<Element>.Index {
        return elements.endIndex
    }
    
    public typealias Index = Set<Element>.Index
}

extension KeyedSet: SetAlgebra {
    public func union(_ other: KeyedSet<Element>) -> KeyedSet<Element> {
        var keyedSet = self
        keyedSet.formUnion(other)
        return keyedSet
    }
    
    public func intersection(_ other: KeyedSet<Element>) -> KeyedSet<Element> {
        var keyedSet = self
        keyedSet.formIntersection(other)
        return keyedSet
    }
    
    public func symmetricDifference(_ other: KeyedSet<Element>) -> KeyedSet<Element> {
        var keyedSet = self
        keyedSet.formSymmetricDifference(other)
        return keyedSet
    }
    
    public mutating func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let result = elements.insert(newMember)
        if case let (inserted, memberAfterInsert) = result, inserted {
            elementsByKey[memberAfterInsert.keyedSetKey] = memberAfterInsert
        }
        return result
    }
    
    public mutating func remove(_ member: Element) -> Element? {
        if let removed = elements.remove(member) {
            elementsByKey.removeValue(forKey: removed.keyedSetKey)
            assert(elements.count == elementsByKey.count)
            return removed
        } else {
            return nil
        }
    }
    
    public mutating func update(with newMember: Element) -> Element? {
        let updated = elements.update(with: newMember)
        elementsByKey[newMember.keyedSetKey] = newMember
        assert(elements.count == elementsByKey.count)
        return updated
    }
    
    public mutating func formUnion(_ other: KeyedSet<Element>) {
        elements.formUnion(other.elements)
        elementsByKey = elements.byKey()
        assert(elements.count == elementsByKey.count)
    }
    
    public mutating func formIntersection(_ other: KeyedSet<Element>) {
        elements.formIntersection(other.elements)
        elementsByKey = elements.byKey()
        assert(elements.count == elementsByKey.count)
    }
    
    public mutating func formSymmetricDifference(_ other: KeyedSet<Element>) {
        elements.formSymmetricDifference(other.elements)
        elementsByKey = elements.byKey()
        assert(elements.count == elementsByKey.count)
    }

}

public extension KeyedSet {
    public func union<S: Sequence>(_ other: S) -> KeyedSet<Element> where S.Element == Element {
        var keyedSet = self
        keyedSet.formUnion(other)
        return keyedSet
    }
    
    public func intersection<S: Sequence>(_ other: S) -> KeyedSet<Element> where S.Element == Element {
        var keyedSet = self
        keyedSet.formIntersection(other)
        return keyedSet
    }
    
    public mutating func symmetricDifference<S: Sequence>(_ other: S) -> KeyedSet<Element> where S.Element == Element {
        var keyedSet = self
        keyedSet.formSymmetricDifference(other)
        return keyedSet
    }
    
    public mutating func formUnion<S: Sequence>(_ other: S) where S.Element == Element {
        elements.formUnion(other)
        elementsByKey = elements.byKey()
        assert(elements.count == elementsByKey.count)
    }
    
    public mutating func formIntersection<S: Sequence>(_ other: S) where S.Element == Element {
        elements.formIntersection(other)
        elementsByKey = elements.byKey()
        assert(elements.count == elementsByKey.count)
    }
    
    public mutating func formSymmetricDifference<S: Sequence>(_ other: S) where S.Element == Element {
        elements.formSymmetricDifference(other)
        elementsByKey = elements.byKey()
        assert(elements.count == elementsByKey.count)
    }
}

public extension KeyedSet {
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> KeyedSet<Element> {
        return try KeyedSet(elements.filter(isIncluded))
    }
    public func map(_ transform: (Element) throws -> Element) rethrows -> KeyedSet<Element> {
        return try KeyedSet(elements.map(transform))
    }
}

extension KeyedSet: Decodable where Element: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        elements = try container.decode(type(of: elements))
        elementsByKey = elements.byKey()
    }
}

extension KeyedSet: Encodable where Element: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self)
    }
}
