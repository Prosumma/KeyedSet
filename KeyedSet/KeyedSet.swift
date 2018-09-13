//
//  KeyedSet.swift
//  KeyedSet
//
//  Created by Gregory Higley on 9/5/18.
//  Copyright © 2018 Prosumma LLC. All rights reserved.
//

import Foundation

/**
 The protocol which elements of a `KeyedSet` must
 implement.
 
 Elements of a `KeyedSet` are subscripted by the
 key attribute. By implementing `Keyed`, the
 `keyedSetKeyPath` tells `KeyedSet` which attribute
 is the key attribute.
 
 `Keyed` elements must be unique by virtue of the
 key attribute. If two elements in a `KeyedSet` are
 unique in terms of `Hashable` and `Equatable`, but
 have the same key attribute, an unrecoverable runtime
 exception will occur.
 
 For this reason, default implementations of `Hashable`
 and `Equatable` are provided for types that implement
 `Keyed`. In general, it is best to defer to these
 implementations.
 
 Implementation is straightforward:
 
 ```
 struct Order: Keyed {
    static let keyedSetKeyPath = \Order.id
    let id: UUID
    let dateOrdered: Date
 }
 ```
 
 Conforming implementations of `Hashable` and `Equatable` are
 synthesized automatically for the `Order` type. Because
 `keyedSetKeyPath` is `\Order.id`, subscripting is by `id`:
 
 ```
 func getOrder(id: UUID, from orders: KeyedSet<Order>) -> Order? {
    return orders[id]
 }
 ```
 */
public protocol Keyed: Hashable {
    /// The type of the key attribute.
    associatedtype KeyedSetKey: Hashable
    /// The `KeyPath` of the key attribute.
    static var keyedSetKeyPath: KeyPath<Self, KeyedSetKey> { get }
}

public extension Keyed {
    /// Shorthand for `self[keyPath: Self.keyedSetKeyPath]`.
    var keyedSetKey: KeyedSetKey {
        return self[keyPath: Self.keyedSetKeyPath]
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(keyedSetKey)
    }
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.keyedSetKey == rhs.keyedSetKey
    }
}

public extension Sequence where Self: SetAlgebra, Element: Keyed {
    /**
     Transforms the receiver into a dictionary keyed by the key
     attribute of each `Keyed` element.
     
     - warning: If there are any duplicates in the receiver, an unrecoverable
     runtime exception will occur.
     */
    public func byKey() -> [Element.KeyedSetKey: Element] {
        if let ks = self as? KeyedSet<Element> {
            return ks.byKey()
        } else {
            return Dictionary(uniqueKeysWithValues: map{ ($0.keyedSetKey, $0) })
        }
    }
}

/**
 A hybrid of `Set` and `Dictionary`. Mostly a `Set`, but with `Dictionary`-like subscripting operations.
 
 Conforming elements must implement `Keyed`. (See the documentation for `Keyed`.)
 
 The element's `Keyed` implementation determines which attribute to use for subscripting:
 
 ```
 struct Order: Keyed {
    static let keyedSetKeyPath = \Order.id
    let id: UUID
    let dateOrdered: Date
 }
 ```
 
 We can now look up elements in a `KeyedSet<Order>` instance by `UUID`:
 
 ```
 func getOrder(id: UUID, from orders: KeyedSet<Order>) -> Order? {
    return orders[id]
 }
 ```
 
 However, in all other respects, `KeyedSet` is a `Set`. (It implements `Collection` and `SetAlgebra`.) Adding to and removing from a `KeyedSet` is the same as with `Set`:
 
 ```
 var orders: KeyedSet<Order> = []
 orders.update(with: Order(id: UUID()))
 ```
 
 All of the standard `SetAlgebra` operations such as `union`, `intersection` and so on are available.
 */
public struct KeyedSet<Element: Keyed> {
    private var elements: Set<Element>
    private var keyedElements: [Element.KeyedSetKey: Element]
    
    public init() {
        elements = []
        keyedElements = [:]
    }
    
    public init<S: Sequence>(_ sequence: S) where S.Element == Element {
        elements = Set(sequence)
        keyedElements = elements.byKey()
        assert(elements.count == keyedElements.count)
    }
    
