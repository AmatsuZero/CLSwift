//
//  Leetcode.swift
//  CLSwiftTests
//
//  Created by modao on 2018/3/23.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import XCTest

class Leetcode: XCTestCase {

    func testLeetCode() {
        let given = [2, 7, 11, 15]
        let val = 9
        XCTAssert(twoSum(given, val) == [0,1])
    }

    func removeElement(_ nums: inout [Int], _ val: Int) -> Int {
        if let index = nums.index(where: { $0 == val }) {
            nums.remove(at: index)
        } else {
            return nums.count
        }
        return removeElement(&nums, val)
    }

    func twoSum(_ nums: [Int], _ target: Int) -> [Int] {
        var i = 0
        var j = 0
        for out in 0..<nums.count-1 {
            i = out
            for inside in out+1..<nums.count {
                j = inside
                if nums[out] + nums[inside] == target {
                     return [i, j]
                }
            }
        }
        return [i, j]
    }
}
