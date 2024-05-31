//
//  PhotoView.swift
//  PHAssetDemo
//
//  Created by Itsuki on 2024/05/26.
//

import SwiftUI
import Photos

struct PhotoView: View {
    @EnvironmentObject var photoLibraryManager: PhotoLibraryManager

    var asset: PHAsset
    @Binding var saveData: () async -> Void

    
    @State private var image: Image?


    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                let result = try await photoLibraryManager.cacheManager.requestImageData(for: asset)
                guard let uiImage = result.uiImage else {return}
                image = Image(uiImage: uiImage)
                saveData = {
                    do {
                       try await photoLibraryManager.createAsset(data: result.imageData, type: .photo)
                    } catch(let error) {
                        print(error)
                    }
                }
                
            } catch(let error) {
                print(error)
            }
        }
    }
}
