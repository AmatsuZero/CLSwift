//
//  CLContext.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/27.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

private let contextError: (cl_int) -> NSError = { errType -> NSError in
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
        message = "Unknow error"
    }
    return NSError(domain: "com.daubert.OpenCL.Context", code: Int(errType), userInfo: [NSLocalizedDescriptionKey: message])
}

private func createContextCallBack(erroInfo: UnsafePointer<Int8>?,
                           privateInfo: UnsafeRawPointer?,
                           cb: Int,
                           userData: UnsafeMutableRawPointer?) {
    NotificationCenter.default.post(name: String.CreateContextCallback,
                                    object: nil,
                                    userInfo: nil)
}

public final class CLContext {

    var context: cl_context!

    public init(contextProperties props: [cl_context_properties]? = nil,
                devices: [cl_device_id?]) throws {
        var errCode: cl_int = 0
        context = clCreateContext(props,
                                  cl_uint(devices.count),
                                  devices,
                                  createContextCallBack,
                                  nil,
                                  &errCode)
        guard errCode == CL_SUCCESS else {
            throw contextError(errCode)
        }
    }

    public init(contextProperties props:[cl_context_properties]? = nil,
                deviceType: CLDeviceTypes) throws {
        var errCode: cl_int = 0
        context = clCreateContextFromType(props,
                deviceType.value,
                createContextCallBack,
                nil,
                &errCode)
        guard errCode == CL_SUCCESS else {
            throw contextError(errCode)
        }
    }

    deinit {
        clReleaseContext(context)
    }
}
