//
//  CLKernel.swift
//  CLSwift
//
//  Created by modao on 2018/3/2.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

private let kernelError: (cl_int) -> NSError = { type in
    var message = ""
    switch type {
    case CL_INVALID_ARG_VALUE:
        message = "arg_value specified is not a valid value"
    case CL_INVALID_MEM_OBJECT:
        message = "for an argument declared to be a memory object when the specified arg_value is not a valid memory object."
    case CL_INVALID_SAMPLER:
        message = "an argument declared to be of type sampler_t when the specified arg_value is not a valid sampler objec"
    case CL_INVALID_ARG_SIZE:
        message = "if arg_size does not match the size of the data type for an argument that is not a memory object or if the argument is a memory object and arg_size != sizeof(cl_mem) or if arg_size is zero and the argument is declared with the local qualifier or if the argument is a sampler and arg_size != sizeof(cl_sampler)"
    case CL_INVALID_PROGRAM:
        message = "program is not a valid program object"
    case CL_INVALID_PROGRAM_EXECUTABLE:
        message = "there is no successfully built executable for program"
    case CL_INVALID_KERNEL_NAME:
        message = "kernel_name is not found in program"
    case CL_INVALID_KERNEL_DEFINITION:
        message = "the function definition for __kernel function given by kernel_name such as the number of arguments, the argument types are not the same for all devices for which the program executable has been built"
    case CL_INVALID_VALUE:
        message = "kernel_name is NULL"
    case CL_OUT_OF_RESOURCES:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the device"
    case CL_OUT_OF_HOST_MEMORY:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the host"
    case CL_INVALID_ARG_INDEX: message = "if arg_indx is not a valid argument index."
    case CL_KERNEL_ARG_INFO_NOT_AVAILABLE: message = "if the argument information is not available for kernel"
    default:
        message = "Unknwon Error"
    }
    return NSError(domain: "com.daubert.OpenCL.Kernel", code: Int(type), userInfo: [NSLocalizedFailureReasonErrorKey: message])
}

public final class CLKernel {
    
    internal let program: CLProgram
    internal let kernel: cl_kernel?
    private var _name: String?
    public var name: String? {
        if _name != nil { return _name }
        _name = try? stringValue(CL_KERNEL_FUNCTION_NAME)
        return _name
    }
    public var numOfArgs: UInt32? {
        return try? integerValue(CL_KERNEL_NUM_ARGS)
    }

    public struct CLKernalArgInfo {
        public enum CLKernelArgAddressQualifier: Int32, CLInfoProtocol {
            case global, local, constant, PRIVATE
            typealias valueType = cl_kernel_arg_address_qualifier
            public init(rawValue: Int32) {
                switch rawValue {
                case CL_KERNEL_ARG_ADDRESS_GLOBAL: self = .global
                case CL_KERNEL_ARG_ADDRESS_LOCAL: self = .local
                case CL_KERNEL_ARG_ADDRESS_CONSTANT: self = .constant
                default: self = .PRIVATE
                }
            }
            var value: cl_kernel_arg_address_qualifier {
               return cl_kernel_arg_address_qualifier(rawValue)
            }
        }
        public enum CLKernelArgAccessQualifier: Int32, CLInfoProtocol {
            case READ, WRITE, READWRITE, NONE
            typealias valueType = cl_kernel_arg_access_qualifier
            public init(rawValue: Int32) {
                switch rawValue {
                case CL_KERNEL_ARG_ACCESS_READ_ONLY: self = .READ
                case CL_KERNEL_ARG_ACCESS_WRITE_ONLY: self = .WRITE
                case CL_KERNEL_ARG_ACCESS_READ_WRITE: self = .READWRITE
                default: self = .NONE
                }
            }
            var value: cl_kernel_arg_access_qualifier {
                return cl_kernel_arg_access_qualifier(rawValue)
            }
        }

        public struct CLKernelArgTypeQualifier: OptionSet {
            public let rawValue: Int32
            public static let CONST = CLKernelArgTypeQualifier(rawValue: CL_KERNEL_ARG_TYPE_CONST)
            public static let RESTRICT = CLKernelArgTypeQualifier(rawValue: CL_KERNEL_ARG_TYPE_RESTRICT)
            public static let VOLATILE = CLKernelArgTypeQualifier(rawValue: CL_KERNEL_ARG_TYPE_VOLATILE)
            public static let NONE = CLKernelArgTypeQualifier(rawValue: CL_KERNEL_ARG_TYPE_NONE)
            public init(rawValue: Int32) {
                self.rawValue = rawValue
            }
        }

        public let addressQualifier: CLKernelArgAddressQualifier?
        public let accessQualifier: CLKernelArgAccessQualifier?
        public let typeQualifier: CLKernelArgTypeQualifier?
        public let name: String?
        public let type: String?

