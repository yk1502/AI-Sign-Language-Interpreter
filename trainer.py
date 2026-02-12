import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout, Input
from tensorflow.keras.callbacks import EarlyStopping

# 1. Load the dataset
# Columns: [Label, 126 landmark features]
DATA_PATH = 'sign_data_multi.csv'

try:
    df = pd.read_csv(DATA_PATH, header=None)
    print(f"Successfully loaded {len(df)} samples.")
except FileNotFoundError:
    print("Error: 'sign_data_multi.csv' not found. Make sure you collected data first!")
    exit()

# 2. Separate Features (X) and Labels (y)
y = df.iloc[:, 0].values
X = df.iloc[:, 1:].values

# 3. Split into Train and Test sets
# test_size=0.2 means 20% of data (240 samples) will be used to test accuracy
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, shuffle=True
)

# 4. Build the Neural Network Architecture
model = Sequential([
    Input(shape=(126,)),  # 63 left hand + 63 right hand features
    Dense(128, activation='relu'),
    Dropout(0.2),         # Helps the model generalize (ignores 20% of noise)
    Dense(64, activation='relu'),
    Dense(32, activation='relu'),
    Dense(10, activation='softmax') # 4 classes: A, B, C, and No-Op
])

# 5. Compile the Model
model.compile(
    optimizer='adam',
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

# 6. Setup Early Stopping
# This will stop the training if the 'val_loss' stops improving for 10 epochs
early_stop = EarlyStopping(
    monitor='val_loss', 
    patience=10, 
    restore_best_weights=True,
    verbose=1
)

# 7. Start Training
print("Starting training...")
history = model.fit(
    X_train, y_train,
    epochs=100,
    batch_size=32,
    validation_data=(X_test, y_test),
    callbacks=[early_stop],
    shuffle=True
)

# 8. Save the Model
# Use .keras extension (modern TensorFlow standard)
model.save('sign_language_model.keras')
print("\nSuccess: Model saved as 'sign_language_model.keras'")

# 9. Final Accuracy Check
loss, accuracy = model.evaluate(X_test, y_test, verbose=0)
print(f"Final Test Accuracy: {accuracy*100:.2f}%")