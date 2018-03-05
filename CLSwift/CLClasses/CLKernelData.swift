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
    case CL_INVALID_MEM_OBJECT:
        message = "memobj is not valid"
    case CL_INVALID_MEM_OBJECT:
        message = "buffer is not a valid buffer objefct or is a sub-buffer object"
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

public class CLKernelData {

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
    public struct CLBufferOrigin {
        private(set) var originArray = [Int](repeating: 0, count: 3)
        var x: Int {
            set(newValue) { originArray[0] = newValue }
            get { return originArray[0] }
        }
        var y: Int {
            set(newValue) { originArray[1] = newValue }
            get { return originArray[1] }
        }
        var z: Int {
            set(newValue) { originArray[2] = newValue }
            get { return originArray[2] }
        }
        init(x: Int, y: Int, z: Int) {
            originArray = [x, y, z]
        }
    }
    public struct CLBufferRegion {
        private(set) var regionArray = [Int](repeating: 0, count: 3)
        var width: Int {
            set(newValue) { regionArray[0] = newValue }
            get { return regionArray[0] }
        }
        var height: Int {
            set(newValue) { regionArray[1] = newValue }
            get { return regionArray[1] }
        }
        var depth: Int {
            set(newValue) { regionArray[2] = newValue }
            get { return regionArray[2] }
        }
        init(width: Int, height: Int, depth: Int) {
            regionArray = [width, height, depth]
        }
    }
    let context: CLContext
    let memFlags: CLMemFlags
    var mem: cl_mem?
    var data: [Any]?
    var size: size_t? {
        return try? integerValue(type: CL_MEM_SIZE)
    }
    var offset: size_t? {
        return try? integerValue(type: CL_MEM_OFFSET)
    }
    required public init(_ flags:CLMemFlags, _ memObj: cl_mem?, _ context: CLContext, _ data: [Any]?) {
        mem = memObj
        memFlags = flags
        self.context = context
        self.data = data
    }
    
    fileprivate func integerValue(type: Int32) throws -> Int {
        var actualSize = 0
        let code = clGetMemObjectInfo(mem,
                                      cl_mem_info(type),
                                      Int.max,
                                      nil,
                                      &actualSize)
        guard code == CL_SUCCESS else { throw bufferError(code) }
        var value = 0
        clGetMemObjectInfo(mem, cl_mem_info(type), actualSize, &value, nil)
        return value
    }
    
    fileprivate func ptrValue(type: Int32) throws -> OpaquePointer? {
        var actualSize = 0
        let code = clGetMemObjectInfo(mem,
                                      cl_mem_info(type),
                                      Int.max,
                                      nil,
                                      &actualSize)
        guard code == CL_SUCCESS else { throw bufferError(code) }
        var value: OpaquePointer? = nil
        clGetMemObjectInfo(mem, cl_mem_info(type), actualSize, &value, nil)
        return value
    }

    deinit {
        clReleaseMemObject(mem)
    }
}

public final class CLKernelBuffer: CLKernelData {
    
    init(context: CLContext,
         flags: CLMemFlags,
         hostBuffer vec: [Any]?) throws {
        var err: cl_int = 0
        var data = vec
        let mem = clCreateBuffer(context.context,
                                 flags.value,
                                 MemoryLayout.stride(ofValue: vec),
                                 &data,
                                 &err)
        guard err == CL_SUCCESS else {
            throw bufferError(err)
        }
        super.init(flags, mem, context, vec)
    }
    
    required public init(_ flags:CLMemFlags, _ memObj: cl_mem?, _ context: CLContext, _ ptr: [Any]?) {
        super.init(flags, memObj, context, ptr)
    }
    
    func subBuffer(flags: CLMemFlags,
                   origin start: Int,
                   size end: Int) throws -> CLKernelBuffer {
        var errCode: cl_int = 0
        var region = cl_buffer_region(origin: start, size: end)
        let subMem = clCreateSubBuffer(mem,
                                       flags.value,
                                       cl_buffer_create_type(CL_BUFFER_CREATE_TYPE_REGION),
                                       &region,
                                       &errCode)
        guard errCode == CL_SUCCESS else {
            throw bufferError(errCode)
        }
        return CLKernelBuffer(flags, subMem, context, nil)
    }
}

