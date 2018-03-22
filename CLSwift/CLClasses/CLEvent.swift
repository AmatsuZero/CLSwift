//
//  CLEvent.swift
//  CLSwift
//
//  Created by modao on 2018/3/21.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

func clEventCallback(event: cl_event?, status: cl_int, userData: UnsafeMutableRawPointer?) {
    let target = CLEvent.eventPool.pool.first { (_, ev) -> Bool in
        return ev.event == event
    }?.value
    let data = userData?.assumingMemoryBound(to: [String: Any].self).pointee
    if let executionStatus = CLEvent.CLCommandExecutionStatus(rawValue: status) {
        switch executionStatus {
        case .running: target?.runningBlock?(target, executionStatus, data)
        case .queued: target?.queuedBlock?(target, executionStatus, data)
        case .complete: target?.completeBlock?(target, executionStatus, data)
        case .submitted: target?.submittedBlock?(target, executionStatus, data)
        }
    }
}

final class CLEventPool<T> {
    private(set) var pool = [Int: T]()
    private(set) var idGenerator = Atomic<Int>(value: 0)
    private let queue: DispatchQueue

    init(lable: String) {
        queue = DispatchQueue(label: lable)
    }

    @discardableResult
    func append(event: T) -> Int {
        var id = 0
        queue.sync {
            idGenerator.value += 1
            id = idGenerator.value
            pool[id] = event
        }
        return id
    }

    subscript(id: Int) -> T? {
        var value: T?
        queue.sync {
            value = pool[id]
        }
        return value
    }

    func remove(id: Int) {
        _ = queue.sync {
            pool.removeValue(forKey: id)
        }
    }
}

