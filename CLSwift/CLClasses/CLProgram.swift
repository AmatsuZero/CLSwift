//
//  CLProgram.swift
//  CLSwift
//
//  Created by modao on 2018/2/28.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

internal let programError: (cl_int) -> NSError? = { errType -> NSError? in
    var message = ""
    switch errType {
    case CL_SUCCESS: return nil
    case CL_INVALID_VALUE:
        message = "pfn_notify is NULL but user_data is not NULL"
    case CL_OUT_OF_RESOURCES:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the device"
    case CL_OUT_OF_HOST_MEMORY:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the host"
    case CL_INVALID_CONTEXT:
        message = "context is not a valid context"
    case CL_INVALID_PROGRAM:
        message = "program is not a valid program object"
    case CL_INVALID_DEVICE:
        message = "OpenCL devices listed in device_list are not in the list of devices associated with program"
    case CL_INVALID_BINARY:
        message = "program is created with clCreateProgramWithBinary and devices listed in device_list do not have a valid program binary loaded"
    case CL_INVALID_BUILD_OPTIONS:
        message = "the build options specified by options are invalid"
    case CL_INVALID_OPERATION:
        message = "the build of a program executable for any of the devices listed in device_list by a previous call to clBuildProgram for program has not completed"
    case CL_COMPILER_NOT_AVAILABLE:
        message = "program is created with clCreateProgramWithSource and a compiler is not available i.e. CL_DEVICE_COMPILER_AVAILABLE specified in the table of OpenCL Device Queries for clGetDeviceInfo is set to CL_FALSE"
    case CL_BUILD_PROGRAM_FAILURE:
        message = "there is a failure to build the program executable. This error will be returned if clBuildProgram does not return until the build has completed"
    case CL_INVALID_PROGRAM_EXECUTABLE:
        message = "param_name is CL_PROGRAM_NUM_KERNELS or CL_PROGRAM_KERNEL_NAMES and a successful program executable has not been built for at least one device in the list of devices associated with program"
    default:
        message = "Unknown error"
    }
    return NSError(domain: "com.daubert.OpenCL.Program",
                   code: Int(errType),
                   userInfo: [NSLocalizedFailureReasonErrorKey: message])
}

public final class CLProgram {

    internal let program: cl_program
    public typealias CLBuildProgramCallBack = (Bool, Error?, [String: Any]?, [CLBuildInfo]?) -> Void
    /// CL文件编译选项
    ///
    /// - CLVersion: 告诉编译器所使用的OpenCL版本
    /// - D_NAME: 将宏NAME设置为VALUE，默认为1
    /// - IncludeDir: 包含头文件所在的路径
    /// - SuppressWarning: 抑制警告
    /// - TreatWarningAsError:
    /// - SinglePrecisionConstant: 将所有双精度浮点数作为单精度浮点常数处理
    /// - DenormsAreZero: 将那些所有小于最小可表示数的数字视为0
    /// - OptDisable: 禁止所有的优化
    /// - MadEnable: 将所有涉及先乘后加（a* b+ x）的运算视为基本乘加运算（MAD）；这有可能会降低计算的精度
    /// - NoSingleZero: 防止用到IEEE-754所定义的正/负0
    /// - UnsafeMathOpt: 移除错误建厂来优化运算处理，这回引发不兼容的运算操作
    /// - FiniteMathOnly: 假设所有的结果和参数都是有限的，没有操作会接受和得出无穷量或NaN
    /// - FastRelaxedMath: 将选项UnsafeMathOpt和FastRelaxedMath组合使用
    public enum CLProgramBuildOption: Hashable, Equatable {
        public var hashValue: Int {
            switch self {
            case .CLVersion: return 0
            case .D_NAME: return 1
            case .IncludeDir: return 2
            case .SuppressWarning: return 3
            case .TreatWarningAsError: return 4
            case .SinglePrecisionConstant: return 5
            case .DenormsAreZero: return 6
            case .OptDisable: return 7
            case .MadEnable: return 8
            case .NoSingleZero: return 9
            case .UnsafeMathOpt: return 10
            case .FiniteMathOnly: return 11
            case .FastRelaxedMath: return 12
            }
        }
        case CLVersion(String)
        case D_NAME(String?)
        case IncludeDir(String)
        case SuppressWarning
        case TreatWarningAsError
        case SinglePrecisionConstant
        case DenormsAreZero
        case OptDisable
        case MadEnable
        case NoSingleZero
        case UnsafeMathOpt
        case FiniteMathOnly
        case FastRelaxedMath
        var string: String {
            switch self {
            case .CLVersion(let clVersion): return "-cl-std=\(clVersion)"
            case .D_NAME(let value): return value != nil ? "name=\(value!)" : "-D"
            case .IncludeDir(let dir): return "-I \(dir)"
            case .SuppressWarning: return "-w"
            case .TreatWarningAsError: return "-Werror"
            case .SinglePrecisionConstant: return "-cl-single-precision-constant"
            case .DenormsAreZero: return "-cl-denorms-are-zero"
            case .OptDisable: return "-cl-opt-disable"
            case .MadEnable: return "-cl-mad-enable"
            case .NoSingleZero: return "-cl-no-signed-zeros"
            case .UnsafeMathOpt: return "-cl-unsafe-math-optimizations"
            case .FiniteMathOnly: return "-cl-finite-math-only"
            case .FastRelaxedMath: return "-cl-fast-relaxed-math"
            }
        }
        public static func ==(lhs: CLProgramBuildOption, rhs: CLProgramBuildOption) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
    }

