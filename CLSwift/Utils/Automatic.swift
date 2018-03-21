//
//  Automatic.swift
//  CLSwift
//
//  Created by modao on 2018/3/21.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

class Atomic<T>{
    private let semaphore = DispatchSemaphore(value: 1)
    private var _value: T
    var value: T {
        get {
            wait()
            let result = _value
            defer {
                signal()
            }
            return result
        }
        set (value) {
            wait()
            _value = value
            defer {
                signal()
            }
        }
    }
    func set(closure: (_ currentValue: T) -> (T)) {
        wait()
        _value = closure(_value)
        signal()
    }
    func get(closure: (_ currentValue: T) -> ()) {
        wait()
        closure(_value)
        signal()
    }
    private func wait() {
        semaphore.wait()
    }
    private func signal() {
        semaphore.signal()
    }
    init (value: T) {
        _value = value
    }
}
