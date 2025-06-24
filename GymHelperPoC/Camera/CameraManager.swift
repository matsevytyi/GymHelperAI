//
//  CameraManager.swift
//  GymHelperPoC
//
//  Created by Andrii Matsevytyi on 19.06.2025.
//

import AVFoundation
import Accelerate
import SwiftUI


/// Captures videostream from camera and handles permissions
class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let session = AVCaptureSession()
    private var sessionQueue = DispatchQueue(label: "camera.session")
    private var videoQueue = DispatchQueue(label: "camera.video")
    
    var poseDetector = SimpleYOLOAnalyzer()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    @Published var currentUserPoses: [CGPoint] = []

    
    
    override init() {
        super.init()
        
        checkPermissionAndConfigureSession()
        
        poseDetector.onPoseDetected = { [weak self] keypoints in
            DispatchQueue.main.async {
                self?.currentUserPoses = keypoints
            }
        }
    }
    
    private func checkPermissionAndConfigureSession() {
        
        print("authstatus: \(AVCaptureDevice.authorizationStatus(for: .video))")
        
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            self.configureSession()
        }
        else {
            AVCaptureDevice.requestAccess(for: .video)
            { granted in
                
                if granted {
                    print("Configuring session")
                    self.configureSession()
                    
                } else {
                    print("Camera access denied")
                }
                
            }
        }
    }

    private func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            //self.session.sessionPreset = .high
            
            self.session.sessionPreset = .vga640x480

            let discovery = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .unspecified
            )

            guard let device = discovery.devices.first else {
                print("No camera available")
                self.session.commitConfiguration()
                return
            }

            guard let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                print("Failed to set up camera input")
                self.session.commitConfiguration()
                return
            }

            self.session.addInput(input)
            
            self.videoOutput.setSampleBufferDelegate(self, queue: self.videoQueue)
            self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            guard self.session.canAddOutput(self.videoOutput) else {
                print("Cannot add video output")
                return
            }
            
            self.session.addOutput(self.videoOutput)
            
            self.session.commitConfiguration()
            
            self.session.startRunning()
        }
    }

    func startSession() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
            guard let modifiedBuffer = resizePixelBuffer(pixelBuffer, width: 640, height: 640) else { return }

            // YOLO on pixelBuffer
            self.poseDetector.processLiveFrame(modifiedBuffer)
            
        }
    
    private func resizePixelBuffer(_ pixelBuffer: CVPixelBuffer, width: Int, height: Int) -> CVPixelBuffer? {
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly) // locked buffer
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) } // unlock once function exits

        // image properties and memory pointer
        guard let srcBaseAddr = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }

        let srcWidth = CVPixelBufferGetWidth(pixelBuffer)
        let srcHeight = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        // buffer from src
        var srcBuffer = vImage_Buffer(
            data: srcBaseAddr,
            height: vImagePixelCount(srcHeight),
            width: vImagePixelCount(srcWidth),
            rowBytes: bytesPerRow
        )

        // buffer for dst
        var destPixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            nil,
            width,
            height,
            CVPixelBufferGetPixelFormatType(pixelBuffer),
            nil,
            &destPixelBuffer
        )

        guard let dst = destPixelBuffer else { return nil }

        // lock the destination buffer and wrap it in vImage_Buffer
        CVPixelBufferLockBaseAddress(dst, [])
        defer { CVPixelBufferUnlockBaseAddress(dst, []) }

        var dstBuffer = vImage_Buffer(
            data: CVPixelBufferGetBaseAddress(dst),
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: CVPixelBufferGetBytesPerRow(dst)
        )

        // Fast resize
        vImageScale_ARGB8888(&srcBuffer, &dstBuffer, nil, vImage_Flags(0)) // use Accelerate

        return dst
        
    }

    

}
