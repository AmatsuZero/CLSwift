//
//  CLCommandQueue.swift
//  CLSwift
//
//  Created by modao on 2018/3/2.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

private let commandQueueError: (cl_int) -> NSError = { type in
    var message = ""
    switch type {
    case CL_INVALID_PROGRAM_EXECUTABLE:
        message = "there is no successfully built program executable available for device associated with command_queue"
    case CL_INVALID_COMMAND_QUEUE:
        message = "ommand_queue is not a valid command-queue"
    case CL_INVALID_KERNEL:
        message = "kernel is not a valid kernel object."
    case CL_INVALID_KERNEL_ARGS:
        message = "kernel argument values have not been specified."
    case CL_INVALID_WORK_GROUP_SIZE:
        message = "if a work-group size is specified for kernel using the __attribute__((reqd_work_group_size(X, Y, Z))) qualifier in program source and is not (1, 1, 1)"
    case CL_MEM_OBJECT_ALLOCATION_FAILURE:
        message = "if there is a failure to allocate memory for data store associated with image or buffer objects specified as arguments to kernel"
    case CL_INVALID_CONTEXT:
        message = "context is not a valid context"
    case CL_INVALID_DEVICE:
        message = "device is not a valid device or is not associated with context"
    case CL_INVALID_VALUE:
        message = "values specified in properties are not valid"
    case CL_INVALID_QUEUE_PROPERTIES:
        message = "values specified in properties are valid but are not supported by the device"
    case CL_OUT_OF_RESOURCES:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the device"
    case CL_OUT_OF_HOST_MEMORY:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the host"
    default:
        message = "Unknown Error"
    }
    return NSError(domain: "com.daubert.OpenCL.CommandQueue",
                   code: Int(type),
                   userInfo: [NSLocalizedFailureReasonErrorKey: message])
}

public final class CLCommandQueue {

    internal let context: CLContext
    internal let device: CLDevice
    internal let queue: cl_command_queue

    public enum CLCommandProperties {
        case ProfileEnable, OutOfOrder
        var value: Int32 {
            switch self {
            case .ProfileEnable: return CL_QUEUE_PROFILING_ENABLE
            case .OutOfOrder: return CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE
            }
        }
    }

    init(context: CLContext, device: CLDevice, properties: CLCommandProperties) throws {
        self.context = context
        self.device = device
        var errorCode: cl_int = 0
        queue = clCreateCommandQueue(context.context,
                                     device.deviceId,
                                     cl_command_queue_properties(properties.value),
                                     &errorCode)
        guard errorCode == CL_SUCCESS else {
            throw commandQueueError(errorCode)
        }
    }

    @discardableResult
    func enqueue(kernel: CLKernel, eventsAwait: [cl_event?] = []) throws -> cl_event? {
        var event: cl_event?
        let code = clEnqueueTask(queue,
                                 kernel.kernel,
                                 cl_uint(eventsAwait.count),
                                 eventsAwait,
                                 &event)
        guard code == CL_SUCCESS else {
            throw commandQueueError(code)
        }
        return event
    }

    deinit {
        clReleaseCommandQueue(queue)
    }
}
