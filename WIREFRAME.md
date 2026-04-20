# 📐 Login Screen UI Wireframe & Visual Guide

## Screen Layout - Mobile View (375x812)

```
┌──────────────────────────┐
│                          │  ← Safe Area (top padding)
├──────────────────────────┤
│                          │
│  ┌────────────────────┐  │
│  │                    │  │
│  │   [Calculator]     │  │ ← AppHeader
│  │      Icon          │  │  (blue background)
│  │                    │  │
│  └────────────────────┘  │
│                          │
│ Anesthetic Consumption   │
│      Calculator          │
│ (24px, Bold)             │
│                          │
│ Secure clinical case     │
│ calculation and storage  │
│ (14px, Medium Gray)      │
│                          │
├──────────────────────────┤  ← 24pt spacing
│  ┌──────────────────┐   │
│  │ USER ID / EMAIL  │   │ ← CustomInputField
│  │ ┌──────────────┐│   │
│  │ │👤 [input...]││   │   Input with left icon
│  │ └──────────────┘│   │
│  └──────────────────┘   │
│           8pt            │
│  ┌──────────────────┐   │
│  │    PASSWORD      │   │
│  │ ┌──────────────┐│   │
│  │ │🔒 [password]👁│   │ Reveal toggle icon
│  │ └──────────────┘│   │
│  └──────────────────┘   │
│           8pt            │
│  ┌──────────────────┐   │
│  │  DEPARTMENT ID   │   │
│  │ ┌──────────────┐│   │
│  │ │🏥 [optional]││   │
│  │ └──────────────┘│   │
│  └──────────────────┘   │
│           8pt            │
│  [✓] Remember me   Link? │ ← CustomCheckbox + Text link
│           8pt            │
│  ┌──────────────────┐   │
│  │                  │   │
│  │     LOGIN        │   │ ← PrimaryButton
│  │  (Blue, Bold)    │   │  48px height
│  │                  │   │
│  └──────────────────┘   │
│           8pt            │
│  ┌──────────────────┐   │
│  │ CONTINUE AS GUEST│   │ ← SecondaryButton
│  │  (Outline, Blue) │   │  48px height
│  └──────────────────┘   │
│                          │
│  ─────── OR ───────      │ ← Divider
│                          │
│ Already have account?    │
│   Create New Account     │ ← Text link
│                          │
├──────────────────────────┤
│  ┌──────────────────┐   │
│  │ [🛡]             │   │ ← SecurityInfoCard
│  │ HIPAA-safe       │   │
│  │ secure storage   │   │
│  └──────────────────┘   │
│                          │
│                          │  ← Safe Area (bottom padding)
└──────────────────────────┘
```

---

## Component Breakdown

### 1. AppHeader Component
```
Height: 160px
┌───────────────────────────────┐
│                               │
│       [Blue Circle Icon]       │  ← 40x40 icon
│        (24pt padding)         │
│                               │
│ Anesthetic Consumption        │  ← H3: 24px, Bold
│ Calculator                    │
│                               │
│ Secure clinical case...       │  ← Body: 14px, Regular
│                               │
└───────────────────────────────┘
```

### 2. CustomInputField Component
```
Height: 72px (label + field)
┌─────────────────────────┐
│ USER ID / EMAIL         │  ← Label: 14px, 600
│ (4pt below)             │
│  ┌─────────────────────┐│
│  │👤  Enter your email││ │ ← Input: 14px, 400
│  └─────────────────────┘│   Light gray fill
│   |<─ 16pt padding ─>|  │   1px blue border on focus
└─────────────────────────┘
```

States:
- **Default**: Light gray fill, 1px gray border
- **Focused**: Light gray fill, 2px blue border
- **Error**: Light gray fill, red border + red text
- **Disabled**: Darker gray fill, grayed text

### 3. PrimaryButton
```
Width: 100% (minus margins)
Height: 48px
┌────────────────────────────────┐
│                                │
│           LOGIN                │  ← 16px, Bold, White
│    (Blue background)           │
│                                │
└────────────────────────────────┘
Border Radius: 12px
Loading State: Spinner inside button
Disabled: Grayed background + text
```

### 4. SecondaryButton
```
Width: 100%
Height: 48px
┌────────────────────────────────┐
│ ─────── CONTINUE AS GUEST ──── │  ← 16px, Bold, Blue
│        (White, outline)        │
└────────────────────────────────┘
Border: 1.5px blue
Border Radius: 12px
```

### 5. CustomCheckbox
```
┌─────────────────────────────────┐
│ ┌───┐                           │
│ │✓ │  Remember me              │  ← 20x20 checkbox
│ └───┘                           │     14px text
│       (4pt spacing)             │     Blue when checked
└─────────────────────────────────┘
```

### 6. SecurityInfoCard
```
Height: 64px
┌──────────────────────────────┐
│  ┌────┐                      │
│  │🛡 │  HIPAA-safe           │  ← Icon in blue bg
│  └────┘  secure case storage │     13px, Medium text
│           (spacing: 8pt)     │
└──────────────────────────────┘
Background: Light gray (#F5F7FA)
Border: 1px light gray
Icon: Blue (#4A90E2)
```

