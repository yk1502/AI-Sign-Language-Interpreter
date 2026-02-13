import base64
import cv2
import numpy as np
import mediapipe as mp
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import tensorflow as tf

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# 1. Load Model & MediaPipe
model = tf.keras.models.load_model('sign_language_model.keras')
mp_holistic = mp.solutions.holistic
holistic = mp_holistic.Holistic(static_image_mode=True, min_detection_confidence=0.5)

LABELS = {0: "A", 1: "B", 2: "C", 3: "No-Op", 4: "Hello", 5: "My", 6: "Name", 7: "T", 8: "E", 9: "O"}

# 2. Define Input: Base64 String
class ImageInput(BaseModel):
    image: str

# 3. Extract Landmarks(Similar to collect.py)
def extract_landmarks(results):
    lh = [item for lm in results.left_hand_landmarks.landmark for item in (lm.x - results.left_hand_landmarks.landmark[0].x, lm.y - results.left_hand_landmarks.landmark[0].y, lm.z - results.left_hand_landmarks.landmark[0].z)] if results.left_hand_landmarks else [0.0]*63
    rh = [item for lm in results.right_hand_landmarks.landmark for item in (lm.x - results.right_hand_landmarks.landmark[0].x, lm.y - results.right_hand_landmarks.landmark[0].y, lm.z - results.right_hand_landmarks.landmark[0].z)] if results.right_hand_landmarks else [0.0]*63
    return lh + rh

@app.websocket("/ws/predict")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    print("Client Connected")
    
    try:
        while True:
            # 1. Receive Base64 string directly
            data = await websocket.receive_text()
            
            # 2. Decode Image
            if ',' in data:
                data = data.split(',')[1]
            
            nparr = np.frombuffer(base64.b64decode(data), np.uint8)
            frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

            # 3. Process (MediaPipe)
            results = holistic.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
            
            # 4. Extract & Predict
            if results.left_hand_landmarks or results.right_hand_landmarks:
                features = extract_landmarks(results)
                
                prediction = model.predict(np.array([features]), verbose=0)
                label = LABELS.get(np.argmax(prediction), "Unknown")
                conf = float(np.max(prediction))
                
                # 5. Send Result back to Client
                await websocket.send_json({"label": label, "confidence": conf})
            else:
                await websocket.send_json({"label": "No Hands", "confidence": 0.0})

    except Exception as e:
        print(f"Connection Closed: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)