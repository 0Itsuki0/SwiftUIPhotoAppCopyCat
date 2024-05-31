//
//  CacheManager.swift
//  PHAssetDemo
//
//  Created by Itsuki on 2024/05/25.
//


import UIKit
import Photos
import SwiftUI

actor CachedImageManager {
    
    private let imageManager = PHCachingImageManager()
    
    private var imageContentMode = PHImageContentMode.aspectFit
    
    enum CachedImageError: LocalizedError {
        case error(Error)
        case cancelled
        case failed
    }
    
    private var cachedAssetIdentifiers = [String : Bool]()
    
    private lazy var requestOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        return options
    }()
    
    init() {
        imageManager.allowsCachingHighQualityImages = false
    }
    
    var cachedImageCount: Int {
        cachedAssetIdentifiers.keys.count
    }
    
    func startCaching(for phAssets: [PHAsset], targetSize: CGSize) {
        phAssets.forEach {
            cachedAssetIdentifiers[$0.localIdentifier] = true
        }
        imageManager.startCachingImages(for: phAssets, targetSize: targetSize, contentMode: imageContentMode, options: requestOptions)
    }

    func stopCaching(for phAssets: [PHAsset], targetSize: CGSize) {
        phAssets.forEach {
            cachedAssetIdentifiers.removeValue(forKey: $0.localIdentifier)
        }
        imageManager.stopCachingImages(for: phAssets, targetSize: targetSize, contentMode: imageContentMode, options: requestOptions)
    }
    
    func stopCaching() {
        imageManager.stopCachingImagesForAllAssets()
    }

    
    func requestImage(for phAsset: PHAsset, targetSize: CGSize) async throws -> ImageRequestResult {
        var requestId: PHImageRequestID?
        let (image, info): (UIImage?, [AnyHashable : Any]?) = await withCheckedContinuation { continuation in
            var nillableContinuation: CheckedContinuation<(UIImage?, [AnyHashable : Any]?), Never>? = continuation
            
            requestId = imageManager.requestImage(for: phAsset, targetSize: targetSize, contentMode: imageContentMode, options: requestOptions) { image, info in
                nillableContinuation?.resume(returning: (image, info))
                nillableContinuation = nil

            }
        }
        
        if let error = info?[PHImageErrorKey] as? Error {
            print("CachedImageManager requestImage error: \(error.localizedDescription)")
            throw CachedImageError.error(error)
        } else if let cancelled = (info?[PHImageCancelledKey] as? NSNumber)?.boolValue, cancelled {
            print("CachedImageManager request canceled")
            throw CachedImageError.cancelled
        } 
        
        if let image = image {
            let isLowerQualityImage = (info?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false
            let result = ImageRequestResult(requestId: requestId, image: Image(uiImage: image), isLowerQuality: isLowerQualityImage)
            return result

        } else {
            throw CachedImageError.failed
        }
    }
    
    func requestImageData(for phAsset: PHAsset) async throws -> ImageDataRequestResult  {
        var requestId: PHImageRequestID?
        let (imageData, dataUTI, _, info): (Data?, String?, CGImagePropertyOrientation, [AnyHashable : Any]?) = await withCheckedContinuation { continuation in
            var nillableContinuation: CheckedContinuation<(Data?, String?, CGImagePropertyOrientation, [AnyHashable : Any]?), Never>? = continuation
            requestId = imageManager.requestImageDataAndOrientation(for: phAsset, options: nil) { imageData, dataUTI, orientation, info in
                nillableContinuation?.resume(returning: (imageData, dataUTI, orientation, info))
                nillableContinuation = nil

            }
        }
        
        print(dataUTI ?? "uniform type identifiers not available")
        
        if let error = info?[PHImageErrorKey] as? Error {
            print("CachedImageManager requestImage error: \(error.localizedDescription)")
            throw CachedImageError.error(error)
        } else if let cancelled = (info?[PHImageCancelledKey] as? NSNumber)?.boolValue, cancelled {
            print("CachedImageManager request canceled")
            throw CachedImageError.cancelled
        }
        
        if let data = imageData {
            let result = ImageDataRequestResult(requestId: requestId, dataUTI: dataUTI, imageData: data)
            return result

        } else {
            throw CachedImageError.failed
        }
    }
    
    
    func requestVideoPlayback(for phAsset: PHAsset) async throws -> VideoPlaybackRequestResult {
        var requestId: PHImageRequestID?
        
        let (playerItem, info): (AVPlayerItem?, [AnyHashable : Any]?) = await withCheckedContinuation { continuation in
            var nillableContinuation: CheckedContinuation<(AVPlayerItem?, [AnyHashable : Any]?), Never>? = continuation
            
            let option = PHVideoRequestOptions()
            option.deliveryMode = .highQualityFormat
            requestId = imageManager.requestPlayerItem(forVideo: phAsset, options: option) { playerItem, info in
                nillableContinuation?.resume(returning: (playerItem, info))
                nillableContinuation = nil
            }
        }
        
        if let error = info?[PHImageErrorKey] as? Error {
            print("CachedImageManager requestImage error: \(error.localizedDescription)")
            throw CachedImageError.error(error)
        } else if let cancelled = (info?[PHImageCancelledKey] as? NSNumber)?.boolValue, cancelled {
            print("CachedImageManager request canceled")
            throw CachedImageError.cancelled
        }
        
        if let playerItem = playerItem {
            let result = VideoPlaybackRequestResult(requestId: requestId, playerItem: playerItem)
            return result

        } else {
            throw CachedImageError.failed
        }
    }
    
    
    func cancelImageRequest(for requestID: PHImageRequestID) {
        imageManager.cancelImageRequest(requestID)
    }    
}
