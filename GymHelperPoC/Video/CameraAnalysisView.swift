//
//  CameraAnalysisView.swift
//  GymHelperPoC
//
//  Created by Andrii Matsevytyi on 11.06.2025.
//


import SwiftUI
import AVFoundation


struct CameraAnalysisView: View {
    @StateObject private var cameraManager = CameraManager()

    var body: some View {
        CameraPreviewView(session: cameraManager.session)
            .ignoresSafeArea()
            .onDisappear {
                cameraManager.stopSession()
            }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}

class VideoPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}


#Preview {
    //CameraAnalysisView()
}
