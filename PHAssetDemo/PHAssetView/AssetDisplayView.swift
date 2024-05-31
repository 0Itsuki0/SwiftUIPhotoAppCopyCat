//
//  PhotoView.swift
//  PHAssetDemo
//
//  Created by Itsuki on 2024/05/26.
//

import SwiftUI
import Photos

struct AssetDisplayView: View {
    
    @EnvironmentObject var photoLibraryManager: PhotoLibraryManager
    @Environment(\.dismiss) var dismiss

    var asset: PHAsset
    @State var saveData: () async -> Void = {}
        
    var body: some View {
        
        VStack(spacing: 0) {
            HStack(spacing: 30) {
                Button(action: {
                    dismiss()
                }, label: {
                    Text("back")
                })
                Spacer()
                
                Button(action: {
                    Task {
                        await saveData()
                    }
                }, label: {
                    Text("Duplicate")
                })
                
                if asset.playbackStyle == .image {
                    NavigationLink {
                        AssetEditView(asset: asset)
                    } label: {
                        Text("Edit")
                    }
                }

                Button(action: {
                    Task {
                        do {
                            try await photoLibraryManager.setIsFavorite(for: asset, !asset.isFavorite)
                        } catch(let error) {
                            print(error)
                        }
                    }
                }, label: {
                    Image(systemName: asset.isFavorite ? "heart.fill" : "heart")
                })
                
                Button(action: {
                    Task {
                        Task {
                            do {
                                try await photoLibraryManager.deleteAsset(asset)
                                DispatchQueue.main.async {
                                    dismiss()
                                }
                            } catch(let error) {
                                print(error)
                            }
                        }

                    }
                }, label: {
                    Image(systemName: "trash")
                })
            }
            .foregroundStyle(.white)
            .padding(.all, 20)
            .frame(height: 50)
            .background(.gray.opacity(0.3))
            .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                switch asset.playbackStyle {

                case .image:
                    PhotoView(asset: asset, saveData: $saveData)
                case .video:
                    VideoView(asset: asset, saveData: $saveData)
                case .videoLooping:
                    VideoView(asset: asset, saveData: $saveData)
                
                default:
                    Text("OOPS, NOT SUPPORTED")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
                }

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }
                       
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)

        .navigationBarHidden(true)
        .statusBar(hidden: true)

    }
}