    public subscript(key: Element.KeyedSetKey) -> Element? {
        return keyedElements[key]
    }
    
    public var isEmpty: Bool {
        return elements.isEmpty
    }
    
    /// Return a dictionary of the elements keyed by key attribute.
    public func byKey() -> [Element.KeyedSetKey : Element] {
        return keyedElements
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
    
    @discardableResult public mutating func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let result = elements.insert(newMember)
        if case let (inserted, memberAfterInsert) = result, inserted {
            keyedElements[memberAfterInsert.keyedSetKey] = memberAfterInsert
        }
        return result
    }
    
    @discardableResult public mutating func remove(_ member: Element) -> Element? {
        if let removed = elements.remove(member) {
            keyedElements.removeValue(forKey: removed.keyedSetKey)
            assert(elements.count == keyedElements.count)
            return removed
        } else {
            return nil
        }
    }
    
    @discardableResult public mutating func update(with newMember: Element) -> Element? {
        let updated = elements.update(with: newMember)
        keyedElements[newMember.keyedSetKey] = newMember
        assert(elements.count == keyedElements.count)
        return updated
    }
    
    public mutating func formUnion(_ other: KeyedSet<Element>) {
        elements.formUnion(other.elements)
        keyedElements = elements.byKey()
        assert(elements.count == keyedElements.count)
    }
    
    public mutating func formIntersection(_ other: KeyedSet<Element>) {
        elements.formIntersection(other.elements)
        keyedElements = elements.byKey()
        assert(elements.count == keyedElements.count)
    }
    
    public mutating func formSymmetricDifference(_ other: KeyedSet<Element>) {
        elements.formSymmetricDifference(other.elements)
        keyedElements = elements.byKey()
        assert(elements.count == keyedElements.count)
    }

}

public extension KeyedSet {
    /// Returns a new set with the elements of both this set and the given
    /// sequence.
    ///
    /// In the following example, the `attendeesAndVisitors` set is made up
    /// of the elements of the `attendees` set and the `visitors` array:
    ///
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     let visitors = ["Marcia", "Nathaniel"]
    ///     let attendeesAndVisitors = attendees.union(visitors)
    ///     print(attendeesAndVisitors)
    ///     // Prints "["Diana", "Nathaniel", "Bethany", "Alicia", "Marcia"]"
    ///
    /// If the set already contains one or more elements that are also in
    /// `other`, the existing members are kept. If `other` contains multiple
    /// instances of equivalent elements, only the first instance is kept.
    ///
    ///     let initialIndices = Set(0..<5)
    ///     let expandedIndices = initialIndices.union([2, 3, 6, 6, 7, 7])
    ///     print(expandedIndices)
    ///     // Prints "[2, 4, 6, 7, 0, 1, 3]"
    ///
    /// - Parameter other: A sequence of elements. `other` must be finite.
    /// - Returns: A new set with the unique elements of this set and `other`.
    public func union<S: Sequence>(_ other: S) -> KeyedSet<Element> where S.Element == Element {
        var keyedSet = self
        keyedSet.formUnion(other)
        return keyedSet
    }
    
    /// Returns a new set with the elements that are common to both this set and
    /// the given sequence.
    ///
    /// In the following example, the `bothNeighborsAndEmployees` set is made up
    /// of the elements that are in *both* the `employees` and `neighbors` sets.
    /// Elements that are in only one or the other are left out of the result of
    /// the intersection.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani", "Greta"]
    ///     let bothNeighborsAndEmployees = employees.intersection(neighbors)
    ///     print(bothNeighborsAndEmployees)
    ///     // Prints "["Bethany", "Eric"]"
    ///
    /// - Parameter other: Another set.
    /// - Returns: A new set.
    public func intersection<S: Sequence>(_ other: S) -> KeyedSet<Element> where S.Element == Element {
        var keyedSet = self
        keyedSet.formIntersection(other)
        return keyedSet
    }
    
