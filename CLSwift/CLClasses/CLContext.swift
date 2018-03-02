//
//  CLContext.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/27.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

internal let contextError: (cl_int) -> NSError = { errType -> NSError in
    var message = ""
    switch errType {
    case CL_INVALID_PLATFORM:
        message = "platform is not a valid platform"
    case CL_INVALID_PROPERTY:
        message = """
        context property name in properties is not a supported property name,
        or if the value specified for a supported property name is not valid,
        or if the same property name is specified more than once
        """
    case CL_INVALID_DEVICE_TYPE:
        message = "device_type is not a valid value"
    case CL_INVALID_VALUE:
        message = "pfn_notify is NULL but user_data is not NULL"
    case CL_DEVICE_NOT_AVAILABLE:
        message = "no devices that match device_type and property values specified in properties are currently available"
    case CL_DEVICE_NOT_FOUND:
        message = "no OpenCL devices that matched device_type were found"
    case CL_OUT_OF_RESOURCES:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the device"
    case CL_OUT_OF_HOST_MEMORY:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the host"
    case CL_INVALID_OPERATION:
        message = """
        if interoperability is specified by setting CL_CONTEXT_ADAPTER_D3D9_KHR, CL_CONTEXT_ADAPTER_D3D9EX_KHR
        or CL_CONTEXT_ADAPTER_DXVA_KHR to a non-NULL value,
        and interoperability with another graphics API is also specified.
        (only if the cl_khr_dx9_media_sharing extension is supported)
        """
    case CL_INVALID_CONTEXT:
        message = "context is not a valid context"
    default:
        message = "Unknown error"
    }
    return NSError(domain: "com.daubert.OpenCL.Context", code: Int(errType), userInfo: [NSLocalizedDescriptionKey: message])
}

internal func createContextCallBack(errorInfo: UnsafePointer<Int8>?,
                                    privateInfo: UnsafeRawPointer?,
                                    cb: Int,
                                    userData: UnsafeMutableRawPointer?) {
    NotificationCenter.default.post(name: String.CreateContextCallback,
                                    object: nil,
                                    userInfo: nil)
}

public final class CLContext {

    internal let context: cl_context!
    private var _devices: [CLDevice]?
    private var properties: [cl_context_properties]?
    public private(set) var devices: [CLDevice]? {
        set(newDevices) {
            _devices = newDevices
        }
        get {
            if _devices?.isEmpty == false {
                return _devices!
            }
            var actualSize = 0
            let code = clGetContextInfo(context, cl_context_info(CL_CONTEXT_DEVICES), Int.max, nil, &actualSize)
            guard code == CL_SUCCESS, actualSize > 0 else {
                return nil
            }
            let count = actualSize / MemoryLayout<cl_device_id>.stride
            var deviceIds: [cl_device_id?] = Array(repeating: nil, count: count)
            clGetContextInfo(context, cl_context_info(CL_CONTEXT_DEVICES), actualSize, &deviceIds, nil)
            _devices = deviceIds.map {
                CLDevice(deviceId: $0)
            }
            return _devices
        }
    }

    public init(contextProperties props: [cl_context_properties]? = nil,
                devices: [CLDevice]) throws {
        var errCode: cl_int = 0
        context = clCreateContext(props,
                                  cl_uint(devices.count),
                                  devices.map { $0.deviceId },
                                  createContextCallBack,
                                  nil,
                                  &errCode)
        guard errCode == CL_SUCCESS else {
            throw contextError(errCode)
        }
        properties = props
        _devices = devices
    }

    public init(contextProperties props: [cl_context_properties]? = nil,
                deviceType: CLDevice.CLDeviceType) throws {
        var errCode: cl_int = 0
        context = clCreateContextFromType(props,
                                          deviceType.value,
                                          createContextCallBack,
                                          nil,
                                          &errCode)
        guard errCode == CL_SUCCESS else {
            throw contextError(errCode)
        }
        properties = props
    }

    deinit {
        clReleaseContext(context)
    }
}
