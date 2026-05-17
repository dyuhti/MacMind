# Speech-to-Text Implementation Fix - Debugging Guide

## Overview

Fixed the speech-to-text implementation to properly handle voice recognition results and update TextFields in real time. The issue was that spoken words were not appearing in the TextField, even though permissions and initialization were successful.

## What Was Fixed

### 1. **Speech Result Handling**
- ✅ Improved `onResult` callback with comprehensive logging
- ✅ Proper extraction of `recognizedWords` from results
- ✅ Real-time TextEditingController updates
- ✅ Handling of both partial and final results

### 2. **Locale Handling**
- ✅ Default locale fallback (en_US) if system locale is null
- ✅ Proper locale ID passing to `listen()` method
- ✅ Debug logging of which locale is being used

### 3. **Listen Parameters**
- ✅ Fixed `listenMode` to `ListenMode.dictation`
- ✅ Enabled `partialResults: true` for real-time updates
- ✅ Added `sampleRate: 48000` for clarity
- ✅ Proper `pauseFor` and `listenFor` durations

### 4. **Debug Logging**
- ✅ Comprehensive logging at every step
- ✅ Emoji tags for visual scanning
- ✅ Field tracking and status reporting
- ✅ Error messages with stack traces

## Debug Log Tags to Monitor

Search for these tags in your Flutter console:

| Tag | What It Shows |
|-----|---------------|
| `[SpeechInputService]` | Core speech recognition lifecycle |
| `[VoiceInputMicButton]` | User interactions and UI updates |
| `[MicrophonePermissionService]` | Permission state changes |

## Testing Steps

### Step 1: Check Debug Output

1. Open Flutter console
2. Run the app: `flutter run`
3. Look for initialization logs:
   ```
   [SpeechInputService] 🔄 Initializing speech recognition...
   [SpeechInputService] ✅ Speech recognition initialized successfully (locale: en_US)
   ```

### Step 2: Test First Voice Input

1. Navigate to any calculator screen (e.g., Oxygen Cylinder Module)
2. Tap the microphone button on the Pressure field
3. Check console for:
   ```
   [VoiceInputMicButton] 🎤 Microphone button tapped for field: Pressure
   [SpeechInputService] 🎤 Starting listener for field: <fieldId>
   [SpeechInputService] ✅ Speech recognition listener started successfully
   [SpeechInputService] 👂 Actively listening for speech...
   ```

### Step 3: Verify Voice Recognition

1. Speak a number (e.g., "2000")
2. Look for in console:
   ```
   [SpeechInputService] 📝 Speech result received:
   [SpeechInputService]    - Text: "2000"
   [SpeechInputService]    - Partial: true
   [SpeechInputService]    - Confidence: 0.95
   [SpeechInputService] ✅ Controller updated with text: "2000"
   [VoiceInputMicButton] 📝 Partial result: "2000"
   ```

3. **Check the TextField** - text should appear immediately

### Step 4: Test Final Result

1. Pause after speaking
2. Wait for the pause duration (3 seconds)
3. Console should show:
   ```
   [SpeechInputService] ✅ Final speech result received: "2000"
   [VoiceInputMicButton] ✅ Final result: "2000"
   [SpeechInputService] 🛑 Speech recognition stopped (status: done)
   [SpeechInputService] 🔄 Resetting listening session
   ```

### Step 5: Test Multiple Fields

1. Use voice input on multiple fields
2. Verify active field tracking:
   ```
   [SpeechInputService] 🎤 Starting listener for field: pressure_2000
   [SpeechInputService] 🔄 Switching fields - stopping previous listener
   [SpeechInputService] 🎤 Starting listener for field: cylinder_type_3
   ```

## Common Debug Scenarios

### Scenario 1: Voice Input Not Appearing

**Console Output Should Show:**
```
[SpeechInputService] 📝 Speech result received:
[SpeechInputService]    - Text: "2000"
[SpeechInputService] ✅ Controller updated with text: "2000"
```

**If Controller Update Fails:**
```
[SpeechInputService] ❌ Error updating controller: <error>
```

**What to Check:**
1. Is the TextField mounted?
2. Is the controller valid?
3. Are there validation rules preventing the update?

### Scenario 2: Listening Doesn't Start

**Expected:**
```
[SpeechInputService] ✅ Speech recognition listener started successfully
[SpeechInputService] 👂 Actively listening for speech...
```

**If It Fails:**
```
[SpeechInputService] ❌ Error starting listener: <error>
[SpeechInputService] Stack trace: <stack trace>
```

**What to Check:**
1. Permissions granted?
2. Microphone available?
3. Device language/locale compatible?

### Scenario 3: No Speech Detected

**Expected:**
```
[SpeechInputService] 📈 Speech received: false
[SpeechInputService] 🤐 No speech detected - calling onNoSpeech callback
```

**What to Check:**
1. Microphone volume sufficient?
2. Background noise too high?
3. Speaking clearly?

### Scenario 4: Permission Issues

**Expected (First Time):**
```
[MicrophonePermissionService] Requesting microphone permission...
[MicrophonePermissionService] Permission request result: granted
```

**If Denied:**
```
[MicrophonePermissionService] Permission request result: denied
[VoiceInputMicButton] 📍 Showing permission error dialog
```

