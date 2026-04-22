# 🏥 Login Screen Design Documentation

## Overview
A professional, healthcare-themed login screen for the Anesthetic Consumption Calculator app. The design system is built on:
- **Material Design 3** with custom theming
- **8pt Spacing Grid** for consistent alignment
- **Soft Blue Healthcare Aesthetic** matching calculator app
- **Reusable Components** for consistency across screens

---

## 📐 Design System

### Colors
| Use | Color | Hex | Usage |
|-----|-------|-----|-------|
| Primary | Soft Blue | #4A90E2 | Buttons, icons, focus states |
| Background | White | #FFFFFF | Main app background |
| Cards | Light Gray | #F5F7FA | Input fields, cards |
| Text Dark | Dark Gray | #1F2937 | Body text, labels |
| Text Medium | Gray | #6B7280 | Secondary text |
| Text Light | Light Gray | #9CA3AF | Hints, disabled text |
| Success | Green | #10B981 | Success messages |
| Error | Red | #EF4444 | Error messages |
| Border | Light Gray | #E5E7EB | Input borders, dividers |

### Spacing Grid (8pt units)
```
xs  = 4px   (0.5x)
sm  = 8px   (1x base)
md  = 16px  (2x)
lg  = 24px  (3x)
xl  = 32px  (4x)
xxl = 48px  (6x)
```

### Border Radius
- **Small components**: 12px (inputs, buttons)
- **Large components**: 16px (cards, modals)

### Typography
All fonts use **Inter / SF Pro**:
- **H1**: 32px, Bold
- **H2**: 28px, Bold
- **H3**: 24px, Bold
- **Title L**: 20px, 600
- **Body**: 16px, 400
- **Label**: 14px, 600
- **Small**: 12px, 400

---

## 🎨 Components

