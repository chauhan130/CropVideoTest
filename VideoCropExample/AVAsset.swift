//
//  AVAsset.swift
//  VideoCropExample
//
//  Created by Sunil Chauhan on 20/04/22.
//

import Foundation
import AVFoundation

extension AVAsset {
    func videoTransformation(rect: CGRect?) -> CGAffineTransform {
        guard let videoTrack = tracks(withMediaType: .video).first else {
            return .identity
        }

        let size = videoTrack.naturalSize
        let cropRect = rect ?? .zero
        let transformation = videoTrack.preferredTransform
        if size.width == transformation.tx && size.height == transformation.ty {
            /// Left
            return CGAffineTransform(translationX: videoTrack.naturalSize.width - cropRect.origin.x,
                                     y: videoTrack.naturalSize.height - cropRect.origin.y)
            .rotated(by: Double.pi)
        } else if transformation.tx == 0 && transformation.ty == 0 {
            /// Right
            return CGAffineTransform(translationX: 0 - cropRect.origin.x, y: 0 - cropRect.origin.y)
                .rotated(by: 0)
        } else if transformation.tx == 0 && transformation.ty == size.width {
            /// Down
            return CGAffineTransform(translationX: 0 - cropRect.origin.x, y: size.width - cropRect.origin.y)
                .rotated(by: -Double.pi / 2)
        } else {
            /// Up
            return CGAffineTransform(translationX: size.height - cropRect.origin.x, y: 0 - cropRect.origin.y)
                .rotated(by: -Double.pi / 2)
        }
    }

    func getRotation() -> CGFloat {
        guard let videoTrack = tracks(withMediaType: .video).first else {
            return 0
        }

        let size = videoTrack.naturalSize
        let transformation = videoTrack.preferredTransform
        if size.width == transformation.tx && size.height == transformation.ty {
            /// Left
            return Double.pi
        } else if transformation.tx == 0 && transformation.ty == 0 {
            /// Right
            return 0
        } else if transformation.tx == 0 && transformation.ty == size.width {
            /// Down
            return -Double.pi / 2
        } else {
            /// Up
            return -Double.pi / 2
        }
    }
}

