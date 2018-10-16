//
//  KeyedSet.swift
//  KeyedSet
//
//  Created by Gregory Higley on 9/5/18.
//  Copyright © 2018 Prosumma LLC. All rights reserved.
//

import Foundation

public protocol Keyed {
    associatedtype KeyedSetKey: Hashable
    static var keyedSetKeyPath: KeyPath<Self, KeyedSetKey> { get }
}

public extension Keyed {
    var keyedSetKey: KeyedSetKey {
        return self[keyPath: Self.keyedSetKeyPath]
    }
}

public protocol KeyedSetProtocol {
    associatedtype Element: Keyed
    init<Elements: Sequence>(_ elements: Elements) where Elements.Element == Element
    subscript(key key: Element.KeyedSetKey) -> Element? { get set }
    func byKey() -> [Element.KeyedSetKey: Element]
    func byValue() -> [Element]
}

public struct KeyedSet<Element: Keyed>: KeyedSetProtocol {
    fileprivate var elements: [Element.KeyedSetKey: Element] = [:]
    public init<Elements: Sequence>(_ elements: Elements) where Elements.Element == Element {
        for element in elements {
            self.elements[element.keyedSetKey] = element
        }
    }
    public subscript(key key: Element.KeyedSetKey) -> Element? {
        get { return elements[key] }
        set { elements[key] = newValue }
    }
    public subscript(key: Element.KeyedSetKey) -> Element? {
        get { return elements[key] }
        set { elements[key] = newValue }
    }
    @discardableResult public mutating func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        if let oldMember = elements[newMember.keyedSetKey] {
            return (false, oldMember)
        }
        elements[newMember.keyedSetKey] = newMember
        return (true, newMember)
    }
    @discardableResult public mutating func update(with newMember: Element) -> Element? {
        return elements.updateValue(newMember, forKey: newMember.keyedSetKey)
    }
    @discardableResult public mutating func remove(_ member: Element) -> Element? {
        return elements.removeValue(forKey: member.keyedSetKey)
    }
    public func byKey() -> [Element.KeyedSetKey : Element] {
        return elements
    }
    public func byValue() -> [Element] {
        return Array(elements.values)
    }
}

extension KeyedSet: Sequence {
    public func makeIterator() -> IndexingIterator<Dictionary<Element.KeyedSetKey, Element>.Values> {
        return elements.values.makeIterator()
    }
}

extension KeyedSet: Collection {
    public typealias Index = Dictionary<Element.KeyedSetKey, Element>.Values.Index
    public func index(after i: Index) -> Index {
        return elements.values.index(after: i)
    }
    public subscript(position: Index) -> Element {
        get { return elements[position].value }
    }
    public var startIndex: Index {
        return elements.values.startIndex
    }
    public var endIndex: Index {
        return elements.values.endIndex
    }
    public var isEmpty: Bool {
        return elements.isEmpty
    }
}

public extension Sequence where Element: Keyed {
    func byKey() -> [Element.KeyedSetKey: Element] {
        var result: [Element.KeyedSetKey: Element] = [:]
        for element in self {
            result[element.keyedSetKey] = element
        }
        return result
    }
}

extension KeyedSet: Equatable where Element: Equatable {
    public static func ==(lhs: KeyedSet<Element>, rhs: KeyedSet<Element>) -> Bool {
        return lhs.elements == rhs.elements
    }
}

extension KeyedSet: SetAlgebra where Element: Hashable {
    public init() {}
    
    public func union(_ other: KeyedSet<Element>) -> KeyedSet<Element> {
        return KeyedSet(Set(self).union(other))
    }
    
    public func intersection(_ other: KeyedSet<Element>) -> KeyedSet<Element> {
        return KeyedSet(Set(self).intersection(other))
    }
    
    public func symmetricDifference(_ other: KeyedSet<Element>) -> KeyedSet<Element> {
        return KeyedSet(Set(self).symmetricDifference(other))
    }
    
    public mutating func formUnion(_ other: KeyedSet<Element>) {
        elements = Set(self).union(other).byKey()
    }
    
    public mutating func formIntersection(_ other: KeyedSet<Element>) {
        elements = Set(self).intersection(other).byKey()
    }
    
    public mutating func formSymmetricDifference(_ other: KeyedSet<Element>) {
        elements = Set(self).symmetricDifference(other).byKey()
    }
}

public extension KeyedSet where Element: Hashable {
    public func union<S: Sequence>(_ other: S) -> KeyedSet<Element> where S.Element == Element {
        return KeyedSet(Set(self).union(other))
    }
    
    public func intersection<S: Sequence>(_ other: S) -> KeyedSet<Element> where S.Element == Element {
        return KeyedSet(Set(self).intersection(other))
    }
    
    public func symmetricDifference<S: Sequence>(_ other: S) -> KeyedSet<Element> where S.Element == Element {
        return KeyedSet(Set(self).symmetricDifference(other))
    }
    
    public mutating func formUnion<S: Sequence>(_ other: S) where S.Element == Element {
        elements = Set(self).union(other).byKey()
    }
    
    public mutating func formIntersection<S: Sequence>(_ other: S) where S.Element == Element {
        elements = Set(self).intersection(other).byKey()
    }
    
    public mutating func formSymmetricDifference<S: Sequence>(_ other: S) where S.Element == Element {
        elements = Set(self).symmetricDifference(other).byKey()
    }
}

extension KeyedSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

extension KeyedSet: Decodable where Element: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(container.decode([Element].self))
    }
}

extension KeyedSet: Encodable where Element: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Array(elements.values))
    }
}
