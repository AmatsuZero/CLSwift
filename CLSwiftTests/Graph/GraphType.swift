//
//  GraphType.swift
//  CLSwiftTests
//
//  Created by modao on 2018/3/22.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

class BFSQueue<T> {
    private var queue = SingleDirectionLinkList<T>()
    
}

protocol GraphType {

    associatedtype Element
    /**
     根据节点数据以及节点关系来创建图

     - parameter notes:    节点数据
     - parameter relation: 节点关系
     */
    mutating func createGraph<Notes: Collection, Relation: Collection>(notes: Notes, relation: Relation, isDirectional:Bool) where Notes.Iterator.Element == Element, Relation.Iterator.Element == (Element,Element,Int)

    /**
     BFS: 广度优先搜索
     */

    func breadthFirstSearch()

    /**
     DFS: 深度优先搜索
     */
    func depthFirstSearch()

    /**
     输出图的物理存储结构
     */
    func displayGraph()

    /**
     创建最小生成树: Prim
     */
    func createMiniSpanTreePrim()

    /**
     创建最小生成树: Prim
     */
    func createMiniSpanTreeKruskal()

    /**
     层次遍历最小生成树
     */
    func breadthFirstSearchTree()

    /**
     最短路径--迪杰斯特拉算法
     */
    func shortestPathDijkstra(beginIndex: Int, endIndex: Int)
}