---

## Modal Dialogs

### Forgot Password Modal
```
┌─────────────────────────────┐
│                             │
│  Reset Password             │  ← Title: 20px, Bold
│                             │
│  Enter your email and       │
│  we'll send reset link      │  ← Body: 14px, Regular
│                             │
│  ┌─────────────────────┐   │
│  │ EMAIL ADDRESS       │   │
│  │ ┌─────────────────┐ │   │
│  │ │📧 your@email...│ │   │
│  │ └─────────────────┘ │   │
│  └─────────────────────┘   │
│                             │
│  [Cancel] [Send Reset Link] │  ← Buttons
│                             │
└─────────────────────────────┘
```

### Create Account Modal
```
┌─────────────────────────────┐
│                             │
│  Create Account             │  ← Title
│                             │
│  ┌─────────────────────┐   │
│  │ FULL NAME           │   │
│  │ ┌─────────────────┐ │   │
│  │ │👤 Dr. Jane Doe │ │   │
│  │ └─────────────────┘ │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ EMAIL               │   │
│  │ ┌─────────────────┐ │   │
│  │ │📧 jane@...     │ │   │
│  │ └─────────────────┘ │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ PASSWORD            │   │
│  │ ┌─────────────────┐ │   │
│  │ │🔒 [password]  👁│ │   │
│  │ └─────────────────┘ │   │
│  └─────────────────────┘   │
│                             │
│  [Cancel] [Create Account]  │  ← Buttons
│                             │
└─────────────────────────────┘
```

---

## Color Reference

### Input Field States
```
DEFAULT:
┌──────────────────┐
│ 🔍 Search...    │  Background: #F5F7FA (light gray)
└──────────────────┘  Border: #E5E7EB (1px)
  Text: #1F2937 (dark gray)

FOCUSED:
┌──────────────────┐
│ 🔵 Type here...  │  Background: #F5F7FA
└──────────────────┘  Border: #4A90E2 (2px, blue)
  Icon: #4A90E2 (blue)

ERROR:
┌──────────────────┐
│ ❌ Invalid      │  Background: #F5F7FA
└──────────────────┘  Border: #EF4444 (1px, red)
  Text: #EF4444 (red)
```

### Button States
```
PRIMARY:
┌──────────────────┐
│    LOGIN         │  Background: #4A90E2 (blue)
└──────────────────┘  Text: White
  Enabled: Full opacity
  Disabled: #F3F4F6 (gray)

SECONDARY:
┌──────────────────┐
│  CONTINUE       │  Border: #4A90E2 (1.5px)
└──────────────────┘  Text: #4A90E2
  Background: White

TEXT:
Create New Account    Text: #4A90E2, underlined
  Normal: #4A90E2
  Hover: Darker blue
  Disabled: #9CA3AF (light gray)
```

---

## Spacing Examples (8pt Grid)

```
Top Padding:        24pt (3x 8pt)
Element Spacing:    16pt (2x 8pt)
Label to Input:     4pt (0.5x 8pt)
Card Padding:       16pt (2x 8pt)
Icon Padding:       8pt (1x 8pt)
Input Height:       48pt (6x 8pt)
Button Height:      48pt (6x 8pt)
Checkbox Size:      20pt (2.5x 8pt)
Icon Size:          24pt (3x 8pt)
```

---

## Responsive Behavior

### Small Screens (< 600px height)
- Reduce spacing: 16pt → 12pt
- Remove extra margins
- Stack modals differently
- Scrollable login card

### Tablet (600-1000px)
- Centered card (600px wide)
- Extra padding
- Side-by-side buttons possible

### Desktop (> 1000px)
- Centered modal (500px)
- Horizontal layout options
- Wider cards

---

## Accessibility Features

- ✅ High contrast text (#1F2937 on #FFFFFF)
- ✅ Large touch targets (48px min for buttons)
- ✅ Clear focus indicators (2px blue border)
- ✅ Icon + text labels
- ✅ Password visibility toggle
- ✅ Semantic HTML structure
- ✅ Error messages in red
- ✅ Success messages in green

---

## Animation Timing

```
Button Press:     150ms ripple effect
Input Focus:      200ms border color transition
Checkbox Check:   200ms checkmark animation
Modal Open:       300ms slide-up animation
SnackBar Show:    150ms slide-in animation
SnackBar Hide:    120ms fade-out animation
```

---

## Dark Mode Support (Future)

The theme system supports easy dark mode addition:
```dart
// In AppTheme:
static ThemeData get dark { ... }

// In MyApp:
theme: isDarkMode ? AppTheme.dark : AppTheme.light,
```

---

## Summary

✅ Professional healthcare design  
✅ Consistent spacing & colors  
✅ Fully accessible  
✅ Responsive  
✅ Production-ready  
✅ Component-based  
✅ Easy to customize  

**Screen is ready to ship!** 🚀
