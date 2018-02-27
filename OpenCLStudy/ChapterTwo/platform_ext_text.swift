//
//  platform_ext_text.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/23.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

func isExtensionSupport(name: String = "cl_khr_icd")  {
    var num_platforms: cl_uint = 0
    var platforms: cl_platform_id?
    var ext_size: size_t = 0
    var ext_data = [cl_char]()
    var platform_index: cl_int = -1
    guard clGetPlatformIDs(1, nil, &num_platforms) >= 0 else {
        fatalError("找不到平台信息")
    }
    clGetPlatformIDs(num_platforms, &platforms, nil)
    let platformValues = Array(UnsafeBufferPointer(start: &platforms,
                                                   count: MemoryLayout<cl_platform_id>.size * Int(num_platforms)))
    for i in 0..<num_platforms {
        guard let platform = platformValues[Int(i)], clGetPlatformInfo(platform,
                          cl_platform_info(CL_PLATFORM_EXTENSIONS),
                          0,
                          nil,
                          &ext_size) >= 0 else {
                            fatalError("无法读取extension data")
        }
        clGetPlatformInfo(platform, cl_platform_info(CL_PLATFORM_EXTENSIONS), ext_size, &ext_data, nil)
        let extensionData = String(cString: ext_data)
        print("平台 \(i) 所支持的extesnion：\(extensionData)")
        if extensionData.contains(name) {
            platform_index = cl_int(i)
            break
        }
    }
    if platform_index > -1 {
        print("平台 \(platform_index) 支持 \(name) extension")
    } else {
        print("没有平台支持 \(name) extension")
    }
}
