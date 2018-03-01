//
//  StringFileExtenions.swift
//  CLSwift
//
//  Created by modao on 2018/2/28.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

extension String {

    func toDataBuffer() throws -> (size: Int, charBuffer: UnsafePointer<Int8>?) {
        let data = try Data(contentsOf: URL(fileURLWithPath: self))
        return (data.count,
                (String(data: data,
                        encoding: .utf8)! as NSString).utf8String)
    }
}

extension UInt8 {
    func char() -> Character {
        return Character(UnicodeScalar(Int(self))!)
    }
}
