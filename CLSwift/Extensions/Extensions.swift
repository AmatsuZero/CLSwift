//
//  Extensions.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/27.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

internal func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
    var i = 0
    return AnyIterator {
        let next = withUnsafeBytes(of: &i) { $0.load(as: T.self) }
        if next.hashValue != i { return nil }
        i += 1
        return next
    }
}

public extension OptionSet where RawValue: FixedWidthInteger {
    func elements() -> AnySequence<Self> {
        var remainingBits = rawValue
        var bitMask: RawValue = 1
        return AnySequence {
            return AnyIterator {
                while remainingBits != 0 {
                    defer { bitMask = bitMask &* 2 }
                    if remainingBits & bitMask != 0 {
                        remainingBits = remainingBits & ~bitMask
                        return Self(rawValue: bitMask)
                    }
                }
                return nil
            }
        }
    }
}

public extension Dictionary {
    mutating func append(_ other: Dictionary) {
        for (key, value) in other {
            updateValue(value, forKey: key)
        }
    }
}

protocol CLInfoProtocol {
    associatedtype valueType
    var value: valueType { get }
}

extension Array where Element == UInt8 {
    mutating func convertToCGmage(desc: CLKernelImageBuffer.CLImageDesc) -> CGImage? {
        let bytesPerPixel = 1
        let bytesPerRow = bytesPerPixel * desc.imageWidth
        let bitsPerComponent = 8
        let totalBytes = desc.imageHeight * bytesPerRow
        let bitsPerPixel = bytesPerPixel * bitsPerComponent
        let imageRef = withUnsafePointer(to: &self, { ptr -> CGImage? in
            var imageRef: CGImage?
            let colorSpaceRef = CGColorSpaceCreateDeviceGray()
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue).union(CGBitmapInfo())
            let data = UnsafeRawPointer(ptr.pointee).assumingMemoryBound(to: UInt8.self)
            let releaseData: CGDataProviderReleaseDataCallback = {
                (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
            }
            if let providerRef = CGDataProvider(dataInfo: nil, data: data, size: totalBytes, releaseData: releaseData) {
                imageRef = CGImage(width: desc.imageWidth,
                                   height: desc.imageHeight,
                                   bitsPerComponent: bitsPerComponent,
                                   bitsPerPixel: bitsPerPixel,
                                   bytesPerRow: bytesPerRow,
                                   space: colorSpaceRef,
                                   bitmapInfo: bitmapInfo,
                                   provider: providerRef,
                                   decode: nil,
                                   shouldInterpolate: false,
                                   intent: .defaultIntent)
            }

            return imageRef
        })
        return imageRef
    }
}

extension UInt64 {
    /// 纳秒转秒
    var seconds: TimeInterval {
        return Double(self)/1000000000.0
    }
}
