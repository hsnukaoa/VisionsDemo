//
//  CameraViewController.swift
//  VisionsDemo
//
//  Created by 宇田川航太 on 2025/10/31.
//


import UIKit
import AVFoundation

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var captureSession = AVCaptureSession()
    var previewLayer:AVCaptureVideoPreviewLayer!
    var photoOutput = AVCapturePhotoOutput()
    
    // SwiftUI側に画像を返すクロージャ
    var onPhotoCaptured: ((UIImage) -> Void)?
    var onFacePartsDetected: (([FaceParts]) -> Void)?
    
    let vision = VisionController()
    
    //初期設定
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }
    
    //MARK: カメラのセットアップ
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        // フロントカメラを取得。見つからなかった場合はエラーを出して終了
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,for: .video,position: .front) else {
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
            
            //カメラ起動処理(DispatchQueueを使用することでバックグラウンドスレッドに移動し、UIのフリーズを防ぐ)
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        } catch {
            print("Camera setup error: \(error)")
        }
    }
    
    //MARK: UIのセットアップ
    private func setupUI() {
        let shutterButton = UIButton(type: .system)
        //ボタンのデザインを作成
        shutterButton.setTitle("📸 撮影", for: .normal)
        shutterButton.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        shutterButton.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        shutterButton.layer.cornerRadius = 30
        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        //ボタンが押されたときにtakePhoto関数が呼ばれるように設定
        shutterButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        view.addSubview(shutterButton)
        
        //レイアウトをルールで表現する仕組み
        NSLayoutConstraint.activate([
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60),
            shutterButton.widthAnchor.constraint(equalToConstant: 100),
            shutterButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func takePhoto() {
        //写真を撮る操作を実行
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    
    //画面が閉じられた時の後処理担当
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //カメラを停止して、リソースを解放する
        captureSession.stopRunning()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        //ここで撮影結果のデータからUIImageを作り出している
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("Failed to capture photo")
            return
        }
        
        vision.detectAndDrawFaceLandmarks(on: image) { [weak self] facePartsArray in
            DispatchQueue.main.async {
                
                // 検出結果から、描画済みの画像を取得する
                let imageToSend: UIImage
                if let firstFace = facePartsArray.first {
                    // 最初の顔のランドマーク描画済み画像を使用
                    imageToSend = firstFace.originalWithDrawings
                } else {
                    // 顔が検出されなかった場合は元の画像を使用
                    imageToSend = image
                }
                
                // パーツ情報を返す
                self?.onFacePartsDetected?(facePartsArray)
                
                self?.onPhotoCaptured?(imageToSend)
                self?.dismiss(animated: true)
            }
        }
    }
}

