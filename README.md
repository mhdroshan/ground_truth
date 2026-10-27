# GroundTruth — Location-Verified Real-Time Citizen Journalism Platform

**GroundTruth** is a next-generation Flutter application engineered to eliminate misinformation, fake news, and coordinated propaganda during breaking events. Every post and comment is cryptographically anchored to verified eyewitnesses physically present inside defined geographic boundaries (**GeoFences**).

---

## 🌟 Core Concept: Follow Events, Not People
In traditional social platforms, remote accounts, bad actors, and bots can comment on breaking crises from thousands of miles away. 

GroundTruth inverts this paradigm:
- **Events are the central hubs**: Users follow real-world events (e.g. *Delhi Farmers Protest*, *Wayanad Flash Floods*, *London Paddington Fire*, *Tokyo Shibuya Seismic Tremor*).
- **Physical Presence Gate**: Only contributors demonstrably inside the active circular or polygon geofence are permitted to create posts, upload eyewitness footage, vote on situation polls, or comment.
- **Observer Mode**: Remote users can read verified reports and track updates, but their participation is strictly read-only to preserve ground truth.

---

## 🛡️ Multi-Layer Verification & Anti-Spoofing Architecture
GroundTruth enforces defense-in-depth across 5 verification tiers:

1. **Polygon & Radial Geofencing Engine**:
   - Geodesic Haversine calculations and Ray-casting Point-in-Polygon validation.
   - Supports irregular high-security polygons (e.g. Delhi Protest corridor across Parliament Road, India Gate, Jantar Mantar, and Connaught Place).
2. **High-Precision GNSS / GPS**:
   - Requires horizontal accuracy < 10 meters.
   - Altitude and satellite geometry checks.
3. **Anti-Spoofing & Mock Location Heuristics**:
   - Real-time detection of mock location providers, fake GPS software, and developer options spoofing.
   - Teleportation anomaly test (rejects impossible travel velocities).
4. **Hardware & OS Integrity Attestation**:
   - Verified against Google Play Integrity API (`MEETS_STRONG_INTEGRITY`) and Apple DeviceCheck / App Attest.
   - Flags rooted or jailbroken operating environments.
5. **Continuous Location Monitoring**:
   - Re-verifies coordinates before composition, during upload, and at final cryptographic hash anchoring.

---

## 📱 Features & Screen Flow

### 1. Events Feed (`HomeFeedScreen`)
- **Breaking News Ticker**: Instant red-alert ticker for active critical events.
- **Search & Filters**: Search by event, country, city, category (Protest, Disaster, War, Fire, Election, Accident, etc.).
- **Feed Tabs**: *Trending*, *Nearby* (sorted by geodesic proximity to user), *Live*, *High Activity*.
- **Rich Event Cards**: Severity risk badges (`CRITICAL`, `HIGH`, `MODERATE`), active eyewitness counters, geofence radius/polygon tags, and on-site indicator.

### 2. Event Discussion Hub (`EventDetailScreen`)
- **Tactical Radar Map**: Custom Canvas-rendered radar map with animated sweep beam, polygon vertices, epicenter marker, eyewitness density dots, and live geodesic telemetry HUD.
- **Geofence Status Banner**:
  - `🟢 GEOFENCE VERIFIED ON-SITE`: Displays accuracy and unlocks posting/commenting.
  - `🌐 OBSERVER MODE (READ-ONLY)`: Explains physical proximity restriction when outside the zone.
  - `⚠️ ANTI-SPOOF ALERT`: Warns if mock GPS or rooted OS is detected.
- **Eyewitness Timeline**: Sorted by *Most Reliable* (weighted by author trust score, confidence %, upvotes, and freshness decay), *Latest Dispatches*, or *Most Upvoted*.
- **Multi-Format Content**:
  - Breaking text dispatches
  - Photos with GPS EXIF verification watermark
  - Ground videos with hardware attestation tags
  - Interactive voice dispatches with animated sound waveforms and scrubbers
  - Eyewitness consensus polls with real-time percentage progress bars

### 3. Pre-Flight Verification & Post Composer (`CreatePostScreen`)
- **Pre-Flight Checklist**: Real-time evaluation of boundary containment, GNSS accuracy, mock GPS flags, and hardware integrity tokens.
- **Live Confidence Meter**: Displays aggregate confidence percentage (e.g. `99.4% CONF`).
- **Cryptographic Hash Anchoring**: Displays verifiable hash (e.g. `GT-SEC-9F2B-DELHI-01`).

### 4. Contributor Trust & Reputation (`ProfileScreen`)
- Contributor Trust Score (0 - 100).
- Tier badge (*Tier 1 Verified Senior Eyewitness*).
- Breakdown of verified contributions, accuracy rating, and community helpful votes.
- Real-time hardware security status diagnostics.

---

## 🚀 Running the App

### Prerequisites
- Flutter SDK (3.41+ with Dart 3.11+)

### Analyze and Run Tests
```bash
flutter analyze
flutter test
```

### Run Locally on macOS
```bash
flutter run -d macos
```

### Run on Chrome Web
```bash
flutter run -d chrome
```

### Run on iOS / Android Simulator
```bash
flutter run
```
