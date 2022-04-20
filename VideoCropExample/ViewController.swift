//
//  ViewController.swift
//  VideoCropExample
//
//  Created by Sunil Chauhan on 20/04/22.
//

import UIKit
import TLPhotoPicker
import Photos

class ViewController: UIViewController {
    enum Error: Swift.Error {
        case couldNotAddMutableTracks
        case couldNotFindVideoTrack
    }

    @IBOutlet var xValueTextField: UITextField!
    @IBOutlet var yValueTextField: UITextField!
    @IBOutlet var wValueTextField: UITextField!
    @IBOutlet var hValueTextField: UITextField!
    @IBOutlet var imageView: UIImageView!

    var asset: AVAsset?

    var photoPicker: TLPhotosPickerViewController?

    private let numberFormatter = NumberFormatter()

    var x: CGFloat {
        guard let xText = xValueTextField.text else { return 0 }
        return CGFloat(numberFormatter.number(from: xText)?.floatValue ?? 0)
    }

    var y: CGFloat {
        guard let yText = yValueTextField.text else { return 0 }
        return CGFloat(numberFormatter.number(from: yText)?.floatValue ?? 0)
    }

    var w: CGFloat {
        guard let wText = wValueTextField.text else { return 0 }
        return CGFloat(numberFormatter.number(from: wText)?.floatValue ?? 0)
    }

    var h: CGFloat {
        guard let hText = hValueTextField.text else { return 0 }
        return CGFloat(numberFormatter.number(from: hText)?.floatValue ?? 0)
    }

    @IBAction func selectVideo() {
        let photoPicker = TLPhotosPickerViewController()
        photoPicker.delegate = self
        self.photoPicker = photoPicker
        self.present(photoPicker, animated: true)
    }

    @IBAction func cropVideo() {
        guard let asset = asset else { return }
        let composition = AVMutableComposition()

        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            return
        }

        let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        if let videoAssetTrack = asset.tracks(withMediaType: .video).first {
            do {
                try videoTrack.insertTimeRange(timeRange, of: videoAssetTrack, at: .zero)
            } catch {
                return
            }
        } else {
            return
        }

        if let audioAssetTrack = asset.tracks(withMediaType: .audio).first {
            do {
                try audioTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: .zero)
            } catch {
                return
            }
        }

        let preset = AVAssetExportPresetMediumQuality
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: preset) else {
            return
        }

        guard var exportURL = cacheDirectoryURL() else {
            return
        }

        /// Prepare Instructions
        let compositionInstructions = AVMutableVideoCompositionInstruction()
        compositionInstructions.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
//        compositionInstructions.timeRange = timeRange

        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
//        let transform = asset.videoTransformation(editingOptions: editingOptions)

        let rotation = asset.getRotation()
        var naturalSize = videoTrack.naturalSize
        //TODO: - Fix the height/width if the `editingOptions` is nil.

        var originalCropFrame = CGRect(x: x, y: y, width: w, height: h)
        print(String(format: "✴️ BCF: (%.2f, %.2f),(%.2f, %.2f). NS: (%.2f, %.2f), ROT: %.2f", originalCropFrame.origin.x, originalCropFrame.origin.y,
                     originalCropFrame.width, originalCropFrame.height, naturalSize.width, naturalSize.height, rotation))
//        cropFrame = cropFrame.applying(videoTrack.preferredTransform)
//        naturalSize = naturalSize.applying(CGAffineTransform(rotationAngle: rotation))
//        naturalSize = CGSize(width: abs(naturalSize.width), height: abs(naturalSize.height))
//        let cropFrame = videoRect(rect: originalCropFrame, size: naturalSize)
//        let cropFrame = originalCropFrame.applying(CGAffineTransform(rotationAngle: rotation))
        let cropFrame = originalCropFrame
        print(String(format: "✴️ ACF: (%.2f, %.2f),(%.2f, %.2f). NS: (%.2f, %.2f), ROT: %.2f", cropFrame.origin.x, cropFrame.origin.y,
                     cropFrame.width, cropFrame.height, naturalSize.width, naturalSize.height, rotation))

        let transform = getTransform(for: videoTrack, cropFrame: cropFrame)
        layerInstructions.setTransform(transform, at: .zero)
//        layerInstructions.setOpacity(1.0, at: CMTime.zero)
        compositionInstructions.layerInstructions = [layerInstructions]

        print("🎬 Original translation: \(videoTrack.preferredTransform.translation), rotation: \(videoTrack.preferredTransform.rotation), scale: \(videoTrack.preferredTransform.scale)")
        print("🎬 new translation: \(transform.translation), rotation: \(transform.rotation), scale: \(transform.scale)")

        /// Add video composition.
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = cropFrame.size
        videoComposition.instructions = [compositionInstructions]
        videoComposition.frameDuration = videoTrack.minFrameDuration

        exportURL.appendPathComponent(UUID().uuidString + ".mp4")
        exportSession.videoComposition = videoComposition
        exportSession.outputURL = exportURL
        exportSession.outputFileType = AVFileType.mov
        exportSession.exportAsynchronously {
            if exportSession.status == .failed {
                print("Failed - \(exportSession.error)")
            } else if exportSession.status == .completed {
                UISaveVideoAtPathToSavedPhotosAlbum(exportURL.path, nil, nil, nil)
            } else {
                print("Failed - Unknown")
            }
        }
    }

    func load(asset: AVAsset) {
        self.asset = asset
    }

    func cacheDirectoryURL() -> URL? {
        if let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
            return URL(fileURLWithPath: path)
        }

        return nil
    }

    func getTransform(for videoTrack: AVAssetTrack, cropFrame: CGRect) -> CGAffineTransform {
        let renderSize = cropFrame.size
        let renderScale = renderSize.width / cropFrame.width
        let offset = CGPoint(x: -cropFrame.origin.x, y: -cropFrame.origin.y)
        let rotation = atan2(videoTrack.preferredTransform.b, videoTrack.preferredTransform.a)

        var rotationOffset = CGPoint(x: 0, y: 0)

        if videoTrack.preferredTransform.b == -1.0 {
            rotationOffset.y = videoTrack.naturalSize.width
        } else if videoTrack.preferredTransform.c == -1.0 {
            rotationOffset.x = videoTrack.naturalSize.height
        } else if videoTrack.preferredTransform.a == -1.0 {
            rotationOffset.x = videoTrack.naturalSize.width
            rotationOffset.y = videoTrack.naturalSize.height
        }

        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: renderScale, y: renderScale)
        transform = transform.translatedBy(x: offset.x + rotationOffset.x, y: offset.y + rotationOffset.y)
        transform = transform.rotated(by: rotation)

        print("track size \(videoTrack.naturalSize)")
        print("preferred Transform = \(videoTrack.preferredTransform)")
        print("rotation angle \(rotation)")
        print("rotation offset \(rotationOffset)")
        print("actual Transform = \(transform)")
        return transform
    }

    func videoRect(rect: CGRect, size: CGSize) -> CGRect {
        return CGRect(x: rect.origin.x, y: size.height - rect.maxY, width: rect.width, height: rect.height)
    }
}