//MARK: - 事件
public final class CLEvent {
    public enum CLCommandExecutionStatus: Int32, CLInfoProtocol {
        typealias valueType = cl_int
        case queued, submitted, running, complete
        public init?(rawValue: Int32) {
            switch rawValue {
            case CL_QUEUED: self = .queued
            case CL_SUBMITTED: self = .submitted
            case CL_RUNNING: self = .running
            case CL_COMPLETE: self = .complete
            default: return nil
            }
        }
        var value: cl_int {
            switch self {
            case .queued: return CL_QUEUED
            case .submitted: return CL_SUBMITTED
            case .running: return CL_RUNNING
            case .complete: return CL_COMPLETE
            }
        }
    }
    public enum CLCommandType: Int32, CLInfoProtocol {
        typealias valueType = cl_command_type
        case ndrangeKernel, nativeKernel
        case readBuffer, writeBuffer, copyBuffer
        case readImage, writeImage, copyImage
        case copyBufferToImage, copyImageToBuffer
        case mapBuffer, unmapMemObject
        case marker, acquireGLObjects, releaseCLObjects
        case readBufferRect, writeBufferRect, copyBufferRect
        case user, barrier, migrateMemObjects, fillBuffer, fillImage
        // case svmFree, svmMemCopy, svmMemFill, smvmMap, svmUnMap
        public init?(rawValue: Int32) {
            switch rawValue {
            case CL_COMMAND_NDRANGE_KERNEL: self = .ndrangeKernel
            case CL_COMMAND_NATIVE_KERNEL: self = .nativeKernel
            case CL_COMMAND_READ_BUFFER: self = .readBuffer
            case CL_COMMAND_WRITE_BUFFER: self = .writeBuffer
            case CL_COMMAND_COPY_BUFFER: self = .copyBuffer
            case CL_COMMAND_READ_IMAGE: self = .readImage
            case CL_COMMAND_WRITE_IMAGE: self = .writeImage
            case CL_COMMAND_COPY_IMAGE: self = .copyImage
            case CL_COMMAND_COPY_BUFFER_TO_IMAGE: self = .copyBufferToImage
            case CL_COMMAND_COPY_IMAGE_TO_BUFFER: self = .copyImageToBuffer
            case CL_COMMAND_MAP_BUFFER: self = .mapBuffer
            case CL_COMMAND_UNMAP_MEM_OBJECT: self = .unmapMemObject
            case CL_COMMAND_MARKER: self = .marker
            case CL_COMMAND_ACQUIRE_GL_OBJECTS: self = .acquireGLObjects
            case CL_COMMAND_RELEASE_GL_OBJECTS: self = .releaseCLObjects
            case CL_COMMAND_READ_BUFFER_RECT: self = .readBufferRect
            case CL_COMMAND_WRITE_BUFFER_RECT: self = .writeBufferRect
            case CL_COMMAND_COPY_BUFFER_RECT: self = .copyBufferRect
            case CL_COMMAND_USER: self = .user
            case CL_COMMAND_BARRIER: self = .barrier
            case CL_COMMAND_MIGRATE_MEM_OBJECTS: self = .migrateMemObjects
            case CL_COMMAND_FILL_IMAGE: self = .fillImage
            case CL_COMMAND_FILL_BUFFER: self = .fillBuffer
            default: return nil
            }
        }
        var value: cl_command_type {
            var raw: Int32 = 0
            switch self {
            case .ndrangeKernel: raw = CL_COMMAND_NDRANGE_KERNEL
            case .nativeKernel: raw = CL_COMMAND_NATIVE_KERNEL
            case .readBuffer: raw = CL_COMMAND_READ_BUFFER
            case .writeBuffer: raw = CL_COMMAND_WRITE_BUFFER
            case .copyBuffer: raw = CL_COMMAND_COPY_BUFFER
            case .readImage: raw = CL_COMMAND_READ_IMAGE
            case .writeImage: raw = CL_COMMAND_WRITE_IMAGE
            case .copyImage: raw =  CL_COMMAND_COPY_IMAGE
            case .copyBufferToImage: raw = CL_COMMAND_COPY_BUFFER_TO_IMAGE
            case .copyImageToBuffer: raw = CL_COMMAND_COPY_IMAGE_TO_BUFFER
            case .mapBuffer: raw = CL_COMMAND_MAP_BUFFER
            case .unmapMemObject: raw = CL_COMMAND_UNMAP_MEM_OBJECT
            case .marker: raw = CL_COMMAND_MARKER
            case .acquireGLObjects: raw = CL_COMMAND_ACQUIRE_GL_OBJECTS
            case .releaseCLObjects: raw = CL_COMMAND_RELEASE_GL_OBJECTS
            case .readBufferRect: raw = CL_COMMAND_READ_BUFFER_RECT
            case .writeBufferRect: raw = CL_COMMAND_WRITE_BUFFER_RECT
            case .copyBufferRect: raw = CL_COMMAND_COPY_BUFFER_RECT
            case .user: raw = CL_COMMAND_USER
            case .barrier: raw = CL_COMMAND_BARRIER
            case .migrateMemObjects: raw = CL_COMMAND_MIGRATE_MEM_OBJECTS
            case .fillImage: raw = CL_COMMAND_FILL_IMAGE
            case .fillBuffer: raw = CL_COMMAND_FILL_BUFFER
            }
            return cl_command_type(raw)
        }
    }
    typealias eventCallback = (CLEvent?, CLCommandExecutionStatus, [String: Any]?) -> Void
    var status: CLCommandExecutionStatus? {
        let type = cl_event_info(CL_EVENT_COMMAND_EXECUTION_STATUS)
        var value: cl_int = 0
        guard clGetEventInfo(event, type, MemoryLayout<cl_int>.size, &value, nil) == CL_SUCCESS else {
            return nil
        }
        return CLCommandExecutionStatus(rawValue: value)
    }
    var type: CLCommandType? {
        let type = cl_event_info(CL_EVENT_COMMAND_TYPE)
        var value: cl_int = 0
        guard clGetEventInfo(event, type, MemoryLayout<cl_int>.size, &value, nil) == CL_SUCCESS else {
            return nil
        }
        return CLCommandType(rawValue: value)
    }
    var referenceCount: UInt32? {
        let type = cl_event_info(CL_EVENT_REFERENCE_COUNT)
        var value: cl_uint = 0
        guard clGetEventInfo(event, type, MemoryLayout<cl_uint>.size, &value, nil) == CL_SUCCESS else {
            return nil
        }
        return value
    }
    private(set) var context: CLContext?
    private(set) var queue: CLCommandQueue?
    internal private(set) var event: cl_event?
    var id: Int = 0

    //MARK: - 事件回调
    internal var runningBlock: eventCallback?
    internal var completeBlock: eventCallback?
    internal var queuedBlock: eventCallback?
    internal var submittedBlock: eventCallback?
    internal static let eventPool = CLEventPool<CLEvent>(lable: "com.daubert.CLSwift.CLEvent")
    typealias EventQuery = (isSuccess: Bool, event: CLEvent?)
    //是否是用户创建的事件
    let isUserEvent: Bool
    //MARK: - Profiling Info（单位纳秒）
    var queuedProfiling: UInt64? {
        return try? longValue(type: CL_PROFILING_COMMAND_QUEUED)
    }
    var submitProfiling: UInt64? {
        return try? longValue(type: CL_PROFILING_COMMAND_SUBMIT)
    }
    var startProfiling: UInt64? {
        return try? longValue(type: CL_PROFILING_COMMAND_START)
    }
    var endProfiling: UInt64? {
        return try? longValue(type: CL_PROFILING_COMMAND_END)
    }

