//
//  CLDeviceInfo.swift
//  CLSwift
//
//  Created by modao on 2018/2/28.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

public struct CLDeviceType: OptionSet, CLInfoProtocol, Hashable {

    public let rawValue: Int32
    public static let CPU = CLDeviceType(rawValue: CL_DEVICE_TYPE_CPU)
    public static let GPU = CLDeviceType(rawValue: CL_DEVICE_TYPE_GPU)
    public static let ACCELERATOR = CLDeviceType(rawValue: CL_DEVICE_TYPE_ACCELERATOR)
    public static let CUSTOM = CLDeviceType(rawValue: CL_DEVICE_TYPE_CUSTOM)
    public static let DEFAULT = CLDeviceType(rawValue: CL_DEVICE_TYPE_DEFAULT)
    public static let ALL: Set<CLDeviceType> = [.CPU, .GPU, .ACCELERATOR, CUSTOM, DEFAULT]

    public var value: cl_device_type {
        return cl_device_type(rawValue)
    }

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

public struct CLDeviceInfoType: OptionSet, CLInfoProtocol, Hashable {

    public let rawValue: Int32
    public static let NAME = CLDeviceInfoType(rawValue: CL_DEVICE_NAME)
    public static let DEVICE_VERSION = CLDeviceInfoType(rawValue: CL_DEVICE_VERSION)
    public static let DRIVE_VERSION = CLDeviceInfoType(rawValue: CL_DRIVER_VERSION)
    public static let OPENCL_C_VERSION = CLDeviceInfoType(rawValue: CL_DEVICE_OPENCL_C_VERSION)
    public static let ADDRESS_BITS = CLDeviceInfoType(rawValue: CL_DEVICE_ADDRESS_BITS)
    public static let DEVICE_VENDOR = CLDeviceInfoType(rawValue: CL_DEVICE_VENDOR)
    public static let DEVICE_PROFILE = CLDeviceInfoType(rawValue: CL_DEVICE_PROFILE)
    public static let EXTENSIONS = CLDeviceInfoType(rawValue: CL_DEVICE_EXTENSIONS)
    public static let BUILT_IN_KERNELS = CLDeviceInfoType(rawValue: CL_DEVICE_BUILT_IN_KERNELS)
    public static let DEVICE_TYPE = CLDeviceInfoType(rawValue: CL_DEVICE_TYPE)
    public static let COMMONINFO: Set<CLDeviceInfoType> = [.NAME, .ADDRESS_BITS, .EXTENSIONS, .OPENCL_C_VERSION]

    public var value: cl_device_info {
        return cl_device_info(rawValue)
    }

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

public struct CLDeviceInfo {

    public private(set) var addressBits: UInt32?
    public private(set) var name: String?
    public private(set) var deviceVersion: String?
    public private(set) var deviceVendor: String?
    public private(set) var driverVersion: String?
    public private(set) var openclVersion: String?
    public private(set) var deviceProfile: String?
    public private(set) var extensions: [String]?
    public private(set) var builtInKernels: [String]?
    public private(set) var deviceType: CLDeviceType?

    init(device: cl_device_id?,
         infoTypes: Set<CLDeviceInfoType>) throws {
        for type in infoTypes {
            var actualSize = 0
            // 获取实际大小
            let code = clGetDeviceInfo(device,
                            type.value,
                            Int.max,
                            nil,
                            &actualSize)
            guard code == CL_SUCCESS else {
                throw deviceError(code)
            }
            switch type {
            case .NAME:
                name = try CLDeviceInfo.stringValue(device: device, type: type, size: actualSize)
            case .DEVICE_VERSION:
                deviceVersion = try CLDeviceInfo.stringValue(device: device, type: type, size: actualSize)
            case .DEVICE_VENDOR:
                deviceVendor = try CLDeviceInfo.stringValue(device: device, type: type, size: actualSize)
            case .DEVICE_PROFILE:
                deviceProfile = try CLDeviceInfo.stringValue(device: device, type: type, size: actualSize)
            case .DRIVE_VERSION:
                driverVersion = try CLDeviceInfo.stringValue(device: device, type: type, size: actualSize)
            case .OPENCL_C_VERSION:
                openclVersion = try CLDeviceInfo.stringValue(device: device, type: type, size: actualSize)
            case .EXTENSIONS:
                extensions = try CLDeviceInfo.stringValue(device: device, type: type, size: actualSize)?
                    .components(separatedBy: " ")
                    .filter { !$0.isEmpty }
            case .BUILT_IN_KERNELS:
                builtInKernels = try CLDeviceInfo.stringValue(device: device, type: type, size: actualSize)?
                    .components(separatedBy: ";")
                    .filter { !$0.isEmpty }
            case .ADDRESS_BITS:
                addressBits = try CLDeviceInfo.integerValue(device: device, type: type, size: actualSize)
            case .DEVICE_TYPE:
                var addrDataPtr: cl_int = 0
                let code = clGetDeviceInfo(device, type.value, actualSize, &addrDataPtr, nil)
                guard code == CL_SUCCESS else {
                    throw deviceError(code)
                }
                deviceType = CLDeviceType(rawValue: addrDataPtr)
            default:
                break
            }
        }
    }

    public static func stringValue(device: cl_device_id?,
                                   type: CLDeviceInfoType,
                                   size actualSize: Int) throws -> String? {
        var charBuffer = UnsafeMutablePointer<cl_char>.allocate(capacity: actualSize)
        defer {
            charBuffer.deallocate(capacity: actualSize)
        }
        let code = clGetDeviceInfo(device, type.value, actualSize, charBuffer, nil)
        guard code == CL_SUCCESS else {
            throw deviceError(code)
        }
        return String(cString: charBuffer)
    }

    public static func integerValue(device: cl_device_id?,
                                    type: CLDeviceInfoType,
                                    size actualSize: Int) throws -> cl_uint {
        var addrDataPtr: cl_uint = 0
        let code = clGetDeviceInfo(device, type.value, actualSize, &addrDataPtr, nil)
        guard code == CL_SUCCESS else {
            throw deviceError(code)
        }
        return addrDataPtr
    }
}

extension Sequence where Iterator.Element == CLDeviceType {
    public var value: [cl_device_type] {
        if underestimatedCount == CLDeviceType.ALL.count {
            return [cl_device_type(CL_DEVICE_TYPE_ALL)]
        }
        return map { $0.value }
    }
}

extension Collection where Iterator.Element == CLDeviceType {
    public var value: [cl_device_type] {
        if underestimatedCount == CLDeviceType.ALL.count {
            return [cl_device_type(CL_DEVICE_TYPE_ALL)]
        }
        return map { $0.value }
    }
}
