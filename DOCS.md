# Project Documentation

## Technical Implementation & Google Technologies
The solution uses a real-time client-server model built on a comprehensive Google tech stack:

1. Flutter: The UI and Camera Framework. It manages the camera feed and ensures a smooth user interface while heavy AI processing occurs in the background. It was chosen for its cross-platform capabilities (Android).

2. MediaPipe: Used for real-time feature extraction. It maps 126 specific 3D hand coordinates in each frame. 

3. TensorFlow: The gesture recognition engine. It uses a custom-trained deep learning model (sequential architecture with dense and dropout layers) to classify coordinate data into characters or words.

4. Google Gemini (In Progress): Acts as the semantic layer to transform technical word streams into fluent natural language, accounting for the unique grammar of ASL.

5. Google Cloud & Firebase (Future Scaling): Plans include Firebase Analytics for user retention, Performance Monitoring for latency tracking (<100ms goal), Crashlytics for device stability (2GB RAM devices), and BigQuery for large-scale usage analysis .

## Innovation and Unique Selling Points (USP)

1. Hybrid Real-Time Processing: Send image frames to server via WebSockets for recognition to achieve rapid response times.

2. Inclusive Multimodality: Unlike competitors, this app includes a "Blind Mode" with haptic feedback and Text-to-Speech, and a "Speech-to-Text" function for two-way communication.

3. Community-Driven Data: Uses a model where certified signers can upload signs to keep the library updated with modern slang and regional variations (BIM, BSL, etc.).

4. Contextual Intelligence: Uses Gemini to provide professional-grade English rather than fragmented dictionary labels.

5. Technical Challenges & Solutions: 

    - Challenge: Transitioning from server-side processing to a hybrid model without causing network lag or UI freezing. High-speed video processing often overwhelmed mobile CPUs.

    - Debugging/Solution: 
        1. Implemented a "State-Locked" communication pipeline using WebSockets to reduce overhead.

        2. Introduced "Gatekeeper" logic on the frontend using a boolean flag and a 150ms time-based threshold to throttle frames and prevent congestion.

        3. Data Payload Optimization: Converted raw camera bytes into compressed JPEGs before Base64 encoding to slash bandwidth requirements.

    - Impact: Avoided server lag and achieved a stable 30 FPS.

## Success Metrics
1. Speed: Latency < 100 milliseconds from gesture to text output.

2. Compatibility: 90% device compatibility, maintaining stability on devices with as little as 2GB RAM.

3. Accuracy: 95% Model Accuracy and a Word Error Rate (WER) < 10%.

## Technical Trade-offs

1. Mobile vs. Web: Shifted from Web to Mobile-first (using Flutter) based on 100% of user feedback prioritizing portability.

2. Coordinate vs. Video: Chose to send 126 3D coordinates rather than raw video frames to the server to minimize data usage and prevent UI lag.

3. Feature Prioritization: Removed a planned "user-differentiation" feature (distinguishing between multiple speakers) after users indicated they prioritized translation speed and accuracy over identification.