//
//  PoseOverlay.swift
//  GymHelperPoC
//
//  Created by Andrii Matsevytyi on 09.06.2025.
//

import SwiftUI
import AVKit
import Vision
import CoreML

struct PoseOverlay: View {
    let poses: [CGPoint]
    let badJoints: Set<Int>
    
    var body: some View {
        GeometryReader {
            geometry in
            ForEach(0..<poses.count, id: \.self) { index in
                let point = poses[index]
                let isProblematic = badJoints.contains(index)
                
                Circle()
                    .fill(isProblematic ? Color.red : Color.green)
                    .frame(width: 8, height: 8)
                    .position(
                        x: point.x * geometry.size.width,
                        y: point.y * geometry.size.height
                    )
            }
        }
    }
}
