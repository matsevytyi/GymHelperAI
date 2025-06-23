import SwiftUI

func checkPoseMatch(userPose: [CGPoint], basePose: Position) -> (Bool, Set<Int>) {
    var problematicJoints: Set<Int> = []

    let connections: [(Int, Int)] = [
        (5, 7), (7, 9), // left arm
        (6, 8), (8, 10), // right arm
        (5, 6), (5, 11), (6, 12), (11, 12) // body
    ]
    
    for (start, end) in connections {
        guard start < userPose.count, end < userPose.count else { continue }

        let userVec = toVector(from: userPose[start], to: userPose[end])
        
        // user joints to basePose
        let basePoints: [CGPoint]?
        
        switch (start, end) {
            // correct sections of basePose
            case (5, 7), (7, 9): basePoints = basePose.leftArm
            case (6, 8), (8, 10): basePoints = basePose.rightArm
            case (5, 6), (5, 11), (6, 12), (11, 12): basePoints = basePose.body
            default: basePoints = nil
        }
        
        guard let base = basePoints else { continue }

        //  order in basePose arrays matches joint pairs
        let baseVec = toVector(from: base[0], to: base[1]) // You may need to improve indexing here

        let angleDiff = angleBetweenVectors(userVec, baseVec)
        if angleDiff > .pi / 8 { // ~22.5° threshold
            problematicJoints.insert(start)
            problematicJoints.insert(end)
        }
    }

    let isMatch = problematicJoints.isEmpty
    return (isMatch, problematicJoints)
}

func angleBetweenVectors(_ v1: CGVector, _ v2: CGVector) -> CGFloat {
    let dot = v1.dx * v2.dx + v1.dy * v2.dy
    let mag1 = sqrt(v1.dx * v1.dx + v1.dy * v1.dy)
    let mag2 = sqrt(v2.dx * v2.dx + v2.dy * v2.dy)
    
    guard mag1 > 0 && mag2 > 0 else { return .pi } // 180° if degenerate
    
    let cosTheta = dot / (mag1 * mag2)
    return acos(max(-1, min(1, cosTheta))) // float errors solution
}

func toVector(from p1: CGPoint, to p2: CGPoint) -> CGVector {
    return CGVector(dx: p2.x - p1.x, dy: p2.y - p1.y)
}

