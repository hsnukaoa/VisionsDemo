//
//  VisionController.swift
//  VisionsDemo
//
//  Created by 宇田川航太 on 2025/11/01.
//

import UIKit
import Vision
import ImageIO

final class VisionController {
    
    /// 顔ランドマークを検出して、描画済みUIImageを返す
    func detectAndDrawFaceLandmarks(on image: UIImage, completion: @escaping (UIImage?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let results = request.results as? [VNFaceObservation], !results.isEmpty else {
                completion(image)
                return
            }
            
            let resultImage = self?.drawLandmarks(on: image, observations: results)
            completion(resultImage)
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.vnOrientation, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Vision error:", error)
                completion(nil)
            }
        }
    }
    
    // MARK: - 内部描画処理
    private func drawLandmarks(on image: UIImage, observations: [VNFaceObservation]) -> UIImage {
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        image.draw(in: CGRect(origin: .zero, size: size))
        
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
}

