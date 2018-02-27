//
//  context_count.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/26.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

func contextCount() throws {
    var platform = try getPlatform()
    var devices = [cl_device_id?]()
    if clGetDeviceIDs(platform,
                      cl_device_type(CL_DEVICE_TYPE_GPU),
                      1,
                      &devices,
                      nil) == CL_DEVICE_NOT_FOUND {
        guard clGetDeviceIDs(platform,
                             cl_device_type(CL_DEVICE_TYPE_CPU),
                             1,
                             &devices,
                             nil) >= 0 else {
                                fatalError("未能找到任何设备")
        }
    }
    var err: cl_int = 0
    let context = clCreateContext(nil, 1, &devices, nil, nil, &err)
    defer {
        clReleaseContext(context)
    }
    guard err >= 0 else {
        fatalError("未能创建上下文")
    }
    var refCount: cl_uint = 0
    guard clGetContextInfo(context,
                           cl_context_info(CL_CONTEXT_REFERENCE_COUNT),
                           MemoryLayout.size(ofValue: refCount),
                           &refCount,
                           nil) >= 0 else {
                            fatalError("未能读取引用计数")
    }
    print("初始引用计数为：\(refCount)")

    clRetainContext(context)
    clGetContextInfo(context,
                     cl_context_info(CL_CONTEXT_REFERENCE_COUNT),
                     MemoryLayout.size(ofValue: refCount),
                     &refCount,
                     nil)
    print("当前引用计数为：\(refCount)")

    clReleaseContext(context)
    clGetContextInfo(context,
                     cl_context_info(CL_CONTEXT_REFERENCE_COUNT),
                     MemoryLayout.size(ofValue: refCount),
                     &refCount,
                     nil)
    print("当前引用计数为：\(refCount)")
}
