//
//  CLHelper.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/27.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

func getPlatform(num_entries: cl_uint = 1) throws -> cl_platform_id? {
    var platform: cl_platform_id?
    guard clGetPlatformIDs(num_entries, &platform, nil) == CL_SUCCESS else {
        fatalError("未能找到任何平台")
    }
    return platform
}



func getDeviceInfo(device: cl_device_id) {

}
