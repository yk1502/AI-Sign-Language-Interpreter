import cv2
import mediapipe as mp
import numpy as np
import tensorflow as tf

# 1. Load the updated model 
model = tf.keras.models.load_model('sign_language_model.keras')

# Must match the order in your ACTIONS dictionary from the collector script
actions = ['A', 'B', 'C', 'None', 'Hello', 'My', 'Name', 'T', 'E', 'O'] 
buffer_sentence = 6

# Initialize MediaPipe
mp_holistic = mp.solutions.holistic
mp_drawing = mp.solutions.drawing_utils

# Variables for Sentence Building
sentence = []
predictions = []
threshold = 0.8  # Only accept predictions above 80% confidence

def extract_landmarks(hand_landmarks):
    if hand_landmarks:
        wrist = hand_landmarks.landmark[0]
        return [item for lm in hand_landmarks.landmark for item in (lm.x - wrist.x, lm.y - wrist.y, lm.z - wrist.z)]
    return [0.0] * 63

cap = cv2.VideoCapture(0)

with mp_holistic.Holistic(min_detection_confidence=0.5, min_tracking_confidence=0.5) as holistic:
    while cap.isOpened():
        success, frame = cap.read()
        if not success: break

        frame = cv2.flip(frame, 1)
        image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = holistic.process(image)
        image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)

        # Draw hand connections
        if results.left_hand_landmarks:
            mp_drawing.draw_landmarks(image, results.left_hand_landmarks, mp_holistic.HAND_CONNECTIONS)
        if results.right_hand_landmarks:
            mp_drawing.draw_landmarks(image, results.right_hand_landmarks, mp_holistic.HAND_CONNECTIONS)

        # 2. Prediction Logic
        lh = extract_landmarks(results.left_hand_landmarks)
        rh = extract_landmarks(results.right_hand_landmarks)
        input_features = np.array([lh + rh])

        prediction = model.predict(input_features, verbose=0)
        class_id = np.argmax(prediction)
        confidence = prediction[0][class_id]

        # 3. Visualizing "Stability" (Sentence Building)
        # We check if the last 10 frames consistently predicted the same sign
        predictions.append(class_id)
        predictions = predictions[-10:] # Keep only last 10 frames
        
        if np.unique(predictions[-10:])[0] == class_id:
            if confidence > threshold:
                if actions[class_id] != 'None':
                    if len(sentence) > 0:
                        # Only add to sentence if it's different from the last word
                        if actions[class_id] != sentence[-1]:
                            sentence.append(actions[class_id])
                    else:
                        sentence.append(actions[class_id])

        if len(sentence) > buffer_sentence: # Keep the sentence display short
            sentence = sentence[-buffer_sentence:]

        # 4. Display UI
        # Top Bar for current sign
        cv2.rectangle(image, (0,0), (640, 40), (245, 117, 16), -1)
        if confidence > threshold:
             cv2.putText(image, f'CURRENT: {actions[class_id]} ({int(confidence*100)}%)', (15, 30), 
                         cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2, cv2.LINE_AA)

        # Bottom Bar for sentence history
        cv2.rectangle(image, (0, 440), (640, 480), (50, 50, 50), -1)
        cv2.putText(image, ' '.join(sentence), (15, 470), 
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2, cv2.LINE_AA)

        cv2.imshow('Teo\'s AI Sign Interpreter', image)

        k = cv2.waitKey(1) & 0xFF
        if k == ord('q'): break
        if k == ord('c'): sentence = [] # Press 'C' to clear the sentence

cap.release()
cv2.destroyAllWindows()