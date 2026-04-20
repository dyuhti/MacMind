# Cross-Platform Configuration Guide

## ✅ Changes Made for Android + iOS Compatibility

Your app now runs on both **Android and iOS** with proper API endpoint configuration.

---

## 🔧 What Was Fixed

### 1. **Hardcoded Android Emulator URL** ❌ → ✅ **Dynamic Cross-Platform URL**

| Before | After |
|--------|-------|
| `http://10.0.2.2:5000` | `ApiConfig.baseUrl` (auto-detects platform) |

**Why this matters:**
- `10.0.2.2` = Android emulator only (connects to host machine)
- Real Android devices = `localhost` or actual server IP
- iOS (simulator/device) = `localhost`

---

## 📍 Files Changed

### **New File: `lib/config/api_config.dart`**
- Provides platform-aware base URL selection
- Supports development vs production modes
- Abstracts away platform-specific concerns

### **Updated Files:**
1. `lib/services/auth_service.dart` - Uses `ApiConfig.baseUrl`
2. `lib/services/agent_constants_service.dart` - Uses `ApiConfig.baseUrl`
3. `lib/screens/results_screen.dart` - Uses `ApiConfig.baseUrl`
4. `lib/widgets/case_history_dialog.dart` - Uses `ApiConfig.baseUrl`

### **Android Config:**
- `android/app/src/main/res/xml/network_security_config.xml` (NEW)
- `android/app/src/main/AndroidManifest.xml` (UPDATED)
- Allows HTTP for localhost in development
- Production uses HTTPS only

### **iOS Config:**
- `ios/Runner/Info.plist` (UPDATED)
- Added App Transport Security exceptions for localhost
- Allows HTTP for development

---

## 🚀 How to Configure for Your Environment

### **Option 1: Local Development (Recommended)**

If your backend server runs on the same machine/network as your mobile device:

```dart
// lib/config/api_config.dart
static const String developmentBaseUrl = "http://localhost:5000";
```

**This works for:**
- ✅ iOS simulator (on Mac with backend running locally)
- ✅ iOS physical device (on same WiFi as backend)
- ✅ Android emulator (API 30+)
- ✅ Android physical device (on same WiFi as backend)

---

### **Option 2: Using Your Computer's IP Address**

If devices are on different networks, use your computer's local IP:

```dart
// lib/config/api_config.dart
// First, find your IP: ipconfig (Windows) or ifconfig (Mac/Linux)
static const String developmentBaseUrl = "http://192.168.1.100:5000";
```

---

### **Option 3: Production Server**

For release build, update the production URL:

```dart
// lib/config/api_config.dart
static const String productionBaseUrl = "https://your-api-domain.com";
```

The app automatically uses:
- **Debug mode** → `developmentBaseUrl` (localhost)
- **Release mode** → `productionBaseUrl` (HTTPS)

---

## 📱 Testing on Different Platforms

### **iOS Simulator**
```bash
flutter run -d "iPhone 15 Pro"
```
✅ Works with `localhost:5000`

### **iOS Physical Device**
```bash
flutter run -d <device-id>
```
✅ Works with `localhost:5000` (if on same WiFi)

### **Android Emulator**
```bash
flutter run -d emulator-5554
```
✅ Works with `localhost:5000` (API 30+) or `10.0.2.2:5000` (older)

### **Android Physical Device**
```bash
flutter run -d <device-id>
```
✅ Works with `localhost:5000` or your computer's IP

---

## 🔐 Security Notes

### **Development**
- ✅ HTTP allowed for `localhost` and `127.0.0.1`
- ✅ Useful for local testing
- ⚠️ Remove before production release

### **Production**
- ✅ Must use HTTPS only
- ✅ Update `ApiConfig.productionBaseUrl` to HTTPS
- ✅ Remove HTTP exceptions from Android/iOS configs

---

## ✔️ Verification Checklist

- [x] All hardcoded `10.0.2.2` URLs replaced with `ApiConfig.baseUrl`
- [x] Android network security config allows HTTP for localhost
- [x] iOS App Transport Security allows localhost development
- [x] `flutter analyze` passes (no errors)
- [x] Code compiles for both Android and iOS

---

## 🔄 How It Works

```
┌─────────────────────────────────────────────────────┐
│ Flutter App Starts                                  │
└────────────────┬────────────────────────────────────┘
                 │
                 ├─→ kDebugMode == true
                 │   └─→ Use developmentBaseUrl (localhost:5000)
                 │
                 └─→ kDebugMode == false
                     └─→ Use productionBaseUrl (https://...)
                     
┌─────────────────────────────────────────────────────┐
│ Any API Call (auth, cases, agents)                 │
│ ApiConfig.baseUrl → appropriate URL                │
└─────────────────────────────────────────────────────┘
```

---

## 📌 Quick Start

1. **Start your Node.js backend:**
   ```bash
   cd backend
   npm install
   npm start
   ```
   Should be running on `http://localhost:5000`

2. **Run Flutter app:**
   ```bash
   flutter run
   ```
   Automatically connects to `localhost:5000`

3. **Test on different devices:**
   - iOS Simulator ✅
   - Android Emulator ✅
   - Physical devices ✅

Everything should work seamlessly now! 🎉
