//
//  CLEvent.swift
//  CLSwift
//
//  Created by modao on 2018/3/5.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation

public class CLEvent {
    let event: cl_event
    init(event: cl_event) {
        self.event = event
    }
}
