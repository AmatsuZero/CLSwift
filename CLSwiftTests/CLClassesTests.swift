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

    var clPlatform: CLPlatform?
    var clDevice: CLDevice?
    var platform: OpaquePointer?
    var device: OpaquePointer?
    var context: CLContext?
    
    override func setUp() {
        super.setUp()
        clPlatform = try? CLPlatform()
        guard let platforms = clPlatform?.platforms,
            platforms.count > 0 else {
            return XCTFail("没有得到平台")
        }
        platform = platforms.first!
        clDevice = try? CLDevice(platform: platform)
        guard let devices = clDevice?.devices,
            devices.count > 0 else {
            return XCTFail("没有得到设备")
        }
        device = devices.first!
        context = try? CLContext(devices: devices)
        XCTAssertNotNil(context?.context, "未能创建上下文")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testExample() {
        let platformName = try? platform?.allPlatformInfo()[CLPlatformInfoTypes.NAME.rawValue] as! String
        XCTAssertNotNil(platformName, "没有获得平台名称")
        let deviceName = try? device?.allDeviceInfo()[CLDeviceInfoTypes.NAME.rawValue] as! String
        XCTAssertNotNil(deviceName, "没有获得设备名称")
    }
}
