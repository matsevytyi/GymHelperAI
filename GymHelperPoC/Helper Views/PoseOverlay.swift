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
    
    /// COCO keypoint names & indexes:
        // 0=nose,1=left eye,2=right eye,3=left ear,4=right ear,
        // 5=left shoulder,6=right shoulder,7=left elbow,8=right elbow,
        // 9=left wrist,10=right wrist,11=left hip,12=right hip,
        // 13=left knee,14=right knee,15=left ankle,16=right ankle
    
    let connections: [(Int, Int)] = [
        (5, 7), (7, 9), // left arm
        (6, 8), (8, 10), // right arm
        (5, 6), (5, 11), (6, 12), (11, 12) // body
        ]
    // everything else is ignored for the moment
    
    var body: some View {
        GeometryReader {
            geometry in
            ZStack {
                
                // fileter out the invalid connections
                let validConnections = connections.filter { (start, end) in
                    start < poses.count &&
                    end < poses.count &&
                    poses[start].x > 0 && poses[start].y > 0 &&
                    poses[end].x > 0 && poses[end].y > 0
                }

                // overlay only valid connections
                ForEach(validConnections, id: \.0) { (start, end) in
                    let p1 = poses[start]
                    let p2 = poses[end]

                    Path { path in
                        path.move(to: CGPoint(
                            x: (1 - p1.x / 640) * geometry.size.width,
                            y: p1.y / 640 * geometry.size.height
                        ))
                        path.addLine(to: CGPoint(
                            x: (1 - p2.x / 640) * geometry.size.width,
                            y: p2.y / 640 * geometry.size.height
                        ))
                    }
                    .stroke(Color.white, lineWidth: 2)
                }
                
                ForEach(Array(poses.enumerated()).filter { $0.element.x > 0 && $0.element.y > 0 }, id: \.0) { (index, point) in
                    let isProblematic = badJoints.contains(index)

                    Circle()
                        .fill(isProblematic ? Color.red : Color.green)
                        .frame(width: 8, height: 8)
                        .position(
                            x: (1 - point.x / 640) * geometry.size.width,
                            y: point.y / 640 * geometry.size.height
                        )
                }

                
            }
        }
    }
}
