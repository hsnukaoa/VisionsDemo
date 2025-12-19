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
struct FaceParts: Identifiable {
    let id = UUID()
    var originalWithDrawings: UIImage // ランドマーク描画済みの画像
    var faceCropped: UIImage?         // 顔全体の切り抜き
    var leftEye: UIImage?             // 左目
    var rightEye: UIImage?            // 右目
    var nose: UIImage?                // 鼻
    var lips: UIImage?                // 口（外側）
}

// final classによってこのクラスの継承を拒否している。処理速度がわずかに向上
final class VisionController {
    
    /// 顔ランドマークを検出して、パーツ分解結果を返す（これらは非同期処理で行われる）
    /// completionは非同期で結果（FacePartsの配列）を返すためのクロージャ
    /// imageは解析したい画像
    func detectAndDrawFaceLandmarks(on image: UIImage, completion: @escaping ([FaceParts]) -> Void) {
        
        // UIImageからcgImageを取り出す処理。取り出せない場合はここで処理を終了する
        guard let cgImage = image.cgImage else {
            // エラー修正: nilではなく、空の配列を返す
            completion([])
            return
        }
        
        // リクエストを作成する
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let self = self else { return }
            
            // 検出結果が VNFaceObservation の配列で、空でないことを確認。
            guard let results = request.results as? [VNFaceObservation], !results.isEmpty else {
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
    
    /// ランドマーク領域（目、鼻など）をパスの形で切り抜く（背景透過）
    private func cropLandmarkRegion(on image: UIImage, faceBoundingBox: CGRect, region: VNFaceLandmarkRegion2D?) -> UIImage? {
        guard let region = region else { return nil }
        
        // 1. 正規化座標を画像の絶対座標(UIKit座標)に変換
        //    (この計算は drawLandmarks と同じなので、画面上の見た目通りの位置が求まる)
        let points = region.normalizedPoints.map {
            CGPoint(
                x: faceBoundingBox.origin.x + CGFloat($0.x) * faceBoundingBox.width,
                y: faceBoundingBox.origin.y + (1 - CGFloat($0.y)) * faceBoundingBox.height
            )
        }
        
        guard let firstPoint = points.first else { return nil }
        
        // 2. パスを作成
        let path = UIBezierPath()
        path.move(to: firstPoint)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.close()
        
        // 3. パスのバウンディングボックスを取得（これが切り抜く画像のサイズ）
        let cropRect = path.bounds
        
        // エッジケース対策: サイズが0ならnil
        if cropRect.width <= 0 || cropRect.height <= 0 { return nil }
        
        // 4. 切り抜き用のコンテキストを作成
        //    scaleをimage.scaleに合わせることで高画質を維持
        UIGraphicsBeginImageContextWithOptions(cropRect.size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        // 5. パスをコンテキストの原点(0,0)に合わせて移動させてクリップ
        //    現在のパスは画像全体座標にあるので、cropRectのorigin分だけずらす
        context.translateBy(x: -cropRect.origin.x, y: -cropRect.origin.y)
        path.addClip()
        
        // 6. 画像を描画
        //    image.draw(at: .zero) だと、画像全体の左上が (0,0) に描画されるが、
        //    contextは (-cropRect.origin) だけずれているので、
        //    結果的に cropRect の部分が (0,0) に重なるように描画される。
        image.draw(at: .zero)
        
        // 7. 画像を取得
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return croppedImage
    }
}

extension UIImage{
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
