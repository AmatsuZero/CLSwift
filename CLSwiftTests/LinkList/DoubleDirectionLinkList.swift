//
//  DoubleDirectionLinkList.swift
//  CLSwiftTests
//
//  Created by modao on 2018/3/22.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

struct DoublyLinkedList<T>: ListProtocalType {

    typealias Element = T
    class DoublyLinkedListNode<T>: LinkListNode<T> {
        var pre: DoublyLinkedListNode?
    }
    var length: UInt = 0
    var headNode: DoublyLinkedListNode<T>?
    var tailNode: DoublyLinkedListNode<T>?
    var count: UInt {
        return length
    }

    init() {
        headNode = DoublyLinkedListNode(data: nil)
        tailNode = nil
    }

    @discardableResult
    mutating func append<S>(items: S) -> Bool where S : Sequence, DoublyLinkedList.Element == S.Element {
        for item in items {
            guard append(item: item) else {
                return false
            }
        }
        return true
    }

    @discardableResult
    mutating func unshift<S>(items: S) -> Bool where S : Sequence, DoublyLinkedList.Element == S.Element {
        for item in items {
            guard unshift(item: item) else {
                return false
            }
        }
        return true
    }

    @discardableResult
    mutating func unshift(item: T?) -> Bool {
        let newNode = DoublyLinkedListNode(data: item)
        guard tailNode != nil else {
            return false
        }
        tailNode?.next = newNode
        newNode.pre = tailNode
        tailNode = newNode
        length += 1
        return true
    }

    @discardableResult
    mutating func append(item: T?) -> Bool {
        let newNode = DoublyLinkedListNode(data: item)
        guard tailNode != nil else {
            return false
        }
        //链表关联
        tailNode?.next = newNode
        newNode.pre = tailNode
        length += 1
        if length == 1 {
            tailNode = newNode
        }
        return true
    }

    @discardableResult
    mutating func insert(item: T?, at index: UInt) -> Bool {
        guard checkIndex(index: index) else {
            return false
        }
        if index == 0 {
            return unshift(item: item)
        } else if index == length {
            return append(item: item)
        } else {
            var cursor = headNode
            for _ in 0..<index {
                cursor = cursor?.next as? DoublyLinkedList<T>.DoublyLinkedListNode<T>
            }
            let newNode = DoublyLinkedListNode(data: item)
            newNode.next = cursor?.next
            if cursor?.next != nil {
                (cursor?.next as? DoublyLinkedList<T>.DoublyLinkedListNode<T>)?.pre = newNode
            }
            cursor?.next = newNode
            cursor?.pre = cursor
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

    @discardableResult
    mutating func dropFirst() -> T? {
        guard headNode?.next != nil else {
            return nil
        }
        let removeItem = headNode?.next as? DoublyLinkedListNode<T>
        headNode?.next = removeItem?.next
        if let next = removeItem?.next as? DoublyLinkedListNode<T> {
            next.pre = headNode
        }
        removeItem?.next = nil
        removeItem?.pre = nil
        length -= 1
        if headNode?.next == nil {
            tailNode = headNode
        }
        return removeItem?.data
    }

    @discardableResult
    mutating func dropLast() -> T? {
        guard headNode?.next != nil else {
            return nil
        }
        let preNode = tailNode?.pre
        let removeItem = tailNode
        removeItem?.next = nil
        removeItem?.pre = nil
        preNode?.next = nil
        tailNode = preNode
        length -= 1
        return removeItem?.data
    }

    @discardableResult
    mutating func remove(at index: UInt) -> T? {
        guard headNode?.next != nil, checkIndex(index: index) else {
            return nil
        }
        var cursor = headNode
        for i in 0..<length {
            cursor = cursor?.next as? DoublyLinkedListNode<T>
            if index == i {
                break
            }
        }
        let preCursor = cursor?.pre
        preCursor?.next = cursor?.next
        if let next = cursor?.next as? DoublyLinkedListNode<T> {
            next.pre = preCursor
        }
        cursor?.next = nil
        cursor?.pre = nil
        if index == length-1 {
            tailNode = preCursor
        }
        length -= 1
        return cursor?.data
    }

    func forEach(callback: (T?) -> Void) {
        var currentNode = headNode?.next
        for _ in 0..<length {
            if currentNode == nil { break }
            callback(currentNode?.data)
            currentNode = currentNode?.next
        }
    }

    func checkIndex(index: UInt) -> Bool {
        return length >= index
    }

    func valueAt(index: UInt) -> T? {
        return nodeAt(index: index)?.data
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
}
