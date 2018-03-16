//
//  StringFileExtenions.swift
//  CLSwift
//
//  Created by modao on 2018/2/28.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

public extension String {

    func toDataBuffer() throws -> (size: Int, charBuffer: UnsafePointer<Int8>?) {
        let data = try Data(contentsOf: URL(fileURLWithPath: self))
        return (data.count,
                (String(data: data,
                        encoding: .utf8)! as NSString).utf8String)
    }
}

extension Array where Element == String {
    func kernelFileBuffer() throws -> (size: [Int], buffer: [UnsafePointer<Int8>?]) {
        var bufferSize = [Int]()
        var buffer = [UnsafePointer<Int8>?]()
        for file in self {
            if !FileManager.default.fileExists(atPath: file) {
                throw NSError(domain: "com.daubert.OpenCL.file", code: -404, userInfo: [NSLocalizedDescriptionKey: "File dose not exist!", "File": file])
            }
            let (size, charBuffer) = try file.toDataBuffer()
            bufferSize.append(size)
            buffer.append(charBuffer)
        }
        return (bufferSize, buffer)
    }
}

extension UInt8 {
    func char() -> Character {
        return Character(UnicodeScalar(Int(self))!)
    }
}
