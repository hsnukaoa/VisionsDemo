//
//  ContentView.swift
//  VisionsDemo
//
//  Created by 宇田川航太 on 2025/10/31.
//

import SwiftUI
import UniformTypeIdentifiers

struct FacePartItem: Identifiable {
    let id = UUID()
    let image: UIImage
    let title: String
}

struct ContentView: View {
    @State private var capturedImage: UIImage? = nil
    @State private var showCamera = false
    @State private var faceParts: [FaceParts] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let image = capturedImage {
                    // 撮影＋描画後の画像を表示
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    
                    if !faceParts.isEmpty {
                        Text("分解したパーツ")
                            .font(.title2)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        ForEach(faceParts) { part in
                            VStack(alignment: .leading) {
                                Text("Face")
                                    .font(.headline)
                                    .padding(.leading)
                                
                                //分解したFacePartsを表示
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(part.items) { item in
                                            PartView(image: item.image, title: item.title)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.bottom)
                        }
                    }
                    
                } else {
                    // 初期状態
                    VStack {
                        Image(systemName: "face.dashed")
                            .font(.system(size: 100))
                            .foregroundColor(.gray)
                            .padding()
                        Text("セルフィーを撮影して\n顔のパーツを分析します")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(height: 300)
                }
            }
            .padding(.vertical)
            
            Button {
                showCamera = true
            } label: {
                Label("セルフィーを撮影", systemImage: "camera.fill")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding()
        }
        .sheet(isPresented: $showCamera) {
            CameraViewControllerRepresentable(capturedImage: $capturedImage, faceParts: $faceParts)
        }
    }
}

struct PartView: View {
    let image: UIImage
    let title: String
    
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

extension FaceParts {
    var items: [FacePartItem] {
        [
            faceCropped.map { FacePartItem(image: $0, title: "Face") },
            leftEye.map { FacePartItem(image: $0, title: "Left Eye") },
            rightEye.map { FacePartItem(image: $0, title: "Right Eye") },
            nose.map { FacePartItem(image: $0, title: "Nose") },
            lips.map { FacePartItem(image: $0, title: "Lips") }
        ].compactMap { $0 }
    }
}



#Preview {
    ContentView()
}
