//
//  CLPlatform.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/27.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

internal let platformError: (cl_int) -> NSError = { errType -> NSError in
    var message = ""
    switch errType {
    case CL_INVALID_VALUE:
        message = "num_entries is equal to zero and platforms is not NULL or if both num_platforms and platforms are NULL"
    case CL_OUT_OF_HOST_MEMORY:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the host"
    default:
        message = "Unknown error"
    }
    return NSError(domain: "com.daubert.OpenCL.Platform",
                   code: Int(errType),
                   userInfo: [NSLocalizedDescriptionKey: message])
}

public final class CLPlatform {

    /// 平台ID
    internal let platformId: cl_platform_id?

    init(platformId: cl_platform_id?) {
        self.platformId = platformId
    }

    //MARK: 平台信息
    public private(set) lazy var profile: String? = {
        return try? stringValue(CL_PLATFORM_PROFILE)
    }()
    public private(set) lazy var version: String? = {
        return try? stringValue(CL_PLATFORM_VERSION)
    }()
    public private(set) lazy var name: String? = {
        return try? stringValue(CL_PLATFORM_NAME)
    }()
    public private(set) lazy var extensions: [String]? = {
        return try? stringValue(CL_PLATFORM_EXTENSIONS).components(separatedBy: " ").filter {
            !$0.isEmpty
        }
    }()

    public func devices(num_entries: UInt32 = 0,
                        types: Set<CLDevice.CLDeviceType>) throws -> [CLDevice] {
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
        return devices.map {
            CLDevice(deviceId: $0)
        }
    }

    fileprivate func stringValue(_ type: Int32) throws -> String {
        var size = 0
        let code = clGetPlatformInfo(platformId,
                cl_platform_info(type),
                Int.max,
                nil,
                &size)
        guard code == CL_SUCCESS else {
            throw platformError(code)
        }
        var infoBuffer = UnsafeMutablePointer<cl_char>.allocate(capacity: size)
        defer {
            infoBuffer.deallocate(capacity: size)
        }
        clGetPlatformInfo(platformId, cl_platform_info(type), size, infoBuffer, nil)
        return String(cString: infoBuffer)
    }
}
