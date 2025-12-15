//
//  ContentView.swift
//  VisionsDemo
//
//  Created by 宇田川航太 on 2025/10/31.
//

import SwiftUI

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
                        Text("Detected Parts")
                            .font(.title2)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        ForEach(faceParts) { part in
                            VStack(alignment: .leading) {
                                Text("Face")
                                    .font(.headline)
                                    .padding(.leading)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        if let img = part.faceCropped {
                                            PartView(image: img, title: "Face")
                                        }
                                        if let img = part.leftEye {
                                            PartView(image: img, title: "Left Eye")
                                        }
                                        if let img = part.rightEye {
                                            PartView(image: img, title: "Right Eye")
                                        }
                                        if let img = part.nose {
                                            PartView(image: img, title: "Nose")
                                        }
                                        if let img = part.lips {
                                            PartView(image: img, title: "Lips")
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

#Preview {
    ContentView()
}
