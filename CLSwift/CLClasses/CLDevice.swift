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

    public struct CLDeviceFloatTypeConfig: OptionSet, CLInfoProtocol {
        public let rawValue: Int32
        typealias valueType = cl_device_fp_config
        public static let denorm = CLDeviceFloatTypeConfig(rawValue: CL_FP_DENORM)
        public static let infNaN = CLDeviceFloatTypeConfig(rawValue: CL_FP_INF_NAN)
        public static let roundToNearest = CLDeviceFloatTypeConfig(rawValue: CL_FP_ROUND_TO_NEAREST)
        public static let roundToInf = CLDeviceFloatTypeConfig(rawValue: CL_FP_ROUND_TO_INF)
        public static let fma = CLDeviceFloatTypeConfig(rawValue: CL_FP_FMA)
        public static let sortFloat = CLDeviceFloatTypeConfig(rawValue: CL_FP_SOFT_FLOAT)
        public static let correctlyRoundedDivideSQRT = CLDeviceFloatTypeConfig(rawValue: CL_FP_CORRECTLY_ROUNDED_DIVIDE_SQRT)
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
        var value: cl_device_fp_config {
            return cl_device_fp_config(rawValue)
        }
    }

    public enum CLDeviceMemCacheType: Int32, CLInfoProtocol {
        case READ, NONE, READWRITE
        typealias valueType = cl_device_mem_cache_type
        public init(rawValue: Int32) {
            switch rawValue {
            case CL_READ_ONLY_CACHE: self = .READ
            case CL_READ_WRITE_CACHE: self = .READWRITE
            default: self = .NONE
            }
        }
        var value: cl_device_mem_cache_type {
            return cl_device_mem_cache_type(rawValue)
        }
    }

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
    /// 是否是小端序列
    public private(set) lazy var isEndianLittle: Bool? = {
        return try? integerValue(CL_DEVICE_ENDIAN_LITTLE) == CL_TRUE
    }()
    /// Float型支持信息
    public private(set) lazy var floatSupport: CLDeviceFloatTypeConfig? = {
        guard let value = try? integerValue(CL_DEVICE_SINGLE_FP_CONFIG) else { return nil }
        return CLDeviceFloatTypeConfig(rawValue: Int32(value))
    }()
    /// Double型支持信息
    public private(set) lazy var isDoubleSupport: CLDeviceFloatTypeConfig? = {
        guard let value = try? integerValue(CL_DEVICE_DOUBLE_FP_CONFIG) else { return nil }
        return CLDeviceFloatTypeConfig(rawValue: Int32(value))
    }()
    /// Half Float支持信息
    public private(set) lazy var isHalfFloatSupport: CLDeviceFloatTypeConfig? = {
        guard let value = try? integerValue(CL_DEVICE_HALF_FP_CONFIG) else { return nil }
        return CLDeviceFloatTypeConfig(rawValue: Int32(value))
    }()
    //MARK: 首选向量宽度
    public private(set) lazy var preferredVectorWidthChar: UInt32? = {
        return try? integerValue(CL_DEVICE_PREFERRED_VECTOR_WIDTH_CHAR)
    }()
    public private(set) lazy var preferredVectorWidthShort: UInt32? = {
        return try? integerValue(CL_DEVICE_PREFERRED_VECTOR_WIDTH_SHORT)
    }()
    public private(set) lazy var preferredVectorWidthInt: UInt32? = {
        return try? integerValue(CL_DEVICE_PREFERRED_VECTOR_WIDTH_INT)
    }()
    public private(set) lazy var preferredVectorWidthLong: UInt32? = {
        return try? integerValue(CL_DEVICE_PREFERRED_VECTOR_WIDTH_LONG)
    }()
    public private(set) lazy var preferredVectorWidthFloat: UInt32? = {
        return try? integerValue(CL_DEVICE_PREFERRED_VECTOR_WIDTH_FLOAT)
    }()
    public private(set) lazy var preferredVectorWidthDouble: UInt32? = {
        return try? integerValue(CL_DEVICE_PREFERRED_VECTOR_WIDTH_DOUBLE)
    }()
    public private(set) lazy var preferredVectorWidthHalf: UInt32? = {
        return try? integerValue(CL_DEVICE_PREFERRED_VECTOR_WIDTH_HALF)
    }()
    //MARK: 设备地址空间大小
    public private(set) lazy var globalMemSize: UInt64? = {
        return try? longValue(CL_DEVICE_GLOBAL_MEM_SIZE)
    }()
    public private(set) lazy var globalMemCacheSize: UInt64? = {
        return try? longValue(CL_DEVICE_GLOBAL_MEM_CACHE_SIZE)
    }()
    public private(set) lazy var globakMemCacheType: CLDeviceMemCacheType? = {
        guard let value = try? integerValue(CL_DEVICE_GLOBAL_MEM_CACHE_TYPE) else {
            return nil
        }
        return CLDeviceMemCacheType(rawValue: Int32(value))
    }()
    public private(set) lazy var constantBufferSize: UInt64? = {
        return try? longValue(CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE)
    }()
    /// 是否支持图像处理
    public private(set) lazy var isImageSupport: Bool? = {
        return try? integerValue(CL_DEVICE_IMAGE_SUPPORT) == CL_TRUE
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

    fileprivate func longValue(_ type: Int32) throws -> UInt64 {
        var actualSize = 0
        let code = clGetDeviceInfo(deviceId,
                                   cl_device_info(type),
                                   Int.max,
                                   nil,
                                   &actualSize)
        guard code == CL_SUCCESS else {
            throw deviceError(code)
        }
        var addrDataPtr: cl_ulong = 0
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
