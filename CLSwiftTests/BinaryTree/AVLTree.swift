//
//  AVLTree.swift
//  CLSwiftTests
//
//  Created by modao on 2018/3/20.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

struct AVLTree<T: Comparable> {
    class AVLTreeNode<T: Comparable> {
        typealias SearchResult = (isFound: Bool, searchNode: AVLTreeNode?, parent: AVLTreeNode?)
        /// 节点携带的数据
        var data: T
        /// 父节点
        var parentNode: AVLTreeNode?
        /// 左节点
        var leftChild: AVLTreeNode?
        /// 右节点
        var rightChild: AVLTreeNode?
        /// 该节点对应树的深度
        var depth: Int {
            if leftChild != nil, rightChild != nil {
                if leftChild!.depth < rightChild!.depth {
                    return rightChild!.depth + 1
                } else {
                    return leftChild!.depth + 1
                }
            } else if leftChild != nil {
                return leftChild!.depth + 1
            } else if rightChild != nil {
                return rightChild!.depth + 1
            }
            return 0
        }
        /// 结点的平衡因子为（平衡二叉树中的平衡因子为-1, 0, 1）
        var balanceFactor: Int {
            if leftChild != nil, rightChild != nil {
                return leftChild!.depth - rightChild!.depth
            } else if leftChild != nil {
                return leftChild!.depth + 1
            } else if rightChild != nil {
                return -rightChild!.depth - 1
            }
            return 0
        }
        init(data: T) {
            self.data = data
        }
        func setNil() {
            leftChild = nil
            rightChild = nil
            parentNode = nil
        }
        class func searchBST(currentRoot: AVLTreeNode?, fatherNode: AVLTreeNode?, data key: T) -> SearchResult {
            // 查找失败，返回该节点的父类节点
            guard let current = currentRoot else {
                return (false, nil, fatherNode)
            }
            // 查找成功，返回成功的节点
            if key == current.data {
                return (true, current, fatherNode)
            } else if key < current.data {//递归左子树
                return searchBST(currentRoot: current.leftChild, fatherNode: current, data: key)
            } else {//递归右子树
                return searchBST(currentRoot: current.rightChild, fatherNode: current, data: key)
            }
        }
    }
    /// 不平衡树的类型
    enum NoBalanceType {
        case LL(AVLTreeNode<T>)
        case LR(AVLTreeNode<T>)
        case RR(AVLTreeNode<T>)
        case RL(AVLTreeNode<T>)
        init?(node: AVLTreeNode<T>) {
            switch node.balanceFactor {
            case 2:// LL或者LR的情况
                let leftChildBalancerFactor = node.leftChild?.balanceFactor
                if leftChildBalancerFactor == 1 {
                    self = .LL(node)
                } else if leftChildBalancerFactor == -1 {
                    self = .LR(node)
                } else {
                    self = .LL(node)// 删除节点时使用
                }
            case -2:
                let rightChildBalancerFactor = node.rightChild?.balanceFactor
                if rightChildBalancerFactor == -1 {
                    self = .RR(node)
                } else if rightChildBalancerFactor == 1 {
                    self = .RL(node)
                } else {
                    self = .RR(node)// 删除节点时使用
                }
            default:
                return nil
            }
        }
        func addjust(rootNode: inout AVLTreeNode<T>?) {
            switch self {
            case .LL(let node):
                let currentLeftChild = node.leftChild
                node.leftChild = currentLeftChild?.rightChild
                currentLeftChild?.rightChild = node
                //获取要调整结点的父节点
                guard let fatherNode = node.parentNode else {
                    rootNode = currentLeftChild
                    node.parentNode = currentLeftChild //更新父节点
                    currentLeftChild?.parentNode = nil
                    return
                }
                if currentLeftChild!.data > fatherNode.data {
                    fatherNode.rightChild = currentLeftChild
                } else {
                    fatherNode.leftChild = currentLeftChild
                }
                //更新父节点
                node.parentNode = currentLeftChild
                currentLeftChild?.parentNode = fatherNode
            case .LR(let node):
                let currentLeftChild = node.leftChild
                node.leftChild = currentLeftChild?.rightChild
                currentLeftChild?.rightChild = currentLeftChild?.rightChild?.leftChild
                node.leftChild?.leftChild = currentLeftChild
                //更新父节点
                currentLeftChild?.parentNode = node.leftChild
                currentLeftChild?.rightChild?.parentNode = currentLeftChild
                node.leftChild?.parentNode = node
                NoBalanceType.LL(node).addjust(rootNode: &rootNode)
            case .RR(let node):
                let currentRightChild = node.rightChild
                node.rightChild = node.leftChild
                currentRightChild?.leftChild = node
                guard let fatherNode = node.parentNode else {
                    rootNode = currentRightChild
                    node.parentNode = currentRightChild//更新父节点
                    currentRightChild?.parentNode = nil
                    return
                }
                if currentRightChild!.data > fatherNode.data {
                    fatherNode.rightChild = currentRightChild
                } else {
                    fatherNode.leftChild = currentRightChild
                }
                //更新父节点
                node.parentNode = currentRightChild
                currentRightChild?.parentNode = fatherNode
            case .RL(let node):
                let currentRightChild = node.rightChild
                node.rightChild = currentRightChild?.leftChild
                currentRightChild?.leftChild = currentRightChild?.leftChild?.rightChild
                node.rightChild?.rightChild = currentRightChild
                // 更新父节点
                currentRightChild?.parentNode = node.rightChild
                currentRightChild?.leftChild?.parentNode = currentRightChild
                node.rightChild?.parentNode = node
                NoBalanceType.RR(node).addjust(rootNode: &rootNode)
            }
        }
    }
    var rootNode: AVLTreeNode<T>?
    init<S: Sequence>(_ sequence: S) where S.Iterator.Element == T {
        for key in sequence {
            append(key)
        }
    }
    init(data: T) {
        rootNode = AVLTreeNode<T>(data: data)
    }
    private mutating func adjust(node: AVLTreeNode<T>) {
        var cursor = node.parentNode
        while cursor != nil {
            let balanceFactor = cursor!.balanceFactor
            if balanceFactor < -1 || balanceFactor > 1 {
                NoBalanceType(node: cursor!)?.addjust(rootNode: &rootNode)
                return
            }
            cursor = cursor?.parentNode
        }
    }
    private mutating func insert(parent: AVLTreeNode<T>?, data key: T) {
        let node = AVLTreeNode<T>(data: key)
        node.parentNode = parent
        guard let fatherNode = parent else {// 创建根节点
            rootNode = node
            return
        }
        if key < fatherNode.data {
            fatherNode.leftChild = node
        } else {
            fatherNode.rightChild = node
        }
        adjust(node: node)
    }
    mutating func append(_ newData: T)  {
        let (isFound, _, father) = AVLTreeNode<T>.searchBST(currentRoot: rootNode, fatherNode: nil, data: newData)
        if !isFound {// 如果没有找到
            insert(parent: father, data: newData)
        }
    }
    mutating func remove(data key: T) {
        let searchResult = AVLTreeNode<T>.searchBST(currentRoot: rootNode, fatherNode: nil, data: key)
        delete(searchResult: searchResult)
    }
    func contain(_ element: T) -> Bool {
        return AVLTreeNode<T>.searchBST(currentRoot: rootNode, fatherNode: nil, data: element).isFound
    }
    private mutating func delete(searchResult: AVLTreeNode<T>.SearchResult) {
        guard let searchNode = searchResult.searchNode else {
            return
        }
        if searchNode.leftChild == nil, searchNode.rightChild == nil {//叶子节点
            deleteNodeHaveZeroOrOneChild(searchResult: searchResult, subNode: nil)
        } else if searchNode.leftChild != nil, searchNode.rightChild == nil {//只有左子树
            deleteNodeHaveZeroOrOneChild(searchResult: searchResult, subNode: searchNode.leftChild)
        } else if searchNode.leftChild == nil, searchNode.rightChild != nil {//只有右子树
            deleteNodeHaveZeroOrOneChild(searchResult: searchResult, subNode: searchNode.rightChild)
        } else {
            deleteNodeHaveTowChild(searchResult: searchResult)
        }
    }
    /// 要删除的节点是叶子节点或者有一个子节点的情况
    private mutating func deleteNodeHaveZeroOrOneChild(searchResult: AVLTreeNode<T>.SearchResult, subNode: AVLTreeNode<T>?) {
        searchResult.searchNode?.setNil() // 将要即将删除的节点的左右孩子的指针清空
        guard let fatherNode = searchResult.parent else {
            rootNode = subNode //更新节点
            subNode?.parentNode = rootNode
            return
        }
        if searchResult.searchNode!.data < fatherNode.data {
            fatherNode.leftChild = subNode //要删除的节点是父节点的左孩子
        } else {
            fatherNode.rightChild = subNode //要删除的节点是父节点的右孩子
        }
        subNode?.parentNode = fatherNode
        NoBalanceType(node: fatherNode)?.addjust(rootNode: &rootNode)
    }
    /// 要删除的结点既有左子树也有右子树
    private mutating func deleteNodeHaveTowChild(searchResult: AVLTreeNode<T>.SearchResult) {
        //初始化存储结果
        var cursorSearchResult: AVLTreeNode<T>.SearchResult = (true, searchResult.searchNode?.rightChild, searchResult.searchNode)
        //寻找删除节点右子树最左边的节点
        while cursorSearchResult.searchNode?.leftChild != nil {
            cursorSearchResult.parent = cursorSearchResult.searchNode
            cursorSearchResult.searchNode = cursorSearchResult.searchNode?.leftChild
        }
        //将右子树最左边的节点的值赋给要删除的节点
        searchResult.searchNode?.data = cursorSearchResult.searchNode!.data
        //删除右子树最左边的节点
        delete(searchResult: cursorSearchResult)
    }
    func forEach(callback:(T) -> Void) {
        inOrderTraverse(node: rootNode, callback: callback)
    }
    /// 中序遍历
    private func inOrderTraverse(node: AVLTreeNode<T>?, callback:(T) -> Void) {
        guard let node = node else {
            return
        }
        inOrderTraverse(node: node.leftChild, callback: callback)
        callback(node.data)
        inOrderTraverse(node: node.rightChild, callback: callback)
    }
    var count: Int {
        var totalCount = 0
        forEach { _ in
            totalCount += 1
        }
        return totalCount
    }
}

extension AVLTree: CustomStringConvertible {
    var description: String {
        var desc = ""
        forEach { value in
            desc += "\(value)\n"
        }
        return desc
    }
}

extension AVLTree: ExpressibleByArrayLiteral {
    typealias ArrayLiteralElement = T
    init(arrayLiteral elements: T...) {
        self.init(elements)
    }
}
