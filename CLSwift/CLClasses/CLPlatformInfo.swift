//
// Created by modao on 2018/2/28.
// Copyright (c) 2018 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

public struct CLPlatformInfoType: OptionSet, CLInfoProtocol {

    typealias valueType = cl_platform_info
    public let rawValue: Int32
    public static let PROFILE = CLPlatformInfoType(rawValue: CL_PLATFORM_PROFILE)
    public static let VERSION = CLPlatformInfoType(rawValue: CL_PLATFORM_VERSION)
    public static let NAME = CLPlatformInfoType(rawValue: CL_PLATFORM_NAME)
    public static let EXTENSIONS = CLPlatformInfoType(rawValue: CL_PLATFORM_EXTENSIONS)
    public static let ALL: [CLPlatformInfoType] = [.PROFILE, .VERSION, .NAME, .EXTENSIONS]
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    var value: cl_platform_info {
        return cl_platform_info(rawValue)
    }
}

public struct CLPlatformInfo {

    public private(set) var profile: String?
    public private(set) var version: String?
    public private(set) var name: String?
    public private(set) var extensions: [String]?

    init(platform: cl_platform_id?,
         infoTypes: [CLPlatformInfoType]) throws {
        for type in infoTypes {
            var size = 0
            let code =  clGetPlatformInfo(platform,
                                          type.value,
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
            clGetPlatformInfo(platform, type.value, size, infoBuffer, nil)
            let info = String(cString: infoBuffer)
            switch type {
            case .EXTENSIONS:
                extensions = info.components(separatedBy: " ").filter { !$0.isEmpty }
            case .NAME:
                name = info
            case .VERSION:
                version = info
            case .PROFILE:
                profile = info
            default:
                break
            }
        }
    }
}

extension Sequence where Iterator.Element == CLPlatformInfoType {
    public var value: [cl_platform_info] {
        return map { $0.value }
    }
}

extension Collection where Iterator.Element == CLPlatformInfoType {
    public var value: [cl_platform_info] {
        return map { $0.value }
    }
}
