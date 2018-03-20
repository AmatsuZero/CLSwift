//
//  LinkList.swift
//  CLSwiftTests
//
//  Created by modao on 2018/3/19.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

struct LinkList<T> {
    class LinkNode<T> {
        var data: T?
        var next: LinkNode?
        var index = 0
        init(data: T?, next: LinkNode?) {
            self.data = data
            self.next = next
        }
    }
    var head: LinkNode<T>?
    var tail: LinkNode<T>?

    init(data: T?) {
        self.head = LinkNode<T>(data: data, next: nil)
        self.tail = self.head//新初始化的链表，尾节点就是首节点
    }

    init<S: Sequence>(_ sequence: S) where S.Iterator.Element == T {
        let dataArr = Array<T>(sequence)
        self.init(data: dataArr.first)
        dataArr.dropFirst().forEach { element in
            self.append(element)
        }
    }

    mutating func append(_ new: T) {
        let newNode = LinkNode<T>(data: new, next: nil) //创建新节点
        newNode.index = self.tail?.index ?? 0 + 1
        self.tail?.next = newNode //之前的尾节点的next节点是现在新的节点
        self.tail = newNode //将新节点设置成最新的尾节点
    }

    mutating func remove(at index: Int) {
        guard tail?.index ?? 0 <= index else {
            fatalError("数组越界")
        }
        var current = head
        var prev: LinkNode<T>?
        while current?.index != index, current?.next != nil {
            prev = current
            current = current?.next
        }
        guard current?.index == index else {
            fatalError("未能找到下标对应节点")
        }
        if current === head {// 若current现在指向的是头结点，则把下一个节点为设为Head
            head = current?.next
        } else {// 或者将下一个节点的值赋给前一个节点
            prev?.next = current?.next
        }
    }

    mutating func reverse() {
        var prev: LinkNode<T>?
        var current = head
        var next: LinkNode<T>?
        while current != nil {
            next = current?.next
            current?.next = prev
            prev = current
            current = next
        }
        head = prev
    }

    var count: Int {
        var num = 0
        var current = head
        while current != nil {
            num += 1
            current = current?.next
        }
        return num
    }
}

extension LinkList: CustomStringConvertible {
    var description: String {
        var description = ""
        var current = head
        while current != nil {
            description += "data: \(String(describing: current!.data)) \n"
            current = current?.next
        }
        return description
    }
}

extension LinkList: ExpressibleByArrayLiteral {
    typealias ArrayLiteralElement = T
    init(arrayLiteral elements: LinkList.ArrayLiteralElement...) {
        self.init(elements)
    }
}

//extension LinkList: Collection {
//    typealias Index = Int
//    var startIndex: Int { return head?.index ?? 0}
//    var endIndex: Int { return tail?.index ?? 0 }
//
//
//}
