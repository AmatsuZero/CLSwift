//
//  CLCommandQueue.swift
//  CLSwift
//
//  Created by modao on 2018/3/2.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

let commandQueueError: (cl_int) -> NSError = { type in
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
    case CL_INVALID_MEM_OBJECT:
        message = "src_buffer and dst_buffer are not valid buffer objects"
    case CL_INVALID_EVENT_WAIT_LIST:
        message = "event_wait_list is NULL and num_events_in_wait_list is > 0, or event_wait_list is not NULL and num_events_in_wait_list is 0, or if event objects in event_wait_list are not valid events"
    case CL_MISALIGNED_SUB_BUFFER_OFFSET:
        message = "src_buffer is a sub-buffer object and offset specified when the sub-buffer object is created is not aligned to CL_DEVICE_MEM_BASE_ADDR_ALIGN value for device associated with queue"
    case CL_MEM_COPY_OVERLAP:
        message = "if src_buffer and dst_buffer are the same buffer or subbuffer object and the source and destination regions overlap or if src_buffer and dst_buffer are different sub-buffers of the same associated buffer object and they overlap. The regions overlap if src_offset ≤ dst_offset ≤ src_offset + size - 1, or if dst_offset ≤ src_offset ≤ dst_offset + size - 1"
    case CL_MISALIGNED_SUB_BUFFER_OFFSET:
        message = " sub-buffer object is specified as the value for an argument that is a buffer object and the offset specified when the sub-buffer object is created is not aligned to CL_DEVICE_MEM_BASE_ADDR_ALIGN value for device associated with queue"
    case CL_INVALID_IMAGE_SIZE:
        message = "if an image object is specified as an argument value and the image dimensions (image width, height, specified or compute row and/or slice pitch) are not supported by device associated with queue"
    case CL_IMAGE_FORMAT_NOT_SUPPORTED:
        message = "an image object is specified as an argument value and the image format (image channel order and data type) is not supported by device associated with queue"
    case CL_MEM_OBJECT_ALLOCATION_FAILURE:
        message = "there is a failure to allocate memory for data store associated with image or buffer objects specified as arguments to kernel"
    case CL_INVALID_WORK_GROUP_SIZE:
        message = " local_work_size is NULL and the __attribute__ ((reqd_work_group_size(X, Y, Z))) qualifier is used to declare the work-group size for kernel in the program source"
    case CL_INVALID_WORK_DIMENSION:
        message = "work_dim is not a valid value"
    case CL_INVALID_GLOBAL_WORK_SIZE:
        message = "global_work_size is NULL, or if any of the values specified in global_work_size[0], ...global_work_size [work_dim - 1] are 0 or exceed the range given by the sizeof(size_t) for the device on which the kernel execution will be enqueued"
    case CL_INVALID_GLOBAL_OFFSET:
        message = "the value specified in global_work_size + the corresponding values in global_work_offset for any dimensions is greater than the sizeof(size_t) for the device on which the kernel execution will be enqueued"
    case CL_INVALID_EVENT:
        message = "event is not a valid user event."
    case CL_INVALID_OPERATION:
        message = "the operation is not defined"
    case CL_PROFILING_INFO_NOT_AVAILABLE:
        message = "the CL_QUEUE_PROFILING_ENABLE flag is not set for the command-queue, if the execution status of the command identified by event is not CL_COMPLETE or if event refers to the clEnqueueSVMFree command or is a user event object"
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
        var value: cl_command_queue_properties {
            switch self {
            case .ProfileEnable: return cl_command_queue_properties(CL_QUEUE_PROFILING_ENABLE)
            case .OutOfOrder: return cl_command_queue_properties(CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE)
            }
        }
    }

    public enum CLCommandBufferOperation {
        case ReadBuffer(Int, Int?)
        case WriteBuffer(Int, Int)
        case CopyBuffer(CLKernelBuffer, Int, Int)
        case ReadImage(CLKernelData.CLBufferOrigin, CLKernelData.CLBufferRegion, Int, Int)
        case WriteImage(CLKernelData.CLBufferOrigin, CLKernelData.CLBufferRegion, Int, Int)
        case CopyImage(CLKernelImageBuffer, CLKernelData.CLBufferOrigin, CLKernelData.CLBufferOrigin, CLKernelData.CLBufferRegion)
        case ReadBufferRect(CLKernelData.CLBufferOrigin, CLKernelData.CLBufferOrigin, CLKernelData.CLBufferRegion, (rowPitch: Int, slicePitch: Int), (rowPitch: Int, slicePitch: Int))
        case WriteBufferRect(CLKernelData.CLBufferOrigin, CLKernelData.CLBufferOrigin, CLKernelData.CLBufferRegion, (rowPitch: Int, slicePitch: Int), (rowPitch: Int, slicePitch: Int))
        case CopyBufferRect(CLKernelBuffer, CLKernelData.CLBufferOrigin, CLKernelData.CLBufferOrigin, CLKernelData.CLBufferRegion, (rowPitch: Int, slicePitch: Int), (rowPitch: Int, slicePitch: Int))
        case MapBuffer(Int, CLKernelData.CLMapFlags)
        case MapImage(CLKernelData.CLMapFlags, CLKernelData.CLBufferOrigin, CLKernelData.CLBufferRegion, UnsafeMutablePointer<Int>,  UnsafeMutablePointer<Int>?)
        case UnmapBuffer(UnsafeMutableRawPointer)
    }

    let properties: CLCommandProperties?

    init(context: CLContext, device: CLDevice, properties: CLCommandProperties? = nil) throws {
        self.context = context
        self.device = device
        self.properties = properties
        var errorCode: cl_int = 0
        queue = clCreateCommandQueue(context.context,
                                     device.deviceId,
                                     properties?.value ?? 0,
                                     &errorCode)
        guard errorCode == CL_SUCCESS else {
            throw commandQueueError(errorCode)
        }
    }

    @discardableResult
    func enqueueNDRangeKernel(kernel: CLKernel, workDim: UInt32,
                              globalWorkOffset: [size_t]?, globalWorkSize: [size_t]?, localWorkSize: [size_t]?,
                              awaitEvents: [CLEvent?]? = nil) throws -> CLEvent? {
        var event: cl_event?
        let code = clEnqueueNDRangeKernel(queue, kernel.kernel, workDim, globalWorkOffset, globalWorkSize, localWorkSize,
                                          cl_uint(awaitEvents?.count ?? 0), awaitEvents?.map { $0?.event }, &event)
        guard code == CL_SUCCESS else {
            throw commandQueueError(code)
        }
        return event != nil ? CLEvent(event!) : nil
    }

    @discardableResult
    func enqueueTask(kernel: CLKernel, eventsAwait: [CLEvent?]? = nil) throws -> CLEvent? {
        var event: cl_event?
        let code = clEnqueueTask(queue,
                                 kernel.kernel,
                                 cl_uint(eventsAwait?.count ?? 0),
                                 eventsAwait?.map { $0?.event },
                                 &event)
        guard code == CL_SUCCESS else {
            throw commandQueueError(code)
        }
        return event != nil ? CLEvent(event!) : nil
    }

    @discardableResult
    func mapBuffer(buffer: CLKernelData,
                   operation: CLCommandBufferOperation,
                   eventsAwait: [CLEvent?]? = nil,
                   callBack: ((Bool, Error?, CLEvent?, UnsafeMutableRawPointer?) -> Void)? = nil) throws -> UnsafeMutableRawPointer? {
        var event: cl_event?
        var code: cl_int?
        var result: UnsafeMutableRawPointer?
        switch operation {
        case .MapBuffer(let offset, let flags):
            var errCode: cl_int = 0
            if let cb = callBack {
                DispatchQueue.global().async { [weak self] in
                    guard let strongSelf = self else { cb(false, nil , nil, nil); return }
                    result = clEnqueueMapBuffer(strongSelf.queue, buffer.mem, cl_bool(CL_FALSE), flags.value,
                                                    offset, buffer.size ?? 0, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event, &errCode)
                    let clEvent = event != nil ? CLEvent(event!, context: strongSelf.context, queue: self) : nil
                    while clEvent != nil, clEvent?.status == .running {}
                    cb(code == CL_SUCCESS, code == CL_SUCCESS ? nil : commandQueueError(code!), clEvent, result)
                }
            } else {
                result = clEnqueueMapBuffer(queue, buffer.mem, cl_bool(CL_TRUE), flags.value, offset, buffer.size ?? 0,
                                            cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event, &errCode)
                code = errCode
            }
        case .MapImage(let flags, let origin, let region, let rowPitch, let slicePitch):
            var errCode: cl_int = 0
            if let cb = callBack {
                DispatchQueue.global().async { [weak self] in
                    guard let strongSelf = self else { cb(false, nil , nil, nil); return }
                    result = clEnqueueMapImage(strongSelf.queue, buffer.mem, cl_bool(CL_FALSE), flags.value, origin.originArray,
                                                   region.regionArray, rowPitch, slicePitch, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event, &errCode)
                    let clEvent = event != nil ? CLEvent(event!, context: strongSelf.context, queue: self)  : nil
                    while clEvent != nil, clEvent?.status == .running {}
                    cb(code == CL_SUCCESS, code == CL_SUCCESS ? nil : commandQueueError(code!), clEvent, result)
                }
            } else {
                result = clEnqueueMapImage(queue, buffer.mem, cl_bool(CL_TRUE), flags.value, origin.originArray,
                                               region.regionArray, rowPitch, slicePitch, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event, &errCode)
                code = errCode
            }
        default:
            result = nil
        }
        if let c = code, c != CL_SUCCESS {
            throw commandQueueError(c)
        }
        return result
    }

    @discardableResult
    func enqueueBuffer(buffer: CLKernelData,
                       operation: CLCommandBufferOperation,
                       host: UnsafeMutableRawPointer? = nil,
                       eventsAwait: [CLEvent?]? = nil,
                       callBack: ((Bool, Error?, CLEvent?) -> Void)? = nil) -> CLEvent.EventQuery {
        var event: cl_event?
        var code: cl_int?
        switch operation {
        case .CopyBuffer(let distMem, let srcOffset, let dstOffset):
            if let cb = callBack {
                DispatchQueue.global().async { [weak self] in
                    guard let strongSelf = self else { cb(false, nil , nil); return }
                    code = clEnqueueCopyBuffer(strongSelf.queue, buffer.mem, distMem.mem, srcOffset, dstOffset, buffer.size ?? 0,
                                               cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
                    let clEvent = event != nil ? CLEvent(event!, context: strongSelf.context, queue: self)  : nil
                    while clEvent != nil, clEvent?.status == .running {}
                    cb(code == CL_SUCCESS, code == CL_SUCCESS ? nil : commandQueueError(code!), clEvent)
                }
            } else {
                code = clEnqueueCopyBuffer(queue, buffer.mem, distMem.mem, srcOffset, dstOffset, buffer.size ?? 0,
                                           cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
            }
        case .WriteBuffer(let offset, let size):
            if let cb = callBack {
                DispatchQueue.global().async { [weak self] in
                    guard let strongSelf = self else { cb(false, nil , nil); return }
                    code = clEnqueueWriteBuffer(strongSelf.queue, buffer.mem, cl_bool(CL_FALSE), offset, size,
                                                host, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
                    let clEvent = event != nil ? CLEvent(event!, context: strongSelf.context, queue: self)  : nil
                    while clEvent != nil, clEvent?.status == .running {}
                    cb(code == CL_SUCCESS, code == CL_SUCCESS ? nil : commandQueueError(code!), clEvent)
                }
            } else {
                code = clEnqueueWriteBuffer(queue, buffer.mem, cl_bool(CL_TRUE), offset, size,
                                            host, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
            }
        case .ReadBuffer(let offset, let readingSize):
            if let cb = callBack {
                DispatchQueue.global().async { [weak self] in
                    guard let strongSelf = self else { cb(false, nil , nil); return }
                    code = clEnqueueReadBuffer(strongSelf.queue, buffer.mem, cl_bool(CL_FALSE), offset, readingSize ?? MemoryLayout.size(ofValue: host),
                                               host, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
                    let clEvent = event != nil ? CLEvent(event!, context: strongSelf.context, queue: self)  : nil
                    while clEvent != nil, clEvent?.status == .running {}
                    cb(code == CL_SUCCESS, code == CL_SUCCESS ? nil : commandQueueError(code!), clEvent)
                }
            } else {
                code = clEnqueueReadBuffer(queue, buffer.mem, cl_bool(CL_TRUE), offset, readingSize ?? MemoryLayout.size(ofValue: host),
                                           host, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
            }
        case .ReadImage(let origin, let region, let rowPitch, let slicePitch):
            guard let data = buffer as? CLKernelImageBuffer else { return (false, nil) }
            let originArray = [origin.x, origin.y, origin.z]
            let regionArray = [region.width, region.height, region.depth]
            if let cb = callBack {
                DispatchQueue.global().async { [weak self] in
                    guard let strongSelf = self else { cb(false, nil , nil); return }
                    code = clEnqueueReadImage(strongSelf.queue, data.mem, cl_bool(CL_FALSE), originArray, regionArray,
                                              slicePitch, rowPitch, host, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
                    let clEvent = event != nil ? CLEvent(event!, context: strongSelf.context, queue: self)  : nil
                    while clEvent != nil, clEvent?.status == .running {}
                    cb(code == CL_SUCCESS, code == CL_SUCCESS ? nil : commandQueueError(code!), clEvent)
                }
            } else {
                code = clEnqueueReadImage(queue, data.mem, cl_bool(CL_TRUE), originArray, regionArray,
                                          slicePitch, rowPitch, host, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
            }
        case .WriteImage(let origin, let region, let rowPitch, let slicePitch):
            guard let data = buffer as? CLKernelImageBuffer else { return (false, nil) }
            if let cb = callBack {
                DispatchQueue.global().async { [weak self] in
                    guard let strongSelf = self else { cb(false, nil , nil); return }
                    code = clEnqueueWriteImage(strongSelf.queue, data.mem, cl_bool(CL_FALSE), origin.originArray, region.regionArray,
                                               rowPitch, slicePitch, host, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
                    let clEvent = event != nil ? CLEvent(event!, context: strongSelf.context, queue: self) : nil
                    while clEvent != nil, clEvent?.status == .running {}
                    cb(code == CL_SUCCESS, code == CL_SUCCESS ? nil : commandQueueError(code!), clEvent)
                }
            } else {
                code = clEnqueueWriteImage(queue, data.mem, cl_bool(CL_TRUE), origin.originArray, region.regionArray,
                                           rowPitch, slicePitch, host, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
            }
        case .CopyImage(let distImage,let srcOrigin, let distOrigin, let region):
            guard let data = buffer as? CLKernelImageBuffer else { return (false, nil) }
            if let cb = callBack {
                DispatchQueue.global().async { [weak self] in
                    guard let strongSelf = self else { cb(false, nil , nil); return }
                    code = clEnqueueCopyImage(strongSelf.queue, data.mem, distImage.mem, srcOrigin.originArray, distOrigin.originArray,
                                              region.regionArray, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
                    cb(code == CL_SUCCESS, code == CL_SUCCESS ? nil : commandQueueError(code!), event != nil ? CLEvent(event!) : nil)
                }
            } else {
                code = clEnqueueCopyImage(queue, data.mem, distImage.mem, srcOrigin.originArray, distOrigin.originArray,
                                          region.regionArray, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
            }
        case .ReadBufferRect(let bufferOrigin, let hostOrigin, let region, let bufferSize, let hostSize):
            if let cb = callBack {
                DispatchQueue.global().async { [weak self] in
                    guard let strongSelf = self else { cb(false, nil , nil); return }
                    code = clEnqueueReadBufferRect(strongSelf.queue, buffer.mem, cl_bool(CL_FALSE), bufferOrigin.originArray, hostOrigin.originArray, region.regionArray,
                                                   bufferSize.rowPitch, bufferSize.slicePitch, hostSize.rowPitch, hostSize.slicePitch, host, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
                    let clEvent = event != nil ? CLEvent(event!, context: strongSelf.context, queue: self)  : nil
                    while clEvent != nil, clEvent?.status == .running {}
                    cb(code == CL_SUCCESS, code == CL_SUCCESS ? nil : commandQueueError(code!), clEvent)
                }
            } else {
                code = clEnqueueReadBufferRect(queue, buffer.mem, cl_bool(CL_TRUE), bufferOrigin.originArray, hostOrigin.originArray, region.regionArray,
                                               bufferSize.rowPitch, bufferSize.slicePitch, hostSize.rowPitch, hostSize.slicePitch, host, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
            }
        case .WriteBufferRect(let bufferOrigin, let hostOrigin, let region, let bufferSize, let hostSize):
            if let cb = callBack {
                DispatchQueue.global().async { [weak self] in
                    guard let strongSelf = self else { cb(false, nil , nil); return }
                    code = clEnqueueWriteBufferRect(strongSelf.queue, buffer.mem, cl_bool(CL_FALSE), bufferOrigin.originArray, hostOrigin.originArray, region.regionArray,
                                                    bufferSize.rowPitch, bufferSize.slicePitch, hostSize.rowPitch, hostSize.slicePitch, host, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
                    let clEvent = event != nil ? CLEvent(event!, context: strongSelf.context, queue: self)  : nil
                    while clEvent != nil, clEvent?.status == .running {}
                    cb(code == CL_SUCCESS, code == CL_SUCCESS ? nil : commandQueueError(code!), clEvent)
                }
            } else {
                code = clEnqueueWriteBufferRect(queue, buffer.mem, cl_bool(CL_TRUE), bufferOrigin.originArray, hostOrigin.originArray, region.regionArray,
                                                bufferSize.rowPitch, bufferSize.slicePitch, hostSize.rowPitch, hostSize.slicePitch, host, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
            }
        case .CopyBufferRect(let disBuffer, let bufferOrigin, let hostOrigin, let region, let srcSize, let distSize):
            if let cb = callBack {
                DispatchQueue.global().async { [weak self] in
                    guard let strongSelf = self else { cb(false, nil , nil); return }
                    code = clEnqueueCopyBufferRect(strongSelf.queue, buffer.mem, disBuffer.mem, bufferOrigin.originArray, hostOrigin.originArray, region.regionArray,
                                                   srcSize.rowPitch, srcSize.slicePitch, distSize.rowPitch, distSize.slicePitch, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
                    cb(code == CL_SUCCESS, code == CL_SUCCESS ? nil : commandQueueError(code!), event != nil ? CLEvent(event!) : nil)
                }
            } else {
                code = clEnqueueCopyBufferRect(queue, buffer.mem, disBuffer.mem, bufferOrigin.originArray, hostOrigin.originArray, region.regionArray,
                                               srcSize.rowPitch, srcSize.slicePitch, distSize.rowPitch, distSize.slicePitch, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
            }
        case .UnmapBuffer(let returnHost):
            if let cb = callBack {
                DispatchQueue.global().async { [weak self] in
                    guard let strongSelf = self else { cb(false, nil , nil); return }
                    code = clEnqueueUnmapMemObject(strongSelf.queue, buffer.mem, returnHost, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
                    cb(code == CL_SUCCESS, code == CL_SUCCESS ? nil : commandQueueError(code!), event != nil ? CLEvent(event!) : nil)
                }
            } else {
                code = clEnqueueUnmapMemObject(queue, buffer.mem, returnHost, cl_uint(eventsAwait?.count ?? 0), eventsAwait?.map { $0?.event }, &event)
            }
        default:
            return (false, nil)
        }
        return (code == CL_SUCCESS, CLEvent(event, context: context, queue: self))
    }

    deinit {
        clReleaseCommandQueue(queue)
    }
}
