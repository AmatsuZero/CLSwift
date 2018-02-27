//
//  CLDevice.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/27.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

public enum CLDeviceInfoTypes: String {
    /*
     以下枚举不可用：
     CL_DEVICE_MAX_ON_DEVICE_QUEUES,
     CL_DEVICE_MAX_ON_DEVICE_EVENTS,
     CL_DEVICE_MAX_PIPE_ARGS,
     CL_DEVICE_MAX_READ_WRITE_IMAGE_ARGS,
     CL_DEVICE_PIPE_MAX_ACTIVE_RESERVATIONS，
     CL_DEVICE_PIPE_MAX_PACKET_SIZE
     */
    case ADDRESS_BITS = "ADDRESS_BITS"
    case GLOBAL_MEM_CACHELINE_SIZE = "GLOBAL_MEM_CACHELINE_SIZE"
    case IMAGE_BASE_ADDRESS_ALIGNMENT = "IMAGE_BASE_ADDRESS_ALIGNMENT"
    case IMAGE_PITCH_ALIGNMENT = "IMAGE_PITCH_ALIGNMENT"
    case MAX_CLOCK_FREQUENCY = "MAX_CLOCK_FREQUENCY"
    case MAX_COMPUTE_UNITS = "MAX_COMPUTE_UNITS"
    case MAX_CONSTANT_ARGS = "MAX_CONSTANT_ARGS"
    case MAX_READ_IMAGE_ARGS = "MAX_READ_IMAGE_ARGS"
    case MAX_SAMPLERS = "MAX_SAMPLERS"
    case MAX_WORK_ITEM_DIMENSIONS = "MAX_WORK_ITEM_DIMENSIONS"
    case MAX_WRITE_IMAGE_ARGS = "MAX_WRITE_IMAGE_ARGS"
    case MEM_BASE_ADDR_ALIGN = "MEM_BASE_ADDR_ALIGN"
    case NATIVE_VECTOR_WIDTH_CHAR = "NATIVE_VECTOR_WIDTH_CHAR"
    case NATIVE_VECTOR_WIDTH_SHORT = "NATIVE_VECTOR_WIDTH_SHORT"
    case NATIVE_VECTOR_WIDTH_INT = "NATIVE_VECTOR_WIDTH_INT"
    case NATIVE_VECTOR_WIDTH_LONG = "NATIVE_VECTOR_WIDTH_LONG"
    case NATIVE_VECTOR_WIDTH_FLOAT = "NATIVE_VECTOR_WIDTH_FLOAT"
    case NATIVE_VECTOR_WIDTH_DOUBLE = "NATIVE_VECTOR_WIDTH_DOUBLE"
    case NATIVE_VECTOR_WIDTH_HALF = "NATIVE_VECTOR_WIDTH_HALF"
    case PARTITION_MAX_SUB_DEVICES = "PARTITION_MAX_SUB_DEVICES"
    case AVAILABLE = "AVAILABLE"
    case COMPILER_AVAILABLE = "COMPILER_AVAILABLE"
    case ENDIAN_LITTLE = "ENDIAN_LITTLE"
    case ERROR_CORRECTION_SUPPORT = "ERROR_CORRECTION_SUPPORT"
    case IMAGE_SUPPORT = "IMAGE_SUPPORT"
    case LINKER_AVAILABLE = "LINKER_AVAILABLE"
    case BUILT_IN_KERNELS = "BUILT_IN_KERNELS"
    case NAME = "NAME"
    case EXTENSIONS = "EXTENSIONS"
    case OPENCL_C_VERSION = "OPENCL_C_VERSION"
    case DEVICE_VENDOR = "VENDOR"
    case DEVICE_VERSION = "DEVICE_VERSION"
    case DRIVER_VERSION = "DRIVER_VERSION"
    case DEVICE_PROFILE = "DEVICE_PROFILE"

