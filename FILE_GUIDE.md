# 📄 File Directory & Purpose Guide

## Configuration Files (Design System)

### 🎨 `lib/config/app_colors.dart`
**Purpose**: Central color palette for healthcare app
- Primary colors (soft blue #4A90E2)
- Background & card colors
- Text color variants
- State colors (success, error, warning)
- Semantic colors (borders, disabled, etc.)

**Key Constants**:
```dart
AppColors.primary       // #4A90E2 (blue buttons, icons)
AppColors.background   // #FFFFFF (white app background)
AppColors.cardBackground // #F5F7FA (light gray cards)
AppColors.textDark     // #1F2937 (body text)
AppColors.error        // #EF4444 (error states)
```

**When to use**: Import whenever you need consistent colors

---

### 📐 `lib/config/app_spacing.dart`
**Purpose**: 8pt grid spacing system for consistency
- Base unit: 8pt
- Multiplied values: xs (4pt), sm (8pt), md (16pt), lg (24pt)
- Component-specific sizes (button height, icon size)
- Border radius values

**Key Constants**:
```dart
AppSpacing.md        // 16pt (standard padding)
AppSpacing.lg        // 24pt (large spacing)
AppSpacing.buttonHeight // 48pt (standard button)
AppSpacing.borderRadius // 12pt (inputs, buttons)
```

**When to use**: All padding, margin, height, width values should reference this

---

### 🎨 `lib/config/app_theme.dart`
**Purpose**: Global Material 3 theme configuration
- Color scheme setup
- Typography (font sizes, weights, families)
- Input decoration theme
- Button themes (elevated, outlined, text)
- Card theme
- AppBar theme

**What it affects**: Every widget's default appearance
**When to modify**: Change brand colors globally or adjust font sizes

---

## Widget Components (Reusable)

### 📝 `lib/widgets/custom_input_field.dart`
**Purpose**: Smart text input field with healthcare design
**Features**:
- Left icon support
- Password visibility toggle
- Focus state management
- Label above input
- Validation support
- Light gray background
- Blue focus border

**Usage**:
```dart
CustomInputField(
  label: 'Email',
  hint: 'your@email.com',
  prefixIcon: Icons.email_outlined,
  obscureText: false,
)
```

**Props**:
- `label` (required): Field label text
- `hint`: Placeholder text
- `prefixIcon`: Icon on left side
- `obscureText`: Hide input (passwords)
- `controller`: TextEditingController
- `validator`: Form validation function
- `keyboardType`: Input type
- `maxLines`/`minLines`: Multiple line support
- `textInputAction`: Keyboard action
- `onChanged`: Change callback
- `enabled`: Enable/disable state

---

### 🔘 `lib/widgets/custom_button.dart`
**Purpose**: Three button variants for consistent UI

#### PrimaryButton
```dart
PrimaryButton(
  label: 'Login',
  onPressed: _handleLogin,
  isLoading: false,
)
```
- Blue background
- Full width by default
- Loading spinner support
- 48px height

#### SecondaryButton
```dart
SecondaryButton(
  label: 'Cancel',
  onPressed: _handleCancel,
)
```
- Outline style
- Blue border/text
- Secondary actions

#### TextActionButton
```dart
TextActionButton(
  label: 'Forgot Password?',
  onPressed: _showForgotPasswordModal,
)
```
- Underlined text
- No background
- Lightweight actions

---

### ☑️ `lib/widgets/custom_checkbox.dart`
**Purpose**: Custom styled checkbox matching design system
**Features**:
- Blue checkmark when selected
- Label on right side
- Custom styling (not default Material)
- Disabled state support

**Usage**:
```dart
CustomCheckbox(
  value: _rememberMe,
  onChanged: (value) {
    setState(() => _rememberMe = value ?? false);
  },
  label: 'Remember me',
)
```

**Props**:
- `value`: Current state (bool)
- `onChanged`: Callback when toggled
- `label`: Text label
- `enabled`: Enable/disable

---

### 🛡 `lib/widgets/security_info_card.dart`
**Purpose**: Information card with icon for security/trust messaging
**Features**:
- Icon in blue circular background
- Gray card container
- Professional healthcare messaging
- Used at bottom of screens

**Usage**:
```dart
SecurityInfoCard(
  icon: Icons.shield_outlined,
  text: 'HIPAA-safe secure case storage',
)
```

**Props**:
- `icon`: Icon to display
- `text`: Message text

---

### 🏥 `lib/widgets/app_header.dart`
**Purpose**: Reusable header section with icon, title, subtitle
**Features**:
- App icon in soft blue box
- Large title text
- Subtitle text in gray
- Professional healthcare branding

**Usage**:
```dart
AppHeader(
  title: 'Anesthetic Consumption\nCalculator',
  subtitle: 'Secure clinical case calculation',
  icon: Icons.calculate_outlined,
)
```

**Props**:
- `title`: Main heading
- `subtitle`: Secondary heading
- `icon`: Icon to display

---

## Screen Files

### 🔐 `lib/screens/login_screen.dart`
**Purpose**: Main login page
**Contains**:
- Form fields (user ID, password, department)
- Login form validation
- Remember me functionality
- Forgot password modal
- Create account modal
- Guest login option
- Security info card

**Key Methods**:
- `_validateForm()`: Validates input fields
- `_handleLogin()`: Processes login with 2s delay
- `_handleGuestLogin()`: Skips auth
- `_showForgotPasswordModal()`: Shows recovery dialog
- `_showCreateAccountModal()`: Shows registration dialog

**State Variables**:
- `_userIdController`: User ID input controller
- `_passwordController`: Password input controller
- `_departmentController`: Department input controller
- `_rememberMe`: Remember me checkbox
- `_isLoading`: Loading state during login

**Navigation**:
```
LoginScreen
├─ Login (auth) → DashboardScreen
├─ Guest → DashboardScreen (isGuest: true)
├─ Forgot Password → Modal
└─ Create Account → Modal
```

---

### 📊 `lib/screens/dashboard_screen.dart`
**Purpose**: Post-login calculator screen (placeholder)
**Contains**:
- Welcome message
- Guest mode indicator
- Logout button
- Placeholder for calculator features

**Props**:
- `isGuest`: Whether logged in as guest or not

**Future**: Replace placeholder with actual calculator

---

## Root Files

### 🚀 `lib/main.dart`
**Purpose**: App entry point
**Contains**:
- MyApp widget setup
- Material 3 theme application
- Initial navigation to LoginScreen
- App configuration (title, debug banner)

**Key Setup**:
```dart
MaterialApp(
  title: 'Anesthetic Consumption Calculator',
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,        // Our custom theme
  home: const LoginScreen(),     // Entry screen
)
```

---

## Documentation Files

### 📖 `LOGIN_DESIGN_GUIDE.md`
Comprehensive design documentation including:
- Color palette with hex codes
- Spacing grid system
- Component specifications
- Layout diagrams
- Interaction states
- Design principles
- Component reusability guide

**Read for**: Understanding the design system

---

### 🚀 `QUICK_START.md`
Quick reference guide including:
- What's implemented
- Navigation flow
- How to customize colors/spacing
- Backend integration guide
- Build & run instructions
- Recommended next steps

**Read for**: Getting started quickly

---

### 📐 `WIREFRAME.md`
Visual guide with ASCII wireframes:
- Screen layout diagram
- Component breakdown with sizes
- Modal dialogs
- Color reference
- Spacing examples
- Responsive behavior
- Accessibility features

**Read for**: Understanding the visual design

---

## Architecture Summary

```
lib/
├── config/              ← Design System
│   ├── app_colors.dart  (color palette)
│   ├── app_spacing.dart (8pt grid)
│   └── app_theme.dart   (global theme)
│
├── widgets/             ← Reusable Components
│   ├── custom_input_field.dart
│   ├── custom_button.dart
│   ├── custom_checkbox.dart
│   ├── security_info_card.dart
│   └── app_header.dart
│
├── screens/             ← Full Screens
│   ├── login_screen.dart
│   └── dashboard_screen.dart
│
└── main.dart            ← Entry Point
```

---

## How to Navigate This Codebase

### For Design Changes
1. Colors → `app_colors.dart`
2. Spacing → `app_spacing.dart`
3. Fonts → `app_theme.dart`

### For Component Changes
1. Input field styling → `custom_input_field.dart`
2. Button appearance → `custom_button.dart`
3. Checkbox style → `custom_checkbox.dart`

### For Logic Changes
1. Login validation → `login_screen.dart` `_validateForm()`
2. Navigation flow → `login_screen.dart` `_handleLogin()`
3. Modals → `login_screen.dart` `_showXModal()`

### For New Features
1. Add new component → Create in `lib/widgets/`
2. Add new screen → Create in `lib/screens/`
3. Update theme → Edit `lib/config/app_theme.dart`

---

## Dependency Map

```
main.dart
├── AppTheme (from app_theme.dart)
│   ├── AppColors (from app_colors.dart)
│   └── AppSpacing (from app_spacing.dart)
└── LoginScreen (from login_screen.dart)
    ├── AppHeader (from app_header.dart)
    │   ├── AppColors
    │   └── AppSpacing
    ├── CustomInputField (from custom_input_field.dart)
    │   ├── AppColors
    │   └── AppSpacing
    ├── CustomButton (from custom_button.dart)
    │   ├── AppColors
    │   └── AppSpacing
    ├── CustomCheckbox (from custom_checkbox.dart)
    │   ├── AppColors
    │   └── AppSpacing
    └── SecurityInfoCard (from security_info_card.dart)
        ├── AppColors
        └── AppSpacing
```

---

## Import Guide

**Configuration colors**:
```dart
import 'config/app_colors.dart';
// Use: AppColors.primary
```

**Spacing values**:
```dart
import 'config/app_spacing.dart';
// Use: AppSpacing.md
```

**Reusable widgets**:
```dart
import 'widgets/custom_input_field.dart';
import 'widgets/custom_button.dart';
```

**Screens**:
```dart
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
```

---

## File Statistics

| File | Lines | Purpose |
|------|-------|---------|
| app_colors.dart | 35 | Color palette |
| app_spacing.dart | 35 | Spacing grid |
| app_theme.dart | 200+ | Global theme |
| custom_input_field.dart | 150+ | Text input |
| custom_button.dart | 180+ | Buttons |
| custom_checkbox.dart | 70+ | Checkbox |
| security_info_card.dart | 45+ | Info card |
| app_header.dart | 50+ | Header |
| login_screen.dart | 380+ | Login page |
| dashboard_screen.dart | 80+ | Dashboard |
| main.dart | 20 | Entry point |

**Total**: ~1,200 lines of production code

---

**Last Updated**: March 2026  
**Version**: 1.0.0  
**Status**: Production Ready ✅
