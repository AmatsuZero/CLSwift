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

protocol CLInfoProtocol {
    associatedtype valueType
    var value: valueType { get }
}
