//
//  CLOranganizer.swift
//  CLSwift
//
//  Created by modao on 2018/2/28.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import OpenCL

public final class CLOrganizer {
    
    private let platform_ids: [cl_platform_id?]
    let platformInfoTypes: Set<CLPlatformInfoType>
    public lazy var platforms: [CLPlatform] = {
        return platform_ids
            .map { CLPlatform(platformId: $0, platformInfoTypes: platformInfoTypes) }
    }()
    
    public init(num_entries: cl_uint = 0,
                infoTypes: Set<CLPlatformInfoType> = CLPlatformInfoType.ALL) throws {
        var numEntries = num_entries
        var num_platforms = numEntries
        let code = clGetPlatformIDs(num_entries, nil, &num_platforms)
        guard code == CL_SUCCESS else {
            throw platformError(code)
        }
        if num_entries == 0 {
            numEntries = num_platforms
        }
        var platforms: [cl_platform_id?] = Array(repeating: nil, count: Int(numEntries))
        clGetPlatformIDs(numEntries, &platforms, nil)
        platform_ids = platforms
        self.platformInfoTypes = infoTypes
    }

}
