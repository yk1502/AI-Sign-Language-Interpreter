from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from model import OUTPUT_LABELS, Model
import uvicorn

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

model = Model()

@app.websocket("/ws/predict")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    print("Client Connected")
    
    try:
        while True:
            data = await websocket.receive_text()
            
            result = {"label": "No Hands", "confidence": 0.0}

            if ',' in data:
                data = data.split(',')[1]
                label, confidence, _ = model.forward(data)
                result = {"label": label, "confidence": float(confidence)}
            
            await websocket.send_json(result)

    except Exception as e:
        print(f"Connection Closed: {e}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)