    var typeCode: Int32 {
        switch self {
        case .ADDRESS_BITS:
            return CL_DEVICE_ADDRESS_BITS
        case .GLOBAL_MEM_CACHELINE_SIZE:
            return CL_DEVICE_GLOBAL_MEM_SIZE
        case .IMAGE_PITCH_ALIGNMENT:
            return CL_DEVICE_IMAGE_PITCH_ALIGNMENT
        case .MAX_CLOCK_FREQUENCY:
            return CL_DEVICE_MAX_CLOCK_FREQUENCY
        case .MAX_COMPUTE_UNITS:
            return CL_DEVICE_MAX_COMPUTE_UNITS
        case .MAX_CONSTANT_ARGS:
            return CL_DEVICE_MAX_CONSTANT_ARGS
        case .MAX_READ_IMAGE_ARGS:
            return CL_DEVICE_MAX_READ_IMAGE_ARGS
        case .MAX_SAMPLERS:
            return CL_DEVICE_MAX_SAMPLERS
        case .MAX_WORK_ITEM_DIMENSIONS:
            return CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS
        case .MAX_WRITE_IMAGE_ARGS:
            return CL_DEVICE_MAX_WRITE_IMAGE_ARGS
        case .MEM_BASE_ADDR_ALIGN:
            return CL_DEVICE_MEM_BASE_ADDR_ALIGN
        case .NATIVE_VECTOR_WIDTH_CHAR:
            return CL_DEVICE_NATIVE_VECTOR_WIDTH_CHAR
        case .NATIVE_VECTOR_WIDTH_SHORT:
            return CL_DEVICE_NATIVE_VECTOR_WIDTH_SHORT
        case .NATIVE_VECTOR_WIDTH_INT:
            return CL_DEVICE_NATIVE_VECTOR_WIDTH_INT
        case .NATIVE_VECTOR_WIDTH_LONG:
            return CL_DEVICE_NATIVE_VECTOR_WIDTH_LONG
        case .NATIVE_VECTOR_WIDTH_DOUBLE:
            return CL_DEVICE_NATIVE_VECTOR_WIDTH_DOUBLE
        case .NATIVE_VECTOR_WIDTH_HALF:
            return CL_DEVICE_NATIVE_VECTOR_WIDTH_HALF
        case .NATIVE_VECTOR_WIDTH_FLOAT:
            return CL_DEVICE_PREFERRED_VECTOR_WIDTH_FLOAT
        case .PARTITION_MAX_SUB_DEVICES:
            return CL_DEVICE_PARTITION_MAX_SUB_DEVICES
        case .AVAILABLE:
            return CL_DEVICE_AVAILABLE
        case .COMPILER_AVAILABLE:
            return CL_DEVICE_COMPILER_AVAILABLE
        case .ENDIAN_LITTLE:
            return CL_DEVICE_ENDIAN_LITTLE
        case .ERROR_CORRECTION_SUPPORT:
            return CL_DEVICE_ERROR_CORRECTION_SUPPORT
        case .IMAGE_SUPPORT:
            return CL_DEVICE_IMAGE_SUPPORT
        case .LINKER_AVAILABLE:
            return CL_DEVICE_LINKER_AVAILABLE
        case .BUILT_IN_KERNELS:
            return CL_DEVICE_BUILT_IN_KERNELS
        case .NAME:
            return CL_DEVICE_NAME
        case .EXTENSIONS:
            return CL_DEVICE_EXTENSIONS
        case .OPENCL_C_VERSION:
            return CL_DEVICE_OPENCL_C_VERSION
        case .DEVICE_VENDOR:
            return CL_DEVICE_VENDOR
        case .DEVICE_VERSION:
            return CL_DEVICE_VERSION
        case .DRIVER_VERSION:
            return CL_DRIVER_VERSION
        case .DEVICE_PROFILE:
            return CL_DEVICE_PROFILE
        case .IMAGE_BASE_ADDRESS_ALIGNMENT:
            return CL_DEVICE_IMAGE_BASE_ADDRESS_ALIGNMENT
        }
    }

    var value: cl_device_info {
        return cl_device_info(self.typeCode)
    }
}

private let deviceError: (cl_int) -> NSError = { errType -> NSError in
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
    return NSError(domain: "com.daubert.OpenCL.Device", code: Int(errType), userInfo: [NSLocalizedDescriptionKey: message])
}

public struct CLDeviceTypes: OptionSet {
    public let rawValue: Int32
    public static let CPU = CLDeviceTypes(rawValue: CL_DEVICE_TYPE_CPU)
    public static let GPU = CLDeviceTypes(rawValue: CL_DEVICE_TYPE_GPU)
    public static let ACCELERATOR = CLDeviceTypes(rawValue: CL_DEVICE_TYPE_ACCELERATOR)
    public static let CUSTOM = CLDeviceTypes(rawValue: CL_DEVICE_TYPE_CUSTOM)
    public static let DEFAULT = CLDeviceTypes(rawValue: CL_DEVICE_TYPE_DEFAULT)
    public static let ALL = CLDeviceTypes(rawValue: 101)

    public var value: cl_device_type {
        switch self {
        case .ALL:
            return cl_device_type(CL_DEVICE_TYPE_ALL)
        default:
            return cl_device_type(rawValue)
        }
    }

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

public final class CLDevice {
    
