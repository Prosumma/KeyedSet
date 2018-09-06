//
//  KeyedSetTests.swift
//  KeyedSetTests
//
//  Created by Gregory Higley on 9/5/18.
//  Copyright © 2018 Prosumma LLC. All rights reserved.
//

import XCTest
@testable import KeyedSet

struct Item: Keyed {
    static let keyAttribute = \Item.id
    let id = UUID()
}

struct Zing: Hashable {
    let id = UUID()
}

extension Int {
    func times(_ action: () throws -> Void) rethrows {
        for _ in 0..<self {
            try action()
        }
    }
    
    func times<T>(_ f: (Int) throws -> T) rethrows -> [T] {
        return try (0..<self).map(f)
    }
    
    func times<T>(_ f: () throws -> T) rethrows -> [T] {
        return try (0..<self).map{ _ in try f() }
    }
}

class KeyedSetTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        let elements = 10_000.times(Item.init)
        let others = elements.suffix(5_000) + 5_000.times(Item.init)
        self.measure {
            var ks = KeyedSet(elements)
            ks.formUnion(others)
        }
    }

}
