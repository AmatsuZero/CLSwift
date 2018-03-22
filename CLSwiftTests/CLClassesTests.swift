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

    func testAsyncBuild() {
        let files = ["/Users/modao/Downloads/source_code_mac/Ch3/map_copy/blank.cl"]
        guard var (bufferSize, buffer) = try? files.kernelFileBuffer() else {
            XCTFail("未能获取信息")
            return
        }
        guard let program = try? CLProgram(context: context, buffers: &buffer, sizes: &bufferSize) else {
            return XCTFail("未能创建Program")
        }
        let expectation = XCTestExpectation(description: "异步编译")
        if program.build(devices: devices, callback: { (program, infos) in
            if infos?.first?.status == .SUCCESS {
                expectation.fulfill()
            } else if infos?.first?.status == .ERROR {
                XCTFail("异步编译失败")
                expectation.fulfill()
            }
        }) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 100)
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
        XCTAssert(queue.enqueueBuffer(buffer: bufferOne, operation: copyCommand).isSuccess, "拷贝内存失败")

        let mapCommand = CLCommandQueue.CLCommandBufferOperation.MapBuffer(0, [.READ])
        guard let mappedMemory = try? queue.mapBuffer(buffer: bufferTwo, operation: mapCommand) else {
            return XCTFail("映射内存失败")
        }
        memcpy(&resultArray, mappedMemory, size)
        var returnedValue = [Float]()
        let unmap = CLCommandQueue.CLCommandBufferOperation.UnmapBuffer(&returnedValue)
        XCTAssert(queue.enqueueBuffer(buffer: bufferTwo, operation: unmap).isSuccess, "取消映射失败")
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
        XCTAssert(queue.enqueueBuffer(buffer: msgBuffer, operation: read, host: &msg).isSuccess, "添加Read Buffer失败")
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
        let format = CLKernelImageBuffer.CLImageFormat(order: .RGBA,
                                                       format: .UInt8)
        guard let inputMem = try? CLKernelImageBuffer(context: context,
                                                      flags: [.READ, .COPYHOSTPR],
                                                      format: format,
                                                      image: path) else {
                                                        return XCTFail("未能创建图像对象")
        }
        var desc = inputMem.desc!
        desc.imageWidth *= 3
        desc.imageHeight *= 3
        guard let outputMem = try? CLKernelImageBuffer(context: context, flags: [.WRITE],
                                                       desc: desc,
                                                       format: format, size: 0, data: nil) else {
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
        let region = CLKernelData.CLBufferRegion(width: desc.imageWidth,
                                                   height: desc.imageHeight,
                                                   depth: 1)
        let command = CLCommandQueue.CLCommandBufferOperation.ReadImage(origin, region, 0, 0)
        guard let imgData = inputMem.data else {
            return XCTFail("未能获取图像源")
        }
        let host = UnsafeMutableRawPointer(mutating: imgData)
        let expectation = XCTestExpectation(description: "读取图像信息")
        queue.enqueueBuffer(buffer: outputMem, operation: command, host: host) { isSuccess, error, _ in
            XCTAssert(isSuccess, error?.localizedDescription ?? "读取图像失败")
            let count = inputMem.size ?? 0 / MemoryLayout<UInt8>.size
            let buffer = UnsafeBufferPointer(start: host.assumingMemoryBound(to: UInt8.self), count: count)
            var imgBuffer = Array(buffer)
            if let ref = imgBuffer.convertToCGmage(desc: desc) {
                let image = NSImage.init(cgImage: ref,
                                         size: NSSize(width: CGFloat(desc.imageWidth),
                                                                    height: CGFloat(desc.imageHeight)))
                print(image)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 100)
    }

    func testCallback() {
        let files = ["/Users/modao/Downloads/source_code_gnu/Ch7/callback/callback.cl"]
        guard var (bufferSize, buffer) = try? files.kernelFileBuffer() else {
            XCTFail("未能获取信息")
            return
        }
        guard let program = try? CLProgram(context: context, buffers: &buffer, sizes: &bufferSize) else {
            return XCTFail("未能创建Program")
        }
        XCTAssert(program.build(), "编译失败")
        guard let kernel = try? CLKernel(name: "callback", program: program) else {
            return XCTFail("未能创建内核")
        }
        XCTAssertNotNil(kernel.argInfo, "未能获取参数信息")
        var data = [Float](repeating: 0, count: 4096)
        let size = MemoryLayout<Float>.size*data.count
        guard let dataBuffer = try? CLKernelBuffer(context: context,
                                                   flags: [.WRITE],
                                                   size: size,
                                                   hostBuffer: nil) else {
            return XCTFail("未能创建Data Buffer")
        }
        XCTAssert((try? kernel.setArgument(at: 0, value: dataBuffer)) == true, "设置参数失败")
        guard let queue = try? CLCommandQueue(context: context, device: devices.first!, properties: .ProfileEnable) else {
            return XCTFail("未能创建队列")
        }
        let kernelEvent = try! queue.enqueueTask(kernel: kernel)
        let command = CLCommandQueue.CLCommandBufferOperation.ReadBuffer(0, size)
        let (isSuccess, readEvent) = queue.enqueueBuffer(buffer: dataBuffer, operation: command, host: &data)
        XCTAssert(isSuccess, "读取失败")
        let kernelExpectation = XCTestExpectation(description: "回调一")
        let readExpectiation = XCTestExpectation(description: "回调二")
        var ud:[String: Any]? = ["message": "The kernel finished successfully.\n\0"]
        do {
            try kernelEvent?.setCallback(type: .complete, userData: &ud, callback: { (_, _, data) in
                print(data ?? "")
                kernelExpectation.fulfill()
            })
            ud?["check"] = data
            try readEvent?.setCallback(type: .complete, userData: &ud, callback: { (_, _, data) in
                print(data ?? "")
                readExpectiation.fulfill()
            })
        } catch(let e) {
            XCTFail(e.localizedDescription)
        }
        wait(for: [kernelExpectation, readExpectiation], timeout: 100)
    }
}

