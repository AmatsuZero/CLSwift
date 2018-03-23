//
//  Grep.swift
//  CLSwift
//
//  Created by modao on 2018/3/22.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

private let programCL = """
__kernel void string_search(char16 pattern,
                        __global char* text,
                        int chars_per_item,
                __local int* local_result,
                __global int* global_result) {

    char16 text_vector, check_vector;

    /* initialize local data */
    local_result[0] = 0;
    local_result[1] = 0;
    local_result[2] = 0;
    local_result[3] = 0;

    /* Make sure previous processing has completed */
    barrier(CLK_LOCAL_MEM_FENCE);

    int item_offset = get_global_id(0) * chars_per_item;

    /* Iterate through characters in text */
    for(int i=item_offset; i<item_offset + chars_per_item; i++) {

        /* load global text into private buffer */
        text_vector = vload16(0, text + i);

        /* compare text vector and pattern */
        check_vector = text_vector == pattern;

        /* Check for 'that' */
        if(all(check_vector.s0123))
        atomic_inc(local_result);

        /* Check for 'with' */
        if(all(check_vector.s4567))
        atomic_inc(local_result + 1);

        /* Check for 'have' */
        if(all(check_vector.s89AB))
        atomic_inc(local_result + 2);

        /* Check for 'from' */
        if(all(check_vector.sCDEF))
        atomic_inc(local_result + 3);
    }

    /* Make sure local processing has completed */
    barrier(CLK_GLOBAL_MEM_FENCE);

    /* Perform global reduction */
    if(get_local_id(0) == 0) {
        atomic_add(global_result, local_result[0]);
        atomic_add(global_result + 1, local_result[1]);
        atomic_add(global_result + 2, local_result[2]);
        atomic_add(global_result + 3, local_result[3]);
    }
}
"""

extension Data {
    func grep(patterns: [String]) throws -> [String: Int]? {
        guard let context = try CLOrganizer.simpleOrganizer() else { return nil }
        let programData = (programCL as NSString).utf8String
        var buffer = [programData]
        var bufferSize = [programCL.data(using: .utf8)?.count ?? 0]
        let program = try CLProgram(context: context, buffers: &buffer, sizes: &bufferSize)
        guard program.build() else {
            return nil
        }
        var tmp = self.map { CChar($0) }
        let charSize = MemoryLayout<CChar>.size*tmp.count
        let textBuffer = try CLKernelBuffer(context: context,
                                            flags: [.COPYHOSTPR, .READ],
                                            size: charSize,
                                            hostBuffer: &tmp)
        var result = [Int](repeating: 0, count: patterns.count)
        let resultSize = MemoryLayout<Int>.size*result.count
        let resultBuffer =  try CLKernelBuffer(context: context,
                                               flags: [.READWRITE, .COPYHOSTPR],
                                               size: resultSize,
                                               hostBuffer: &result)
        
        let kernel = try CLKernel(name: "string_search", program: program)
        var pattern = patterns.reduce("", { $0 + $1 }).data(using: .utf8)?.map { CChar($0) }
        guard pattern != nil else {
            return nil
        }
        try kernel.setArgument(at: 0, size: MemoryLayout<CChar>.size*pattern!.count, data: &pattern)
        try kernel.setArgument(at: 1, value: textBuffer)
        guard let device = context.devices?.first else {
            return nil
        }
        var globalSize = Int(device.maxComputeUnits ?? 0)
        let localSize = Int(device.maxWorkGroupCount ?? 0)
        globalSize *= localSize
        var charsPerItem = charSize/globalSize
        try kernel.setArgument(at: 2, size: MemoryLayout.size(ofValue: charsPerItem), data: &charsPerItem)
        try kernel.setArgument(at: 3, size: resultSize, data: nil)
        try kernel.setArgument(at: 4, value: resultBuffer)
        let queue = try CLCommandQueue(context: context, device: device)
        try queue.enqueueNDRangeKernel(kernel: kernel, workDim: 1, globalWorkOffset: [0],
                                       globalWorkSize: [globalSize], localWorkSize: [localSize])
        let readCommand = CLCommandQueue.CLCommandBufferOperation.ReadBuffer(0, resultSize)
        guard queue.enqueueBuffer(buffer: resultBuffer, operation: readCommand, host: &result).isSuccess == true else {
            return nil
        }
        var statistics = [String: Int]()
        for (i, count) in result.enumerated() {
            statistics[patterns[i]] = count
        }
        return statistics
    }
}
