# Setup Instructions

This project requires Python 3.11 and Flutter.

## 1. Prerequisites

Ensure you have the following installed on your system:

1. Flutter SDK

2. Python 3.11

3. Android SDK

## 2. Server Setup (Backend)

### 1. Navigate to the server branch.
 
```
git checkout server
```

### 2. Create and Activate Virtual Environment

```
py -3.11 -m venv venv

# On Windows:
venv\Scripts\activate

# On macOS/Linux:
source venv/bin/activate
```

### 3. Install Dependencies
```
pip install -r req.txt
```

### 4. Run the Server
Start the backend server. It will be configured to listen on all interfaces at port 8000.

```
python server.py
```

## 3. Network & Connection Setup
1. Retrieve Local IPv4: Identify your machine's local IPv4 address (with ipconfig)

2. Verify Network: Ensure all devices are connected to the same local network.

3. Disable VPNs: Confirm that no devices are currently using a VPN.

4. Enable Private Mode: Set your network profile to Private within your Wi-Fi settings.

5. Configure Firewall: Add a new inbound firewall rule.

6. Allow Port 8000: Set the rule to allow TCP traffic on port 8000.

## 4. Frontend Setup (Flutter)

The following instructions will run the Flutter App in Android.

### 1. Open a new terminal/command prompt

### 2. Navigate to the main branch:
```
git checkout main
```

### 3. Update IP Address
- Update the IPv4 Address in the file lib/detectionScreen.dart
- Look for the line
```
const String _serverIp = 'YOUR_SERVER_IP_HERE';
```
- Change ```YOUR_SERVER_UP_HERE``` to the IPv4 Address you obtained from the previous steps.

- Save the changes.

### 4. Connect your Android device via USB (with Developer Options and USB Debugging enabled)


### 5. Fetch Flutter dependencies and run the app:
```
flutter pub get
flutter run

# Select your Android device from the list of available devices when prompted.
```

# Project Description

## Summary and Purpose
The project is a real-time sign language translation and communication system designed to bridge the one-way communication barrier between American Sign Language (ASL) speakers and those with hearing or sensory impairments. The goal is to provide instant agency to ASL users, fostering independence and reducing reliance on expensive human interpreters for routine tasks. The system analyzes gestures to provide meaning with minimal delay while simultaneously capturing spoken language to transform it into text, creating a truly inclusive environment for deaf, non-speaking, illiterate, and blind individuals.

## Problem Statement

1. The Gap: There is a significant accessibility gap because the vast majority of hearing people lack sign language translation skills, leading to the exclusion and discrimination of vulnerable groups in digital, social, and professional situations.

2. Impacted Groups: Over 70 million deaf people worldwide, plus millions who are non-speaking, illiterate, or blind.

3. Critical Settings: Communication is severely impacted in essential environments like medical clinics, banks, retail stores, and emergency services. Misunderstandings in these high-risk areas can lead to life-threatening situations or economic exploitation.

4. Current Solution Failure: Human translation is expensive ($50-100/hour) and not available 24/7 or in remote areas. Existing AI tools often neglect the specific needs of the non-speaking, illiterate, and blind, and frequently struggle with accuracy (often below 60-70%) in realistic conditions.

5. Severity Statistic: By 2050, nearly 2.5 billion people will suffer from varying degrees of hearing loss. Currently, the ratio of certified interpreters to deaf users is roughly 1:2,500.

## SDG Alignment

1. SDG 10: Reduced Inequalities (Target 10.2): The project promotes social, economic, and political inclusion by treating communication as a fundamental human right and preventing neglect in daily life.

2. SDG 9: Industry, Innovation, and Infrastructure (Target 9.5): The solution utilizes advanced AI (MediaPipe, TensorFlow) on mobile devices to make high-tech assistance accessible to anyone with a smartphone, regardless of economic status.

## AI Alignment
The project transforms standard smartphone cameras into intelligent communication tools by understanding human movements as language rather than mere pixels. It integrates a "Semantic Layer" using Google Gemini to move beyond word-for-word dictionaries, refining raw sign sequences into natural, grammatically correct English sentences.

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