**If Permanently Denied:**
```
[MicrophonePermissionService] Permission permanently denied, opening app settings...
```

## Full Lifecycle Example

### Perfect Flow
```
1. User taps mic button
   [VoiceInputMicButton] 🎤 Microphone button tapped for field: Pressure

2. Check initialization
   [SpeechInputService] 🔄 Initializing speech recognition...
   [SpeechInputService] ✅ Speech recognition initialized successfully

3. Start listening
   [SpeechInputService] 🎤 Starting listener for field: <fieldId>
   [SpeechInputService] 📍 Using locale: en_US
   [SpeechInputService] ✅ Speech recognition listener started successfully
   [VoiceInputMicButton] 👂 Listening started for field: Pressure

4. Recognize speech
   [SpeechInputService] 👂 Actively listening for speech...
   [SpeechInputService] 📝 Speech result received:
   [SpeechInputService]    - Text: "2000"
   [SpeechInputService]    - Partial: true
   [SpeechInputService]    - Confidence: 0.95
   [SpeechInputService] ✅ Controller updated with text: "2000"

5. Final result
   [SpeechInputService] ✅ Final speech result received: "2000"
   [VoiceInputMicButton] ✅ Final result: "2000"
   [VoiceInputMicButton] 📝 Snackbar shown: "Voice recognized: \"2000\""

6. Cleanup
   [SpeechInputService] 🛑 Speech recognition stopped (status: done)
   [SpeechInputService] 🔄 Resetting listening session
   [SpeechInputService] ✅ Session reset complete
```

## Quick Troubleshooting Checklist

- [ ] Console shows `✅ Speech recognition initialized successfully`
- [ ] Console shows `✅ Speech recognition listener started successfully` after tap
- [ ] Console shows `📝 Speech result received` when you speak
- [ ] Console shows `✅ Controller updated with text:` with your spoken words
- [ ] TextField shows the recognized text
- [ ] Mic icon glows/animates while listening
- [ ] Status changes to "done" after pause
- [ ] Permission dialog shows when needed

## Enable Full Debug Logging

Add this to your `SpeechInputService` initialization if you need even more detail:

```dart
_available = await _speechToText.initialize(
  onStatus: _handleStatus,
  onError: _handleError,
  debugLogging: true,  // This is already enabled!
);
```

This enables internal `speech_to_text` package logging.

## Platform-Specific Debug Info

### Android
- Look for `speech_to_text` native logs
- Check microphone permission in Settings
- Verify API level >= 23

### iOS
- Check privacy settings for microphone access
- Look for speech recognition entitlements
- Verify NSMicrophoneUsageDescription is set

## Next Steps After Debugging

1. **If Working**: Deploy to TestFlight/internal testing
2. **If Issues Persist**:
   - Collect full console output (copy all logs)
   - Check device microphone (test in OS voice recorder)
   - Try different locale or device
   - Check for platform-specific issues

## Log Filtering in VS Code

Use the Debug Console filter to focus on speech logs:

**Android Studio/IntelliJ:**
- Logcat filter: `SpeechInputService|VoiceInputMicButton`

**VS Code Terminal:**
- Manually search/highlight `[Speech` and `[Voice`

## Performance Metrics to Monitor

- Time from button tap to "Listening started": ~300-500ms
- Time from speech to "Text appears": ~100-200ms (partial)
- Memory usage while listening: Should be stable
- Processor load: Minimal during listening

## Sample Console Output

When you run the app and use voice input, you should see output like:

```
I/flutter (12345): [SpeechInputService] 🔄 Initializing speech recognition...
I/flutter (12345): [SpeechInputService] ✅ Speech recognition initialized successfully (locale: en_US)
I/flutter (12345): [VoiceInputMicButton] 🎤 Microphone button tapped for field: Pressure
I/flutter (12345): [SpeechInputService] 🎤 Starting listener for field: 12345
I/flutter (12345): [SpeechInputService] 📍 Using locale: en_US
I/flutter (12345): [SpeechInputService] ✅ Speech recognition listener started successfully
I/flutter (12345): [VoiceInputMicButton] 👂 Listening started for field: Pressure
I/flutter (12345): [SpeechInputService] 👂 Actively listening for speech...
I/flutter (12345): [SpeechInputService] 📝 Speech result received:
I/flutter (12345): [SpeechInputService]    - Text: "2000"
I/flutter (12345): [SpeechInputService]    - Partial: true
I/flutter (12345): [SpeechInputService]    - Confidence: 0.95
I/flutter (12345): [SpeechInputService] ✅ Controller updated with text: "2000"
I/flutter (12345): [VoiceInputMicButton] ✅ Final result: "2000"
```

## Still Having Issues?

1. **Check the console logs** - every error prints details
2. **Enable `debugLogging: true`** - already done!
3. **Test on different device** - might be device-specific
4. **Check microphone works** - test with device voice recorder
5. **Verify locale** - some locales may not work well
6. **Review file changes** - ensure all edits are applied

See [MICROPHONE_PERMISSIONS_TESTING.md](MICROPHONE_PERMISSIONS_TESTING.md) for permission-specific issues.
