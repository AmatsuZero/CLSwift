//
//  StringFileExtenions.swift
//  CLSwift
//
//  Created by modao on 2018/2/28.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

public extension String {
    /// 获取cl文件大小/Buffer
    func toDataBuffer() throws -> (size: Int, charBuffer: UnsafePointer<Int8>?) {
        let data = try Data(contentsOf: URL(fileURLWithPath: self))
        return (data.count,
                (String(data: data,
                        encoding: .utf8)! as NSString).utf8String)
    }
    func find(_ text: String) -> [Int] {
        guard text.count <= self.count else {// 要查找的子串长度大于字符串长度，比较没有了意义……
            return []
        }
        // 字符串子串前缀与后缀最大公共长度
        let getNext: (String) -> [Int] = { txt -> [Int] in
            var arr = [Int](repeating: 0, count: txt.count+1)
            //0和1的值肯定是0
            arr[0] = 0
            arr[1] = 0
            //根据arr[i]推算arr[i+1]
            for i in 1..<txt.count {
                var j = arr[i]
                // 比较i位置与j位置的字符
                // 如果不相等，则j取arr[j]
                while j > 0, txt[i] != txt[j] {
                    j = arr[j]
                }
                // 如果相等，则j加一即可
                if txt[i] == txt[j] {
                    j += 1
                }
                arr[i+1] = j
            }
            return arr
        }
        var next = getNext(text)
        var index = [Int]()
        // i表示text中的位置，j表示查找字符串的位置
        var j = 0
        for i in 0..<self.count {// 遍历字符
            // 这里是KMP算法的关键，位置移动为next[j]
            while j > 0, self[i] != text[j] {
                j = next[j]
            }
            // 如果i位置和j位置字符相同，移动一位
            if self[i] == text[j] {
                j += 1
            }
            // 如果j已经找到了find的尾部目标是已经找到
            if j == text.count {
                // i-j+1即为目标字符串在text中出现的位置
                index.append(i-j+1)
                // 这里是KMP算法的关键，位置移动为next[j]
                j = next[j]
            }
        }
        return index
    }

    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    subscript (bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ..< end]
    }
    subscript (bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ... end]
    }
    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        return self[start ... end]
    }
    subscript (bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ... end]
    }
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ..< end]
    }
}

extension Substring {
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    subscript (bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ..< end]
    }
    subscript (bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ... end]
    }
    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        return self[start ... end]
    }
    subscript (bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ... end]
    }
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ..< end]
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