    /// 指定类型设备
    let devices: [cl_device_id?]

    public init(platform: cl_platform_id?,
                num_entries: cl_uint = 1,
                type: CLDeviceTypes = .ALL) throws {
        var devicesNum: cl_uint = 1
        // 获取设备数量
        let code: cl_int = clGetDeviceIDs(platform,
                                          cl_device_type(type.rawValue),
                                          num_entries,
                                          nil,
                                          &devicesNum)
        guard code == CL_SUCCESS else {
            throw deviceError(code)
        }
        // 获取设备
        var devices:[cl_device_id?] = Array(repeating: nil, count: Int(devicesNum))
        clGetDeviceIDs(platform, cl_device_type(type.rawValue), num_entries, &devices, nil)
        self.devices = devices
    }

    deinit {
        devices.forEach { clReleaseDevice($0) }
    }
}

extension cl_device_id {

    public func deviceInfo(infoType: CLDeviceInfoTypes) throws -> Any {
        var actualSize = 0
        // 获取实际大小
        clGetDeviceInfo(self,
                        infoType.value,
                        Int.max,
                        nil,
                        &actualSize)
        var retCode: cl_int = 0
        var ret: Any = NSNull()
        switch infoType {
        case .ADDRESS_BITS,
             .GLOBAL_MEM_CACHELINE_SIZE,
             .IMAGE_BASE_ADDRESS_ALIGNMENT,
             .IMAGE_PITCH_ALIGNMENT,
             .MAX_CLOCK_FREQUENCY,
             .MAX_COMPUTE_UNITS,
             .MAX_CONSTANT_ARGS,
             .MAX_READ_IMAGE_ARGS,
             .MAX_SAMPLERS,
             .MAX_WORK_ITEM_DIMENSIONS,
             .MAX_WRITE_IMAGE_ARGS,
             .MEM_BASE_ADDR_ALIGN,
             .NATIVE_VECTOR_WIDTH_CHAR,
             .NATIVE_VECTOR_WIDTH_SHORT,
             .NATIVE_VECTOR_WIDTH_INT,
             .NATIVE_VECTOR_WIDTH_LONG,
             .NATIVE_VECTOR_WIDTH_FLOAT,
             .NATIVE_VECTOR_WIDTH_DOUBLE,
             .NATIVE_VECTOR_WIDTH_HALF,
             .PARTITION_MAX_SUB_DEVICES:
            var addrDataPtr: cl_uint = 0
            retCode = clGetDeviceInfo(self, infoType.value, actualSize, &addrDataPtr, nil)
            ret = addrDataPtr
        case .AVAILABLE,
             .COMPILER_AVAILABLE,
             .ENDIAN_LITTLE,
             .ERROR_CORRECTION_SUPPORT,
             .IMAGE_SUPPORT,
             .LINKER_AVAILABLE:
            var isAvailable = false
            retCode = clGetDeviceInfo(self, infoType.value, actualSize, &isAvailable, nil)
            ret = isAvailable
        case .BUILT_IN_KERNELS:
            var kernels = UnsafeMutablePointer<cl_char>.allocate(capacity: actualSize)
            defer {
                kernels.deallocate(capacity: actualSize)
            }
            retCode = clGetDeviceInfo(self, infoType.value, actualSize, kernels, nil)
            ret =  String(cString: kernels).components(separatedBy: ";").filter { !$0.isEmpty }
        case .EXTENSIONS:
            var names = UnsafeMutablePointer<cl_char>.allocate(capacity: actualSize)
            defer {
                names.deallocate(capacity: actualSize)
            }
            retCode = clGetDeviceInfo(self, infoType.value, actualSize, names, nil)
            ret = String(cString: names).components(separatedBy: " ").filter { !$0.isEmpty }
        case .NAME,
             .OPENCL_C_VERSION,
             .DEVICE_PROFILE,
             .DEVICE_VENDOR,
             .DEVICE_VERSION,
             .DRIVER_VERSION:
            var charBuffer = UnsafeMutablePointer<cl_char>.allocate(capacity: actualSize)
            defer {
                charBuffer.deallocate(capacity: actualSize)
            }
            retCode = clGetDeviceInfo(self, infoType.value, actualSize, charBuffer, nil)
            ret = String(cString: charBuffer)
        }
        guard retCode == CL_SUCCESS else {
            throw deviceError(retCode)
        }
        return ret
    }

    public func allDeviceInfo() throws -> [String: Any] {
        var info = [String: Any]()
        for type in iterateEnum(CLDeviceInfoTypes.self) {
            info[type.rawValue] = try deviceInfo(infoType: type)
        }
        return info
    }
}
