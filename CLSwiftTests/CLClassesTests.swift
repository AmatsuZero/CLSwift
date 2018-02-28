//
//  CLSwiftTests.swift
//  CLSwiftTests
//
//  Created by modao on 2018/2/27.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import XCTest
@testable import CLSwift

class CLClassesTests: XCTestCase {

    var organizer: CLOrganizer!
    
    override func setUp() {
        super.setUp()
        organizer = try! CLOrganizer()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testExample() {
        XCTAssert(!organizer.platforms.isEmpty, "没有获得平台")
        let platform = organizer.platforms.first!
        XCTAssertNotNil(platform.info!, "没有获得平台信息")
        let devices = try! platform.devices(types: [.CPU, .GPU],
                                            infoTyps: [.NAME, .ADDRESS_BITS, .EXTENSIONS, .DEVICE_VENDOR])
        XCTAssert(!devices.isEmpty, "没有获得设备")
        let device = devices.first!
        XCTAssertNotNil(device.info, "没有获得设备信息")
    }
}
