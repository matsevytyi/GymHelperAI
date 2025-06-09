//
//  Exercise.swift.swift
//  GymHelperPoC
//
//  Created by Andrii Matsevytyi on 09.06.2025.
//

//  Exercise data model

import SwiftUI

struct Exercise: Identifiable, Codable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let difficulty: String
    let duration: String
    let rating: Double
    let description: String
    let keyPoints: [String]

    enum CodingKeys: String, CodingKey {
        case name, icon, difficulty, duration, rating, description, keyPoints
    }

    init(name: String, icon: String, color: Color, difficulty: String, duration: String, rating: Double, description: String, keyPoints: [String]) {
        self.name = name
        self.icon = icon
        self.color = color
        self.difficulty = difficulty
        self.duration = duration
        self.rating = rating
        self.description = description
        self.keyPoints = keyPoints
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        duration = try container.decode(String.self, forKey: .duration)
        rating = try container.decode(Double.self, forKey: .rating)
        description = try container.decode(String.self, forKey: .description)
        keyPoints = try container.decode([String].self, forKey: .keyPoints)
        
        color = .blue
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(duration, forKey: .duration)
        try container.encode(rating, forKey: .rating)
        try container.encode(description, forKey: .description)
        try container.encode(keyPoints, forKey: .keyPoints)
    }
}
