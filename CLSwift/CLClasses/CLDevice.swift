//
//  CLDevice.swift
//  OpenCLStudy
//
//  Created by modao on 2018/2/27.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

internal let deviceError: (cl_int) -> NSError = { errType -> NSError in
    var message = ""
    switch errType {
    case CL_INVALID_PLATFORM:
        message = "platform is not a valid platform"
    case CL_INVALID_DEVICE_TYPE:
        message = "device_type is not a valid value"
    case CL_INVALID_VALUE:
        message = "num_entries is equal to zero and devices is not NULL or if both num_devices and devices are NULL"
    case CL_DEVICE_NOT_FOUND:
        message = "no OpenCL devices that matched device_type were found"
    case CL_OUT_OF_RESOURCES:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the device"
    case CL_OUT_OF_HOST_MEMORY:
        message = "there is a failure to allocate resources required by the OpenCL implementation on the host"
    default:
        message = "Unknown error"
    }
    return NSError(domain: "com.daubert.OpenCL.Device", code: Int(errType), userInfo: [NSLocalizedDescriptionKey: message])
}

public final class CLDevice {

    internal let deviceId: cl_device_id?
    public lazy var info: CLDeviceInfo? = {
        return try? CLDeviceInfo(device: deviceId, infoTypes: types)
    }()

    public let types: [CLDeviceInfoType]
    public lazy var deviceType: CLDeviceType? = {
        return try! CLDeviceInfo(device: deviceId, infoTypes: [.DEVICE_TYPE]).deviceType
    }()

    public init(deviceId: cl_device_id?,
                infoTypes: [CLDeviceInfoType]) {
        self.deviceId = deviceId
        types = infoTypes
    }

    func info(types: [CLDeviceInfoType]) throws -> CLDeviceInfo  {
        return try CLDeviceInfo(device: deviceId, infoTypes: types)
    }

    deinit {
        clReleaseDevice(deviceId)
    }
}
