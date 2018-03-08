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
    var dataOne = [Float](repeating: 0, count: 100)
    var dataTwo = [Float](repeating: 0, count: 100)
    var resultArray = [Float](repeating: 0, count: 100)

    override func setUp() {
        super.setUp()
        organizer = try! CLOrganizer()
        testBundle = Bundle(for: type(of: self))
        for i in 0..<100 {
            dataOne[i] = Float(i) * 1.0
            dataTwo[i] = Float(i) * -1.0
        }
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
        guard let ctx = try? CLContext(deviceType: .GPU) else {
            return XCTFail("未能创建上下文")
        }
        let device = ctx.devices?.first!
        XCTAssertNotNil(device, "未能获得设备")
        XCTAssertNotNil(device?.name, "未能获取名称")
    }

    func testBuildProgram() {
        guard let ctx = try? CLContext(deviceType: .GPU) else {
            return XCTFail("未能创建上下文")
        }
        let path1 = "/Users/modao/Downloads/source_code_mac/Ch2/program_build/good.cl"
        let path2 = "/Users/modao/Downloads/source_code_mac/Ch2/program_build/bad.cl"
        let files = [path1, path2]
        files.forEach { XCTAssert(FileManager.default.fileExists(atPath: $0), "没有找到文件") }
        var bufferSize = [Int]()
        var buffer = [UnsafePointer<Int8>?]()
        for file in files {
            if let (size, charBuffer) = try? file.toDataBuffer() {
                bufferSize.append(size)
                buffer.append(charBuffer)
            }
        }
        guard let program = try? CLProgram(context: ctx,
                                           buffers: &buffer,
                                           sizes: &bufferSize) else {
                                            return XCTFail("未能创建Program")
        }
        XCTAssertNotNil(ctx.devices, "没有找到设备")
        let buildComplete = XCTestExpectation(description: "Program build result")
        program.build(options: [.DenormsAreZero, .FiniteMathOnly], devices: ctx.devices!) { isSuccess, error, _, _ in
            print(error?.localizedDescription ?? "Unknown")
            XCTAssert(!isSuccess, "同名函数应该导致编译失败")
            buildComplete.fulfill()
        }
        wait(for: [buildComplete], timeout: 100)
    }

    func testMapCopy() {
        guard let organizer = try? CLOrganizer(num_entries: 1), let platform = organizer.platforms.first else {
            return XCTFail("未能发现平台")
        }
        guard let devices = try? platform.devices(num_entries: 1, types: .GPU) else {
            return XCTFail("未能访问设备")
        }
        guard let context = try? CLContext(devices: devices) else {
            return XCTFail("未能创建上下文")
        }
        let path1 = "/Users/modao/Downloads/source_code_mac/Ch3/map_copy/blank.cl"
        let files = [path1]
        files.forEach { XCTAssert(FileManager.default.fileExists(atPath: $0), "没有找到文件") }
        var bufferSize = [Int]()
        var buffer = [UnsafePointer<Int8>?]()
        for file in files {
            if let (size, charBuffer) = try? file.toDataBuffer() {
                bufferSize.append(size)
                buffer.append(charBuffer)
            }
        }
        guard let program = try? CLProgram(context: context, buffers: &buffer, sizes: &bufferSize) else {
            return XCTFail("未能创建Program")
        }
        XCTAssert(program.build(), "编译失败")
        guard let kernel = try? CLKernel(name: "blank", program: program) else {
            return XCTFail("未能创建内核")
        }

        guard let bufferOne = try? CLKernelBuffer(context: context, flags: [.READWRITE, .COPYHOSTPR], hostBuffer: dataOne) else {
            return XCTFail("未能创建 Buffer one")
        }

        guard let bufferTwo = try? CLKernelBuffer(context: context, flags: [.READWRITE, .COPYHOSTPR], hostBuffer: dataTwo) else {
            return XCTFail("未能创建 Buffer Two")
        }
        XCTAssert((try? kernel.setArgument(at: 0, value: bufferOne)) == true, "设置参数0失败")
        XCTAssert((try? kernel.setArgument(at: 1, value: bufferTwo)) == true, "设置参数1失败")
        guard let queue = try? CLCommandQueue(context: context, device: devices.first!, properties: .ProfileEnable) else {
            return XCTFail("未能创建空值队列")
        }
        do {
            try queue.enqueueTask(kernel: kernel)
        } catch(let e) {
            XCTFail(e.localizedDescription)
        }
        let copyCommand = CLCommandQueue.CLCommandBufferOperation.CopyBuffer(bufferTwo, 0, 0)
        XCTAssert(queue.enqueueBuffer(buffer: bufferOne, operation: copyCommand), "拷贝内存失败")

        let mapCommand = CLCommandQueue.CLCommandBufferOperation.MapBuffer(0, [.READ])
        guard let mappedMemory = try? queue.mapBuffer(buffer: bufferTwo, operation: mapCommand) else {
            return XCTFail("映射内存失败")
        }
        memcpy(&resultArray, mappedMemory, MemoryLayout.size(ofValue: dataTwo))
        var returnedValue = [Float]()
        let unmap = CLCommandQueue.CLCommandBufferOperation.UnmapBuffer(&returnedValue)
        XCTAssert(queue.enqueueBuffer(buffer: bufferTwo, operation: unmap), "取消映射失败")
        for i in 0..<10 {
            for j in 0..<10 {
                print(resultArray[j+i*10])
            }
            print("==========")
        }
    }
}

