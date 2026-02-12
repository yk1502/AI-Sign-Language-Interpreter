import cv2
import mediapipe as mp
import csv
import numpy as np
import os
import time
from collections import Counter

# --- CONFIGURATION ---
ACTIONS = {
    ord('a'): (0, "A"), 
    ord('b'): (1, "B"), 
    ord('c'): (2, "C"),
    ord('n'): (3, "No-Op"), 
    ord('h'): (4, "Hello"), 
    ord('m'): (5, "My"),
    ord('e'): (6, "Name"), 
    ord('t'): (7, "T"), 
    ord('p'): (8, "E"), 
    ord('o'): (9, "O"),
}
DATA_FILE = 'sign_data_multi.csv'
# ---------------------

mp_holistic = mp.solutions.holistic
cap = cv2.VideoCapture(0)

# Recording States
recording = False
countdown_start = 0
current_label = None
current_name = ""
temp_buffer = [] 

def get_counts():
    if not os.path.exists(DATA_FILE): return {}
    with open(DATA_FILE, 'r') as f:
        reader = csv.reader(f)
        labels = [row[0] for row in reader if row]
    return Counter(labels)

def extract_landmarks(results):
    lh = [item for lm in results.left_hand_landmarks.landmark for item in (lm.x - results.left_hand_landmarks.landmark[0].x, lm.y - results.left_hand_landmarks.landmark[0].y, lm.z - results.left_hand_landmarks.landmark[0].z)] if results.left_hand_landmarks else [0.0]*63
    rh = [item for lm in results.right_hand_landmarks.landmark for item in (lm.x - results.right_hand_landmarks.landmark[0].x, lm.y - results.right_hand_landmarks.landmark[0].y, lm.z - results.right_hand_landmarks.landmark[0].z)] if results.right_hand_landmarks else [0.0]*63
    return lh + rh

sample_counts = get_counts()

with mp_holistic.Holistic(min_detection_confidence=0.5, min_tracking_confidence=0.5) as holistic:
    while cap.isOpened():
        success, frame = cap.read()
        if not success: break
        frame = cv2.flip(frame, 1)
        results = holistic.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        
        key = cv2.waitKey(1) & 0xFF
        
        # 1. Handle Key Press (Start Countdown)
        if key in ACTIONS and not recording and countdown_start == 0:
            current_label, current_name = ACTIONS[key]
            countdown_start = time.time()

        # 2. Logic for Countdown vs Recording
        if countdown_start > 0:
            elapsed = time.time() - countdown_start
            if elapsed < 3:
                # Display Countdown
                cv2.putText(frame, f"GET READY: {int(4-elapsed)}", (150, 250), 
                            cv2.FONT_HERSHEY_SIMPLEX, 3, (0, 255, 255), 5)
            else:
                # Start Recording
                recording = True
                countdown_start = 0
                temp_buffer = [] 
                print(f"STARTING: {current_name}")

        # 3. Handle Stop and Truncate
        if key == ord('s') and recording:
            recording = False
            # Truncate the last 10 frames
            clean_data = temp_buffer[:-10] if len(temp_buffer) > 10 else []
            
            with open(DATA_FILE, 'a', newline='') as f:
                writer = csv.writer(f)
                writer.writerows(clean_data)
            
            sample_counts[str(current_label)] = sample_counts.get(str(current_label), 0) + len(clean_data)
            print(f"STOPPED: Saved {len(clean_data)} frames for {current_name}")
            temp_buffer = []

        # 4. Buffering Data
        if recording:
            features = extract_landmarks(results)
            temp_buffer.append([current_label] + features)
            cv2.putText(frame, f"RECORDING {current_name}...", (10, 50), 
                        cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)

        cv2.imshow('Clean Collector', frame)
        if key == ord('q'): break

cap.release()
cv2.destroyAllWindows()