    public struct CLBuildInfo {
        private let program: cl_program
        private let device: cl_device_id?
        public var status: CLBuildStatus? {
            let code = try? integerValue(CL_PROGRAM_BUILD_STATUS)
            return CLBuildStatus(rawValue: code ?? -1)
        }

        public var binaryType: CLBinaryType? {
            let code = try? integerValue(CL_PROGRAM_BINARY_TYPE)
            return CLBinaryType(rawValue: code ?? -1)
        }
        public var log: String? {
            return try? stringValue(CL_PROGRAM_BUILD_LOG)
        }
        public var options: String? {
            return try? stringValue(CL_PROGRAM_BUILD_OPTIONS)
        }

        internal init(program: cl_program, device: cl_device_id?) {
            self.program = program
            self.device = device
        }

        fileprivate func integerValue(_ type: Int32) throws -> Int32 {
            var actualSize = 0
            let code = clGetProgramBuildInfo(program, device, cl_program_info(type), Int.max, nil, &actualSize)
            guard code == CL_SUCCESS else {
                throw programError(code)!
            }
            var status: cl_int = 0
            clGetProgramInfo(program, cl_program_info(type), actualSize, &status, nil)
            return status
        }
        //FIXME: Can't get string value
        fileprivate func stringValue(_ type: Int32) throws -> String {
            var actualSize = 0
            let code = clGetProgramBuildInfo(program, device, cl_program_info(type), 0, nil, &actualSize)
            guard code == CL_SUCCESS else {
                throw programError(code)!
            }
            var charBuffer = UnsafeMutablePointer<cl_char>.allocate(capacity: actualSize)
            defer {
                charBuffer.deallocate(capacity: actualSize)
            }
            clGetProgramInfo(program, cl_program_info(type), actualSize, charBuffer, nil)
            return String(cString: charBuffer)
        }
    }

    public enum CLBuildStatus: Int32 {
        case SUCCESS = 0, NONE, ERROR, IN_PROGRESS
        public init?(rawValue: Int32) {
            switch rawValue {
            case CL_BUILD_SUCCESS: self = .SUCCESS
            case CL_BUILD_NONE: self = .NONE
            case CL_BUILD_IN_PROGRESS: self = .IN_PROGRESS
            case CL_BUILD_ERROR: self = .ERROR
            default: return nil
            }
        }
    }

    public enum CLBinaryType: Int32 {
        case NONE = 0, COMPILED_OBJECT, LIBRARY, EXECUTABLE, INTERMEDIATE
        public init(rawValue: Int32) {
            switch rawValue {
            case CL_PROGRAM_BINARY_TYPE_NONE: self = .NONE
            case CL_PROGRAM_BINARY_TYPE_COMPILED_OBJECT: self = .COMPILED_OBJECT
            case CL_PROGRAM_BINARY_TYPE_LIBRARY: self = .LIBRARY
            case CL_PROGRAM_BINARY_TYPE_EXECUTABLE: self = .EXECUTABLE
            default: self = .INTERMEDIATE
            }
        }
    }
    /// 从cl文件创建Program对象
    ///
    /// - Parameters:
    ///   - context: 上下文对象
    ///   - files: cl文件Buffer
    /// - Throws: 创建过程中的异常
    init(context: CLContext,
         buffers: inout [UnsafePointer<Int8>?],
         sizes: inout [Int]) throws {
        var errorCode: cl_int = 0
        program = clCreateProgramWithSource(context.context,
                                            cl_uint(buffers.count),
                                            &buffers,
                                            &sizes,
                                            &errorCode)
        guard errorCode == CL_SUCCESS else {
            throw programError(errorCode)!
        }
    }

    @discardableResult
    func build(options: Set<CLProgramBuildOption>? = nil,
               devices: [CLDevice]? = nil,
               userData: [String: Any]? = nil,
               callback: CLBuildProgramCallBack? = nil) -> Bool {
        let optionsString = options?.isEmpty == false
            ? options!.map { $0.string }.reduce("") { $0.appending("\($1) ") }
            : nil
        if let cb = callback {
            DispatchQueue.global().async { [weak self] in
                guard let strongSelf = self else { return }
                let code = clBuildProgram(strongSelf.program,
                                          cl_uint(devices?.count ?? 0),
                                          devices == nil ? nil : devices?.map { $0.deviceId },
                                          optionsString,
                                          nil,
                                          nil)
                cb(code == CL_SUCCESS,
                   programError(code),
                   userData,
                   devices?.map { CLBuildInfo(program: strongSelf.program, device: $0.deviceId) })
            }
            return false
        } else {
            return clBuildProgram(program,
                                  cl_uint(devices?.count ?? 0),
                                  devices == nil ? nil : devices?.map { $0.deviceId },
                                  optionsString,
                                  nil,
                                  nil) == CL_SUCCESS
        }
    }

    deinit {
        clReleaseProgram(program)
    }
}