    /// Returns a new set with the elements that are either in this set or in the
    /// given sequence, but not in both.
    ///
    /// In the following example, the `eitherNeighborsOrEmployees` set is made up
    /// of the elements of the `employees` and `neighbors` sets that are not in
    /// both `employees` *and* `neighbors`. In particular, the names `"Bethany"`
    /// and `"Eric"` do not appear in `eitherNeighborsOrEmployees`.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Diana", "Eric"]
    ///     let neighbors = ["Bethany", "Eric", "Forlani"]
    ///     let eitherNeighborsOrEmployees = employees.symmetricDifference(neighbors)
    ///     print(eitherNeighborsOrEmployees)
    ///     // Prints "["Diana", "Forlani", "Alicia"]"
    ///
    /// - Parameter other: A sequence of elements. `other` must be finite.
    /// - Returns: A new set.
    public mutating func symmetricDifference<S: Sequence>(_ other: S) -> KeyedSet<Element> where S.Element == Element {
        var keyedSet = self
        keyedSet.formSymmetricDifference(other)
        return keyedSet
    }
    
    /// Inserts the elements of the given sequence into the set.
    ///
    /// If the set already contains one or more elements that are also in
    /// `other`, the existing members are kept. If `other` contains multiple
    /// instances of equivalent elements, only the first instance is kept.
    ///
    ///     var attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     let visitors = ["Diana", "Marcia", "Nathaniel"]
    ///     attendees.formUnion(visitors)
    ///     print(attendees)
    ///     // Prints "["Diana", "Nathaniel", "Bethany", "Alicia", "Marcia"]"
    ///
    /// - Parameter other: A sequence of elements. `other` must be finite.
    public mutating func formUnion<S: Sequence>(_ other: S) where S.Element == Element {
        elements.formUnion(other)
        keyedElements = elements.byKey()
        assert(elements.count == keyedElements.count)
    }
    
    /// Removes the elements of the set that aren't also in the given sequence.
    ///
    /// In the following example, the elements of the `employees` set that are
    /// not also members of the `neighbors` set are removed. In particular, the
    /// names `"Alicia"`, `"Chris"`, and `"Diana"` are removed.
    ///
    ///     var employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let neighbors = ["Bethany", "Eric", "Forlani", "Greta"]
    ///     employees.formIntersection(neighbors)
    ///     print(employees)
    ///     // Prints "["Bethany", "Eric"]"
    ///
    /// - Parameter other: A sequence of elements. `other` must be finite.
    public mutating func formIntersection<S: Sequence>(_ other: S) where S.Element == Element {
        elements.formIntersection(other)
        keyedElements = elements.byKey()
        assert(elements.count == keyedElements.count)
    }
    
    /// Replace this set with the elements contained in this set or the given
    /// set, but not both.
    ///
    /// In the following example, the elements of the `employees` set that are
    /// also members of `neighbors` are removed from `employees`, while the
    /// elements of `neighbors` that are not members of `employees` are added to
    /// `employees`. In particular, the names `"Bethany"` and `"Eric"` are
    /// removed from `employees` while the name `"Forlani"` is added.
    ///
    ///     var employees: Set = ["Alicia", "Bethany", "Diana", "Eric"]
    ///     let neighbors = ["Bethany", "Eric", "Forlani"]
    ///     employees.formSymmetricDifference(neighbors)
    ///     print(employees)
    ///     // Prints "["Diana", "Forlani", "Alicia"]"
    ///
    /// - Parameter other: A sequence of elements. `other` must be finite.
    public mutating func formSymmetricDifference<S: Sequence>(_ other: S) where S.Element == Element {
        elements.formSymmetricDifference(other)
        keyedElements = elements.byKey()
        assert(elements.count == keyedElements.count)
    }
}

public extension KeyedSet {
    /**
     The standard `filter` method, but returns a `KeyedSet`.
    
     - parameter isIncluded: A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element should be included in the returned array.
     
     - returns: A `KeyedSet` of the filtered elements.
    */
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> KeyedSet<Element> {
        return try KeyedSet(elements.filter(isIncluded))
    }
    /**
     The standard `map` method, but returns a `KeyedSet`.
     
     - parameter transform: A function from `Element` to `Element`.
    */
    public func map(_ transform: (Element) throws -> Element) rethrows -> KeyedSet<Element> {
        return try KeyedSet(elements.map(transform))
    }
}

extension KeyedSet: Decodable where Element: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        elements = try container.decode(type(of: elements))
        keyedElements = elements.byKey()
    }
}

extension KeyedSet: Encodable where Element: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(elements)
    }
}
