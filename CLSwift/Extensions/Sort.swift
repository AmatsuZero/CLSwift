//
//  Sort.swift
//  CLSwift
//
//  Created by modao on 2018/3/11.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

public extension Array where Element: Comparable {
    
    mutating func bubbleSort(isAscend: Bool = true) {
        guard count > 1 else { return }
        var low = 0
        var high = count - 1
        while low < high {
            for j in low..<high {//正向冒泡，找最大者
                if self[j] > self[j+1] {
                    swapAt(j, j+1)
                }
                high -= 1 //修改high值，前移一位
                //反向冒泡，找最小者
                for i in stride(from: high, to: low, by: -1) where self[i] < self[i-1] {
                    swapAt(i, i-1)
                }
                low += 1 //修改low值，后移一位
            }
        }
        if !isAscend { reverse() }
    }

    mutating func selectionSort(isAscend: Bool = true) {
        guard count > 1 else { return }
        var minIndex = 0
        for i in 0..<count-1 {
            minIndex = i
            for j in i+1..<count where self[j] < self[minIndex] {//寻找最小的数
                minIndex = j //将最小的数的索引保存
            }
            swapAt(i, minIndex)
        }
        if !isAscend { reverse() }
    }

    mutating func binaryInsertionSort(isAscend: Bool = true) {
        guard count > 1 else { return }
        for i in 1..<count {
            var (key, left ,right) = (self[i], 0, i-1)
            while left <= right {
                let middle = (left+right)/2
                if key < self[middle] {
                    right = middle - 1
                } else {
                    left = middle + 1
                }
            }
            for j in stride(from: i-1, through: left, by: -1) {
                self[j+1] = self[j]
            }
            self[left] = key
        }
        if !isAscend { reverse() }
    }

    mutating func shellSort(isAscend: Bool = true) {
        guard count > 1 else { return }
        var gap = 1
        while gap < count/5 {
            gap = gap*5+1 //动态定义间隔序列
        }
        var temp = first!
        repeat {
            for i in gap..<count {
                temp = self[i]
                var lastIndex = 0
                for j in stride(from: i-gap, through: 0, by: gap) where self[j] > temp {
                    self[j+gap] = self[j]
                    lastIndex = j
                }
                self[lastIndex+gap] = temp
            }
            gap /= 5
        } while gap > 0
        if !isAscend { reverse() }
    }

    mutating func mergeSort(isAscend: Bool = true) {
        self = self.mergeSort()
        if !isAscend { reverse() }
    }

    func mergeSort() -> [Element] {
        guard count >= 2 else { return self }
        let middle = count/2
        let left = Array(self[..<middle])
        let right = Array(self[middle...])
        return left.mergeSort().merge(with: right.mergeSort())
    }

    func merge(with rhs: [Element]) -> [Element] {
        var left = self
        var right = rhs
        var result = [Element]()
        while left.count > 0, right.count > 0 {
            if left.first! <= right.first! {
                result.append(left.removeFirst())
            } else {
                result.append(right.removeFirst())
            }
        }
        result.append(contentsOf: left)
        result.append(contentsOf: right)
        return result
    }

    mutating func merge(with rhs: [Element]) {
        self = merge(with: rhs)
    }

    fileprivate mutating func partition(low: Int, high: Int) -> Int {
        let privotKey = self[low]// 基准元素
        var (left, right) = (low, high)
        while left < right {//从数组两端交替地向中间扫描
            //从high所指向的位置向前搜索，至多到low+1，将比基准小的元素交换到low
            while left < right, self[right] >= privotKey {
                right -= 1
            }
            swapAt(left, right)
            while left < right, self[left] <= privotKey {
                left += 1
            }
            swapAt(left, right)
        }
        return left
    }

    private mutating func _quickSort(low: Int, high: Int) {
        guard low < high else { return }
        let mid = self.partition(low: low, high: high)
        _quickSort(low: low, high: mid-1)
        _quickSort(low: mid+1, high: high)
    }