public final class CLKernelImageBuffer: CLKernelData {
    struct CLImageFormat {
        enum CLChannelOrder {
            case RGB, RGBA, ARGB, BGRA, RG, RA, R, A, RGBx, Rx, RGx, Intensity
            var value: cl_channel_order {
                switch self {
                case .RGB: return cl_channel_order(CL_RGB)
                case .RGBA: return cl_channel_order(CL_RGBA)
                case .ARGB: return cl_channel_order(CL_ARGB)
                case .BGRA: return cl_channel_order(CL_BGRA)
                case .RG: return cl_channel_order(CL_RG)
                case .RA: return cl_channel_order(CL_RA)
                case .R: return cl_channel_order(CL_R)
                case .A: return cl_channel_order(CL_A)
                case .RGBx: return cl_channel_order(CL_RGBx)
                case .Rx: return cl_channel_order(CL_Rx)
                case .RGx: return cl_channel_order(CL_RGx)
                case .Intensity: return cl_channel_order(CL_INTENSITY)
                }
            }
            init?(_ type: cl_channel_order) {
                switch type {
                case cl_channel_order(CL_RGB): self = .RGB
                case cl_channel_order(CL_RGBA): self = .RGBA
                case cl_channel_order(CL_ARGB): self = .ARGB
                case cl_channel_order(CL_BGRA): self = .BGRA
                case cl_channel_order(CL_RG): self = .RG
                case cl_channel_order(CL_RA): self = .RA
                case cl_channel_order(CL_R): self = .R
                case cl_channel_order(CL_A): self = .A
                case cl_channel_order(CL_RGBx): self = .RGBx
                case cl_channel_order(CL_Rx): self = .Rx
                case cl_channel_order(CL_RGx): self = .RGx
                case cl_channel_order(CL_INTENSITY): self = .Intensity
                default: return nil
                }
            }
        }
        enum CLChannelType {
            case Float16, Float32, UInt8, UInt16, UInt32, Int8, Int16, Int32
            case UNInt8, UNInt16, UNInt24, NInt8, NInt16, NSInt565, NSInt555
            case NInt101010
            var value: cl_channel_type {
                switch self {
                case .Float16: return cl_channel_type(CL_HALF_FLOAT)
                case .Float32: return cl_channel_type(CL_FLOAT)
                case .UInt8: return cl_channel_type(CL_UNSIGNED_INT8)
                case .UInt16: return cl_channel_type(CL_UNSIGNED_INT16)
                case .UInt32: return cl_channel_type(CL_UNSIGNED_INT32)
                case .Int8: return cl_channel_type(CL_SIGNED_INT8)
                case .Int16: return cl_channel_type(CL_SIGNED_INT16)
                case .Int32: return cl_channel_type(CL_SIGNED_INT32)
                case .UNInt8: return cl_channel_type(CL_UNORM_INT8)
                case .UNInt16: return cl_channel_type(CL_UNORM_INT16)
                case .UNInt24: return cl_channel_type(CL_UNORM_INT24)
                case .NInt8: return cl_channel_type(CL_SNORM_INT8)
                case .NInt16: return cl_channel_type(CL_SNORM_INT16)
                case .NSInt565: return cl_channel_type(CL_UNORM_SHORT_565)
                case .NSInt555: return cl_channel_type(CL_UNORM_SHORT_555)
                case .NInt101010: return cl_channel_type(CL_UNORM_INT_101010)
                }
            }
            init?(_ type: cl_channel_type) {
                switch type {
                case cl_channel_type(CL_HALF_FLOAT): self = .Float16
                case cl_channel_type(CL_FLOAT): self = .Float32
                case cl_channel_type(CL_UNSIGNED_INT8): self = .UInt8
                case cl_channel_type(CL_UNSIGNED_INT16): self = .UInt16
                case cl_channel_type(CL_UNSIGNED_INT32): self = .UInt32
                case cl_channel_type(CL_SIGNED_INT8): self = .Int8
                case cl_channel_type(CL_SIGNED_INT16): self = .Int16
                case cl_channel_type(CL_SIGNED_INT32): self = .Int32
                case cl_channel_type(CL_UNORM_INT8): self = .UNInt8
                case cl_channel_type(CL_UNORM_INT16): self = .UNInt16
                case cl_channel_type(CL_UNORM_INT24): self = .UNInt24
                case cl_channel_type(CL_SNORM_INT8): self = .NInt8
                case cl_channel_type(CL_SNORM_INT16): self = .NInt16
                case cl_channel_type(CL_UNORM_SHORT_565): self = .NSInt565
                case cl_channel_type(CL_UNORM_SHORT_555): self = .NSInt555
                case cl_channel_type(CL_UNORM_INT_101010): self = .NInt101010
                default: return nil
                }
            }
        }
        var format: cl_image_format
        var order: CLChannelOrder {
            set(newValue) { format.image_channel_order = newValue.value }
            get { return CLChannelOrder(format.image_channel_order)! }
        }
        var type: CLChannelType {
            set(newValue) { format.image_channel_data_type = newValue.value }
            get { return CLChannelType(format.image_channel_data_type)! }
        }
        init(order: CLChannelOrder, format: CLChannelType) {
            self.format = cl_image_format(image_channel_order: order.value,
                                          image_channel_data_type: format.value)
        }
    }
    struct CLImageDesc {
        enum CLMemObjectType {
            case Image1D, Image1DBuffer, Image1DArray, Image2D, Image2DArray, Image3D
            var value: cl_mem_object_type {
                switch self {
                case .Image1D: return cl_mem_object_type(CL_MEM_OBJECT_IMAGE1D)
                case .Image1DBuffer: return cl_mem_object_type(CL_MEM_OBJECT_IMAGE1D_BUFFER)
                case .Image1DArray: return cl_mem_object_type(CL_MEM_OBJECT_IMAGE1D_ARRAY)
                case .Image2D: return cl_mem_object_type(CL_MEM_OBJECT_IMAGE2D)
                case .Image2DArray: return cl_mem_object_type(CL_MEM_OBJECT_IMAGE2D_ARRAY)
                case .Image3D: return cl_mem_object_type(CL_MEM_OBJECT_IMAGE3D)
                }
            }
            init?(type: cl_mem_object_type) {
                switch type {
                case cl_mem_object_type(CL_MEM_OBJECT_IMAGE1D): self = .Image1D
                case cl_mem_object_type(CL_MEM_OBJECT_IMAGE1D_BUFFER): self = .Image1DBuffer
                case cl_mem_object_type(CL_MEM_OBJECT_IMAGE1D_ARRAY): self = .Image1DArray
                case cl_mem_object_type(CL_MEM_OBJECT_IMAGE2D): self = .Image2D
                case cl_mem_object_type(CL_MEM_OBJECT_IMAGE2D_ARRAY): self = .Image2DArray
                case cl_mem_object_type(CL_MEM_OBJECT_IMAGE3D): self = .Image3D
                default: return nil
                }
            }
        }
        var buffer: CLKernelData? {
            didSet {
                guard type == .Image1D else { return }
                desc.buffer = buffer?.mem
            }
        }
        var imageWidth: size_t {
            set(newValue) {
                guard (type == .Image2D && newValue <= CL_DEVICE_IMAGE2D_MAX_WIDTH) ||
                    (type == .Image3D && newValue <= CL_DEVICE_IMAGE3D_MAX_WIDTH) ||
                    (type == .Image1DBuffer && newValue <= CL_DEVICE_IMAGE_MAX_BUFFER_SIZE) else { return }
                desc.image_width = newValue
            }
            get { return desc.image_width }
        }
        var imageHeight: size_t {
            set(newValue) {
                guard (type == .Image2D && newValue <= CL_DEVICE_IMAGE2D_MAX_HEIGHT) ||
                    (type == .Image3D && newValue <= CL_DEVICE_IMAGE3D_MAX_HEIGHT) ||
                    (type == .Image2DArray && newValue <= CL_DEVICE_IMAGE2D_MAX_HEIGHT) else { return }
                desc.image_height = newValue
            }
            get { return desc.image_width }
        }
        var imageDepth: size_t {
            set(newValue) {
                guard type == .Image3D, newValue >= 1,
                    newValue <= CL_DEVICE_IMAGE3D_MAX_DEPTH else { return }
                desc.image_depth = newValue
            }
            get { return desc.image_depth }
        }
        var arraySize: size_t {
            set(newValue) {
                guard (type == .Image1D || type == .Image2D),
                    newValue >= 1, 
                    newValue <= CL_DEVICE_IMAGE_MAX_ARRAY_SIZE else { return }
                desc.image_array_size = newValue
            }
            get { return desc.image_array_size }
        }
        var rowPitch: size_t {
            set(newValue) { desc.image_row_pitch = newValue }
            get { return desc.image_row_pitch }
        }
        var slicePitch: size_t {
            set(newValue) { desc.image_slice_pitch = newValue }
            get { return desc.image_slice_pitch }
        }
        private(set) var mipLevels: UInt32 = 0 {
            didSet {
                self.desc.num_mip_levels = mipLevels
            }
        }
        private(set) var samplesCount: UInt32 = 0 {
            didSet {
                self.desc.num_samples = samplesCount
            }
        }
        var desc: cl_image_desc
        var type: CLMemObjectType {
            set(newValue) { desc.image_type = newValue.value}
            get { return CLMemObjectType(type: desc.image_type)! }
        }
        init(type: CLMemObjectType,
             width: size_t,
             height: size_t,
             depth: size_t,
             arraySize: size_t = 0,
             rowPitch: size_t = 0,
             slicePitch: size_t = 0,
             buffer: CLKernelData? = nil) throws {
            desc = cl_image_desc(image_type: type.value,
                                 image_width: width,
                                 image_height: height,
                                 image_depth: depth,
                                 image_array_size: arraySize,
                                 image_row_pitch: rowPitch,
                                 image_slice_pitch: slicePitch,
                                 num_mip_levels: mipLevels,
                                 num_samples: samplesCount,
                                 buffer: type == .Image1D ? buffer?.mem : nil)
            self.buffer = buffer
        }
    }
    private(set) var format: CLImageFormat?
    private(set) var desc: CLImageDesc?
    var elementSize: size_t? { return try? integerValue(type: CL_IMAGE_ELEMENT_SIZE) }
    var rowPitch: Int? { return desc?.rowPitch }
    var slicePitch: Int? { return desc?.slicePitch }
    init(context: CLContext,
         flags: CLMemFlags,
         desc: CLImageDesc,
         format: CLImageFormat,
         data: [Any]?) throws {
        var errCode: cl_int = 0
        self.format = format
        self.desc = desc
        var vec = data
        let mem = clCreateImage(context.context,
                                flags.value,
                                &self.format!.format,
                                &self.desc!.desc,
                                &vec,
                                &errCode)
        super.init(flags, mem, context, data)
    }
    
    required public init(_ flags:CLMemFlags, _ memObj: cl_mem?, _ context: CLContext, _ ptr: [Any]?) {
        super.init(flags, memObj, context, ptr)
    }
    
    override func integerValue(type: Int32) throws -> Int {
        var actualSize = 0
        let code = clGetImageInfo(mem,
                                  cl_mem_info(type),
                                  Int.max,
                                  nil,
                                  &actualSize)
        guard code == CL_SUCCESS else { throw bufferError(code) }
        var value = 0
        clGetImageInfo(mem, cl_mem_info(type), actualSize, &value, nil)
        return value
    }
}
