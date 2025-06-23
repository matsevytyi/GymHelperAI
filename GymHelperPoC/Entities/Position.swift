//
//  Position.swift
//  GymHelperPoC
//
//  Created by Andrii Matsevytyi on 23.06.2025.
//

import Foundation
import SwiftUI
import CoreGraphics

struct Position: Codable {
    
    let visual_lnk: String
    
    let rightArm: [CGPoint]
    let leftArm: [CGPoint]
    let body: [CGPoint]
}


