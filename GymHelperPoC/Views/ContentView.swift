//
//  ContentView.swift
//  Main app view with navigation
//

import SwiftUI

struct ContentView: View {
    @StateObject private var exerciseManager = ExerciseManager()

    var body: some View {
        NavigationView {
            ExerciseListView()
                .environmentObject(exerciseManager)
        }
    }
}

    
#Preview {
    ContentView()
}