        init(kernel: cl_kernel?, at index: UInt32) {
            name = try? CLKernalArgInfo.stringValue(kernel: kernel, type: CL_KERNEL_ARG_NAME, at: index)
            type = try? CLKernalArgInfo.stringValue(kernel: kernel, type: CL_KERNEL_ARG_TYPE_NAME, at: index)
            if let code = try? CLKernalArgInfo.integerValue(kernel: kernel, type: CL_KERNEL_ARG_ADDRESS_QUALIFIER, at: index) {
                addressQualifier = CLKernelArgAddressQualifier(rawValue: code)
            } else {
                addressQualifier = nil
            }
            if let code = try? CLKernalArgInfo.integerValue(kernel: kernel, type: CL_KERNEL_ARG_ACCESS_QUALIFIER, at: index) {
                accessQualifier = CLKernelArgAccessQualifier(rawValue: code)
            } else {
                accessQualifier = nil
            }
            if let code = try? CLKernalArgInfo.integerValue(kernel: kernel, type: CL_KERNEL_ARG_TYPE_QUALIFIER, at: index) {
                typeQualifier = CLKernelArgTypeQualifier(rawValue: code)
            } else {
                typeQualifier = nil
            }
        }

        fileprivate static func stringValue(kernel: cl_kernel?, type: Int32, at index: UInt32) throws -> String {
            var actualSize = 0
            let code = clGetKernelArgInfo(kernel, index, cl_kernel_arg_info(type), Int.max, nil, &actualSize)
            guard code == CL_SUCCESS else {
                throw kernelError(code)
            }
            var charBuffer = UnsafeMutablePointer<cl_char>.allocate(capacity: actualSize)
            defer {
                charBuffer.deallocate()
            }
            clGetKernelArgInfo(kernel, index, cl_kernel_arg_info(type), actualSize, charBuffer, nil)
            return String(cString: charBuffer)
        }

        fileprivate static func integerValue(kernel: cl_kernel?, type: Int32, at index: UInt32) throws -> Int32 {
            var actualSize = 0
            let code = clGetKernelArgInfo(kernel, index, cl_kernel_arg_info(type), Int.max, nil, &actualSize)
            guard code == CL_SUCCESS else {
                throw kernelError(code)
            }
            var addrDataPtr: cl_int = 0
            clGetKernelArgInfo(kernel, index, cl_kernel_arg_info(type), actualSize, &addrDataPtr, nil)
            return addrDataPtr
        }
    }
    
    init(name: String, program: CLProgram) throws {
        _name = name
        self.program = program
        var error: cl_int = 0
        var buffer = name.cString(using: .utf8)!
        kernel = clCreateKernel(program.program, &buffer, &error)
        guard error == CL_SUCCESS else {
            throw kernelError(error)
        }
    }
    
    private init(program: CLProgram, kernel: cl_kernel?) {
        self.program = program
        self.kernel = kernel
        _name = nil
    }

    public var argInfo: [CLKernalArgInfo]? {
        guard let count = numOfArgs else {
            return nil
        }
        var infos = [CLKernalArgInfo]()
        for index in 0..<count {
            infos.append(CLKernel.CLKernalArgInfo(kernel: kernel, at: index))
        }
        return infos
    }

    @discardableResult
    func setArgument(at index: UInt32, value: CLKernelData) throws -> Bool {
        let code = clSetKernelArg(kernel,
                                  index,
                                  MemoryLayout.size(ofValue: value.mem),
                                  &value.mem)
        guard code == CL_SUCCESS else {
            throw kernelError(code)
        }
        return code == CL_SUCCESS
    }
    
    class func createKernels(program: CLProgram, num: UInt32 = 0) throws -> [CLKernel] {
        var numOfKernels: cl_uint = 0
        let code = clCreateKernelsInProgram(program.program, 0, nil, &numOfKernels)
        guard code == CL_SUCCESS else {
            throw kernelError(code)
        }
        numOfKernels = num > numOfKernels || num == 0 ? numOfKernels : num
        var kernels: [cl_kernel?] = Array(repeating: nil, count: Int(numOfKernels))
        clCreateKernelsInProgram(program.program, numOfKernels, &kernels, nil)
        return kernels.map { CLKernel(program: program, kernel: $0) }
    }
    
    fileprivate func stringValue(_ type: Int32) throws -> String {
        var actualSize = 0
        let code = clGetKernelInfo(kernel, cl_kernel_info(type), 0, nil, &actualSize)
        guard code == CL_SUCCESS else {
            throw kernelError(code)
        }
        var charBuffer = UnsafeMutablePointer<cl_char>.allocate(capacity: actualSize)
        defer {
            charBuffer.deallocate()
        }
        clGetKernelInfo(kernel, cl_kernel_info(type), actualSize, charBuffer, nil)
        return String(cString: charBuffer)
    }

    fileprivate func integerValue(_ type: Int32) throws -> UInt32 {
        var actualSize = 0
        let code = clGetKernelInfo(kernel, cl_kernel_info(type), 0, nil, &actualSize)
        guard code == CL_SUCCESS else {
            throw  kernelError(code)
        }
        var addrDataPtr: cl_uint = 0
        clGetKernelInfo(kernel, cl_kernel_info(type), actualSize, &addrDataPtr, nil)
        return addrDataPtr
    }
    
    deinit {
        clReleaseKernel(kernel)
    }
}
