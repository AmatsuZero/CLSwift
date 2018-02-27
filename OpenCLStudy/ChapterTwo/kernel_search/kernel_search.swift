//
//  kernel_search.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/26.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

func kernelSearch() throws {

    var platform: cl_platform_id?
    guard clGetPlatformIDs(1, &platform, nil) >= 0 else {
        fatalError("未能找到任何平台")
    }

    let num_entries: cl_uint = 1 // 获取设备最大值
    var devices: [cl_device_id?] = Array(repeating: nil,
                                         count: Int(num_entries))
    defer {
        devices.forEach { clRetainDevice($0) }
    }
    if clGetDeviceIDs(platform,
                   cl_device_type(CL_DEVICE_TYPE_GPU),
                   num_entries,
                   &devices,
                   nil) == CL_DEVICE_NOT_FOUND {
        guard clGetDeviceIDs(platform,
                             cl_device_type(CL_DEVICE_TYPE_CPU),
                             num_entries,
                             &devices,
                             nil) >= 0 else {
            fatalError("未能找到设备")
        }
    }

    var err: cl_int = 0
    var context = clCreateContext(nil, 1, &devices, nil, nil, &err)
    if err < 0 {
        fatalError("未能创建上下文")
    }
    defer {
        clReleaseContext(context)
    }
    let path = "/Users/modao/OpenCLStudy/OpenCLStudy/ChapterTwo/kernel_search/test.cl"
    let program_handle = try String(contentsOf: URL(fileURLWithPath: path)) as NSString
    var programBuffer = [program_handle].map { $0.utf8String }
    var programSize = MemoryLayout.size(ofValue: program_handle)
    var program = clCreateProgramWithSource(context,
                                            1,
                                            &programBuffer,
                                            &programSize,
                                            &err)
    if err < 0 {
        fatalError("未能创建Program")
    }
    defer {
        clReleaseProgram(program)
    }
    guard clBuildProgram(program, 0, nil, nil, nil, nil) >= 0 else {
        var logSize: size_t = 0
        clGetProgramBuildInfo(program,
                              devices.first!,
                              cl_program_build_info(CL_PROGRAM_BUILD_LOG),
                              0,
                              nil,
                              &logSize)
        var program_log: [cl_char] = Array(repeating: 0, count: logSize+1)
        program_log[logSize] = "\0".cString(using: .utf8)!.first!
        clGetProgramBuildInfo(program,
                              devices.first!,
                              cl_program_build_info(CL_PROGRAM_BUILD_LOG),
                              program_log.count,
                              &program_log,
                              nil)
        fatalError(String(cString: &program_log))
    }

    var num_kernels: cl_uint = 0
    guard clCreateKernelsInProgram(program, 0, nil, &num_kernels) >= 0 else {
        fatalError("未能找到任何核心")
    }

    var kernels: [cl_kernel?] = Array(repeating: nil, count: Int(num_kernels))
    defer {
        kernels.forEach { clReleaseKernel($0) }
    }
    clCreateKernelsInProgram(program, num_kernels, &kernels, nil)
    let kernel_names = kernels.map { kernel -> String in
        var kernel_name:[cl_char] = Array(repeating: 0, count: 20)
        let size = MemoryLayout<cl_char>.stride * kernel_name.count
        clGetKernelInfo(kernel,
                        cl_kernel_info(CL_KERNEL_FUNCTION_NAME),
                        size,
                        &kernel_name,
                        nil)
        return String(cString: &kernel_name)
    }
    if kernel_names.contains("mult") {
        print("Found mult kernel")
    }
}