    init(_ event: cl_event?, context: CLContext? = nil, queue: CLCommandQueue? = nil) {
        self.event = event
        self.context = context
        self.queue = queue
        isUserEvent = false
        id = CLEvent.eventPool.append(event: self)
    }

    init(context: CLContext) throws {
        self.context = context
        queue = nil
        var err: cl_int = 0
        event = clCreateUserEvent(context.context, &err)
        isUserEvent = true
        guard err == CL_SUCCESS else {
            throw commandQueueError(err)
        }
        id = CLEvent.eventPool.append(event: self)
    }

    func setStatus(isOnComplete: Bool) throws {
        guard isUserEvent else {
            return
        }
        let code = clSetUserEventStatus(event, isOnComplete ? CL_COMPLETE : -1)
        guard code == CL_SUCCESS else {
            throw commandQueueError(code)
        }
    }

    func setCallback(type: CLCommandExecutionStatus, userData: inout [String:Any]?, callback: @escaping eventCallback) throws {
        switch type {
        case .running: runningBlock = callback
        case .complete: completeBlock = callback
        case .queued: queuedBlock = callback
        case .submitted: submittedBlock = callback
        }
        let code = clSetEventCallback(event, type.value, clEventCallback, &userData)
        guard code == CL_SUCCESS else {
            throw commandQueueError(code)
        }
    }

    @discardableResult
    func setMarker(on queue: CLCommandQueue) throws -> EventQuery {
        var ref: cl_event?
        let code = clEnqueueMarkerWithWaitList(queue.queue, 1, [event], &ref)
        guard code == CL_SUCCESS else {
            throw commandQueueError(code)
        }
        self.queue = queue
        return (true, CLEvent(ref, context: context, queue: queue))
    }

    @discardableResult
    func setBarrier(on queue: CLCommandQueue) throws -> EventQuery {
        var ref: cl_event?
        let code = clEnqueueBarrierWithWaitList(queue.queue, 1, [event], &ref)
        guard code == CL_SUCCESS else {
            throw commandQueueError(code)
        }
        self.queue = queue
        return (true, CLEvent(ref, context: context, queue: queue))
    }

    @discardableResult
    class func enqueue<C: Collection>(events: C, on queue: CLCommandQueue) throws -> EventQuery where C.Iterator.Element == CLEvent {
        var ref: cl_event?
        let evts = events.map { $0.event }
        let code = clEnqueueMarkerWithWaitList(queue.queue, cl_uint(evts.count), evts, &ref)
        guard code == CL_SUCCESS else {
            throw commandQueueError(code)
        }
        events.forEach { ev in
            ev.queue = queue
        }
        return (true, CLEvent(ref, context: queue.context, queue: queue))
    }

    @discardableResult
    class func enqueue<C: Collection>(barriers: C, on queue: CLCommandQueue) throws -> EventQuery where C.Iterator.Element == CLEvent {
        var ref: cl_event?
        let evts = barriers.map { $0.event }
        let code = clEnqueueBarrierWithWaitList(queue.queue, cl_uint(evts.count), evts, &ref)
        guard code == CL_SUCCESS else {
            throw commandQueueError(code)
        }
        barriers.forEach { ev in
            ev.queue = queue
        }
        return (true, CLEvent(ref, context: queue.context, queue: queue))
    }

    private func longValue(type: Int32) throws -> cl_ulong {
        var value: cl_ulong = 0
        let code = clGetEventProfilingInfo(event, cl_profiling_info(type), MemoryLayout<cl_ulong>.size, &value, nil)
        guard code == CL_SUCCESS else {
            throw commandQueueError(code)
        }
        return value
    }

    deinit {
        CLEvent.eventPool.remove(id: id)
        clReleaseEvent(event)
    }
}

extension Collection where Element == CLEvent {

    @discardableResult
    func enqueue(on queue: CLCommandQueue) throws -> CLEvent.EventQuery {
        return try CLEvent.enqueue(events: self, on: queue)
    }

    @discardableResult
    func block(on queue: CLCommandQueue) throws -> CLEvent.EventQuery {
        return try CLEvent.enqueue(barriers: self, on: queue)
    }
}
