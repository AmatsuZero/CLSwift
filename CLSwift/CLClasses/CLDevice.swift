//
//  CLDevice.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/27.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

internal let deviceError: (cl_int) -> NSError = { errType -> NSError in
    var message = ""
    switch errType {
    case CL_INVALID_PLATFORM:
        message = "platform is not a valid platform"
    case CL_INVALID_DEVICE_TYPE:
        message = "device_type is not a valid value"
    case CL_INVALID_VALUE:
        message = "num_entries is equal to zero and devices is not NULL or if both num_devices and devices are NULL"
    case CL_DEVICE_NOT_FOUND:
        message = "no OpenCL devices that matched device_type were found"
    case CL_OUT_OF_RESOURCES:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the device"
    case CL_OUT_OF_HOST_MEMORY:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the host"
    default:
        message = "Unknown error"
    }
    return NSError(domain: "com.daubert.OpenCL.Device",
                   code: Int(errType),
                   userInfo: [NSLocalizedFailureReasonErrorKey: message])
}

public final class CLDevice {

    internal let deviceId: cl_device_id?
    //MARK: 设备信息
    public private(set) lazy var addressBits: UInt32? = {
        return try? integerValue(CL_DEVICE_ADDRESS_BITS)
    }()
    public private(set) lazy var name: String? = {
        return try? stringValue(CL_DEVICE_NAME)
    }()
    public private(set) lazy var deviceVersion: String? = {
        return try? stringValue(CL_DEVICE_VERSION)
    }()
    public private(set) lazy var vendor: String? = {
        return try? stringValue(CL_DEVICE_VENDOR)
    }()
    public private(set) lazy var driverVersion: String? = {
        return try? stringValue(CL_DRIVER_VERSION)
    }()
    public private(set) lazy var clVersion: String? = {
        return try? stringValue(CL_DEVICE_OPENCL_C_VERSION)
    }()
    public private(set) lazy var profile: String? = {
        return try? stringValue(CL_DEVICE_PROFILE)
    }()
    public private(set) lazy var extensions: [String]? = {
        return try? stringValue(CL_DEVICE_EXTENSIONS)
            .components(separatedBy: " ")
            .filter {
                !$0.isEmpty
        }
    }()
    public private(set) lazy var builtInKernels: [String]? = {
        return try? stringValue(CL_DEVICE_BUILT_IN_KERNELS)
            .components(separatedBy: ";")
            .filter {
                !$0.isEmpty
        }
    }()
    public private(set) lazy var type: CLDeviceType? = {
        return try? typeValue()
    }()

    public struct CLDeviceType: OptionSet, CLInfoProtocol {
        public let rawValue: Int32
        public static let CPU = CLDeviceType(rawValue: CL_DEVICE_TYPE_CPU)
        public static let GPU = CLDeviceType(rawValue: CL_DEVICE_TYPE_GPU)
        public static let ACCELERATOR = CLDeviceType(rawValue: CL_DEVICE_TYPE_ACCELERATOR)
        public static let CUSTOM = CLDeviceType(rawValue: CL_DEVICE_TYPE_CUSTOM)
        public static let DEFAULT = CLDeviceType(rawValue: CL_DEVICE_TYPE_DEFAULT)
        public static let ALL: CLDeviceType = [.CPU, .GPU, .ACCELERATOR, CUSTOM, DEFAULT]
        public var hashValue: Int {
            return Int(rawValue)
        }
        public var value: cl_device_type {
            return cl_device_type(rawValue)
        }

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
    }

    public init(deviceId: cl_device_id?) {
        self.deviceId = deviceId
    }

    fileprivate func stringValue(_ type: Int32) throws -> String {
        var actualSize = 0
        let code = clGetDeviceInfo(deviceId,
                                   cl_device_info(type),
                                   Int.max,
                                   nil,
                                   &actualSize)
        guard code == CL_SUCCESS else {
            throw deviceError(code)
        }
        var charBuffer = UnsafeMutablePointer<cl_char>.allocate(capacity: actualSize)
        defer {
            charBuffer.deallocate()
        }
        clGetDeviceInfo(deviceId, cl_device_info(type), actualSize, charBuffer, nil)
        return String(cString: charBuffer)
    }

    fileprivate func integerValue(_ type: Int32) throws -> UInt32 {
        var actualSize = 0
        let code = clGetDeviceInfo(deviceId,
                                   cl_device_info(type),
                                   Int.max,
                                   nil,
                                   &actualSize)
        guard code == CL_SUCCESS else {
            throw deviceError(code)
        }
        var addrDataPtr: cl_uint = 0
        clGetDeviceInfo(deviceId, cl_device_info(type), actualSize, &addrDataPtr, nil)
        return addrDataPtr
    }

    fileprivate func typeValue() throws -> CLDeviceType {
        var actualSize = 0
        let code = clGetDeviceInfo(deviceId,
                                   cl_device_info(CL_DEVICE_TYPE),
                                   Int.max,
                                   nil,
                                   &actualSize)
        guard code == CL_SUCCESS else {
            throw deviceError(code)
        }
        var addrDataPtr: cl_int = 0
        clGetDeviceInfo(deviceId, cl_device_info(CL_DEVICE_TYPE), actualSize, &addrDataPtr, nil)
        return CLDeviceType(rawValue: addrDataPtr)
    }

    deinit {
        clReleaseDevice(deviceId)
    }
}
