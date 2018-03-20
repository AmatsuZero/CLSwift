//
//  HashTable.swift
//  CLSwiftTests
//
//  Created by modao on 2018/3/20.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

class HashableObject {

    private static var hashTable = [Int: Int]()
    private(set) var hashKey: Int = 0
    private(set) var id: Int = 0
    private(set) static var globalCount = 0
    private static var queue = DispatchQueue(label: "your.queue.identifier")

    required init() {
        HashableObject.queue.sync {
            HashableObject.globalCount += 1
        }
        id = HashableObject.globalCount
        hashKey = HashableObject.add(value: id)
    }

    @discardableResult
    private static func add(value: Int) -> Int {
        let key = createHashKey(value: value)
        hashTable[key] = value
        return key
    }

    private static func createHashKey(value: Int) -> Int {
        var key = hashFuntion(value: value)
        if hashTable[key] != nil {
            key = conflictHandling(value: key)
        }
        return key
    }

    private static func conflictHandling(value: Int) -> Int {
        var key = value
        var cursor = hashTable[key]
        while cursor != nil {
            key = conflictMethod(value: key)
            cursor = hashTable[key]
        }
        return key
    }

    /// 散列函数： 除留取余法
    ///
    /// - parameter value: 散列函数的参数
    ///
    /// - returns: 返回散列函数创建的值
    class func hashFuntion(value: Int) -> Int {
        return value % globalCount
    }

    /// 处理冲突的函数：线性探测
    ///
    /// - parameter value: 要处理冲突的值
    ///
    /// - returns: 不冲突的key
    class func conflictMethod(value: Int) -> Int {
        return (value+1) % globalCount
    }

    deinit {
        HashableObject.queue.sync {
            HashableObject.globalCount -= 1
        }
        HashableObject.hashTable.removeValue(forKey: hashKey)
    }
}

class CustomHashableObject: HashableObject {

    override class func hashFuntion(value: Int) -> Int {
        return value % globalCount
    }

    override class func conflictMethod(value: Int) -> Int {
        let randomDisplacement = Int(arc4random_uniform(50))
        return (value + randomDisplacement) % globalCount
    }
}
