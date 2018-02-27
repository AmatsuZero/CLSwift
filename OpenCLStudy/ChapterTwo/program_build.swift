//
//  File.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/26.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

func programBuild() throws {

    var platform: cl_platform_id?
    guard clGetPlatformIDs(1, &platform, nil) >= 0 else {
        fatalError("未能找到任何平台")
    }

    var err: cl_int = 0
    var devices:[cl_device_id?] = Array(repeating: nil, count: 1)
    err = clGetDeviceIDs(platform,
                         cl_device_type(CL_DEVICE_TYPE_GPU),
                         1,
                         &devices,
                         nil)
    if err == CL_DEVICE_NOT_FOUND {
        err = clGetDeviceIDs(platform,
                             cl_device_type(CL_DEVICE_TYPE_CPU),
                             1,
                             &devices,
                             nil)
    }
    guard err >= 0 else {
        fatalError("未能找到任何设备")
    }
    let context = clCreateContext(nil, 1, &devices, nil, nil, &err)
    defer {
        clReleaseContext(context)
    }
    guard err >= 0 else {
        fatalError("未能创建上下文")
    }
    // 这里如果直接扔进去cl文件，Xcode会因为函数名相同而无法通过编译
    var good = """
    __kernel void good(__global float *a,
                   __global float *b,
                   __global float *c) {

        *c = *a + *b;
    }
    """
    // 如果想要成功，改一个不同的函数名
    var bad = """
    __kernel void good(__global float *a,
                   __global float *b,
                   __global float *c) {

        *c = *a + *b;
    }
    """
    var programBuffer = [good, bad]
        .map { ($0 as NSString).utf8String }
    var program_size = programBuffer.reduce(0) { (size, next) -> Int in
        return size + MemoryLayout.size(ofValue: next)
    }
    let program = clCreateProgramWithSource(context,
                                            cl_uint(programBuffer.count),
                                            &programBuffer,
                                            nil,
                                            &err)
    defer {
        clReleaseProgram(program)
    }
    guard err >= 0 else {
        fatalError("未能创建CL程序（progrram）")
    }
    let options = "-cl-finite-math-only -cl-no-signed-zeros"
    err = clBuildProgram(program, 1, &devices, options, nil, nil)
    if err < 0 {
        var program_log = [cl_char]()
        clGetProgramBuildInfo(program,
                              devices.first!,
                              cl_program_build_info(CL_PROGRAM_BUILD_LOG),
                              0,
                              &program_log,
                              nil)
        print(String(cString: &program_log, encoding: .utf8) ?? "Empty")
    }
}
