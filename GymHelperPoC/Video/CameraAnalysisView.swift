//
//  CameraAnalysisView.swift
//  GymHelperPoC
//
//  Created by Andrii Matsevytyi on 11.06.2025.
//


import SwiftUI
import AVFoundation

// MARK: wrapper for Mac Catalyst (unnsupported function solved)
struct CameraSheetView: View {
    @Binding var showingCamera: Bool
    var exercise: Exercise

    var body: some View {
        VStack {
            
            #if targetEnvironment(macCatalyst)
            HStack {
                Spacer()
                Button(action: {
                    showingCamera = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .padding()
                }
            }
            #endif

            Text(exercise.description)
            CameraAnalysisView()
        }
    }
}

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
