//
//  CLDeviceInfo.swift
//  CLSwift
//
//  Created by modao on 2018/2/28.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

public struct CLDeviceType: OptionSet, CLInfoProtocol {

    public let rawValue: Int32
    public static let CPU = CLDeviceType(rawValue: CL_DEVICE_TYPE_CPU)
    public static let GPU = CLDeviceType(rawValue: CL_DEVICE_TYPE_GPU)
    public static let ACCELERATOR = CLDeviceType(rawValue: CL_DEVICE_TYPE_ACCELERATOR)
    public static let CUSTOM = CLDeviceType(rawValue: CL_DEVICE_TYPE_CUSTOM)
    public static let DEFAULT = CLDeviceType(rawValue: CL_DEVICE_TYPE_DEFAULT)
    public static let ALL = [.CPU, .GPU, .ACCELERATOR, CUSTOM, DEFAULT]

    public var value: cl_device_type {
        return cl_device_type(rawValue)
    }

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

public struct CLDeviceInfoType: OptionSet, CLInfoProtocol {

    public let rawValue: Int32
    public static let NAME = CLDeviceInfoType(rawValue: CL_DEVICE_NAME)
    public static let DEVICE_VERSION = CLDeviceInfoType(rawValue: CL_DEVICE_VERSION)
    public static let DRIVE_VERSION = CLDeviceInfoType(rawValue: CL_DRIVER_VERSION)
    public static let OPENCL_C_VERSION = CLDeviceInfoType(rawValue: CL_DEVICE_OPENCL_C_VERSION)
    public static let ADDRESS_BITS = CLDeviceInfoType(rawValue: CL_DEVICE_ADDRESS_BITS)
    public static let DEVICE_VENDOR = CLDeviceInfoType(rawValue: CL_DEVICE_VENDOR)
    public static let DEVICE_RPOFILE = CLDeviceInfoType(rawValue: CL_DEVICE_PROFILE)
    public static let EXTENSIONS = CLDeviceInfoType(rawValue: CL_DEVICE_EXTENSIONS)
    public static let BUILT_IN_KERNELS = CLDeviceInfoType(rawValue: CL_DEVICE_BUILT_IN_KERNELS)

    public var value: cl_device_info {
        return cl_device_info(rawValue)
    }

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

public struct CLDeviceInfo {

    var addressBits: Int?
    var name: String?
    var deviceVersion: String?
    var deviceVendor: String?
    var driverVersion: String?
    var openclVersion: String?
    var deviceProfile: String?
    var extensions: [String]?
    var builtInKernels: [String]?

    init(device: cl_device_id?,
         infoTypes: [CLDeviceInfoType]) throws {
        for type in infoTypes {
            var actualSize = 0
            // 获取实际大小
            clGetDeviceInfo(device,
                            type.value,
                            Int.max,
                            nil,
                            &actualSize)
            switch type {
            case .NAME:
                name = try CLDeviceInfo.stringValue(device: device, type: type, size: actualSize)
            case .DEVICE_VERSION:
                deviceVersion = try CLDeviceInfo.stringValue(device: device, type: type, size: actualSize)
            case .DEVICE_VENDOR:
                deviceVendor = try CLDeviceInfo.stringValue(device: device, type: type, size: actualSize)
            case .DEVICE_RPOFILE:
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
