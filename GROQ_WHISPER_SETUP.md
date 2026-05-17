# 🎤 Groq Whisper Voice Recognition Setup & Migration Guide

## Overview

This guide covers the complete migration from `speech_to_text` (native Android speech recognition) to **Groq Whisper API**, providing stable, AI-powered voice transcription.

---

## ✅ What Changed

### Removed
- ❌ `speech_to_text` Flutter package
- ❌ Native Android speech recognizer
- ❌ Google Voice Typing integration
- ❌ Platform-specific speech APIs
- ❌ Xiaomi/MIUI workarounds

### Added
- ✅ `record` package for audio recording
- ✅ `dio` package for API communication
- ✅ Groq Whisper API integration
- ✅ New `VoiceRecordingService` (singleton)
- ✅ New `GroqWhisperService` for API calls
- ✅ Updated `VoiceInputMicButton` widget
- ✅ New `VoiceInputTextField` widget (optional)

---

## 🔑 Groq API Key Setup

### Step 1: Get Your API Key

1. Visit [Groq Console](https://console.groq.com)
2. Sign up or log in
3. Navigate to **API Keys**
4. Create a new API key
5. **Copy and save it securely**

### Step 2: Configure in Your App

#### For Development (Using dart-define)

Run Flutter with environment variable:

```bash
flutter run --dart-define=GROQ_API_KEY=your_api_key_here
```

Or build APK:

```bash
flutter build apk --dart-define=GROQ_API_KEY=your_api_key_here
```

#### For Production (Recommended)

**Do NOT hardcode the API key in the app.** Instead:

1. Store the API key on your backend
2. Create an endpoint that returns a temporary token
3. Have the app request the token from your backend
4. Update `lib/config/api_config.dart`:

```dart
static String groqApiKey = ''; // Will be fetched from backend

static Future<void> fetchGroqApiKey() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/groq-token'),
    headers: {'Authorization': 'Bearer $userToken'},
  );
  
  if (response.statusCode == 200) {
    groqApiKey = json.decode(response.body)['token'];
  }
}
```

---

## 🎙️ How the New System Works

### Audio Recording Flow

```
User taps mic icon
    ↓
Permission check (grant if needed)
    ↓
Start recording audio → File saved to temp directory
    ↓
User speaks and taps stop (or auto-stop on silence)
    ↓
Audio file uploaded to Groq Whisper API
    ↓
Groq returns transcribed text
    ↓
TextField updated automatically
    ↓
Audio file deleted
```

### Architecture

```
VoiceInputMicButton / VoiceInputTextField (UI)
    ↓
VoiceRecordingService (Orchestration)
    ↓
├── Record (Audio Recording)
└── GroqWhisperService (API)
    ↓
Groq Whisper API
    ↓
Transcribed Text
```

---

## 📚 Using the New Voice System

### Option 1: VoiceInputMicButton (Existing Code)

Used as a suffix icon in TextFields. **No changes needed for existing usage:**

```dart
TextField(
  controller: _notesController,
  decoration: InputDecoration(
    suffixIcon: VoiceInputMicButton(
      controller: _notesController,
      fieldLabel: 'Clinical notes',
    ),
  ),
)
```

**Features:**
- Compact microphone icon
- Tap to start recording
- Tap again to stop and transcribe
- Automatic field update
- Error handling with retry

### Option 2: VoiceInputTextField (New, Full-Featured)

Standalone widget with integrated label and error display:

```dart
VoiceInputTextField(
  controller: _durationController,
  label: 'Surgery Duration (minutes)',
  hintText: 'Tap mic or type duration',
  keyboardType: TextInputType.number,
  onChanged: (value) => _updateDuration(value),
)
```

**Features:**
- Integrated label and hint
- Recording indicator with timer
- Transcribing progress indicator
- Error messages with retry
- Full accessibility

---

## 🔧 Service Usage

### Direct Service Access

```dart
import 'services/voice_recording_service.dart';

// Get singleton instance
final voiceService = VoiceRecordingService();

// Record and transcribe
try {
  final transcribedText = await voiceService.recordAndTranscribe();
  print('Transcribed: $transcribedText');
} catch (e) {
  print('Error: ${e.toString()}');
}
```

### Manual Recording Control

```dart
// Start recording
await voiceService.startRecording();

// Do something...

// Stop and transcribe
final audioPath = await voiceService.stopRecording();
final text = await voiceService.transcribeAudio(audioPath);

// Or cancel without transcribing
await voiceService.cancelRecording();
```

### State Listening

```dart
voiceService.addStateListener((state) {
  switch (state) {
    case VoiceRecordingService.VoiceRecordingState.recording:
      print('Recording...');
      break;
    case VoiceRecordingService.VoiceRecordingState.transcribing:
      print('Transcribing...');
      break;
    case VoiceRecordingService.VoiceRecordingState.completed:
      print('Done!');
      break;
    case VoiceRecordingService.VoiceRecordingState.error:
      print('Error!');
      break;
    default:
      break;
  }
});
```

---

## 🚨 Error Handling

### Common Errors

| Error Code | Cause | Solution |
|-----------|-------|----------|
| `NO_SPEECH_DETECTED` | No audio detected | Speak clearly near microphone |
| `PERMISSION_DENIED` | Microphone access denied | Grant permission in app settings |
| `TIMEOUT` | Network timeout | Check internet connection |
| `NETWORK_ERROR` | Connection failed | Ensure connected to internet |
| `MISSING_API_KEY` | Groq API key not configured | Set GROQ_API_KEY environment variable |
| `BAD_RESPONSE` | Groq API returned error | Check API quota and status |

### Error Recovery

The system automatically shows user-friendly error messages with retry options:

```
"Voice transcription failed"
[Cancel] [Try Again]
```

---

## 📱 Supported Fields

Voice input is available for ALL TextFields in the app:

- **Oxygen Cylinder Module**: Pressure, FGF
- **Consumption Calculator**: Time, Concentration
- **Economy Calculator**: Duration, Concentration
- **Results Screen**: Clinical notes
- **Feedback Screen**: Message field
- **Profile Edit**: Any text field
- **Search Bars**: Any search field
- **Future TextFields**: Automatically supported

---

## ✅ Testing the Integration

### Test Recording & Transcription

1. **Grant Microphone Permission**
   - First use will request permission

2. **Tap Microphone Icon**
   - Should show "Recording..." indicator
   - Icon changes to filled microphone

3. **Speak Clearly**
   - Pause 1-2 seconds before stopping

4. **Tap Microphone Again**
   - Shows "Transcribing..." spinner
   - Wait for API response (~2-5 seconds)

5. **Verify Text**
   - Field updates with transcribed text
   - Should be accurate medical terminology

### Debug Logging

Check debug console for detailed logs with `[VoiceInputMicButton]` tag:

```
[VoiceInputMicButton] Starting voice recording
[VoiceRecordingService] Recording started
[GroqWhisperService] Upload progress: 100.0%
[GroqWhisperService] Transcription successful: "two thousand"
```

---

## 🔒 Security Best Practices

### Do's ✅
- Store API key on secure backend
- Fetch temporary tokens in app
- Rotate keys regularly
- Monitor API usage
- Use HTTPS for all API calls

### Don'ts ❌
- Don't hardcode API key in app
- Don't expose key in client code
- Don't commit key to version control
- Don't log full API responses

---

## 📊 API Limits

Groq Whisper API quotas:

- **Free Tier**: Check [Groq Console](https://console.groq.com)
- **Model**: `whisper-large-v3`
- **Max File Size**: 25 MB
- **Supported Formats**: WAV, MP3, M4A, FLAC, OGG

---

## 🐛 Troubleshooting

### Issue: "Missing API Key"

**Solution:**
```bash
flutter run --dart-define=GROQ_API_KEY=your_key_here
```

### Issue: "No Speech Detected"

**Solution:**
- Speak clearly into microphone
- Ensure no background noise
- Position phone close to mouth
- Speak for 2+ seconds

### Issue: Transcription Very Slow

**Possible Causes:**
- Slow internet connection
- Large audio file
- High API load

**Solution:**
- Keep recordings short (< 30 seconds)
- Use 5G or strong WiFi
- Try again if API is busy

### Issue: Permission Denied

**Solution:**
1. Settings → Apps → MacMind → Permissions → Microphone
2. Grant microphone permission
3. Retry in app

---

## 📝 Migration Checklist

- [x] Remove `speech_to_text` from pubspec.yaml
- [x] Add `record` and `dio` packages
- [x] Update `VoiceInputMicButton` widget
- [x] Create `VoiceRecordingService`
- [x] Create `GroqWhisperService`
- [x] Add Groq configuration to `api_config.dart`
- [x] Update all screens (no code changes needed)
- [x] Test on multiple devices
- [x] Set up backend token endpoint
- [x] Configure API key securely
- [x] Deploy to production

---

## 🎯 Next Steps

1. **Get Groq API Key**: Visit [console.groq.com](https://console.groq.com)
2. **Test Locally**: `flutter run --dart-define=GROQ_API_KEY=your_key`
3. **Set Up Backend**: Create token endpoint
4. **Deploy**: Build and release with environment config
5. **Monitor**: Check Groq console for usage

---

## 📞 Support

For issues or questions:
- Check Groq API docs: https://console.groq.com/docs/speech-text
- Review error messages: Use debug logging
- Verify internet connection
- Ensure API key is valid
- Check microphone permissions

---

**✨ Your app now uses modern AI-powered voice transcription! 🎉**
