//
//  CameraViewController.swift
//  VisionsDemo
//
//  Created by 宇田川航太 on 2025/10/31.
//


import UIKit
import AVFoundation

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    // カメラプレビューを表示するレイヤー
    private var previewLayer: AVCaptureVideoPreviewLayer!
    // 撮影セッション
    private var captureSession: AVCaptureSession!
    // 写真出力
    private var photoOutput: AVCapturePhotoOutput!
    
    // SwiftUI側に画像を返すクロージャ
    var onPhotoCaptured: ((UIImage) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        // フロントカメラを取得
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front) else {
            print("Front camera not found")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            // 出力設定
            photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

            // プレビュー設定
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)

            captureSession.startRunning()
        } catch {
            print("Camera setup error: \(error)")
        }
    }

    private func setupUI() {
        let shutterButton = UIButton(type: .system)
        shutterButton.setTitle("📸 撮影", for: .normal)
        shutterButton.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        shutterButton.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        shutterButton.layer.cornerRadius = 30
        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        shutterButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        view.addSubview(shutterButton)
        
        NSLayoutConstraint.activate([
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60),
            shutterButton.widthAnchor.constraint(equalToConstant: 100),
            shutterButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    @objc private func takePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // 撮影完了時に呼ばれる
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("Failed to capture photo")
            return
        }

        // SwiftUIに画像を返す
        onPhotoCaptured?(image)
        dismiss(animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
}