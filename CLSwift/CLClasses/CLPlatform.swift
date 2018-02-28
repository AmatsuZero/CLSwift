//
//  CLPlatform.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/27.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

internal let platformError: (cl_int) -> NSError = { errType -> NSError in
    var message = ""
    switch errType {
    case CL_INVALID_VALUE:
        message = "num_entries is equal to zero and platforms is not NULL or if both num_platforms and platforms are NULL"
    case CL_OUT_OF_HOST_MEMORY:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the host"
    default:
        message = "Unknow error"
    }
    return NSError(domain: "com.daubert.OpenCL.Platform", code: Int(errType), userInfo: [NSLocalizedDescriptionKey: message])
}

public final class CLPlatform {

    /// 平台信息类型
    private let types: [CLPlatformInfoType]
    /// 平台ID
    internal let platformId: cl_platform_id?
    /// 平台信息
    public lazy var info: CLPlatformInfo? = {
        return try? CLPlatformInfo(platform: platformId, infoTypes: types)
    }()

    init(platformId: cl_platform_id?,
         platfromInfoTypes: [CLPlatformInfoType] = CLPlatformInfoType.ALL) {
        types = platfromInfoTypes
        self.platformId = platformId
    }

    public func devices(num_entries: cl_uint = 0,
                        types: [CLDeviceType] = CLDeviceType.ALL,
                        infoTyps: [CLDeviceInfoType]) throws -> [CLDevice] {
        var devices = [cl_device_id?]()
        for type in types {
            var devicesNum = num_entries
            var numEntries = num_entries
            // 获取设备数量
            let code: cl_int = clGetDeviceIDs(platformId,
                                              type.value,
                                              num_entries,
                                              nil,
                                              &devicesNum)
            guard code == CL_SUCCESS else {
                throw deviceError(code)
            }
            if num_entries == 0 {
                numEntries = devicesNum
            }
            // 获取设备
            var devicesIds:[cl_device_id?] = Array(repeating: nil, count: Int(numEntries))
            clGetDeviceIDs(platformId, type.value, numEntries, &devicesIds, nil)
            devices.append(contentsOf: devicesIds)
        }
        return devices.map { CLDevice(deviceId: $0, infoTypes: infoTyps) }
    }
}
