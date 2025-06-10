//
//  ExerciseManager.swift.swift
//  GymHelperPoC
//
//  Created by Andrii Matsevytyi on 09.06.2025.
//

//  Manager for exercises and analysis
// TODO: replace with data load fron json file

import SwiftUI
import Combine

class ExerciseManager: ObservableObject {
    
    @Published var exercises: [Exercise] = []
    @Published var selectedExercise: Exercise?

    init() {
        loadExercises()
    }

    private func loadExercises() {
        exercises = [
            Exercise(
                name: "Push-ups",
                icon: "hand.raised.fill",
                color: .blue,
                difficulty: "Beginner",
                duration: "30 sec",
                rating: 4.5,
                description: "Classic upper body exercise",
                keyPoints: ["Keep body straight", "Lower chest to ground", "Push up explosively"]
            ),
            Exercise(
                name: "Squats",
                icon: "arrow.down.to.line.circle.fill",
                color: .green,
                difficulty: "Beginner",
                duration: "45 sec",
                rating: 4.7,
                description: "Fundamental leg exercise",
                keyPoints: ["Feet shoulder-width apart", "Lower hips back", "Keep chest up"]
            ),
            Exercise(
                name: "Planks",
                icon: "figure.core.training",
                color: .orange,
                difficulty: "Intermediate",
                duration: "60 sec",
                rating: 4.3,
                description: "Core strengthening exercise",
                keyPoints: ["Keep body straight", "Engage core", "Don't let hips sag"]
            ),
            Exercise(
                name: "Lunges",
                icon: "figure.walk.circle.fill",
                color: .purple,
                difficulty: "Intermediate",
                duration: "40 sec",
                rating: 4.4,
                description: "Lower body stability",
                keyPoints: ["Step forward", "Lower back knee", "Keep front knee over ankle"]
            ),
            Exercise(
                name: "Burpees",
                icon: "bolt.fill",
                color: .red,
                difficulty: "Advanced",
                duration: "20 sec",
                rating: 4.1,
                description: "Full body cardio",
                keyPoints: ["Jump down to plank", "Do push-up", "Jump back up"]
            ),
            Exercise(
                name: "Deadlifts",
                icon: "dumbbell",
                color: .indigo,
                difficulty: "Advanced",
                duration: "30 sec",
                rating: 4.6,
                description: "Posterior chain exercise",
                keyPoints: ["Straight back", "Hip hinge movement", "Drive through heels"]
            )
        ]
    }
}
