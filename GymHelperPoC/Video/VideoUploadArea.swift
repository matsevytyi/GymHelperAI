//
//  VideoUploadArea.swift
//  GymHelperPoC
//
//  Created by Andrii Matsevytyi on 09.06.2025.
//

import SwiftUI
import AVKit
import Vision
import CoreML

struct VideoUploadArea: View {

    let title: String
    let videoURL: URL?
    let poses: [CGPoint]
    let badJoints: Set<Int>
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                
                if let url = videoURL {
                    ZStack {
                        VideoPlayer(player: AVPlayer(url: url))
                            .cornerRadius(10)
                        
                        // pose overlay
                        PoseOverlay(poses: poses, badJoints: badJoints)
                    }
                } else {
                    VStack {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 50))
                        Text("Tap to upload")
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .onTapGesture(perform: onTap)
    }
}