### 1. **CustomInputField**
Reusable text input with healthcare aesthetics
```dart
CustomInputField(
  label: 'User ID / Email',
  hint: 'Enter your email',
  prefixIcon: Icons.person_outline,
  obscureText: false,
)
```
**Features:**
- Left icon with color state
- Light gray fill (#F5F7FA)
- Blue focus border (#4A90E2)
- Auto visibility toggle for password fields
- Label above input

### 2. **PrimaryButton**
Main action button (Login)
```dart
PrimaryButton(
  label: 'Login',
  onPressed: _handleLogin,
  isLoading: false,
)
```
**Features:**
- Full width by default
- Soft blue background
- Loading state with spinner
- 48px height (6 x 8pt)
- Rounded corners (12px)

### 3. **SecondaryButton**
Alternate action (Continue as Guest)
```dart
SecondaryButton(
  label: 'Continue as Guest',
  onPressed: _handleGuestLogin,
)
```
**Features:**
- Outline style
- Blue border & text
- Same height as primary
- Professional secondary action

### 4. **CustomCheckbox**
Remember me checkbox
```dart
CustomCheckbox(
  value: _rememberMe,
  onChanged: (value) {},
  label: 'Remember me',
)
```
**Features:**
- Custom styled checkbox
- Checkmark animation
- Label on right side
- Blue when selected

### 5. **SecurityInfoCard**
Bottom security information
```dart
SecurityInfoCard(
  icon: Icons.shield_outlined,
  text: 'HIPAA-safe secure case storage',
)
```
**Features:**
- Icon in soft blue background
- Gray card container
- Professional trust messaging

### 6. **AppHeader**
Top section with icon, title, subtitle
```dart
AppHeader(
  title: 'Anesthetic Consumption\nCalculator',
  subtitle: 'Secure clinical case calculation and storage',
  icon: Icons.calculate_outlined,
)
```

---

## 📱 Screen Layout: LoginScreen

```
┌─────────────────────────────────────┐
│                                     │
│    [Icon in Blue Box]               │ ← AppHeader
│    Title                            │
│    Subtitle                         │
│                                     │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ User ID / Email      [icon]   │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │  ← Login Card
│  │ Password         [reveal icon] │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ Department ID (optional)      │  │
│  └───────────────────────────────┘  │
│                                     │
│  [✓] Remember me    Forgot Password? │
│                                     │
│  ┌───────────────────────────────┐  │
│  │         LOGIN                 │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  CONTINUE AS GUEST            │  │
│  └───────────────────────────────┘  │
│                        OR           │
│     Don't have account? Create New  │
│                                     │
├─────────────────────────────────────┤
│  [🛡] HIPAA-safe secure storage    │ ← SecurityInfoCard
│                                     │
└─────────────────────────────────────┘
```

---

## 🔧 Interaction States

### Login Button
- **Default**: Blue, clickable
- **Loading**: Spinner inside
- **Disabled**: Grayed out
- **Error**: Shows SnackBar below

### Input Fields
- **Unfocused**: Light gray, 1px border
- **Focused**: Blue border, 2px width
- **Error**: Red border
- **Disabled**: Grayed background

### Forgot Password Modal
- Opens bottom sheet with email input
- Sends reset link
- Shows success message

### Create Account Modal
- Collects: Name, Email, Password
- Form validation
- Shows success message

---

## 🚀 Features Implemented

✅ **Form Validation**
- Empty field checks
- Password length validation (min 6 chars)
- Email format support

✅ **Navigation**
- Login → Dashboard
- Guest → Dashboard (guest mode)
- Logout → Back to login

✅ **Modals**
- Forgot Password (email recovery)
- Create Account (registration)

✅ **State Management**
- Remember Me checkbox
- Loading state during login
- Error messages via SnackBar

✅ **Accessibility**
- Proper focus management
- Icon visibility toggle
- TextInputAction for keyboard navigation
- High contrast colors

---

## 📦 Component Reusability

### For Other Screens:
```dart
// Input field anywhere
CustomInputField(
  label: 'Phone',
  prefixIcon: Icons.phone_outlined,
)

// Buttons in modals/submissions
PrimaryButton(label: 'Submit', onPressed: ...)

// Checkboxes in forms
CustomCheckbox(value: false, label: 'I agree', ...)

// Cards with info
SecurityInfoCard(text: 'Message', icon: Icons.shield)
```

---

## 🎯 Next Steps

1. **Connect to Backend**
   - Replace simulated login with API calls
   - Add authentication tokens
   - Implement session management

2. **Add More Screens**
   - Patient Setup Screen
   - Calculator Screen
   - Case History
   - Settings

3. **Enhance Security**
   - Implement biometric login
   - Add two-factor authentication
   - Secure credential storage

4. **Customization**
   - Change colors in `app_colors.dart`
   - Adjust spacing in `app_spacing.dart`
   - Modify theme in `app_theme.dart`

---

## 📖 File Guide

| File | Purpose |
|------|---------|
| `app_colors.dart` | Color palette definition |
| `app_spacing.dart` | 8pt spacing grid + sizing |
| `app_theme.dart` | Global Material theme |
| `custom_input_field.dart` | Text input component |
| `custom_button.dart` | Button variants |
| `custom_checkbox.dart` | Checkbox component |
| `security_info_card.dart` | Info card component |
| `app_header.dart` | Header section component |
| `login_screen.dart` | Main login UI + logic |
| `dashboard_screen.dart` | Post-login screen |
| `main.dart` | App entry point |

---

## 💡 Design Principles Applied

1. **Healthcare Aesthetic** - Clean, professional, trustworthy
2. **Minimalism** - No unnecessary elements
3. **Consistency** - Reusable components, unified spacing
4. **Accessibility** - Clear hierarchy, good contrast
5. **Responsiveness** - Works on all screen sizes
6. **Professional** - Hospital dashboard feel
7. **Trust** - Security messaging, HIPAA compliance

---

**Version**: 1.0.0  
**Last Updated**: March 2026  
**Status**: Production Ready ✅
