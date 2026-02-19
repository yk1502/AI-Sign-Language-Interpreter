import tensorflow as tf
import mediapipe as mp
import numpy as np
import base64
import cv2

OUTPUT_LABELS = {0: "A", 1: "B", 2: "C", 3: "No-Op", 4: "Hello", 5: "My", 6: "Name", 7: "T", 8: "E", 9: "O"}

class Model:
    def __init__(self, path='sign_language_model.keras'):
        self.model = tf.keras.models.load_model(path)
        self.holistic = mp.solutions.holistic.Holistic(static_image_mode=True, min_detection_confidence=0.5)

    def forward(self, image):

        def process_image(image):
            image = np.frombuffer(base64.b64decode(image), np.uint8)
            image = cv2.imdecode(image, cv2.IMREAD_COLOR)
            image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            return image

        def extract_landmarks(mediapipe_output):
            lh = [item for lm in mediapipe_output.left_hand_landmarks.landmark for item in (lm.x - mediapipe_output.left_hand_landmarks.landmark[0].x, lm.y - mediapipe_output.left_hand_landmarks.landmark[0].y, lm.z - mediapipe_output.left_hand_landmarks.landmark[0].z)] if mediapipe_output.left_hand_landmarks else [0.0]*63
            rh = [item for lm in mediapipe_output.right_hand_landmarks.landmark for item in (lm.x - mediapipe_output.right_hand_landmarks.landmark[0].x, lm.y - mediapipe_output.right_hand_landmarks.landmark[0].y, lm.z - mediapipe_output.right_hand_landmarks.landmark[0].z)] if mediapipe_output.right_hand_landmarks else [0.0]*63
            return lh + rh
    
        # Get mediapipe output
        image = process_image(image)
        mediapipe_output = self.holistic.process(image)
        features = extract_landmarks(mediapipe_output)

        # Predict mediapipe output using self-trained tensorflow model
        prediction = self.model.predict(np.array([features]), verbose=0)

        # Get and return final predicted output
        label_index = np.argmax(prediction)
        label = OUTPUT_LABELS.get(label_index, "Unknown")
        confidence = float(np.max(prediction))
        return label, confidence, label_index 

    