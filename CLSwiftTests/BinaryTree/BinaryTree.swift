//
//  BinaryTree.swift
//  CLSwiftTests
//
//  Created by modao on 2018/3/21.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

struct BinaryTree<T: CustomDebugStringConvertible> {
    class BinaryTreeNode<T: CustomDebugStringConvertible> {
        let data: T?
        var leftChild: BinaryTreeNode?
        var rightChild: BinaryTreeNode?
        ///true - 指向左子树， false-指向前驱
        var leftTag = true
        ///true - 指向右子树， false-指向后继
        var rightTag = true

        init(data: T?) {
            self.data = data
        }
    }
    private(set) var rootNode: BinaryTreeNode<T>?
    private(set) var preNode: BinaryTreeNode<T>?
    private(set) var headNode: BinaryTreeNode<T>?
    private(set) var index = -1

    init(items: [T?])  {
        rootNode = buildTree(items: items)
        headNode = BinaryTreeNode(data: nil)
        headNode?.leftChild = rootNode
        headNode?.leftTag = true
        preNode = headNode
    }

    private mutating func buildTree(items: [T?]) -> BinaryTreeNode<T>? {
        index += 1
        if index < items.count, index >= 0 {
            guard let item = items[index] else {
                return nil
            }
            let node = BinaryTreeNode(data: item)
            node.leftChild = buildTree(items: items)
            node.rightChild = buildTree(items: items)
            return node
        }
        return nil
    }

    func forEach(callback: (T?) -> Void) {
        preorderTraverse(rootNode, callback: callback)
    }

    private func preorderTraverse(_ node: BinaryTreeNode<T>?, callback: (T?) -> Void) {
        guard let node = node else { return }
        callback(node.data)
        if node.leftTag {
            preorderTraverse(node.leftChild, callback: callback)
        }
        if node.rightTag {
            preorderTraverse(node.rightChild, callback: callback)
        }
    }

    func threaded() -> BinaryTree<T> {
        var copyTree = self
        copyTree.inThreading(copyTree.rootNode)
        return copyTree
    }

    mutating func thread() {
        inThreading(rootNode)
    }

    private mutating func inThreading(_ element: BinaryTreeNode<T>?) {
        guard let node = element else {
            return
        }
        inThreading(node.leftChild)
        //如果节点的左节点为nil
        if node.leftChild == nil {
            node.leftTag = false
            node.leftChild = preNode
        }
        if preNode?.rightChild == nil {
            preNode?.rightTag = false
            preNode?.rightChild = node
        }
        preNode = node
        inThreading(node.rightChild)
    }
}

extension BinaryTree: CustomDebugStringConvertible {
    var debugDescription: String {
        var desc = "先序遍历: \n"
        forEach { value in
            desc += "\(value.debugDescription) \n"
        }
        return desc
    }
}
