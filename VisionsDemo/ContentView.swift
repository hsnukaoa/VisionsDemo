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

    var body: some View {
        VStack {
            if let image = capturedImage {
                // 撮影＋描画後の画像を表示
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 500)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
            } else {
                // 初期状態
                Text("セルフィーを撮影して顔の輪郭線を描画します")
                    .font(.headline)
                    .padding()
            }

            Button {
                showCamera = true
            } label: {
                Label("セルフィーを撮影", systemImage: "camera.fill")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding()
        }
        .sheet(isPresented: $showCamera) {
            CameraViewControllerRepresentable(capturedImage: $capturedImage)
        }
    }
}
#Preview {
    ContentView()
}
