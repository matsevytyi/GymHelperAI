from ultralytics import YOLO
import cv2

model = YOLO("yolov8n-pose.pt")

# cap = cv2.VideoCapture(0) 
cap = cv2.VideoCapture("perfect_test.mp4")

while True:
    ret, frame = cap.read()
    if not ret:
        break

    # Inference
    results = model(frame)

    # Results include keypoints and other metadata
    for result in results:
        keypoints = result.keypoints.xy  # shape: (num_persons, 17, 2)

        for i, person_kps in enumerate(keypoints):
            print(f"\nPerson {i+1} keypoints:")
            for idx, (x, y) in enumerate(person_kps):
                print(f"  Joint {idx}: (x={x:.2f}, y={y:.2f})")

    # visualize
    annotated_frame = results[0].plot()
    cv2.imshow("YOLOv8 Pose Detection", annotated_frame)

    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()
