//
//  YoloCoreMLAnalyser.swift
//  GymHelperPoC
//
//  Created by Andrii Matsevytyi on 09.06.2025.
//

import SwiftUI
import AVKit
import Vision
import CoreML

@MainActor
class SimpleYOLOAnalyzer: ObservableObject {
    
    @Published var userVideo: URL?
    @Published var referenceVideo: URL?
    @Published var userPoses: [CGPoint] = []
    @Published var referencePoses: [CGPoint] = []
    @Published var problematicJoints: Set<Int> = []
    @Published var results: [String] = []
    
    private var yoloModel: yolov8n_pose_model?
    
    var canAnalyze: Bool {
        userVideo != nil && referenceVideo != nil
    }
    
    init() {
        loadYOLOModel()
    }
    
    private func loadYOLOModel() {
            do {
                let config = MLModelConfiguration()

                self.yoloModel = try yolov8n_pose_model(configuration: config)
                print("YOLO model loaded successfully")
            } catch {
                print("Failed to load YOLO model: \(error)")
            }
        }
    
    func runAnalysis() {
        guard let userURL = userVideo, let refURL = referenceVideo else { return }
        
        Task {
            let userKeypoints = await extractKeypoints(from: userURL)
            let refKeypoints = await extractKeypoints(from: refURL)
            
            await MainActor.run {
                self.userPoses = userKeypoints
                self.referencePoses = refKeypoints
                self.compareAndHighlight()
            }
        }
    }
    
    private func extractKeypoints(from videoURL: URL) async -> [CGPoint] {
        guard let model = yoloModel else { return [] }
        
        // Get first frame from video
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        do {
                let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
                
                // MLMultiArray format for YOLO
                let input = try await preprocessImage(cgImage)
                
                // YOLO inference
                let prediction = try model.prediction(image: input)
                
                // Extract keypoints from YOLO output
                return parseYOLOOutput(prediction)
                
            } catch {
                print("Error extracting keypoints: \(error)")
                return []
        }
    }
    
    private func preprocessImage(_ cgImage: CGImage) async throws -> CVPixelBuffer {
        let width = 640
        let height = 640

        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw NSError(domain: "ImageProcessing", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create pixel buffer"])
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            throw NSError(domain: "ImageProcessing", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGContext"])
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return buffer
    }


    
    private func parseYOLOOutput(_ prediction: MLFeatureProvider) -> [CGPoint] {
        // [x, y, confidence] for 17 keypoints
        guard let outputArray = prediction.featureValue(for: "output")?.multiArrayValue else {
            return []
        }
        
        var keypoints: [CGPoint] = []
        
        // 17 COCO keypoints from YOLO output
        for i in 0..<17 {
            let baseIndex = i * 3
            if baseIndex + 2 < outputArray.count {
                let x = outputArray[baseIndex].doubleValue
                let y = outputArray[baseIndex + 1].doubleValue
                let confidence = outputArray[baseIndex + 2].doubleValue
                
                if confidence > 0.5 {
                    keypoints.append(CGPoint(x: x / 640.0, y: y / 640.0)) // Normalizzze to 0-1
                }
            }
        }
        
        return keypoints
    }
    
    private func compareAndHighlight() {
        guard userPoses.count == referencePoses.count else { return }
        
        problematicJoints.removeAll()
        results.removeAll()
        
        for i in 0..<userPoses.count {
            let distance = calculateDistance(userPoses[i], referencePoses[i])
            
            if distance > 0.1 { // Threshold for "problematic"
                problematicJoints.insert(i)
                results.append(getJointName(i) + " position differs significantly")
            }
        }
    }
    
    private func calculateDistance(_ point1: CGPoint, _ point2: CGPoint) -> Double {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx*dx + dy*dy)
    }
    
    private func getJointName(_ index: Int) -> String {
        let jointNames = ["Nose", "Left Eye", "Right Eye", "Left Ear", "Right Ear",
                         "Left Shoulder", "Right Shoulder", "Left Elbow", "Right Elbow",
                         "Left Wrist", "Right Wrist", "Left Hip", "Right Hip",
                         "Left Knee", "Right Knee", "Left Ankle", "Right Ankle"]
        return index < jointNames.count ? jointNames[index] : "Joint \(index)"
    }
}
