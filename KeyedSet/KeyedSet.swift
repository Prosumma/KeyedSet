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
        get { return elements.values[position] }
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

protocol KeyedElementProtocol {
    associatedtype Element: Keyed
    var element: Element { get }
}

struct KeyedElement<Element: Keyed>: KeyedElementProtocol, Hashable {
    let element: Element
    
    init(_ element: Element) {
        self.element = element
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(element.keyedSetKey)
    }
    
    static func ==(lhs: KeyedElement<Element>, rhs: KeyedElement<Element>) -> Bool {
        return lhs.element.keyedSetKey == rhs.element.keyedSetKey
    }
}

extension Sequence where Element: Keyed {
    func asKeyedElements() -> Set<KeyedElement<Element>> {
        return Set(map(KeyedElement.init))
    }
}

extension Sequence where Element: KeyedElementProtocol & Hashable {
    func byKey() -> Dictionary<Element.Element.KeyedSetKey, Element.Element> {
        var dictionary: [Element.Element.KeyedSetKey: Element.Element] = [:]
        for element in self {
            dictionary[element.element.keyedSetKey] = element.element
        }
        return dictionary
    }
}

extension Dictionary where Value: Keyed, Key == Value.KeyedSetKey {
    func asKeyedElements() -> Set<KeyedElement<Value>> {
        return Set(values.map(KeyedElement.init))
    }
}

extension KeyedSet {
    init<KeyedElements: Sequence>(_ elements: KeyedElements) where KeyedElements.Element: KeyedElementProtocol, KeyedElements.Element.Element == Element {
        self.init(elements.map{ $0.element })
    }
}

extension KeyedSet: Equatable where Element: Equatable {
    public static func == (lhs: KeyedSet<Element>, rhs: KeyedSet<Element>) -> Bool {
        return lhs.elements == rhs.elements
    }
}

extension KeyedSet: SetAlgebra where Element: Equatable {
    public init() {}
    
    public func contains(_ member: Element) -> Bool {
        return elements.keys.contains(member.keyedSetKey)
    }
    
    public mutating func formUnion(_ other: KeyedSet<Element>) {
        elements = asKeyedElements().union(other.asKeyedElements()).byKey()
    }
    
    public mutating func formIntersection(_ other: KeyedSet<Element>) {
        elements = asKeyedElements().intersection(other.asKeyedElements()).byKey()
    }
    
    public mutating func formSymmetricDifference(_ other: KeyedSet<Element>) {
        elements = KeyedSet(asKeyedElements().symmetricDifference(other.asKeyedElements())).byKey()
    }
    
    public func union(_ other: KeyedSet<Element>) -> KeyedSet<Element> {
        return KeyedSet(asKeyedElements().union(other.asKeyedElements()))
    }
    
    public func intersection(_ other: KeyedSet<Element>) -> KeyedSet<Element> {
        return KeyedSet(asKeyedElements().intersection(other.asKeyedElements()))
    }
    
    public func symmetricDifference(_ other: KeyedSet<Element>) -> KeyedSet<Element> {
        return KeyedSet(asKeyedElements().symmetricDifference(other.asKeyedElements()))
    }
    
    @discardableResult public mutating func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let key = newMember.keyedSetKey
        if let oldElement = elements[key] {
            return (false, oldElement)
        }
        elements[key] = newMember
        return (true, newMember)
    }
    
    @discardableResult public mutating func remove(_ member: Element) -> Element? {
        return elements.removeValue(forKey: member.keyedSetKey)
    }
    
    @discardableResult public mutating func update(with newMember: Element) -> Element? {
        return elements.updateValue(newMember, forKey: newMember.keyedSetKey)
    }
}

public extension KeyedSet {
    public mutating func formUnion<S: Sequence>(_ other: S) where S.Element == Element {
        elements = asKeyedElements().union(other.asKeyedElements()).byKey()
    }
    
    public mutating func formIntersection<S: Sequence>(_ other: S) where S.Element == Element {
        elements = asKeyedElements().intersection(other.asKeyedElements()).byKey()
    }
    
    public mutating func formSymmetricDifference<S: Sequence>(_ other: S) where S.Element == Element {
        elements = asKeyedElements().symmetricDifference(other.asKeyedElements()).byKey()
    }

    public func union<S: Sequence>(_ other: S) -> KeyedSet<Element> where S.Element == Element {
        return KeyedSet(asKeyedElements().union(other.asKeyedElements()).map{ $0.element })
    }
    
    public func intesection<S: Sequence>(_ other: S) -> KeyedSet<Element> where S.Element == Element {
        return KeyedSet(asKeyedElements().intersection(other.asKeyedElements()).map{ $0.element })
    }
    
    public func symmetricDifference<S: Sequence>(_ other: S) -> KeyedSet<Element> where S.Element == Element {
        return KeyedSet(asKeyedElements().symmetricDifference(other.asKeyedElements()).map{ $0.element })
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
