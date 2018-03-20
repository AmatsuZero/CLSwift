//
//  Trigonometric.swift
//  CLSwift
//
//  Created by modao on 2018/3/20.
//  Copyright © 2018年 MockingBot. All rights reserved.
//

import Foundation
import Darwin

extension Double {
    /// 象限角
    var quadrantAngle: Double {
        return (self/180) * .pi
    }

    var quadrantSin: Double {
        return sin(quadrantAngle)
    }

    var quadrantCos: Double {
        return cos(quadrantAngle)
    }

    var quadrantTan: Double {
        return tan(quadrantAngle)
    }

    var quadrantCot: Double {
        return quadrantAngle.acot()
    }

    func acot() -> Double {
        if self > 1.0 {
            return atan(1.0/self)
        } else if self < -1.0 {
            return .pi + atan(1.0/self)
        } else {
            return .pi/2 - atan(self)
        }
    }

    static func acot(_ x: Double) -> Double {
        if x > 1.0 {
            return atan(1.0/x)
        } else if x < -1.0 {
            return .pi + atan(1.0/x)
        } else {
            return .pi/2 - atan(x)
        }
    }
}
