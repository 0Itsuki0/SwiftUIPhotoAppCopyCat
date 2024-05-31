//
//  ImageDataRequestResult.swift
//  PHAssetDemo
//
//  Created by Itsuki on 2024/05/26.
//

import Photos
import UIKit

struct ImageDataRequestResult {
    var requestId: PHImageRequestID?
    var uiImage: UIImage?
    var imageData: Data
    var dataUTI: String?

    init(requestId: PHImageRequestID?, dataUTI: String?, imageData: Data) {
        self.imageData = imageData
        self.dataUTI = dataUTI
        self.uiImage = UIImage(data: imageData)
    }
}
