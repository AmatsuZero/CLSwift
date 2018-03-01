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
        XCTAssertNotNil(platform.info!, "没有获得平台信息")
        let devices = try! platform.devices(types: [.CPU, .GPU],
                infoTypes: [.NAME, .ADDRESS_BITS, .EXTENSIONS, .DEVICE_VENDOR])
        XCTAssert(!devices.isEmpty, "没有获得设备")
        let device = devices.first!
        XCTAssertNotNil(device.info, "没有获得设备信息")
    }

    func testContext() {
        let ctx = try! CLContext(contextProperties: nil, deviceType: .GPU)
        XCTAssertNotNil(ctx, "未能创建上下文")
        let device = ctx.info.devices!.first!
        XCTAssertNotNil(device, "未能获得设备")
        let info = device[[.NAME,
                           .ADDRESS_BITS,
                           .DEVICE_VENDOR,
                           .BUILT_IN_KERNELS,
                           .OPENCL_C_VERSION,
                           .EXTENSIONS,
                           .DEVICE_VERSION,
                           .DRIVE_VERSION,
                           .BUILT_IN_KERNELS,
                           .DEVICE_PROFILE,
                           .DEVICE_TYPE]]
        XCTAssertNotNil(info, "未能获取信息")
    }

    func testBuildSingleProgram() {
        let ctx = try! CLContext(contextProperties: nil, deviceType: .GPU)
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
        var version = ctx.info.devices?.first?.info?.openclVersion
        if version == nil {
            version = ctx.info.devices?.first?[[.OPENCL_C_VERSION]]?.openclVersion
        }
        program?.build(options: [.D_NAME(nil), .FiniteMathOnly, .CLVersion(version!)])
    }
}
