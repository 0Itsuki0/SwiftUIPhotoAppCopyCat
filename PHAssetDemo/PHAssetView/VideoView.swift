//
//  VideoView.swift
//  PHAssetDemo
//
//  Created by Itsuki on 2024/05/26.
//


import SwiftUI
import AVKit
import Photos


struct VideoView: View {
    @EnvironmentObject var photoLibraryManager: PhotoLibraryManager

    var asset: PHAsset
    @Binding var saveData: () async -> Void

    @State private var player: AVPlayer = AVPlayer()
    @State private var playerItem: AVPlayerItem?
    
    
    var body: some View {
        Group {
            if playerItem != nil {
                VideoPlayer(player: player)
            } else {
                ProgressView()
            }
        }
        .task {
            guard playerItem == nil else { return }
            do {
                let result = try await photoLibraryManager.cacheManager.requestVideoPlayback(for: asset)
                playerItem = result.playerItem
                player.replaceCurrentItem(with: result.playerItem)
                saveData = {
                    do {
                        try await photoLibraryManager.createAsset(asset: result.playerItem.asset)
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
