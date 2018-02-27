//
//  matvec.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/22.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

func matvec()  {
    let PROGRAM_FILE = "matvec.cl"
    let KERNEL_FUNC = "matvec_mult"

    //MARK: Host/device data structures
    var platform: cl_platform_id?
    var device: cl_device_id?
    var err: cl_int = 0
    //MARK: Program/kernel data structures
    var program_buffer: [cl_char]? = [cl_char]()
    var program_log = [cl_char]()

    //MARK: Data and buffers
    var mat = (0..<16).map { Float($0) * 2.0 }
    var vec = (0..<4).map { Float($0) * 3.0 }
    var result: [Float] = Array(repeating: 0, count: 4)
    var correct: [Float] = Array(repeating: 0, count: 4)

    //MAKR: Initialize data to be processed by the kernel
    for (i, value) in vec.enumerated() {
        correct[i] += mat[i+4*i] * value
    }
    //MARK: Identify a platform
    guard clGetPlatformIDs(1, &platform, nil) >= 0 else {
        fatalError("Couldn't find the program file")
    }
    //MARK: Access a device
    guard clGetDeviceIDs(platform, cl_device_type(CL_DEVICE_TYPE_CPU), 1, &device, nil) >= 0 else {
        fatalError("Couldn't find any devices")
    }
    //MARK: Create the context
    let context = clCreateContext(nil, 1, &device, nil, nil, &err)
    defer {
        clReleaseContext(context)
    }
    guard err >= 0  else {
        fatalError("Couldn't create a context")
    }
    guard let program_handle = fopen("/Users/modao/OpenCLStudy/OpenCLStudy/ChapterOne/matvec.cl", "r") else {
        fatalError("Couldn't find the program file")
    }
    fseek(program_handle, 0, SEEK_END)
    var program_size: size_t = 0
    program_size = ftell(program_handle)
    fread(&program_buffer,
          MemoryLayout<cl_char>.size,
          program_size,
          program_handle)
    fclose(program_handle)
    //MARK: Create program from file
    var ptr = UnsafePointer<cl_char>(program_buffer)
    defer {
        ptr?.deallocate()
    }
    var program = clCreateProgramWithSource(context,
                                            1,
                                            &ptr,
                                            &program_size,
                                            &err)
    defer {
        clReleaseProgram(program)
    }
    guard err >= 0 else {
        fatalError("Couldn't create the program")
    }
    //MARK: Build program
    err = clBuildProgram(program, 0, nil, nil, nil, nil)
    var log_size = UnsafeMutablePointer<size_t>.allocate(capacity: MemoryLayout<size_t>.size)
    defer {
        log_size.deallocate()
    }
    guard err >= 0 else {
        // Find size of log and print to std output
        clGetProgramBuildInfo(program, device, cl_program_build_info(CL_PROGRAM_BUILD_LOG), 0, nil, log_size)
        clGetProgramBuildInfo(program,
                              device,
                              cl_program_build_info(CL_PROGRAM_BUILD_LOG),
                              log_size.pointee+1,
                              &program_log,
                              nil)
        print(String(cString: program_log, encoding: .utf8) ?? "Empty log")
        exit(1)
    }
    //MARK: Create kernel for the mat_vec_mult function
    var kernel = clCreateKernel(program, KERNEL_FUNC, &err)
    defer {
        clReleaseKernel(kernel)
    }
    guard err >= 0 else {
        fatalError("Couldn't create the kernel")
    }
    //MARK: Create CL buffers to hold input and output data
    var mat_buff = clCreateBuffer(context,
                                  cl_mem_flags(CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR),
                                  MemoryLayout.size(ofValue: mat),
                                  &mat,
                                  &err)
    defer {
        clReleaseMemObject(mat_buff)
    }
    guard err >= 0 else {
        fatalError("Couldn't create a buffer object")
    }
    var vec_buff = clCreateBuffer(context,
                                  cl_mem_flags(CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR),
                                  MemoryLayout.size(ofValue: vec),
                                  &vec,
                                  nil)
    defer {
        clReleaseMemObject(vec_buff)
    }
    var res_buff = clCreateBuffer(context,
                                  cl_mem_flags(CL_MEM_WRITE_ONLY),
                                  MemoryLayout<Float>.size*4,
                                  nil,
                                  nil)
    defer {
        clReleaseMemObject(res_buff)
    }
    //MARK: Create kernel arguments from the CL buffers
    let clMemSize = MemoryLayout<cl_mem>.size
    guard clSetKernelArg(kernel, 0, clMemSize, &mat_buff) >= 0 else {
        fatalError("Couldn't set the kernel argument")
    }
    clSetKernelArg(kernel, 1, clMemSize, &vec_buff)
    clSetKernelArg(kernel, 2, clMemSize, &res_buff)
    //MARK: Create a CL command queue for the device
    let queue = clCreateCommandQueue(context,
                                     device,
                                     0,
                                     &err)
    defer {
        clReleaseCommandQueue(queue)
    }
    guard err >= 0 else {
        fatalError("Couldn't create the command queue")
    }
    //MARK: Enqueue the command queue to the device
    var work_units_per_kernel: size_t = 4
    guard clEnqueueNDRangeKernel(queue,
                                 kernel,
                                 1,
                                 nil,
                                 &work_units_per_kernel,
                                 nil,
                                 0,
                                 nil,
                                 nil) >= 0 else {
        fatalError("Couldn't enqueue the kernel execution command")
    }
    //MARK: Read the result
    guard clEnqueueReadBuffer(queue,
                              res_buff,
                              cl_bool(CL_TRUE),
                              0,
                              MemoryLayout.size(ofValue: result),
                              &result,
                              0,
                              nil,
                              nil) >= 0 else {
        fatalError("Couldn't enqueue the read buffer command")
    }
    //MARK: Test the result
    var ret = true
    for (i, value) in result.enumerated() {
        if correct[i] != value {
            ret = false
            break
        }
    }
    if ret {
        print("Matrix-vector multiplication successful.")
    } else {
        print("Matrix-vector multiplication unsuccessful")
    }
}
