# SOS Mesh Network

> Offline disaster communication using Bluetooth.

---

## The Problem

When disasters strike — earthquakes, floods, building collapses, cellular infrastructure fails exactly when people need it most. A person trapped under debris has no way to call for help if there's no signal. Traditional communication breaks down at the worst possible moment.

## The Solution

SOS Mesh Network is an Android app that enables offline emergency communication using Bluetooth Low Energy (BLE). Devices form a self-organizing mesh network, messages hop from phone to phone until they reach someone with internet access, who then relays the SOS to rescue teams via Firebase.

No internet required. No cell towers required. Just mobile phones.

---

## How It Works

```
[Victim Phone] --BLE--> [Relay Phone] --BLE--> [Relay Phone] --BLE--> [Gateway Phone] --Internet--> [Rescue Dashboard]
```

1. **Victim** sends an SOS with their name and GPS coordinates
2. Message hops across nearby phones via BLE (flood routing with TTL)
3. Each relay checks if it's seen the message before, if not, it forwards it
4. The first relay node with internet access pushes the message to Firebase
5. Rescue team sees the victim's location in real-time on a web dashboard

---

## Node Roles

| Role | Description |
|------|-------------|
| **Victim** | Sends the initial SOS message |
| **Relay** | Receives and forwards messages across the mesh |
| **Gateway** | Last node with internet — uploads SOS to Firebase |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter (Dart) |
| BLE Scanning | `flutter_blue_plus` |
| BLE Advertising | `ble_peripheral` |
| Routing | Flood routing with UUID deduplication + TTL |
| Location | `geolocator` |
| Backend | Firebase Realtime Database |
| Dashboard | React + Leaflet.js |
| Connectivity Check | `internet_connection_checker` |

---

## BLE Architecture

Unlike naive BLE mesh implementations, this app uses a **beacon + GATT** pattern:

- **Advertising**: Only a 16-byte message ID beacon is broadcast (stays within BLE's 26-byte manufacturer data limit)
- **Payload transfer**: Full SOS message is transferred via GATT connection after a peer discovers the beacon
- **Scan/Advertise mutex**: Radio never scans and advertises simultaneously — prevents Android BLE stack conflicts
- **Deduplication**: Message IDs tracked in memory — each message is forwarded exactly once per node

---

## Project Structure

```
lib/
├── models/
│   └── sos_message.dart        # SOS data model with serialization
├── services/
│   ├── ble_mesh_service.dart   # Core BLE mesh logic
│   ├── firebase_service.dart   # Gateway upload to Firebase
│   └── location_service.dart   # GPS coordinates
├── screens/
│   ├── home_screen.dart        # Main navigation
│   ├── sos_screen.dart         # Victim SOS interface
│   ├── settings_screen.dart    # Node role selection
│   └── status_screen.dart      # Live mesh activity log
└── main.dart
```

---

## Setup

### Prerequisites
- Flutter SDK >= 3.44.0
- Android Studio (for Android SDK)
- Firebase project with Realtime Database enabled

### Installation

```bash
git clone https://github.com/harkirat-data/SOS-Mesh-Network.git
cd SOS-Mesh-Network
flutter pub get
```

### Firebase Configuration

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Realtime Database
3. Run `flutterfire configure` to generate `firebase_options.dart`

### Run

```bash
flutter run -d <device-id>
```

---

## Permissions Required

```xml
BLUETOOTH_SCAN
BLUETOOTH_ADVERTISE  
BLUETOOTH_CONNECT
ACCESS_FINE_LOCATION
INTERNET
```

---

## Current Status

- [x] Project scaffold and folder structure
- [x] BLE mesh service (beacon + GATT architecture)
- [x] Flood routing with TTL and deduplication
- [x] Firebase gateway service
- [x] Location service
- [ ] UI screens (in progress)
- [ ] Rescue dashboard (React + Leaflet)
- [ ] Multi-device testing

