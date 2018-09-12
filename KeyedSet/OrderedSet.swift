//
//  OrderedSet.swift
//  KeyedSet
//
//  Created by Gregory Higley on 9/8/18.
//  Copyright © 2018 Prosumma LLC. All rights reserved.
//

import Foundation

public struct OrderedSet<Element: Hashable> {
    private var elements: Set<Element> = []
    private var orderedElements: [Element] = []
    
    public init() {}
    
    public init<S: Sequence>(_ sequence: S) where S.Element == Element {
        for elem in sequence {
            if elements.update(with: elem) == nil {
                orderedElements.append(elem)
            }
        }
    }
    
    public var isEmpty: Bool {
        return elements.isEmpty
    }
}

extension OrderedSet: Sequence {
    public func makeIterator() -> IndexingIterator<Array<Element>> {
        return orderedElements.makeIterator()
    }
}

extension OrderedSet: Collection {
    public func index(after i: Int) -> Int {
        return orderedElements.index(after: i)
    }
    
    public subscript(position: Int) -> Element {
        return orderedElements[position]
    }
    
    public var startIndex: Int {
        return orderedElements.startIndex
    }
    
    public var endIndex: Int {
        return orderedElements.endIndex
    }
}

extension OrderedSet: SetAlgebra {
    public func union(_ other: OrderedSet<Element>) -> OrderedSet<Element> {
        var orderedSet = self
        orderedSet.formUnion(other)
        return orderedSet
    }
    
    public func intersection(_ other: OrderedSet<Element>) -> OrderedSet<Element> {
        var orderedSet = self
        orderedSet.formIntersection(other)
        return orderedSet
    }
    
    public func symmetricDifference(_ other: OrderedSet<Element>) -> OrderedSet<Element> {
        var orderedSet = self
        orderedSet.formSymmetricDifference(other)
        return orderedSet
    }
    
    @discardableResult public mutating func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let result = elements.insert(newMember)
        if case let (inserted, memberAfterInsert) = result, inserted {
            orderedElements.append(memberAfterInsert)
        }
        return result
    }
    
    @discardableResult public mutating func remove(_ member: Element) -> Element? {
        if let removed = elements.remove(member) {
            orderedElements.remove(at: firstIndex(of: removed)!)
            return removed
        } else {
            return nil
        }
    }
    
    @discardableResult public mutating func update(with newMember: Element) -> Element? {
        if let updated = elements.update(with: newMember) {
            return updated
        } else {
            orderedElements.append(newMember)
            return nil
        }
    }
    
    public mutating func formUnion(_ other: OrderedSet<Element>) {
        for elem in other {
            insert(elem)
        }
    }
    
    public mutating func formIntersection(_ other: OrderedSet<Element>) {
        var other = other
        for elem in other {
            if !elements.contains(elem) {
                other.remove(elem)
            }
        }
        for elem in self {
            if !other.elements.contains(elem) {
                remove(elem)
            }
        }
        for elem in other {
            insert(elem)
        }
    }
    
    public mutating func formSymmetricDifference(_ other: OrderedSet<Element>) {
        let this = self.subtracting(other)
        let that = other.subtracting(self)
        self = this.union(that)
    }
}

