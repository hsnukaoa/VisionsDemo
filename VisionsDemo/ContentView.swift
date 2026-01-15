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
    @State private var partsLoaction: [CGPoint] = [CGPoint.zero, CGPoint.zero, CGPoint.zero, CGPoint.zero]
    
    var body: some View {
        VStack(spacing: 20) {
            if let _ = capturedImage {
                AfterCaptureUI()
            } else {
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
            partsLoaction = [.zero, .zero, .zero, .zero]
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
        .sheet(isPresented: $showCamera) {
            CameraViewControllerRepresentable(capturedImage: $capturedImage, faceParts: $faceParts)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}

