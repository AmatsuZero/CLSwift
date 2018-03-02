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
    var testBundle: Bundle!

    override func setUp() {
        super.setUp()
        organizer = try! CLOrganizer()
        testBundle = Bundle(for: type(of: self))
    }

    override func tearDown() {
        super.tearDown()
    }

    func testExample() {
        XCTAssert(!organizer.platforms.isEmpty, "没有获得平台")
        let platform = organizer.platforms.first!
        XCTAssertNotNil(platform.name, "没有获得平台名称")
        let devices = try! platform.devices(types: [.CPU, .GPU])
        XCTAssert(!devices.isEmpty, "没有获得设备")
        let device = devices.first!
        XCTAssertNotNil(device.name, "没有获得设备名称")
    }

    func testContext() {
        let ctx = try! CLContext(contextProperties: nil, deviceType: .GPU)
        XCTAssertNotNil(ctx, "未能创建上下文")
        let device = ctx.devices?.first!
        XCTAssertNotNil(device, "未能获得设备")
        XCTAssertNotNil(device?.name, "未能获取名称")
    }

    func testBuildProgram() {
        let ctx = try! CLContext(deviceType: .GPU)
        XCTAssertNotNil(ctx, "未能创建上下文")
        let path = "/Users/modao/Downloads/source_code_mac/Ch2/queue_kernel/blank.cl"
        XCTAssert(FileManager.default.fileExists(atPath: path), "没有找到文件")
        let files = [path]
        var bufferSize = 0
        var buffer = [UnsafePointer<Int8>?]()
        for file in files {
            if let (size, charBuffer) = try? file.toDataBuffer() {
                bufferSize += size
                buffer.append(charBuffer)
            }
        }
        let program = try? CLProgram(context: ctx,
                                     buffer: &buffer,
                                     size: &bufferSize)
        XCTAssertNotNil(program, "未能创建Program")
//        program?.build(options: [.D_NAME(nil), .FiniteMathOnly])
    }
}

