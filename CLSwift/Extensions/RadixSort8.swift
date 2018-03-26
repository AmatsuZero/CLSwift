//
//  RadixSort8.swift
//  CLSwift
//
//  Created by modao on 2018/3/26.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

private let programCL = """
__kernel void radix_sort8(__global ushort8 *global_data) {

typedef union {
ushort8 vec;
ushort array[8];
} vec_array;

uint one_count, zero_count;
uint cmp_value = 1;
vec_array mask, ones, data;

data.vec = global_data[0];

/* Rearrange elements according to bits */
for(int i=0; i<3; i++) {
zero_count = 0;
one_count = 0;

/* Iterate through each element in the input vector */
for(int j = 0; j < 8; j++) {
if(data.array[j] & cmp_value)

/* Place element in ones vector */
ones.array[one_count++] = data.array[j];
else {

/* Increment number of elements with zero */
mask.array[zero_count++] = j;
}
}

/* Create sorted vector */
for(int j = zero_count; j < 8; j++)
mask.array[j] = 8 - zero_count + j;
data.vec = shuffle2(data.vec, ones.vec, mask.vec);
cmp_value <<= 1;
}
global_data[0] = data.vec;
}
"""

extension Array where Element == UInt8 {
    mutating func radixSort() throws {
        guard let context = try CLOrganizer.simpleOrganizer() else { return }
        let programData = (programCL as NSString).utf8String
        var buffer = [programData]
        var bufferSize = [programCL.data(using: .utf8)?.count ?? 0]
        let program = try CLProgram(context: context, buffers: &buffer, sizes: &bufferSize)
        guard program.build() else { return }

        let size = MemoryLayout<UInt8>.size*self.count
        let kernel = try CLKernel(name: "radix_sort8", program: program)
        let arg = try CLKernelBuffer(context: context,
                                     flags: [.READWRITE, .COPYHOSTPR],
                                     size: size,
                                     hostBuffer: &self)
        guard try kernel.setArgument(at: 0, value: arg) == true, let device = context.devices?.first else { return }

        let queue = try CLCommandQueue(context: context, device: device)
        try queue.enqueueTask(kernel: kernel)
        
        let command = CLCommandQueue.CLCommandBufferOperation.ReadBuffer(0, size)
        guard queue.enqueueBuffer(buffer: arg, operation: command).isSuccess else { return }
    }
}
