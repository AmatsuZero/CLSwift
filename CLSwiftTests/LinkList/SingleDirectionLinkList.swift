//
//  SingleDirectionLinkList.swift
//  CLSwiftTests
//
//  Created by modao on 2018/3/21.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

struct SingleDirectionLinkList<T>: ListProtocalType {

    typealias Element = T
    var headNode: LinkListNode<T>?
    var tailNode: LinkListNode<T>?
    private(set) var length: UInt = 0

    init() {
        headNode = LinkListNode<T>(data: nil)
        tailNode = headNode
    }

    init<S: Sequence>(_ sequence: S) where S.Iterator.Element == T {
        self.init()
        append(items: sequence)
    }

    mutating func remove(at index: UInt) -> T? {
        guard headNode?.next != nil, checkIndex(index: index) else {
            return nil
        }
        var cursor = headNode //遍历游标
        var preCursor = headNode//记录一下cursor的前面的节点
        for i in 0..<length {
            preCursor = cursor
            cursor = cursor?.next
            if index == i {
                break
            }
        }
        // 对节点进行移除
        preCursor?.next = cursor?.next
        cursor?.next = nil
        if index == length - 1 {
            tailNode = preCursor
        }
        return cursor?.data
    }

    var count: UInt {
        return length
    }

    @discardableResult
    mutating func append<S>(items: S) -> Bool where S : Sequence, SingleDirectionLinkList.Element == S.Element {
        for item in items {
            guard append(item: item) else {
                return false
            }
        }
        return true
    }

    @discardableResult
    mutating func unshift<S>(items: S) -> Bool where S : Sequence, SingleDirectionLinkList.Element == S.Element {
        for item in items {
            guard unshift(item: item) else {
                return false
            }
        }
        return true
    }

    @discardableResult
    mutating func append(item: T?) -> Bool {
        let newElement = LinkListNode<T>(data: item)
        guard tailNode != nil else { return false }
        tailNode?.next = newElement
        tailNode = newElement
        length += 1
        return true
    }

    @discardableResult
    mutating func unshift(item: T?) -> Bool {
        let newLinkListNode = LinkListNode<T>(data: item)
        guard headNode != nil else {
            return false
        }
        newLinkListNode.next = headNode?.next
        headNode?.next = newLinkListNode
        length += 1
        if length == 1 {
            tailNode = newLinkListNode
        }
        return true
    }

    subscript(_ index: UInt) -> T? {
        mutating set(newValue) {
            nodeAt(index: index)?.data = newValue
        }
        nonmutating get {
            return valueAt(index: index)
        }
    }

    @discardableResult
    mutating func insert(item: T?, at index: UInt) -> Bool {
        guard checkIndex(index: index) else { return false }
        if index == 0 {
            return unshift(item: item)
        } else if index == length {
            return append(item: item)
        } else {
            var cursor = headNode
            for _ in 0..<index {
                cursor = cursor?.next
            }
            let newItem = LinkListNode<T>(data: item)
            newItem.next = cursor?.next
            cursor?.next = newItem
            length += 1
            return true
        }
    }

    mutating func removeAllItemFromHead() {
        while dropFirst() != nil {

        }
    }

    mutating func removeAllItemFromLast() {
        while dropLast() != nil {
            
        }
    }

    func nodeAt(index: UInt) -> LinkListNode<T>? {
        guard index <= length-1 else { return nil }
        if index == 0 {
            return headNode
        } else if index == length-1 {
            return tailNode
        } else {
            var cursor = headNode?.next
            for _ in 0..<index {
                if cursor == nil { break }
                cursor = cursor?.next
            }
            return cursor
        }
    }

    func valueAt(index: UInt) -> T? {
        return nodeAt(index: index)?.data
    }

    mutating func dropFirst() -> T? {
        guard headNode?.next != nil else {//链表为空
            return nil
        }
        let removeItem = headNode?.next
        headNode?.next = removeItem?.next
        removeItem?.next = nil
        length -= 1
        if headNode?.next == nil {// 如果移除的是最后一个元素，就将尾指针指向头指针
            tailNode = headNode
        }
        return removeItem?.data
    }

    mutating func dropLast() -> T? {
        guard headNode?.next != nil else {
            return nil
        }
        return remove(at: length-1)
    }

    func forEach(callback: (T?) -> Void) {
        var currentNote = headNode?.next
        for _ in 0..<length {
            if currentNote == nil { break }
            callback(currentNote?.data)
            currentNote = currentNote?.next
        }
    }
    
    func checkIndex(index: UInt) -> Bool {
        return index <= length
    }
}
