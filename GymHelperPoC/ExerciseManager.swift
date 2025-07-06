//
//  ExerciseManager.swift.swift
//  GymHelperPoC
//
//  Created by Andrii Matsevytyi on 09.06.2025.
//

//  Manager for exercises and analysis
// TODO: replace with data load fron json file

import SwiftUI
//import Combine

class ExerciseManager: ObservableObject {
    
    @Published var exercises: [Exercise] = []
    @Published var selectedExercise: Exercise?

    init() {
        loadExercises()
    }

    private func loadExercises() {
        guard let url = Bundle.main.url(forResource: "cross-jab", withExtension: "json") else {
            print("data file not found in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            
            let decodedExercises = try decoder.decode([Exercise].self, from: data)
            
            print("decoded \(decodedExercises.count) exercises")
            
            DispatchQueue.main.async {
                self.exercises = decodedExercises
            }
            
        } catch {
            print("Failed to decode JSON: \(error)")
        }
    }

}
