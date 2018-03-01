//
//  main.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/22.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

let string = """
hello
"""

let data = string.data(using: .utf8)!

let stream = InputStream(data: data)
defer {
    stream.close()
}
stream.open()

var buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
defer {
    buffer.deallocate()
}

while stream.hasBytesAvailable {
    stream.read(buffer, maxLength: 100)
}

buffer.bindMemory

let charBuffer = UnsafeBufferPointer(start: buffer,
                                     count: data.count/MemoryLayout<CChar>.stride)
var array = Array(charBuffer)
