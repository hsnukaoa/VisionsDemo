//
//  VisionController.swift
//  VisionsDemo
//
//  Created by 宇田川航太 on 2025/11/01.
//

import UIKit
import Vision
import ImageIO

/// 検出された顔と、そのパーツごとの画像をまとめる構造体
struct FaceParts {
    var originalWithDrawings: UIImage // ランドマーク描画済みの画像
    var faceCropped: UIImage?         // 顔全体の切り抜き
    var leftEye: UIImage?             // 左目
    var rightEye: UIImage?            // 右目
    var nose: UIImage?                // 鼻
    var lips: UIImage?                // 口（外側）
}

// final classによってこのクラスの継承を拒否している。これによって最適化を助けることができるらしい
final class VisionController {
    
    /// 顔ランドマークを検出して、パーツ分解結果を返す（これらは非同期処理で行われる）
    /// completionは非同期で結果（FacePartsの配列）を返すためのクロージャ
    /// 顔ランドマークを検出して、パーツ分解結果を返す（これらは非同期処理で行われる）
        /// 変更点: completionの型を (UIImage?) -> Void から ([FaceParts]) -> Void に変更
        func detectAndDrawFaceLandmarks(on image: UIImage, completion: @escaping ([FaceParts]) -> Void) {
            
            // UIImageからcgImageを取り出す処理。取り出せない場合はここで処理終了する
            guard let cgImage = image.cgImage else {
                // エラー修正: nilではなく、空の配列を返す
                completion([])
                return
            }
            
            // VNDetectFaceLandmarksRequestを作成する
            let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
                guard let self = self else { return }
                
                // 検出結果が VNFaceObservation の配列で、空でないことを確認。
                guard let results = request.results as? [VNFaceObservation], !results.isEmpty else {
                    // エラー修正: ここで completion(image) を返すと型不一致エラーになります。
                    // 顔が見つからなかった場合は空配列 [] を返します。
                    completion([])
                    return
                }
                
                // 1. 全体の描画処理
                let drawnImage = self.drawLandmarks(on: image, observations: results)
                
                var facePartsArray: [FaceParts] = []
                
                // 2. 検出された顔ごとに切り抜き処理を実行
                for face in results {
                    let size = image.size
                    
                    let faceRect = CGRect(
                        x: face.boundingBox.origin.x * size.width,
                        y: (1 - face.boundingBox.origin.y - face.boundingBox.height) * size.height,
                        width: face.boundingBox.width * size.width,
                        height: face.boundingBox.height * size.height
                    )
                    
                    let faceCropped = image.crop(rect: faceRect)
                    
                    var leftEyeImg: UIImage?
                    var rightEyeImg: UIImage?
                    var noseImg: UIImage?
                    var lipsImg: UIImage?
                    
                    if let landmarks = face.landmarks {
                        leftEyeImg = self.cropLandmarkRegion(on: image, faceBoundingBox: faceRect, region: landmarks.leftEye)
                        rightEyeImg = self.cropLandmarkRegion(on: image, faceBoundingBox: faceRect, region: landmarks.rightEye)
                        noseImg = self.cropLandmarkRegion(on: image, faceBoundingBox: faceRect, region: landmarks.nose)
                        lipsImg = self.cropLandmarkRegion(on: image, faceBoundingBox: faceRect, region: landmarks.outerLips)
                    }
                    
                    let parts = FaceParts(
                        originalWithDrawings: drawnImage,
                        faceCropped: faceCropped,
                        leftEye: leftEyeImg,
                        rightEye: rightEyeImg,
                        nose: noseImg,
                        lips: lipsImg
                    )
                    facePartsArray.append(parts)
                }
                
                // ここで [FaceParts] を返します
                completion(facePartsArray)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.vnOrientation, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    print("Vision error:", error)
                    // エラー修正: nilではなく、空の配列を返す
                    completion([])
                }
            }
        }
    
    // MARK: - 描画関連 (既存ロジック)
    
    // 内部描画処理
    private func drawLandmarks(on image: UIImage, observations: [VNFaceObservation]) -> UIImage {
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        image.draw(in: CGRect(origin: .zero, size: size))
        
        // 線の色と太さを決定
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.green.cgColor)
        context?.setLineWidth(2)
        
        for face in observations {
            let rect = CGRect(
                x: face.boundingBox.origin.x * size.width,
                y: (1 - face.boundingBox.origin.y - face.boundingBox.height) * size.height,
                width: face.boundingBox.width * size.width,
                height: face.boundingBox.height * size.height
            )
            context?.stroke(rect)
            
            if let landmarks = face.landmarks {
                draw(region: landmarks.faceContour, in: rect, context: context)
                draw(region: landmarks.leftEye, in: rect, context: context)
                draw(region: landmarks.rightEye, in: rect, context: context)
                draw(region: landmarks.nose, in: rect, context: context)
                draw(region: landmarks.outerLips, in: rect, context: context)
            }
        }
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resultImage ?? image
    }
    
    private func draw(region: VNFaceLandmarkRegion2D?, in rect: CGRect, context: CGContext?) {
        guard let region = region else { return }
        
        let points = region.normalizedPoints.map {
            CGPoint(
                x: rect.origin.x + CGFloat($0.x) * rect.width,
                y: rect.origin.y + (1 - CGFloat($0.y)) * rect.height
            )
        }
        
        guard let first = points.first else { return }
        context?.beginPath()
        context?.move(to: first)
        for p in points.dropFirst() { context?.addLine(to: p) }
        context?.closePath()
        context?.strokePath()
    }
    
    // MARK: - 切り抜き関連 (新規追加)
    
    /// ランドマーク領域（目、鼻など）の点群を囲む最小の矩形を計算して切り抜く
    private func cropLandmarkRegion(on image: UIImage, faceBoundingBox: CGRect, region: VNFaceLandmarkRegion2D?) -> UIImage? {
        guard let region = region else { return nil }
        
        // 1. 正規化座標を画像の絶対座標(UIKit座標)に変換
        let points = region.normalizedPoints.map {
            CGPoint(
                x: faceBoundingBox.origin.x + CGFloat($0.x) * faceBoundingBox.width,
                // Y座標は反転させる（Visionは左下原点、UIKitは左上原点のため）
                y: faceBoundingBox.origin.y + (1 - CGFloat($0.y)) * faceBoundingBox.height
            )
        }
        
        // 2. 点群が含まれる最小の矩形（BoundingBox）を計算
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = CGFloat.leastNormalMagnitude
        var maxY = CGFloat.leastNormalMagnitude
        
        for point in points {
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        }
        
        // 切り抜き範囲を作成 (widthやheightが負にならないよう安全策をとっても良い)
        let cropRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        
        // 3. 切り抜き実行
        return image.crop(rect: cropRect)
    }
}

extension UIImage {
    var vnOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default:
            return .up
        }
    }
    
    func crop(rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        // rectが画像の範囲外にある場合やサイズがおかしい場合の対策が必要であればここに追加しますが、
        // 基本的にはCoreGraphicsが処理可能な範囲でクリッピングします。
        // ただし、座標計算時に浮動小数の誤差が出る可能性があるため、Intへの変換時に調整することもあります。
        
        guard let croppedCGImage = cgImage.cropping(to: rect) else { return nil }
        return UIImage(cgImage: croppedCGImage)
    }
}
