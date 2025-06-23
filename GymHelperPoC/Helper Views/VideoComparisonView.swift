//
//  VideoComparisonView.swift
//  GymHelperPoC
//
//  Created by Andrii Matsevytyi on 09.06.2025.
//

import SwiftUI
import AVKit
import Vision
import CoreML

struct VideoComparisonView: View {
    @StateObject private var analyzer = SimpleYOLOAnalyzer()
    @State private var showingPicker = false
    @State private var userPickerSelected = false
    @State private var refPickerSelected = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Exercise Comparison")
                .font(.title2)
                .bold()
            
            // Two video areas
            HStack(spacing: 15) {
                // User video
                VideoUploadArea(
                    title: "Your Video",
                    videoURL: analyzer.userVideo,
                    poses: analyzer.userPoses,
                    badJoints: analyzer.problematicJoints,
                    onTap: {
                    print("clicked")
                    refPickerSelected = false
                    userPickerSelected = true
                    showingPicker = true
                    print("done")
                    }
                )
                
                // Reference video
                VideoUploadArea(
                    title: "Reference",
                    videoURL: analyzer.referenceVideo,
                    poses: analyzer.referencePoses,
                    badJoints: [],
                    onTap: {
                        print("clicked")
                        userPickerSelected = false
                        refPickerSelected = true
                        showingPicker = true
                        print("done")}
                )
            }
            
            // Analysis button
            Button("Analyze Pose Differences") {
                analyzer.runAnalysis()
            }
            .disabled(!analyzer.canAnalyze)
            .padding()
            .background(analyzer.canAnalyze ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            // Results
            if !analyzer.results.isEmpty {
                VStack(alignment: .leading) {
                    Text("Issues Found:")
                        .font(.headline)
                    ForEach(analyzer.results, id: \.self) { result in
                        Text("• \(result)")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .fileImporter(isPresented: $showingPicker, allowedContentTypes: [.movie]) { result in
            print("reference video chose n")
            if case .success(let url) = result {
                if userPickerSelected {analyzer.userVideo = url}
                else {analyzer.referenceVideo = url}
            }
        }
    }
}

#Preview {
    VideoComparisonView()
}
