//
//  ExerciseCard.swift
//  GymHelperPoC
//
//  Created by Andrii Matsevytyi on 09.06.2025.
//

//  Individual exercise selection card

import SwiftUI

struct ExerciseCardView: View {
    let exercise: Exercise
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [exercise.color.opacity(0.2), exercise.color.opacity(0.1)]),
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing))
                        .frame(width: 60, height: 60)

                    Image(systemName: exercise.icon)
                        .font(.title2)
                        .foregroundColor(exercise.color)
                }

                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text("\(exercise.difficulty) • \(exercise.duration)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(exercise.rating, specifier: "%.1f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
