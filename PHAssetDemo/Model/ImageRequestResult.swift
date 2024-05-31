//
//  ImageRequestResult.swift
//  PHAssetDemo
//
//  Created by Itsuki on 2024/05/26.
//

import SwiftUI
import Photos

struct ImageRequestResult {
    var requestId: PHImageRequestID?
    var image: Image?
    var isLowerQuality: Bool
}
