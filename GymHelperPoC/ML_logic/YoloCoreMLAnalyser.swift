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

class SimpleYOLOAnalyzer: ObservableObject {
    
    @Published var userVideo: URL?
    @Published var referenceVideo: URL?
    @Published var userPoses: [CGPoint] = []
    @Published var referencePoses: [CGPoint] = []
    @Published var problematicJoints: Set<Int> = []
    @Published var results: [String] = []
    
    var onPoseDetected: ((_ keypoints: [CGPoint], _ badJoints: Set<Int>) -> Void)? = nil
    
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
    
    func processLiveFrame(_ pixelBuffer: CVPixelBuffer) -> [CGPoint]? {
        //guard let model = yoloModel else { throw Error }
        let model = yoloModel!
        
        do {
            let input = yolov8n_pose_modelInput(image: pixelBuffer)
            let prediction = try model.prediction(input: input)
            print(prediction.featureNames)

            let keypoints = parseRawYOLOOutput(prediction: prediction)
            print(keypoints)
            print("Detected \(keypoints.count) keypoints")
            
//            if let output = prediction.featureValue(for: "var_1035") {
//                print("Output shape:", output.multiArrayValue?.shape ?? "no multiArray")
//                print("Output values:", output.multiArrayValue ?? "no multiArray")
//            } else {
//                print("No output for key var_1035")
//            }
            

//            await MainActor.run {
//                self.userPoses = keypoints
//            }
            //let badJoints: Set<Int> = calculateBadJoints(from: keypoints) // Optional logic
            var badJoints: Set<Int> = Set()
            badJoints.insert(1)
            badJoints.insert(2)
            badJoints.insert(3)
            onPoseDetected?(keypoints, badJoints)

            
            return keypoints

        } catch {
            print("Live frame processing error: \(error)")
        }
        return nil
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

    private func parseRawYOLOOutput(prediction: yolov8n_pose_modelOutput) -> [CGPoint] {
        guard let multiArray = prediction.featureValue(for: "var_1035")?.multiArrayValue else {
            print("No multiArray output")
            return []
        }

        let ptr = UnsafeMutablePointer<Float32>(OpaquePointer(multiArray.dataPointer))

        let channels = 56  // 4 bbox + 1 obj + 51 keypoints
        let anchors = 8400

        var bestObjectness: Float32 = 0
        var bestIndex: Int = -1

        // Find anchor with highest objectness (channel index 4)
        for i in 0..<anchors {
            let obj = ptr[4 * anchors + i]
            if obj > bestObjectness {
                bestObjectness = obj
                bestIndex = i
            }
        }

        guard bestIndex != -1, bestObjectness > 0.5 else {
            print("No object detected")
            return []
        }

        // Extract 17 keypoints (from channel 5 to 55)
        var keypoints: [CGPoint] = []

        for kp in 0..<17 {
            
            let x = ptr[(5 + kp * 3) * anchors + bestIndex]
            let y = ptr[(5 + kp * 3 + 1) * anchors + bestIndex]
            let conf = ptr[(5 + kp * 3 + 2) * anchors + bestIndex]

            if conf > 0.5 {
                keypoints.append(CGPoint(x: 1 - CGFloat(x) / 640.0, y: CGFloat(y) / 640.0)) // normalized
                print("normal kp _\(kp) with \(x), \(y)")
            } else {
                keypoints.append(CGPoint(x: -1, y: -1))
                print("abnormal kp _ \(kp)")
            }
        }

        return keypoints
    }

    
//    private func parseRawYOLOOutput(prediction: yolov8n_pose_modelOutput) {
//        guard let multiArray = prediction.featureValue(for: "var_1035")?.multiArrayValue else {
//            print("No multiArray output")
//            return
//        }
//
//        // Access raw pointer to the multi-array data
//        let ptr = UnsafeMutablePointer<Float32>(OpaquePointer(multiArray.dataPointer))
//
//        // Constants from model design
//        let channels = 56
//        let width = 8400
//
//        for keypointIndex in 0..<channels {
//            var maxConfidence: Float32 = 0
//            var maxIndex: Int = 0
//
//            for i in 0..<width {
//                let confidence = ptr[keypointIndex * width + i]
//                if confidence > maxConfidence {
//                    maxConfidence = confidence
//                    maxIndex = i
//                }
//            }
//
//            if maxConfidence > 0.5 {  // Threshold
//                // Convert maxIndex to (x, y) coordinates depending on model grid size
//                let x = maxIndex % 640
//                let y = maxIndex / 640
//
//                print("Keypoint \(keypointIndex): x=\(x), y=\(y), confidence=\(maxConfidence)")
//            }
//        }
//
//    }

    
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
