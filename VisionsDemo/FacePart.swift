//
//  FaceParts.swift
//  VisionsDemo
//
//  Created by 宇田川航太 on 2025/12/21.
//

import SwiftUI
import UniformTypeIdentifiers

struct FacePartItem: Identifiable {
    let id = UUID()
    let image: UIImage
    let title: String
}

struct PartView: View {
    let image: UIImage?
    let title: String
    @Binding var size: CGFloat
    
    var body: some View {
        VStack {
            Image(uiImage: image!)
                .resizable()
                .scaledToFit()
                .frame(height: size)
        }
    }
}

extension FaceParts {
    var items: [FacePartItem] {
        [
            leftEye.map { FacePartItem(image: $0, title: "Left Eye") },
            rightEye.map { FacePartItem(image: $0, title: "Right Eye") },
            nose.map { FacePartItem(image: $0, title: "Nose") },
            lips.map { FacePartItem(image: $0, title: "Lips") }
        ].compactMap { $0 }
    }
}

extension FacePartItem: Transferable{
    static var transferRepresentation: some TransferRepresentation{
        DataRepresentation(exportedContentType: .image){ item in
            item.image.pngData() ?? Data()
        }
    }
}
