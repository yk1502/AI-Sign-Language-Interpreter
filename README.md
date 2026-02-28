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
static const String _serverIp = 'YOUR_SERVER_IP_HERE';
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

