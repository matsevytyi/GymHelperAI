//
//  CameraManager.swift
//  GymHelperPoC
//
//  Created by Andrii Matsevytyi on 19.06.2025.
//

import AVFoundation


/// Captures videostream from camera and handles permissions
class CameraManager: NSObject, ObservableObject {
    
    let session = AVCaptureSession()
    private var sessionQueue = DispatchQueue(label: "camera.session")
    
    override init() {
        super.init()
        checkPermissionAndConfigureSession()
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
}
