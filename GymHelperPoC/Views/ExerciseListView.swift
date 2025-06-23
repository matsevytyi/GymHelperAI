//
//  ExerciseListView.swift
//  GymHelperPoC
//
//  Created by Andrii Matsevytyi on 09.06.2025.
//

//  Main screen showing exercise list and user stats

import SwiftUI

struct ExerciseListView: View {
    @EnvironmentObject var exerciseManager: ExerciseManager
    @State private var showingCamera = false

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {

                    // Exercise category
                    LazyVGrid(
                        columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                        ],
                        spacing: 15)
                {
                        ForEach(exerciseManager.exercises) {
                            exercise in ExerciseCardView(exercise: exercise) {
                                exerciseManager.selectedExercise = exercise
                                showingCamera = true
                            }
                        }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Sport Assistant")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingCamera) {
            if let exercise = exerciseManager.selectedExercise {
                
                CameraSheetView(showingCamera: $showingCamera, exercise: exercise)
                    .frame(minWidth: 600, minHeight: 800)
            }
        }
    }
}

