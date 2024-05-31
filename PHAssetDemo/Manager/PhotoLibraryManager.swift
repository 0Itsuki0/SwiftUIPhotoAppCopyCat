//
//  PhotoLibraryManager.swift
//  PHAssetDemo
//
//  Created by Itsuki on 2024/05/25.
//


import Photos

class PhotoLibraryManager: NSObject, ObservableObject {
    
    @Published var photoAssetCollection: PhotoAssetCollection = PhotoAssetCollection(PHFetchResult<PHAsset>())

    let cacheManager = CachedImageManager()
    
    enum PhotoLibraryError: LocalizedError {
        case error(Error)
        case cancelled
        case failed
    }

    override init() {
        super.init()
        Task {
            let isAuthorized = await checkAuthorization()
            if (!isAuthorized) {
                return
            }
            PHPhotoLibrary.shared().register(self)
            await refreshPhotoAssets()
        }
    }
    
    private func checkAuthorization() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized:
            print("Photo library access authorized.")
            return true
        case .notDetermined:
            print("Photo library access not determined.")
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite) == .authorized
        case .denied:
            print("Photo library access denied.")
            return false
        case .limited:
            print("Photo library access limited.")
            return false
        case .restricted:
            print("Photo library access restricted.")
            return false
        @unknown default:
            return false
        }
    }
    
    private func refreshPhotoAssets(_ fetchResult: PHFetchResult<PHAsset>? = nil) async {

        var newFetchResult = fetchResult

        if newFetchResult == nil {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            if let fetchResult = (PHAsset.fetchAssets(with: fetchOptions) as AnyObject?) as? PHFetchResult<PHAsset> {
                newFetchResult = fetchResult
            }
        }
        
        if let newFetchResult = newFetchResult {
            await MainActor.run {
                self.photoAssetCollection = PhotoAssetCollection(newFetchResult)
            }
        }
    }
    
    
    func deleteAsset(_ asset: PHAsset) async throws {
        if !asset.canPerform(.delete) {
            print("not able to delete asset")
            throw PhotoLibraryError.failed
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets([asset] as NSArray)
            }
            print("PhotoAsset asset deleted")
        } catch (let error) {
            print("Failed to delete photo: \(error.localizedDescription)")
            throw PhotoLibraryError.failed
        }
    }
    
    
    func setIsFavorite(for asset: PHAsset, _ isFavorite: Bool) async throws{
        if !asset.canPerform(.properties) {
            print("not able to edit asset property")
            throw PhotoLibraryError.failed
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest(for: asset)
                request.isFavorite = isFavorite
            }
        } catch (let error) {
            print("Failed to change isFavorite: \(error.localizedDescription)")
            throw PhotoLibraryError.failed

        }
    }
    
    
    func createAsset(data: Data, type: PHAssetResourceType) async throws {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: type, data: data, options: nil)
            }
        } catch (let error) {
            print("Failed to create asset: \(error.localizedDescription)")
            throw PhotoLibraryError.failed
        }
    }
    
    func createAsset(asset: AVAsset?) async throws {
        guard let asset = asset else {
            throw PhotoLibraryError.failed
        }
        let urlAsset = asset as! AVURLAsset

        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .video, fileURL: urlAsset.url, options: nil)
            }
        } catch (let error) {
            print("Failed to create asset: \(error.localizedDescription)")
            throw PhotoLibraryError.failed

        }

    }
    
    
    // image editing
    func requestContentEditingInput(for phAsset: PHAsset) async throws -> ContentEditInputRequest {
        let option = PHContentEditingInputRequestOptions()
        option.canHandleAdjustmentData = { _ in
            // true for enabling rolling back to a previous version made elsewhere
//            return true
            return false
        }
        var requestId: PHContentEditingInputRequestID?
        
        let (contentEditingInput, info): (PHContentEditingInput?, [AnyHashable : Any]?) = await withCheckedContinuation { continuation in
            var nillableContinuation: CheckedContinuation<(PHContentEditingInput?, [AnyHashable : Any]?), Never>? = continuation

            requestId = phAsset.requestContentEditingInput(with: option) { contentEditingInput, info in
                nillableContinuation?.resume(returning: (contentEditingInput, info))
                nillableContinuation = nil
            }
        }
        
        if let error = info?[PHContentEditingInputErrorKey] as? Error {
            print("PhotoLibraryError request edit error: \(error.localizedDescription)")
            throw PhotoLibraryError.error(error)
        } else if let cancelled = (info?[PHContentEditingInputCancelledKey] as? NSNumber)?.boolValue, cancelled {
            print("PhotoLibraryError request canceled")
            throw PhotoLibraryError.cancelled
        }
        
        if let contentEditingInput = contentEditingInput {
            return ContentEditInputRequest(
                requestId: requestId,
                contentEditingInput: contentEditingInput
            )
        } else {
            throw PhotoLibraryError.failed
        }
        
    }
    
    func saveEditContent(for asset: PHAsset, contentEditingInput: PHContentEditingInput, with adjustment: PHAdjustmentData) async throws{
        let editingOutput = PHContentEditingOutput(contentEditingInput: contentEditingInput)
        editingOutput.adjustmentData = adjustment
        
        do {
            let url = editingOutput.renderedContentURL
            let data = adjustment.data
            try data.write(to: url)

            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest(for: asset)
                request.contentEditingOutput = editingOutput
            }
                        
        } catch (let error) {
            print("Failed to create asset: \(error.localizedDescription)")
            throw PhotoLibraryError.failed
        }
    }
    
}

extension PhotoLibraryManager: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            guard let changes = changeInstance.changeDetails(for: self.photoAssetCollection.fetchResult) else { return }
            await self.refreshPhotoAssets(changes.fetchResultAfterChanges)
        }
    }
}



