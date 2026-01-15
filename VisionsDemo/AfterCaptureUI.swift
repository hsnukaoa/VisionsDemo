//
//  AfterCaptureUI.swift
//  VisionsDemo
//
//  Created by 宇田川航太 on 2026/01/15.
//

import SwiftUI

struct AfterCaptureUI: View {
    @State private var faceParts: [FaceParts] = []
    @State private var partsLoaction: [CGPoint] = [CGPoint.zero, CGPoint.zero, CGPoint.zero, CGPoint.zero]
    
    var body: some View {
        Image("okame")
            .resizable()
            .scaledToFit()
            .frame(minHeight: 500,maxHeight: 500)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        
        if !faceParts.isEmpty {
            VStack{
                Text("分解したパーツ")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                HStack {
                    ForEach(faceParts.first?.items.indices ?? 0..<0, id: \.self) { index in
                        PartView(
                            image: faceParts.first?.items[index].image,
                            title: "test",
                            size: .constant(index < 2 ? 30 : 60)
                        )
                        .position(x: partsLoaction[index].x, y: partsLoaction[index].y)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    print("\(value.location)")
                                    partsLoaction[index] = value.location
                                }
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    AfterCaptureUI()
}
