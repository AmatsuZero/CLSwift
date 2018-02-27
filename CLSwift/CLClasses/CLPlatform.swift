//
//  CLPlatform.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/27.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

public enum CLPlatformInfoTypes: String {

    case PROFILE = "profile"
    case VERSION = "version"
    case NAME = "name"
    case VENDOR = "vendor"
    case EXTENSIONS = "extension"
    
    var typeCode: Int32 {
        switch self {
        case .PROFILE:
            return CL_PLATFORM_PROFILE
        case .VERSION:
            return CL_PLATFORM_VERSION
        case .NAME:
            return CL_PLATFORM_NAME
        case .VENDOR:
            return CL_PLATFORM_VENDOR
        case .EXTENSIONS:
            return CL_PLATFORM_EXTENSIONS
        }
    }

    var value: cl_platform_info {
        return cl_platform_info(self.typeCode)
    }
}

private let platformError: (cl_int) -> NSError = { errType -> NSError in
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

    let platforms: [cl_platform_id?]

    init(num_entries: cl_uint = 0) throws {
        var numEntries = num_entries
        var num_platforms = numEntries
        let code = clGetPlatformIDs(num_entries, nil, &num_platforms)
        guard code == CL_SUCCESS else {
            throw platformError(code)
        }
        if num_entries == 0 {
            numEntries = num_platforms
        }
        var platforms: [cl_platform_id?] = Array(repeating: nil, count: Int(numEntries))
        clGetPlatformIDs(numEntries, &platforms, nil)
        self.platforms = platforms
    }

    class func platFormInfo(platform: cl_platform_id?, infoType: Int32) throws -> Any {
        var size = 0
        let code =  clGetPlatformInfo(platform,
                                      cl_platform_info(infoType),
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
        clGetPlatformInfo(platform, cl_platform_info(infoType), size, infoBuffer, nil)
        let info = String(cString: infoBuffer)
        switch infoType {
        case CL_PLATFORM_EXTENSIONS:
            return info.components(separatedBy: " ").filter { !$0.isEmpty }
        default:
            return info
        }
    }
}

extension cl_platform_id {

    public func platformInfo(infoType: CLPlatformInfoTypes) throws -> Any {
        var size = 0
        let code =  clGetPlatformInfo(self,
                                      infoType.value,
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
        clGetPlatformInfo(self, infoType.value, size, infoBuffer, nil)
        let info = String(cString: infoBuffer)
        switch infoType.typeCode {
        case CL_PLATFORM_EXTENSIONS:
            return info.components(separatedBy: " ").filter { !$0.isEmpty }
        default:
            return info
        }
    }

    func allPlatformInfo() throws -> [String: Any] {
        var infos = [String: Any]()
        for type in iterateEnum(CLPlatformInfoTypes.self) {
            infos[type.rawValue] = try platformInfo(infoType: type)
        }
        return infos
    }
}
