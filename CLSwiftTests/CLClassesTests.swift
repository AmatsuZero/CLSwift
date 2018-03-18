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
    var devices: [CLDevice]!
    var context: CLContext!
    var testBundle: Bundle!

    override func setUp() {
        super.setUp()
        guard let organizer = try? CLOrganizer(num_entries: 1), let platform = organizer.platforms.first else {
            return XCTFail("未能发现平台")
        }
        self.organizer = organizer
        guard let devices = try? platform.devices(num_entries: 1, types: .GPU) else {
            return XCTFail("未能访问设备")
        }
        self.devices = devices
        guard let context = try? CLContext(devices: devices) else {
            return XCTFail("未能创建上下文")
        }
        self.context = context
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
        guard let ctx = try? CLContext(deviceType: .GPU) else {
            return XCTFail("未能创建上下文")
        }
        let device = ctx.devices?.first!
        XCTAssertNotNil(device, "未能获得设备")
        XCTAssertNotNil(device?.name, "未能获取名称")
    }

    func testMapCopy() {
        let files = ["/Users/modao/Downloads/source_code_mac/Ch3/map_copy/blank.cl"]
        guard var (bufferSize, buffer) = try? files.kernelFileBuffer() else {
            XCTFail("未能获取信息")
            return
        }
        guard let program = try? CLProgram(context: context, buffers: &buffer, sizes: &bufferSize) else {
            return XCTFail("未能创建Program")
        }
        XCTAssert(program.build(), "编译失败")
        guard let kernel = try? CLKernel(name: "blank", program: program) else {
            return XCTFail("未能创建内核")
        }
        XCTAssertNotNil(kernel.argInfo, "未能获取参数信息")
        var dataOne = [Float](repeating: 0, count: 100)
        var dataTwo = [Float](repeating: 0, count: 100)
        var resultArray = [Float](repeating: 0, count: 100)
        for i in 0..<100 {
            dataOne[i] = Float(i) * 1.0
            dataTwo[i] = Float(i) * -1.0
        }
        var size = MemoryLayout<Float>.size*dataOne.count
        guard let bufferOne = try? CLKernelBuffer(context: context, flags: [.READWRITE, .COPYHOSTPR], size: size, hostBuffer: dataOne) else {
            return XCTFail("未能创建 Buffer one")
        }
        size = MemoryLayout<Float>.size*dataTwo.count
        guard let bufferTwo = try? CLKernelBuffer(context: context, flags: [.READWRITE, .COPYHOSTPR], size: size, hostBuffer: dataTwo) else {
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
        memcpy(&resultArray, mappedMemory, size)
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

    func testReadBuffer()  {
        let files = ["/Users/modao/Downloads/source_code_mac/Ch4/hello_kernel/hello_kernel.cl"]
        guard var (bufferSize, buffer) = try? files.kernelFileBuffer() else {
            XCTFail("未能获取信息")
            return
        }
        guard let program = try? CLProgram(context: context, buffers: &buffer, sizes: &bufferSize) else {
            return XCTFail("未能创建Program")
        }
        XCTAssert(program.build(), "编译失败")
        guard let kernel = try? CLKernel(name: "hello_kernel", program: program) else {
            return XCTFail("未能创建内核")
        }
        XCTAssertNotNil(kernel.argInfo, "未能获取参数信息")
        var msg = [cl_char](repeating: 0, count: 16)
        let size = MemoryLayout<cl_char>.size*msg.count
        guard let msgBuffer = try? CLKernelBuffer(context: context,
                                                  flags: [.WRITE],
                                                  size: size,
                                                  hostBuffer: nil) else {
            return XCTFail("未能创建字符串Buffer")
        }
        XCTAssert((try? kernel.setArgument(at: 0, value: msgBuffer)) == true, "Kernel传值失败")
        guard let queue = try? CLCommandQueue(context: context, device: devices.first!, properties: .ProfileEnable) else {
            return XCTFail("未能创建空值队列")
        }
        do {
            try queue.enqueueTask(kernel: kernel)
        } catch(let e) {
            XCTFail(e.localizedDescription)
        }
        let read = CLCommandQueue.CLCommandBufferOperation.ReadBuffer(0, size)
        XCTAssert(queue.enqueueBuffer(buffer: msgBuffer, operation: read, host: &msg), "添加Read Buffer失败")
        print(String(cString: msg))
    }

    func testImageBuffer() {
        guard devices.first?.isImageSupport == true else {
            return XCTFail("不支持图像处理")
        }
        let files = ["/Users/modao/Downloads/source_code_gnu/Ch6/interp/interp.cl"]
        guard var (bufferSize, buffer) = try? files.kernelFileBuffer() else {
            XCTFail("未能获取信息")
            return
        }
        guard let program = try? CLProgram(context: context, buffers: &buffer, sizes: &bufferSize) else {
            return XCTFail("未能创建Program")
        }
        XCTAssert(program.build(options: [.D("SCALE=%u", "3")]), "编译失败")
        guard let kernel = try? CLKernel(name: "interp", program: program) else {
            return XCTFail("未能创建内核")
        }
        XCTAssertNotNil(kernel.argInfo, "未能获取参数信息")
        guard let path = testBundle.path(forResource: "input", ofType: "png") else {
            return XCTFail("图片不存在！")
        }
        let format = CLKernelImageBuffer.CLImageFormat(order: .Luminance,
                                                       format: .UInt16)
        guard let inputMem = try? CLKernelImageBuffer(context: context,
                                                      flags: [.READ, .COPYHOSTPR],
                                                      format: format,
                                                      image: path) else {
                                                        return XCTFail("未能创建图像对象")
        }
        guard let outputMem = try? CLKernelImageBuffer(context: context, flags: [.WRITE],
                                                       desc: inputMem.desc!,
                                                       format: format, size: inputMem.size!, data: nil) else {
                                                        return XCTFail("未能创建写入对象")
        }
        XCTAssert((try? kernel.setArgument(at: 0, value: inputMem)) == true, "设置参数0失败")
        XCTAssert((try? kernel.setArgument(at: 1, value: outputMem)) == true, "设置参数1失败")
        guard let queue = try? CLCommandQueue(context: context, device: devices.first!, properties: .ProfileEnable) else {
            return XCTFail("未能创建空值队列")
        }

        let globalSize = [inputMem.desc!.imageWidth, inputMem.desc!.imageHeight, 0]
        do {
         try queue.enqueueNDRangeKernel(kernel: kernel, workDim: 2, globalWorkOffset: nil,
                                        globalWorkSize: globalSize, localWorkSize: nil)
        } catch (let e) {
            XCTFail(e.localizedDescription)
        }
        let origin = CLKernelData.CLBufferOrigin(x: 0, y: 0, z: 0)
        let region = CLKernelData.CLBufferRegion(width: 3*inputMem.desc!.imageWidth,
                                                   height: 3*inputMem.desc!.imageHeight,
                                                   depth: 1)
        let command = CLCommandQueue.CLCommandBufferOperation.ReadImage(origin, region, 0, 0)
        guard var imgData = inputMem.data else {
            return XCTFail("未能获取图像源")
        }
        let host = UnsafeMutableRawPointer(mutating: imgData)
        defer {
            host.deallocate()
        }
        XCTAssert(queue.enqueueBuffer(buffer: outputMem, operation: command, host: host), "添加Read Buffer失败")
        XCTAssertNotNil(outputMem.data, "没有读取到数据")
    }
}

