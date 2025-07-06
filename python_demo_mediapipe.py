import cv2
import mediapipe as mp
import numpy as np
import math
from typing import List, Tuple, Optional

class PoseVideoComparator:
    def __init__(self):
        
        self.mp_pose = mp.solutions.pose
        self.mp_drawing = mp.solutions.drawing_utils
        self.mp_drawing_styles = mp.solutions.drawing_styles
        
        self.pose1 = self.mp_pose.Pose(
            static_image_mode=False,
            model_complexity=1,
            enable_segmentation=False,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        
        self.pose2 = self.mp_pose.Pose(
            static_image_mode=False,
            model_complexity=1,
            enable_segmentation=False,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
    
    def extract_keypoints(self, landmarks) -> np.ndarray:
        """Extract normalized keypoints from MediaPipe landmarks"""
        if landmarks is None:
            return np.zeros(33*2)  # 33 landmarks, x,y coordinates
        
        keypoints = []
        for landmark in landmarks.landmark:
            keypoints.extend([landmark.x, landmark.y])
        return np.array(keypoints)
    
    def calculate_cosine_similarity(self, vec1: np.ndarray, vec2: np.ndarray) -> float:
        """Calculate cosine similarity between two pose vectors"""
        if np.linalg.norm(vec1) == 0 or np.linalg.norm(vec2) == 0:
            return 0.0
        
        dot_product = np.dot(vec1, vec2)
        magnitude1 = np.linalg.norm(vec1)
        magnitude2 = np.linalg.norm(vec2)
        
        return dot_product / (magnitude1 * magnitude2)
    
    def get_problematic_joints(self, landmarks1, landmarks2, threshold=0.15) -> List[int]:
        """Identify joints with significant differences"""
        if landmarks1 is None or landmarks2 is None:
            return []
        
        problematic = []
        for i, (lm1, lm2) in enumerate(zip(landmarks1.landmark, landmarks2.landmark)):
            distance = math.sqrt((lm1.x - lm2.x)**2 + (lm1.y - lm2.y)**2)
            if distance > threshold:
                problematic.append(i)
        
        return problematic
    
    def draw_pose_with_highlights(self, image, landmarks, problematic_joints: List[int]):
        """Draw pose landmarks with problematic joints highlighted in red"""
        if landmarks is None:
            return image
        
        # Draw connections
        self.mp_drawing.draw_landmarks(
            image,
            landmarks,
            self.mp_pose.POSE_CONNECTIONS,
            landmark_drawing_spec=self.mp_drawing_styles.get_default_pose_landmarks_style()
        )
        
        # Highlight bad parts
        h, w, _ = image.shape
        for joint_idx in problematic_joints:
            if joint_idx < len(landmarks.landmark):
                landmark = landmarks.landmark[joint_idx]
                x = int(landmark.x * w)
                y = int(landmark.y * h)
                cv2.circle(image, (x, y), 8, (0, 0, 255), -1)
                cv2.circle(image, (x, y), 12, (0, 0, 255), 2)
        
        return image
    
    def add_info_overlay(self, image, similarity_score: float, frame_num: int, 
                        total_frames: int, problematic_count: int):
        """Add information overlay to the image"""

        overlay = image.copy()
        cv2.rectangle(overlay, (10, 10), (350, 120), (0, 0, 0), -1)
        image = cv2.addWeighted(image, 0.7, overlay, 0.3, 0)
        
        color = (0, 255, 0) if similarity_score > 0.8 else (0, 165, 255) if similarity_score > 0.6 else (0, 0, 255)
        cv2.putText(image, f"Similarity: {similarity_score:.2f}", (20, 35), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
        cv2.putText(image, f"Frame: {frame_num}/{total_frames}", (20, 65), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        cv2.putText(image, f"Issues: {problematic_count} joints", (20, 95), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        
        return image
    
    def process_videos(self, video1_path: str, video2_path: str):
        """Main processing function"""
        # cpture videos
        cap1 = cv2.VideoCapture(video1_path)
        cap2 = cv2.VideoCapture(video2_path)
        
        if not cap1.isOpened() or not cap2.isOpened():
            print("Error: Could not open one or both videos")
            return
        
        # extract properties
        fps1 = int(cap1.get(cv2.CAP_PROP_FPS))
        fps2 = int(cap2.get(cv2.CAP_PROP_FPS))
        total_frames1 = int(cap1.get(cv2.CAP_PROP_FRAME_COUNT))
        total_frames2 = int(cap2.get(cv2.CAP_PROP_FRAME_COUNT))
        
        print(f"Video 1: {total_frames1} frames at {fps1} FPS")
        print(f"Video 2: {total_frames2} frames at {fps2} FPS")
        print("Press 'q' to quit, 'SPACE' to pause/resume")
        
        frame_num = 0
        paused = False
        similarity_scores = []
        
        while True:
            if not paused:
                ret1, frame1 = cap1.read()
                ret2, frame2 = cap2.read()
                
                if not ret1 or not ret2:
                    print("End of video(s) reached")
                    break
                
                frame_num += 1
            
            # Resize frames to standard size
            frame1 = cv2.resize(frame1, (640, 480))
            frame2 = cv2.resize(frame2, (640, 480))
        
            rgb1 = cv2.cvtColor(frame1, cv2.COLOR_BGR2RGB)
            rgb2 = cv2.cvtColor(frame2, cv2.COLOR_BGR2RGB)
            
            # Process poses
            results1 = self.pose1.process(rgb1)
            results2 = self.pose2.process(rgb2)
            
            # Calc similarity + find problematic joints
            similarity_score = 0.0
            problematic_joints = []
            
            if results1.pose_landmarks and results2.pose_landmarks:
                keypoints1 = self.extract_keypoints(results1.pose_landmarks)
                keypoints2 = self.extract_keypoints(results2.pose_landmarks)
                similarity_score = self.calculate_cosine_similarity(keypoints1, keypoints2)
                problematic_joints = self.get_problematic_joints(
                    results1.pose_landmarks, results2.pose_landmarks
                )
                similarity_scores.append(similarity_score)
            
            # Draw poses with highlights
            frame1_processed = self.draw_pose_with_highlights(
                frame1.copy(), results1.pose_landmarks, []
            )
            frame2_processed = self.draw_pose_with_highlights(
                frame2.copy(), results2.pose_landmarks, problematic_joints
            )
            
            # Add info overlays
            frame1_processed = self.add_info_overlay(
                frame1_processed, similarity_score, frame_num, 
                min(total_frames1, total_frames2), len(problematic_joints)
            )
        
            cv2.putText(frame1_processed, "USER VIDEO", (220, 30), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 0), 2)
            cv2.putText(frame2_processed, "PERFECT VIDEO", (180, 30), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            
            # frames side by side + separator line
            combined_frame = np.hstack((frame1_processed, frame2_processed))
            cv2.line(combined_frame, (640, 0), (640, 480), (255, 255, 255), 2)
            
            cv2.imshow('Pose Comparison - Your Video | Reference Video', combined_frame)
            
            key = cv2.waitKey(30) & 0xFF
            if key == ord('q'):
                break
            elif key == ord(' '):
                paused = not paused
                print("Paused" if paused else "Resumed")
        
        cap1.release()
        cap2.release()
        cv2.destroyAllWindows()
        
        if similarity_scores:
            avg_similarity = np.mean(similarity_scores)
            print(f"\nFinal Statistics:")
            print(f"Average Similarity: {avg_similarity:.3f}")
            print(f"Best Match: {max(similarity_scores):.3f}")
            print(f"Worst Match: {min(similarity_scores):.3f}")
            print(f"Total Frames Processed: {len(similarity_scores)}")

def main():

    comparator = PoseVideoComparator()
    
    video1_path = "GymHelperPoC/Resources/cross-jab/library-cross-jab-3.mp4" 
    video2_path = "GymHelperPoC/Resources/cross-jab/library-cross-jab-3.mp4"
    
    print("=== AI-Powered Sport Assistant: Pose Comparison Demo ===")
    print(f"Processing videos:")
    print(f"User video: {video1_path}")
    print(f"Reference video: {video2_path}")
    print()
    
    try:
        comparator.process_videos(video1_path, video2_path)
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
