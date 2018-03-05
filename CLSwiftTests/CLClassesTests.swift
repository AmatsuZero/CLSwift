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
        let ctx = CLContext(deviceType: .GPU) { ret, error in
            XCTAssert(ret, "未能创建上下文：\(error?.localizedDescription ?? "unknown")")
        }
        let device = ctx.devices?.first!
        XCTAssertNotNil(device, "未能获得设备")
        XCTAssertNotNil(device?.name, "未能获取名称")
    }

    func testBuildProgram() {
        let ctx = CLContext(deviceType: .GPU)
        XCTAssertNotNil(ctx, "未能创建上下文")
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

    func testKernels() {
        let ctx = CLContext(deviceType: .GPU)
        XCTAssertNotNil(ctx, "未能创建上下文")
        let path = "/Users/modao/Downloads/source_code_gnu/Ch3/buffer_test/blank.cl"
        let files = [path]
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
                                            XCTFail("未能创建Program")
                                            return
        }
        XCTAssertNotNil(ctx.devices, "没有找到设备")
        let buildComplete = XCTestExpectation(description: "Program build result")
        let enqueueWrite = XCTestExpectation(description: "Buffer wirte")
        let enqueueRead = XCTestExpectation(description: "Buffer read")
        var fullMatrix = [Float](repeating: 0, count: 80)
        for i in 0..<fullMatrix.count {
            fullMatrix[i] = Float(i)
        }
        var zeroMatrix = [Float](repeating: 0, count: 80)
        program.build() { isSuccess, error, userData, info in
            guard isSuccess else {
                return XCTAssert(isSuccess, "未能成功编译: \(error?.localizedDescription ?? "Unknown"))")
            }
            print(info?.first?.options ?? "")
            guard let kernel = try? CLKernel(name: "blank", program: program) else {
                XCTFail("未能成功创建内核")
                return
            }
            do {
                let matrixBuffer = try CLKernelBuffer(context: ctx, flags: [.READWRITE, .COPYHOSTPR], hostBuffer: fullMatrix)
                try kernel.setArgument(at: 0, value: matrixBuffer)
                let queue = try CLCommandQueue(context: ctx, device: ctx.devices!.first!, properties: .ProfileEnable)
                try queue.enqueueTask(kernel: kernel)
                let write: CLCommandQueue.CLCommandBufferOperation = .WriteBuffer(0)
                queue.enqueueBuffer(buffer: matrixBuffer, operation: write, host: &fullMatrix) { isSuccess, error, event in
                    guard isSuccess else {
                        return XCTAssert(isSuccess, error?.localizedDescription ?? "Unknown")
                    }
                    if isSuccess {
                        let bufferOrigin = CLKernelData.CLBufferOrigin(x: 5*MemoryLayout<Float>.stride, y: 3, z: 0)
                        let hostOrigin = CLKernelData.CLBufferOrigin(x: MemoryLayout<Float>.stride, y: 1, z: 0)
                        let region = CLKernelData.CLBufferRegion(width: 4*MemoryLayout<Float>.stride, height: 4, depth: 1)
                        let read: CLCommandQueue.CLCommandBufferOperation = .ReadBufferRect(bufferOrigin, hostOrigin, region, (10*MemoryLayout<Float>.stride, 0), (10*MemoryLayout<Float>.stride, 0))
                        queue.enqueueBuffer(buffer: matrixBuffer, operation: read, host: &zeroMatrix) { isSuccess, error, event in
                            XCTAssert(isSuccess, error?.localizedDescription ?? "Unknown")
                            zeroMatrix.forEach { print($0) }
                            enqueueRead.fulfill()
                        }
                    }
                    enqueueWrite.fulfill()
                }
            } catch (let error) {
                XCTAssert(false, error.localizedDescription)
            }
            buildComplete.fulfill()
        }
        wait(for: [buildComplete, enqueueWrite, enqueueRead], timeout: 100)
    }
}

