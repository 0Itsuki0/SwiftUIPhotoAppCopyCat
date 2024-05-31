//
//  AsssetEditView.swift
//  PHAssetDemo
//
//  Created by Itsuki on 2024/05/31.
//

import SwiftUI
import Photos


struct AssetEditView: View {
    @EnvironmentObject var photoLibraryManager: PhotoLibraryManager
    @Environment(\.dismiss) var dismiss

    var asset: PHAsset
    @State private var uiImage: UIImage?
    @State private var editInputRequest: ContentEditInputRequest?
    @State private var adjustments: [PHAdjustmentData] = []
    
        
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
                    
                    // to make sure we are not removing the adjusment for the original image
                    if adjustments.count <= 1 {
                        return
                    }

                    let _ = adjustments.popLast() // remove the newest adjustment
                    guard let lastAdjustment = adjustments.last else { return }
                    guard let uiImage = UIImage(data: lastAdjustment.data) else {
                        print("uiimage not available")
                        return }
                    self.uiImage = uiImage
                    
                }, label: {
                    Text("Undo")
                })
                
                Button(action: {
                    guard let contentEditingInput = editInputRequest?.contentEditingInput, let adjustment = adjustments.last else {return}
                    Task {
                        do {
                            try await photoLibraryManager.saveEditContent(
                                for:asset,
                                contentEditingInput: contentEditingInput,
                                with:adjustment)
                        } catch (let error) {
                            print(error)
                        }
                    }

                    
                }, label: {
                    Text("Save")
                })

                
                Button(action: {
                    guard let uiImage = uiImage else {return}

                    let currentSize = uiImage.size
                    guard let halvedImage = uiImage.cgImage?.cropping(to: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: currentSize.width/2, height: currentSize.height))) else {return}
                    let halvedUIImage = UIImage(cgImage: halvedImage)
                    self.uiImage = halvedUIImage
                    
                    addToAdjustment(halvedUIImage)

                    
                }, label: {
                    Text("Crop left half")
                })

            }
            .foregroundStyle(.white)
            .padding(.all, 20)
            .frame(height: 50)
            .background(.gray.opacity(0.3))
            .frame(maxWidth: .infinity, alignment: .leading)
            
            
            Group {
                if let uiImage = uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    ProgressView()
                }
            }
            .task {
                
                do {
                    let editInputRequest = try await photoLibraryManager.requestContentEditingInput(for: asset)
                    uiImage = editInputRequest.contentEditingInput.displaySizeImage
                    self.editInputRequest = editInputRequest
                    addToAdjustment(editInputRequest.contentEditingInput.displaySizeImage)

                    
                    // for rolling back to a previous version made elsewhere
//                    let editInputRequest = try await photoLibraryManager.requestContentEditingInput(for: asset)
//                    let previousImage = editInputRequest.contentEditingInput.displaySizeImage
//                    self.editInputRequest = editInputRequest
//
//                    // add the current version as an adjustment
//                    addToAdjustment(previousImage)
//                    self.uiImage = previousImage
//
//                    
//                    // if there is adjustment maded, set the image to be the newest
//                    if let adjustmentData = editInputRequest.contentEditingInput.adjustmentData {
//                        self.adjustments.append(adjustmentData)
//                        guard let image = UIImage(data: adjustmentData.data) else  {return}
//                        self.uiImage = image
//                    }
                    
                    
                } catch(let error) {
                    print(error)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }
                       
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)

        .navigationBarHidden(true)
        .statusBar(hidden: true)

    }
    
    
    private func addToAdjustment(_ image: UIImage?) {
        
//        compressionQuality: a value from 0.0 to 1.0.
//        0.0: maximum compression (or lowest quality)
//        1.0  least compression (or best quality)
        guard let image = image, let imageData = image.jpegData(compressionQuality: 0.5) else {return}
        let id = UUID().uuidString
        let adjustment = PHAdjustmentData(formatIdentifier: id, formatVersion: "\(adjustments.count + 1)", data: imageData)
        self.adjustments.append(adjustment)

    }

}
