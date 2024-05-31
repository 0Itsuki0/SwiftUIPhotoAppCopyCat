//
//  PHAssetCollection.swift
//  PHAssetDemo
//
//  Created by Itsuki on 2024/05/26.
//

import Photos

class PhotoAssetCollection: RandomAccessCollection {
    private(set) var fetchResult: PHFetchResult<PHAsset>
    private var iteratorIndex: Int = 0
    
    var startIndex: Int { 0 }
    var endIndex: Int { fetchResult.count }
    
    init(_ fetchResult: PHFetchResult<PHAsset>) {
        self.fetchResult = fetchResult
    }

    subscript(position: Int) -> PHAsset {
        return fetchResult.object(at: position)
    }
    
    var phAssets: [PHAsset] {
        var assets = [PHAsset]()
        fetchResult.enumerateObjects { (object, count, stop) in
            assets.append(object)
        }
        return assets
    }
}

extension PhotoAssetCollection: Sequence, IteratorProtocol {

    func next() -> PHAsset? {
        if iteratorIndex >= count {
            return nil
        }
        
        defer {
            iteratorIndex += 1
        }
        
        return self[iteratorIndex]
    }
}


extension PHAsset: Identifiable {
    public var id: String {
        self.localIdentifier
    }
}
