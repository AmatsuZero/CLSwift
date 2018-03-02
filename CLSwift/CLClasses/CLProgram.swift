//
//  CLProgram.swift
//  CLSwift
//
//  Created by modao on 2018/2/28.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

internal let programError: (cl_int) -> NSError = { errType -> NSError in
    var message = ""
    switch errType {
    case CL_INVALID_VALUE:
        message = "pfn_notify is NULL but user_data is not NULL"
    case CL_OUT_OF_RESOURCES:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the device"
    case CL_OUT_OF_HOST_MEMORY:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the host"
    case CL_INVALID_CONTEXT:
        message = "context is not a valid context"
    default:
        message = "Unknown error"
    }
    return NSError(domain: "com.daubert.OpenCL.Program",
                   code: Int(errType),
                   userInfo: [NSLocalizedDescriptionKey: message])
}

public final class CLProgram {

    internal let program: cl_program
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
        case IncludeDir
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
            case .D_NAME(let value):
                guard let name = value else {
                    return "-DNAME"
                }
                return "-DNAME=\(name)"
            case .IncludeDir: return "-Idir"
            case .SuppressWarning: return "-w"
            case .TreatWarningAsError: return "-Werror"
            case .SinglePrecisionConstant: return "-cl-single-precision-constant"
            case .DenormsAreZero: return "-cl-denorms-are-zero"
            case .OptDisable: return "-cl-opt-disable"
            case .MadEnable: return "-cl-mad-enable"
            case .NoSingleZero: return "-cl-no-signed-zero"
            case .UnsafeMathOpt: return "-cl-unsafe-math-optimizations"
            case .FiniteMathOnly: return "-cl-finite-math-only"
            case .FastRelaxedMath: return "-cl-fast-relaxed-math"
            }
        }

        public static func ==(lhs: CLProgramBuildOption, rhs: CLProgramBuildOption) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
    }

    /// 从cl文件创建Program对象
    ///
    /// - Parameters:
    ///   - context: 上下文对象
    ///   - files: cl文件Buffer
    /// - Throws: 创建过程中的异常
    init(context: CLContext,
         buffer: inout [UnsafePointer<Int8>?],
         size: inout Int) throws {
        var errorCode: cl_int = 0
        program = clCreateProgramWithSource(context.context,
                                            cl_uint(buffer.count),
                                            &buffer,
                                            &size,
                                            &errorCode)
        guard errorCode == CL_SUCCESS else {
            throw programError(errorCode)
        }
    }

    func build(options: Set<CLProgramBuildOption>, devices: [CLDevice]) {
        let optionsString = options.map {
            $0.string
        }.reduce("") {
            $0.appending("\($1) ")
        }
        print(optionsString)
    }

    deinit {
        clReleaseProgram(program)
    }
}
