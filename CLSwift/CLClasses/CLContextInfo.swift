//
// Created by modao on 2018/2/28.
// Copyright (c) 2018 MockingBot. All rights reserved.
//

import Foundation

public struct CLContextInfo {

    public private(set) var devices: [CLDevice]?
    public let properties: [cl_context_properties]?

    init(context ctx: cl_context,
         devices: [CLDevice]? = nil,
         properties: [cl_context_properties]?) throws {
        self.properties = properties
        if devices == nil {
            var actualSize = 0
            let code = clGetContextInfo(ctx, cl_context_info(CL_CONTEXT_DEVICES), Int.max, nil, &actualSize)
            guard code == CL_SUCCESS else {
                throw contextError(code)
            }
            guard actualSize > 0 else {
                return
            }
            let count = actualSize/MemoryLayout<cl_device_id>.stride
            var deviceIds: [cl_device_id?] = Array(repeating: nil, count: count)
            clGetContextInfo(ctx, cl_context_info(CL_CONTEXT_DEVICES), actualSize, &deviceIds, nil)
            self.devices = deviceIds.map {
                CLDevice(deviceId: $0)
            }
        }
    }
}
