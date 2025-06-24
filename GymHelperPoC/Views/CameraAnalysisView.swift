//
//  CameraAnalysisView.swift
//  GymHelperPoC
//
//  Created by Andrii Matsevytyi on 11.06.2025.
//


import SwiftUI
import AVFoundation
import _AVKit_SwiftUI

// MARK: wrapper for Mac Catalyst (unnsupported function solved)
struct CameraSheetView: View {
    @Binding var showingCamera: Bool
    var exercise: Exercise

    @State private var currentStepIndex = 0
    @State private var currentVideoName: String

    init(showingCamera: Binding<Bool>, exercise: Exercise) {
        self._showingCamera = showingCamera
        self.exercise = exercise
        _currentVideoName = State(initialValue: exercise.movementSequence.first?.visual_lnk ?? "")
    }

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

            if let player = loadPlayer(for: currentVideoName) {
                    VideoPlayer(player: player)
                        .frame(height: 200)
                        .background(Color.black.opacity(0))
                        .onAppear { player.play() }
                        .onDisappear {
                                    player.pause()
                                    player.replaceCurrentItem(with: nil)
                                }
                }

            CameraAnalysisView(currentCheckpoint: exercise.movementSequence[currentStepIndex]) {
                advanceStep()
            }
            
            if currentStepIndex < exercise.movementSequence.count - 1 {
                    Button(action: {
                        advanceStep()
                    }) {
                        HStack(spacing: 5) {
                            Text("Next")
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    }
                    .padding()
                }
        }
    }

    func loadPlayer(for exercise: String) -> AVPlayer? {
        if let url = Bundle.main.url(forResource: exercise, withExtension: "mp4") {
            let player = AVPlayer(url: url)
            
            
            NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem,
                    queue: .main
                ) { _ in
                    player.seek(to: .zero)
                    player.play()
                }
                
                return player
            
        }
        return nil
    }

    func advanceStep() {
        if currentStepIndex < exercise.movementSequence.count - 1 {
            currentStepIndex += 1
            currentVideoName = exercise.movementSequence[currentStepIndex].visual_lnk
        }
    }

}

struct CameraAnalysisView: View {
    @StateObject private var cameraManager = CameraManager()
    
    let currentCheckpoint: Position
    let onPoseMatched: () -> Void
    
    @State private var hasMatchedCurrentStep = false
    @State private var currentBadJoints: Set<Int> = []
    
    var body: some View {
        
        ZStack {
            CameraPreviewView(session: cameraManager.session)
                .ignoresSafeArea()
                .onDisappear {
                    cameraManager.stopSession()
                }
            
            PoseOverlay(poses: cameraManager.currentUserPoses, badJoints: currentBadJoints)
                .allowsHitTesting(false)
            
//           Button(action: {
//                              onPoseMatched()
//                          }) {
//                              Image(systemName: "xmark.circle.fill") //update here
//                                  .font(.title)
//                                  .padding()
//                          }
        }
        
        .onChange(of: cameraManager.currentUserPoses)
        { newPoses in
            guard !hasMatchedCurrentStep else { return }
            
            let (matched, badJoints) = checkPoseMatch(userPose: newPoses, basePose: currentCheckpoint)

            self.currentBadJoints = badJoints
            
            if matched {
                onPoseMatched()
            }
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
