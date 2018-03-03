//
//  CLKernelData.swift
//  CLSwift
//
//  Created by modao on 2018/3/3.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

private let bufferError: (cl_int) -> NSError = { type in
    var message = ""
    switch type {
    case CL_INVALID_CONTEXT:
        message = "context is not a valid context."
    case CL_INVALID_VALUE:
        message = "values specified in flags are not valid as defined in the table above"
    case CL_INVALID_BUFFER_SIZE:
        message = "size is 0. Implementations may return CL_INVALID_BUFFER_SIZE if size is greater than the CL_DEVICE_MAX_MEM_ALLOC_SIZE value specified in the table of allowed values for param_name for clGetDeviceInfo for all devices in context"
    case CL_INVALID_HOST_PTR:
        message = "host_ptr is NULL and CL_MEM_USE_HOST_PTR or CL_MEM_COPY_HOST_PTR are set in flags or if host_ptr is not NULL but CL_MEM_COPY_HOST_PTR or CL_MEM_USE_HOST_PTR are not set in flags."
    case CL_MEM_OBJECT_ALLOCATION_FAILURE:
        message = "there is a failure to allocate memory for buffer object"
    case CL_OUT_OF_RESOURCES:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the device"
    case CL_OUT_OF_HOST_MEMORY:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the host"
    default:
        message = "Unknown Error"
    }
    return NSError(domain: "com.daubert.OpenCL.Buffer",
                   code: Int(type),
                   userInfo: [NSLocalizedFailureReasonErrorKey: message])
}

public class CLKernelBuffer {

    let context: CLContext
    internal let mem: cl_mem

    public struct CLMemFlags: OptionSet {
        public var rawValue: Int32
        public static let WRITE = CLMemFlags(rawValue: CL_MEM_WRITE_ONLY)
        public static let READ = CLMemFlags(rawValue: CL_MEM_READ_ONLY)
        public static let READWRITE = CLMemFlags(rawValue: CL_MEM_READ_WRITE)
        public static let USEHOSTPTR = CLMemFlags(rawValue: CL_MEM_USE_HOST_PTR)
        public static let COPYHOSTPR = CLMemFlags(rawValue: CL_MEM_COPY_HOST_PTR)
        public static let ALLOCHOSTPTR = CLMemFlags(rawValue: CL_MEM_ALLOC_HOST_PTR)
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
        var value: cl_mem_flags {
            return cl_mem_flags(rawValue)
        }
    }

    init(context: CLContext, flags: CLMemFlags, data: [Any]) throws {
        self.context = context
        var err: cl_int = 0
        var buffer = data
        mem = clCreateBuffer(context.context,
                             flags.value,
                             MemoryLayout.size(ofValue: data),
                             &buffer,
                             &err)
        guard err == CL_SUCCESS else {
            throw bufferError(err)
        }
    }
}
