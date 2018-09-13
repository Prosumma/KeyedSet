//
//  KeyedSetTests.swift
//  KeyedSetTests
//
//  Created by Gregory Higley on 9/5/18.
//  Copyright © 2018 Prosumma LLC. All rights reserved.
//

import XCTest
@testable import KeyedSet

class KeyedSetTests: XCTestCase {
    
    func testInit() {
        let count = 10_000
        let keyedSet = KeyedSet(count.times(Order.init))
        XCTAssertEqual(keyedSet.count, count)
    }
    
    func testInsert() {
        let count = 100
        var keyedSet = KeyedSet(count.times(Order.init))
        let id = UUID()
        var order = Order(id: id)
        order.name = "Order1"
        keyedSet.insert(order)
        XCTAssertNotNil(keyedSet[id])
        order = Order(id: id)
        order.name = "Order2"
        keyedSet.insert(order)
        XCTAssertEqual(keyedSet.count, count + 1)
        XCTAssertEqual(keyedSet[id]!.name!, "Order1")
    }
    
    func testUpdate() {
        let count = 100
        var keyedSet = KeyedSet(count.times(Order.init))
        let id = UUID()
        var order = Order(id: id)
        order.name = "Order1"
        keyedSet.insert(order)
        XCTAssertNotNil(keyedSet[id])
        order = Order(id: id)
        order.name = "Order2"
        keyedSet.update(with: order)
        XCTAssertEqual(keyedSet.count, count + 1)
        XCTAssertEqual(keyedSet[id]!.name!, "Order2")
    }

    func testUnion() {
        let count = 5_000
        var keyedSet = KeyedSet(count.times(Order.init))
        let halfCount = count / 2
        keyedSet.formUnion(keyedSet.suffix(halfCount) + halfCount.times(Order.init))
        XCTAssertEqual(keyedSet.count, count + halfCount)
    }
}
