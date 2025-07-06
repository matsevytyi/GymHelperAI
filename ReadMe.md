# Boxing Helper

**Boxing Helper** is an AI-powered mobile app that helps users improve their workout or martial arts techniques. It analyzes body movements based on video from user camera and gives real-time feedback. The app is designed to be accessible for beginners and those who don't have access to a personal coach due to cost, time, or comfort level. It provides a clear, engaging, and fault-tolerant UI/UX, integrates object detection and pose estimatio models and uses CoreML for Metal acceleration.

## Motivation

Many people train without supervision due to:
- High costs
- Lack of time
- Discomfort working with others

This often results in:
- Poor technique
- Anxiety
- Injuries
- Lack of progress

## Existing Solutions

| Solution   | Drawbacks                                                   |
|------------|-------------------------------------------------------------|
| Kayyo      | Paid, no expert video reference, complicated UI             |
| Firefly    | Paid, not focused on martial arts                           |
| AutoBody   | Paid, requires smart watches, no video input/feedback, not focused on martial arts |

Boxing Helper addresses these shortcomings by focusing on accessibility, martial arts, and providing direct feedback without extra hardware.

## Key Features

- Real-time body movement analysis and feedback
- Beginner-friendly, clear, and robust UI/UX
- No additional hardware required
- CoreML integration for fast, on-device inference
- Designed for martial arts and general fitness
- Fault-tolerant to user position and camera zoom
- Multi-person detection support

## Technologies Used

- SwiftUI
- CoreML
- Accelerate
- AVFoundation

## Supported devices

- iPhone/iPad (iOS > 16.0)
- Mac Catalyst

## Models tested

- **YOLO-v8 (pose-nano):**
  - Handles occlusions, low light, and blurry images well
  - Supports multiple formats and multi-person detection
  - Large community and many examples
  - Manual implementation needed (and was done) for NMS and keypoints parsing in CoreML

- **Mediapipe:**
  - Faster inference, optimized for edge devices
  - More facial keypoints
  - Conversion to CoreML is not straightforward

## User Performance Assessment Approaches

- **Angle-to-angle:**  
  Compares angles between corresponding keypoints, adapts to user position or zoom.

- **Point-to-point:**  
  Compares relative positions of detected keypoints, faster and easier to implement.

- **Realtime video matching:**  
  Matches user and anchor video on-the-fly, but is computationally intensive and less suitable for beginners.

- **Step-by-step matching:**  
  Splits anchor video into key movements, tracks user progress through each movement, advancing as correct positions are achieved

## Technical Details & Caveats

- Manual implementation of post-processing (NMS, keypoints parsing) for YOLO in CoreML
- Video stream reading/resizing is more complex than with OpenCV in Python/C++
- YOLO performed well for martial arts poses except for overlapping limbs, despite being trained on general datasets
- CoreML mixed compute precision allows high quality in critical layers while reducing overall inference speed

## Usage

1. **Install the app** on your iOS device.
2. **Select a training exercise** (boxing, fitness, etc.).
3. **Follow the on-screen instructions** and allow camera access.
4. **Perform the movements** as demonstrated by the anchor video or animation.
5. Once you **achieve the necessary position**, app shows the next exercise
6. **Receive real-time feedback** on your technique and progress.

## Future Work

- Add more exercises and training modules
- Create separate pages for specific exercise pipelines
- Enhance personalization and user feedback features
- Adapt technology for other domains: dance instruction, sports, physical rehabilitation, workplace ergonomics

