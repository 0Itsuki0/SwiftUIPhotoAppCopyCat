//
//  ContentView.swift
//  PHAssetDemo
//
//  Created by Itsuki on 2024/05/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var photoLibraryManager = PhotoLibraryManager()
    
    var body: some View {
        NavigationStack {
            Text("Assets Loaded: \(photoLibraryManager.photoAssetCollection.count)")
                .foregroundStyle(.white)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(.black))
            ThumbnailCollectionView()
        }
        .environmentObject(photoLibraryManager)
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .statusBar(hidden: true)

    }
}

