# Microphone Permission Error Fix - Testing Guide

## Overview
This guide helps you validate that the microphone permission system is working correctly across all scenarios.

## Permission States to Test

### 1. **First Time Permission Request**
**Scenario**: App installed fresh, no permission granted yet
- **Steps**: 
  1. Tap microphone button on any calculator screen
  2. Permission dialog appears (native OS dialog)
  3. Grant permission
  4. Mic button should activate and start listening
- **Expected Result**: ✅ Voice input works immediately

### 2. **Permission Already Granted**
**Scenario**: User has already granted microphone permission
- **Steps**:
  1. Tap microphone button
  2. Listening state should activate immediately
- **Expected Result**: ✅ No permission dialog, starts listening directly

### 3. **Permission Denied (First Time)**
**Scenario**: User denies permission in OS dialog
- **Steps**:
  1. Tap microphone button
  2. OS permission dialog appears
  3. Tap "Don't Allow" or "Deny"
  4. MacMind error dialog should appear
- **Expected Result**: ✅ Detailed error dialog showing status and action buttons

### 4. **Permission Permanently Denied**
**Scenario**: User has permanently denied permission (dismissed multiple times or blocked in settings)
- **Steps**:
  1. Go to device settings and disable microphone permission for MacMind
  2. Return to app
  3. Tap microphone button
- **Expected Behavior**:
  - MacMind error dialog appears
  - Dialog shows: "Microphone permission is permanently denied"
  - "Open Settings" button is provided
  - Tapping "Open Settings" opens device settings
- **Expected Result**: ✅ User can navigate to settings to enable permission

### 5. **Change Permission While App in Background**
**Scenario**: User grants permission via settings while app is backgrounded
- **Steps**:
  1. Deny microphone permission initially
  2. Minimize app (go home screen)
  3. Open Settings > Apps > MacMind > Permissions > Microphone > Enable
  4. Return to app (tap app icon)
  5. Tap microphone button
- **Expected Result**: ✅ Permission is re-checked and now works (no cache stale data)

### 6. **iOS-Specific: Provisional Permission**
**iOS Only** - iOS 14+ allows provisional (temporary) access
- **Steps**:
  1. Grant provisional permission when prompted
  2. Tap microphone button
- **Expected Result**: ✅ Works with provisional access; may prompt for full access later

### 7. **iOS-Specific: Restricted Permission**
**iOS Only** - Parental controls can restrict microphone
- **Steps**:
  1. Enable parental controls on iOS device
  2. Disable microphone access
  3. Try to tap microphone button in app
- **Expected Result**: ✅ Error dialog shows "Microphone access is restricted" with guidance

### 8. **Android: Verify RECORD_AUDIO Permission**
**Android Only**
- **Steps**:
  1. Check AndroidManifest.xml for RECORD_AUDIO permission
  2. Grant permission at runtime via app
  3. Test voice input
- **Expected Result**: ✅ Permission visible in Settings > Apps > MacMind > Permissions

### 9. **Multiple Voice Input Fields**
**Scenario**: Voice input works on different calculator fields
- **Steps**:
  1. Tap mic button on Pressure field
  2. Say a number (e.g., "2000")
  3. Text appears in field
  4. Tap mic button on another field (e.g., Cylinder Type)
  5. Say input
- **Expected Result**: ✅ Voice input works on all supported fields

### 10. **Voice Input Error Handling**
**Scenario**: Various speech recognition errors
- **Ambient noise, overlapping speech, etc.**
- **Steps**:
  1. Tap mic button
  2. Trigger error (don't speak, speak too quietly, etc.)
- **Expected Result**: ✅ Appropriate error message displayed (e.g., "No speech detected")

## Debug Information

### Enable Debug Logs
To see detailed permission debugging info, check the Flutter console output for these tags:
```
[MicrophonePermissionService]
[SpeechInputService]
[VoiceInputMicButton]
[PermissionLifecycleManager]
```

### Accessing Permission Service Directly (For Testing)
In any screen with speech service, you can check permission status:
```dart
final speechService = context.read<SpeechInputService>();
final status = await speechService.requestMicrophonePermission();
print('Permission status: $status');
```

### Testing Permission Dialog
The error dialog includes:
- **Status Badge**: Shows current permission state
- **Explanation Text**: User-friendly description
- **Action Buttons**:
  - "Cancel": Dismiss dialog
  - "Grant Permission": Try to request again (if permission was denied)
  - "Open Settings": Navigate to app settings (if permanently denied)

## Expected Error Messages

| State | Message |
|-------|---------|
| Denied | "Microphone permission is required for voice input. Please grant permission to continue." |
| Permanently Denied | "Microphone permission is permanently denied. Please enable it in app settings to use voice input." |
| Restricted | "Microphone access is restricted on this device (parental controls may be active)." |
| Provisional | "Temporary microphone access granted. You may be prompted to provide full access." |

## Configuration Files to Verify

### Android: `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS: `ios/Runner/Info.plist`
```xml
<key>NSMicrophoneUsageDescription</key>
<string>MacMind uses the microphone to dictate calculator inputs.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>MacMind uses speech recognition to convert your voice into calculator text.</string>
```

## Troubleshooting

### Issue: Permission dialog doesn't appear
- **Check**: Device settings - microphone may already be granted or blocked
- **Check**: Android minSdk >= 23 (required for runtime permissions)
- **Check**: `flutter pub get` - ensure packages are updated

### Issue: Voice input stops working after app restart
- **Check**: Permission cache reset works correctly
- **Solution**: Kill app from background and reopen

### Issue: Permission still shows as denied after granting
- **Check**: Close and reopen app completely
- **Check**: Verify permission in device settings

### Issue: Voice input works but shows error dialog
- **Check**: Different error type (not permission) - see error message
- **Check**: Check debug logs for specific error codes

## Performance Expectations

- **First Permission Request**: ~500ms (system dialog)
- **Subsequent Requests**: <50ms (cached)
- **Voice Recognition Start**: ~1-2 seconds
- **Speech-to-Text**: ~1-3 seconds (depends on speech length)

## Files Modified/Created

1. **New Service**: `lib/services/microphone_permission_service.dart`
   - Handles all permission states
   - Provides user-friendly messages
   - Platform-aware (Android/iOS)

2. **Updated Service**: `lib/services/speech_input_service.dart`
   - Integrated MicrophonePermissionService
   - Improved error reporting

3. **Updated Widget**: `lib/widgets/voice_input_mic_button.dart`
   - Added permission error dialog
   - Better error handling

4. **New Widget**: `lib/widgets/permission_lifecycle_manager.dart`
   - Handles app lifecycle events
   - Resets permission cache on app resume

5. **Updated App**: `lib/main.dart`
   - Integrated PermissionLifecycleManager

## Next Steps After Testing

1. **Deploy to TestFlight (iOS)** or **Internal Testing (Android)**
2. **Have users test across different devices and OS versions**
3. **Monitor crash logs for permission-related issues**
4. **Collect user feedback on error messages clarity**

## Support

If users encounter issues, they should:
1. Check debug logs for permission status
2. Verify microphone permission in device settings
3. Try opening app settings via the error dialog
4. Force close and reopen the app
5. Reinstall app if issues persist
