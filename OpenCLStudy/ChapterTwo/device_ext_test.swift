
//
//  device_ext_tesrt.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/23.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

func deviceInfo() throws -> [String: Any] {
    var platform: cl_platform_id?
    guard clGetPlatformIDs(1, &platform, nil) >= 0 else {
        fatalError("没有找到任何平台")
    }
    var num_devices: cl_uint = 0

    guard clGetDeviceIDs(platform,
                         cl_device_type(CL_DEVICE_TYPE_ALL), 1,
                         nil,
                         &num_devices) >= 0 else {
                             fatalError("没有找到任何设备")
    }

    var devices: [cl_device_id?] = Array(repeating: nil, count: Int(num_devices))
    clGetDeviceIDs(platform,
                   cl_device_type(CL_DEVICE_TYPE_ALL),
                   num_devices,
                   &devices,
                   nil)
    let namePtr = UnsafeMutablePointer<cl_char>.allocate(capacity: 48)
    let extDataPtr = UnsafeMutablePointer<cl_char>.allocate(capacity: 4096)
    var addrDataPtr: cl_uint = 0
    defer {
        namePtr.deallocate()
        extDataPtr.deallocate()
    }
    devices.forEach { device in
        guard clGetDeviceInfo(device,
                              cl_device_info(CL_DEVICE_NAME),
                              MemoryLayout<cl_char>.stride*48,
                              namePtr,
                              nil) >= 0 else {
                                fatalError("无法读取扩展数据")
        }
        let size = MemoryLayout<Int>.stride*4096
        clGetDeviceInfo(device,
                        cl_device_info(CL_DEVICE_ADDRESS_BITS),
                        size,
                        &addrDataPtr,
                        nil)
        clGetDeviceInfo(device,
                        cl_device_info(CL_DEVICE_EXTENSIONS),
                        size,
                        extDataPtr,
                        nil)
        clReleaseDevice(device)
    }
    let name = String(cString: namePtr)
    let ext_data = String(cString: extDataPtr).components(separatedBy: " ").filter { !$0.isEmpty }
    return [
        "name": name,
        "addressWidth": addrDataPtr,
        "extensions": ext_data
    ]
}
