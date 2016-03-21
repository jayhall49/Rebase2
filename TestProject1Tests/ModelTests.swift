//
//  ModelTests.swift
//  TestProject1
//
//  Created by Jay Hall on 3/19/16.
//  Copyright © 2016 Jay Hall. All rights reserved.
//

import XCTest
//@testable import TestProjectOne


class ModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let map = frameSequence
        
        var byteCount = 0
        
        for j in 0..<map.count {
            let sampleType = map[j]
            byteCount += sampleType.groupLength
        }
        
        
        XCTAssert(byteCount == 560, "Map error: byte count \(byteCount) != 560.")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

}