    mutating func quickSort(isAscend: Bool = true) {
        guard count > 1 else { return }
        _quickSort(low: 0, high: count-1)
        if !isAscend { reverse() }
    }

    ///对大顶堆的局部进行调整，使其该节点符合大顶堆的特点
    fileprivate mutating func heapAdjust(startIndex: Int, endIndex: Int) {
        let temp = self[startIndex]
        var fatherIndex = startIndex+1 // 父节点下标
        var maxChildrenIndex = 2*fatherIndex //左孩子下标
        while maxChildrenIndex <= endIndex {
            //比较左右孩子并找出比较大的下标
            if maxChildrenIndex < endIndex, self[maxChildrenIndex-1] < self[maxChildrenIndex] {
                maxChildrenIndex += 1
            }
            //如果较大的那个节点比根节点大，就将该节点的值赋给父节点
            guard temp >= self[maxChildrenIndex-1] else { break }
            self[fatherIndex-1] = self[maxChildrenIndex-1]
            fatherIndex = maxChildrenIndex
            maxChildrenIndex = 2*fatherIndex
        }
        self[fatherIndex-1] = temp
    }

    ///构建大顶堆的层次遍历数组 （f(i) > f(2i), f(i) > f(2i+1), i > 0）
    fileprivate mutating func heapCreate() {
        for i in stride(from: count, to: 0, by: -1) {
            heapAdjust(startIndex: i-1, endIndex: count)
        }
    }

    mutating func heapSort(isAscend: Bool = true) {
        guard count > 1 else { return }
        //创建大顶堆， 其实就是数组转换成大顶堆层次的遍历结果
        heapCreate()
        for i in (0..<count).reversed() {
            //将大顶堆的定点（最大的那个值）与大顶堆的最后一个元素进行交换
            swapAt(0, i)
            //对交换后的大顶堆进行调整，使其成为大顶堆
            heapAdjust(startIndex: 0, endIndex: i)
        }
        if !isAscend { reverse() }
    }
}

public extension Array where Element == Int {
    /// 桶排序
    /// 适用于: 1）数据范围较小，建议在小于1000； 2）每个数值都要大于等于0
    mutating func bucketSort(isAscend: Bool = true) {
        guard count > 1, let maxLength = index(of: self.max()!)?.distance(to: self.startIndex).digitCount else { return }
        let fetchBaseNumer: (Int, Int) -> Int = { number, digit -> Int in
            guard digit > 0, digit <= number.digitCount else {
                return 0
            }
            return "\(number)".map { Int("\($0)") }[number.digitCount - digit]!
        }
        var bucket =  [[Int]](repeating: [Int](), count: 10)
        for digit in 1...maxLength {
            //入桶
            forEach { element in
                let baseNum = fetchBaseNumer(element, digit)
                bucket[baseNum].append(element)
            }
            //出桶
            var index = 0
            for i in 0..<bucket.count where !bucket[i].isEmpty {
                self[index] = bucket[i].removeFirst()
                index += 1
            }
        }
        if !isAscend { reverse() }
    }
}

public extension Int {
    /// returns number of digits in Int number
    public var digitCount: Int {
        get {
            return numberOfDigits(in: self)
        }
    }
    /// returns number of useful digits in Int number
    public var usefulDigitCount: Int {
        get {
            var count = 0
            for digitOrder in 0..<self.digitCount {
                /// get each order digit from self
                let digit = self % (Int(truncating: pow(10, digitOrder + 1) as NSDecimalNumber))
                    / Int(truncating: pow(10, digitOrder) as NSDecimalNumber)
                if isUseful(digit) { count += 1 }
            }
            return count
        }
    }
    // private recursive method for counting digits
    private func numberOfDigits(in number: Int) -> Int {
        if abs(number) < 10 {
            return 1
        } else {
            return 1 + numberOfDigits(in: number/10)
        }
    }
    // returns true if digit is useful in respect to self
    private func isUseful(_ digit: Int) -> Bool {
        return (digit != 0) && (self % digit == 0)
    }
}
