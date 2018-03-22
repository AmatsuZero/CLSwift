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
public class CLEvent {
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
    let event: cl_event?
    var id: Int = 0

    //事件回调
    var runningBlock: eventCallback?
    var completeBlock: eventCallback?
    var queuedBlock: eventCallback?
    var submittedBlock: eventCallback?

    internal static let eventPool = CLEventPool<CLEvent>(lable: "com.daubert.CLSwift.CLEvent")

    init(_ event: cl_event?, context: CLContext? = nil, queue: CLCommandQueue? = nil) {
        self.event = event
        self.context = context
        self.queue = queue
        id = CLEvent.eventPool.append(event: self)
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

    deinit {
        CLEvent.eventPool.remove(id: id)
    }
}
