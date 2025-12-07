//
//  CameraViewControllerRepresentable.swift
//  VisionsDemo
//
//  Created by 宇田川航太 on 2025/10/31.
//


import SwiftUI
import UIKit

struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var faceParts: [FaceParts]

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onPhotoCaptured = { image in
            capturedImage = image
        }
        vc.onFacePartsDetected = { parts in
            faceParts = parts
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}
