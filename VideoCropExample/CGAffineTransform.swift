//
//  CGAffineTransform.swift
//  VideoCropExample
//
//  Created by Sunil Chauhan on 20/04/22.
//

import CoreGraphics

public extension CGAffineTransform {
    var translation: CGPoint {
        CGPoint(x: tx, y: ty)
    }

    var rotation: CGFloat {
        atan2(b, a)
    }

    var scale: CGFloat {
        sqrt((a * a) + (c * c))
    }
}
