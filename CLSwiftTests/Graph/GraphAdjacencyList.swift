//
//  GraphAdjacencyList.swift
//  CLSwiftTests
//
//  Created by modao on 2018/3/22.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

struct GraphAdjacencyList<T: Hashable>: GraphType {
    private var relation = [(T,T,Int)]()
    private var graph = [GraphAdjacencyListNode<T>]()
    private var minTree = [GraphAdjacencyListNode<T>]()
    private var relationDic = [T: Int]()
    private var bfsQueue = [T]()

    mutating func createGraph<Notes, Relation>(notes: Notes, relation: Relation, isDirectional:Bool) where Notes : Collection, Relation : Collection, GraphAdjacencyList.Element == Notes.Element, Relation.Element == (GraphAdjacencyList.Element, GraphAdjacencyList.Element, Int) {
        self.relation = relation.map { $0 }
        for (key, item) in notes.enumerated() {
            let node = GraphAdjacencyListNode<T>(data: item)
            graph.append(node)
            relationDic[item] = key
        }
        for item in relation {
            guard let i = relationDic[item.0], let j = relationDic[item.1] else {
                continue
            }
            let weight = item.2
            let newNode = GraphAdjacencyListNode(data: item.1, weight: weight, preNodeIndex: i)
            newNode.next = graph[i].next
            graph[i].next = newNode
            //无向图
            if !isDirectional {
                let node = GraphAdjacencyListNode<T>(data: item.0, weight: weight, preNodeIndex: j)
                node.next = graph[j].next
                graph[j].next = node
            }
        }
    }

    func breadthFirstSearch() {

    }

    func depthFirstSearch() {

    }

    func displayGraph() {

    }

    func createMiniSpanTreePrim() {

    }

    func createMiniSpanTreeKruskal() {

    }

    func breadthFirstSearchTree() {

    }

    func shortestPathDijkstra(beginIndex: Int, endIndex: Int) {

    }


    typealias Element = T
    class GraphAdjacencyListNode<T> {
        var data: T?
        /// 权值，最小生成树使用
        var weight: Int
        ///最小生成树使用, 记录该节点挂在那个链上
        var preNodeIndex: Int
        var next: GraphAdjacencyListNode?
        var isVisited = false

        init(data: T? = nil, weight: Int = 0, preNodeIndex: Int = 0) {
            self.data = data
            self.weight = weight
            self.preNodeIndex = preNodeIndex
        }
    }


}
