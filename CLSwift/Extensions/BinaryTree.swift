//
//  BinaryTree.swift
//  CLSwift
//
//  Created by modao on 2018/3/11.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

class BinaryNode<T: Comparable> {
    var left: BinaryNode<T>?
    var right: BinaryNode<T>?
    let data: T
    init(data: T) {
        self.data = data
    }
}

extension Array {

}
