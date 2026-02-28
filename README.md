# YouTube Demonstration Link: 
https://youtu.be/pRTezUOc3Rw

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

## Technical Architecture

- The solution architecture follows a real-time client-server model designed to bridge the gap between high-performance AI processing and mobile accessibility.

    1. Frontend: A Flutter mobile application serves as the primary user interface. It captures live video frames from the device camera and uses an IOWebSocketChannel to establish a persistent, low-latency connection with the backend.

    2. Backend: Built using the FastAPI framework, it acts as the intelligence hub. Base64-encoded image frames are passed to a Python model wrapper.

- AI Components:

    1. Google MediaPipe Holistic: Performs landmarking to extract 126 specific 3D coordinates representing hand geometry.

    2. TensorFlow: A custom-trained neural network with a sequential architecture (dense and dropout layers) that classifies hand positions into alphanumeric characters or words.

    3. Google Gemini (In Progress): Acts as a semantic layer to transform raw word streams into fluent English sentences, accounting for unique ASL grammatical structures.

    4. Data Storage: Handled through a CSV-based dataset strategy storing labeled landmark coordinates used during training.

- Accessibility Integration:

    1. Text-to-Speech: Provides audible feedback for "Blind Mode".

    2. Speech-to-Text: Enables two-way communication by displaying spoken replies to the signer.

## Implementation Details

- The project focuses on transforming a smartphone into an intelligent communication tool using several key implementations:

    1. Platform Transition: Following user feedback where 100% of respondents prioritized a smartphone app, development shifted from a web version to a mobile application using the Flutter framework.

    2. Real-time Processing: The system uses WebSockets instead of standard HTTP requests to achieve rapid response times necessary for fluid recognition.

    3. Multimodal Features: Based on user suggestions, the team implemented Text-to-Speech and a dedicated Blind Mode with haptic feedback and automated voice guides.

    4. Model Optimization: To ensure high performance, the system uses a coordinate-based approach (MediaPipe) rather than sending heavy raw video frames, which minimizes data usage and latency.

    5. Community-Driven Data: A custom data pipeline allows certified signers to upload signs and text to continuously improve the library.

## Challenges Faced
The most significant technical challenge was transitioning from a server-side processing model to a hybrid frontend-processing architecture to achieve real-time recognition without network lag or UI freezing.

- The Problem: High-speed video processing can overwhelm local mobile hardware, leading to UI freezes and high battery drain.

- The Debugging & Solution Process:

    1. State-Locked Pipeline: Transitioned to persistent WebSocket connections to reduce overhead.

    2. Gatekeeper Logic: Introduced a boolean flag and a 150ms time-based threshold to throttle outgoing frames and prevent network congestion.

    3. Payload Optimization: Converted raw camera bytes into compressed JPEGs before Base64 encoding, significantly reducing bandwidth requirements.

    4. The Impact: These changes eliminated the risk of server crashes and resulted in a smooth UI where video remains responsive while AI processes coordinates in the background.

## Future Roadmap

- The project expansion is organized into three distinct phases over a 36-month timeline:

    1. Phase 1: Nuance Differentiation (0-12 months):
    Focus on capturing facial expressions (raised eyebrows, mouth shapes) using MediaPipe facial mesh.
    Launch a community-contributed landmark library to train models on regional sign languages like BIM or BSL.
    Target expansion into specialist clinics and hospitals.

    2. Phase 2: Wearable Transformation (12-24 months): Transition the interface to Augmented Reality (AR) glasses. Optimize Flutter software for specialized wearable hardware to provide hands-free digital overlays of translations.

    3. Phase 3: Global Bridges (24-36 months):
    Leverage Gemini's inference capabilities for cross-modal translation between different sign languages and spoken languages.
    Enable users to sign in their native gestures and have it converted instantly into different spoken languages (e.g., signing BIM and outputting spoken Mandarin).