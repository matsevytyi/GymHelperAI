from ultralytics import YOLO
import cv2
import json

model = YOLO("yolov8n-pose.pt")
visual_lnk = "library-cross-jab-6"
cap = cv2.VideoCapture(f"GymHelperPoC/Resources/cross-jab/{visual_lnk}.mp4")

paused = False

while True:
    if not paused:
        ret, frame = cap.read()
        if not ret:
            break

        # Inference
        results = model(frame)

        # Process only the first person detected (index 0)
        if len(results) > 0 and len(results[0].keypoints.xy) > 0:
            person_kps = results[0].keypoints.xy[0]  # first person keypoints: array of (x,y) tuples

            # Extract required joints
            right_arm_joints = [6, 8, 10]
            left_arm_joints = [5, 7, 9]
            body_joints = [5, 6, 11, 12]

            # Define a helper to safely extract coordinates or default to (0,0)
            def get_joint_coords(idx):
                if idx < len(person_kps):
                    x, y = person_kps[idx]
                    return {"x": float(x), "y": float(y)}
                else:
                    return {"x": 0.0, "y": 0.0}

            position_output = {
                "visual_lnk": visual_lnk,
                "rightArm": [get_joint_coords(i) for i in right_arm_joints],
                "leftArm": [get_joint_coords(i) for i in left_arm_joints],
                "body": [get_joint_coords(i) for i in body_joints]
            }

            # Print as JSON string (optional: pretty print)
            print(json.dumps(position_output, indent=2))

        # Visualize
        annotated_frame = results[0].plot()
        cv2.imshow("YOLOv8 Pose Detection", annotated_frame)

    key = cv2.waitKey(1) & 0xFF
    if key == ord("q"):
        break
    elif key == ord("p"):
        paused = not paused
        if paused:
            print("⏸️ Paused")
        else:
            print("▶️ Resumed")

cap.release()
cv2.destroyAllWindows()
