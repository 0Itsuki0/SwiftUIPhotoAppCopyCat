//
//  ThumbnailCollectionView.swift
//  PHAssetDemo
//
//  Created by Itsuki on 2024/05/25.
//

import SwiftUI
import Photos

struct ThumbnailCollectionView: View {
    @EnvironmentObject var photoLibraryManager: PhotoLibraryManager

    private static let itemSpacing = 2.0
    private var thumbnailSize: CGSize = CGSize(width: UIScreen.main.bounds.size.width/3 - Self.itemSpacing, height: UIScreen.main.bounds.size.width/3 - Self.itemSpacing)

    var body: some View {

        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: thumbnailSize.width, maximum: thumbnailSize.width), spacing: Self.itemSpacing)
            ], spacing: Self.itemSpacing) {
                ForEach(photoLibraryManager.photoAssetCollection) { asset in
                    NavigationLink {
                        
                        AssetDisplayView(asset: asset)
                        
                    } label: {
                        ThumbnailItemView(asset: asset, thumbnailSize: thumbnailSize)
                            .onAppear {
                                Task {
                                    await photoLibraryManager.cacheManager.startCaching(for: [asset], targetSize: thumbnailSize)
                                }
                            }
                            .onDisappear {
                                Task {
                                    await photoLibraryManager.cacheManager.stopCaching(for: [asset], targetSize: thumbnailSize)
                                }
                            }

                    }
                }
            }
            .padding(.vertical, Self.itemSpacing)
        }

        
    }

}


fileprivate struct ThumbnailItemView: View {
    @ObservedObject var photoLibraryManager = PhotoLibraryManager()

    var asset: PHAsset
    var thumbnailSize: CGSize
    
    @State private var image: Image?

    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable(resizingMode: .stretch)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: thumbnailSize.width, height: thumbnailSize.height, alignment: .center)
                    .clipped()

            } else {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
        .task {
            guard image == nil else { return }
            do {
                let result = try await photoLibraryManager.cacheManager.requestImage(for: asset, targetSize: thumbnailSize)
                image = result.image
            } catch(let error) {
                print(error)
            }
        }
    }
}

