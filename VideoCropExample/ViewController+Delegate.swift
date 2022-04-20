//
//  ViewController+Delegate.swift
//  VideoCropExample
//
//  Created by Sunil Chauhan on 20/04/22.
//

import UIKit
import TLPhotoPicker
import Photos

extension ViewController: TLPhotosPickerViewControllerDelegate {
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        guard let phAsset = withTLPHAssets.first?.phAsset else {
            print("Nothing selected.")
            return
        }

        PHCachingImageManager().requestImage(for: phAsset, targetSize: CGSize(width: phAsset.pixelWidth, height: phAsset.pixelHeight), contentMode: .aspectFit, options: nil) { (image, _) in
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }

        PHImageManager().requestAVAsset(forVideo: phAsset, options: nil) { (asset, nil, _) in
            if let asset = asset {
                self.load(asset: asset)
            }
        }
    }

    func photoPickerDidCancel() {
        print("photoPickerDidCancel.")
    }

    func canSelectAsset(phAsset: PHAsset) -> Bool {
        true
    }

    func handleNoAlbumPermissions(picker: TLPhotosPickerViewController) {
        print("Handle No Album Permissions")
    }

    func handleNoCameraPermissions(picker: TLPhotosPickerViewController) {
        print("Handle Camera Permission.")
    }
}
