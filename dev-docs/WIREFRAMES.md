# Wireframes & UI Specifications

Screen layouts and UI component specifications for TimePlanner.

## Overview

This document provides wireframes, UI patterns, and design specifications for all screens in TimePlanner. Use this as a reference during implementation.

**Last Updated**: 2026-01-17

---

## Screen Inventory

| Priority | Screen | Status | Notes |
|----------|--------|--------|-------|
| **P0 (MVP)** |
| 🟢 High | Day View | ✅ Done | Core screen with timeline, events, category colors |
| 🟢 High | Event Form | ✅ Done | Create/edit events |
| 🟢 High | Event Detail | ✅ Done | Bottom sheet modal |
| 🟡 Medium | Week View | ✅ Done | Weekly overview with 7-day grid |
| 🟡 Medium | Planning Wizard | ❌ Not started | 4-step flow |
| **P1 (V1.0)** |
| 🟡 Medium | Plan Review | ❌ Not started | Schedule comparison |
| 🟡 Medium | Goals Dashboard | ❌ Not started | Goal tracking |
| 🟢 High | Settings | ❌ Not started | App configuration |
| **P2 (Nice to have)** |
| 🔵 Low | People View | ❌ Not started | Manage people |
| 🔵 Low | Locations View | ❌ Not started | Manage locations |
| 🔵 Low | Onboarding | ❌ Not started | First-time user flow |

---

## Day View Wireframe

### Layout (Portrait Phone)

```
┌────────────────────────────────────┐
│ ◀ Thu, Jan 16    [Week] [⚙️]       │ ← App Bar (56dp)
├────────────────────────────────────┤
│ ┌────────────────────────────────┐ │
│ │ 🎯 2/3 goals on track          │ │ ← Goal Summary (optional, 80dp)
│ │ ▓▓▓▓▓░░░ Work    ▓▓▓▓▓▓▓░ Health│ │
│ └────────────────────────────────┘ │
├────────────────────────────────────┤
│ 08:00 AM                           │
│ ─────────────────────────────────  │ ← Timeline
│ 09:00                              │
│ ┌──────────────────────────────┐   │
│ │ 🔵 Deep Work                 │   │ ← Event card (90 min)
│ │ Work • 9:00 - 10:30 AM       │   │
│ └──────────────────────────────┘   │
│ 10:30                              │
│ ─────────────────────────────────  │
│ 11:00 ┄┄┄┄┄ Current Time ┄┄┄┄┄┄   │ ← Current time marker
│ ─────────────────────────────────  │
│ 12:00 PM                           │
│ ┌──────────────────────────────┐   │
│ │ 🟠 Lunch                     │   │
│ │ Personal • 12:00 - 1:00 PM   │   │
│ └──────────────────────────────┘   │
│ 01:00                              │
│ ┌──────────────────────────────┐   │
│ │ 🔴 Team Meeting              │   │ ← Fixed event (locked icon)
│ │ Work • 2:00 - 3:00 PM 🔒     │   │
│ └──────────────────────────────┘   │
│ 03:00                              │
│ ─────────────────────────────────  │
│ 04:00                              │
│ ...                                │
└────────────────────────────────────┘
                                  [+] ← FAB (56dp)
```

### Components

#### App Bar
- **Left**: Back arrow (if nested) or date picker icon
- **Center**: Current date (formatted: "Thu, Jan 16")
  - Tappable → Opens date picker
- **Right**: [Week] button, Settings icon
- **Height**: 56dp
- **Background**: Primary color
- **Text**: On-primary color

#### Goal Summary Card (Optional)
- **Height**: 80dp
- **Padding**: 16dp
- **Background**: Surface color
- **Elements**:
  - Goal title
  - Progress bar (linear indicator)
  - Progress text ("8/10 hours")
- **Tap Action**: Opens Goals Dashboard

#### Timeline
- **Time Labels**: 
  - Every hour
  - Font: Body2 (14sp)
  - Color: On-surface (60% opacity)
  - Position: Left aligned, 40dp width
- **Grid Lines**:
  - Horizontal line every hour
  - Color: Divider color
  - Style: Solid
- **Current Time Marker**:
  - Red horizontal line
  - Small dot indicator on left
  - Label: "Now" or current time
  - Updates every minute

#### Event Card
- **Height**: Proportional to duration (15 min = 20dp minimum)
- **Padding**: 12dp horizontal, 8dp vertical
- **Border Radius**: 8dp
- **Elevation**: 2dp
- **Left Border**: 4dp thick, category color
- **Layout**:
  ```
  ┌─────────────────────────┐
  │ [Icon] Event Title      │
  │ Category • Time range   │
  │ [Status badge]          │
  └─────────────────────────┘
  ```
- **Text**:
  - Title: Body1 (16sp), bold
  - Subtitle: Caption (12sp), regular
- **Icons**:
  - Category icon (18dp)
  - Lock icon (if locked) (16dp)
  - Status indicator (if completed/cancelled)
- **States**:
  - Default: Surface color
  - In Progress: Green tinted background
  - Completed: 50% opacity, checkmark icon
  - Cancelled: 30% opacity, strikethrough text
- **Tap**: Opens Event Detail modal
- **Long Press**: Quick actions menu

#### FAB (Floating Action Button)
- **Size**: 56x56dp
- **Icon**: Add (+)
- **Position**: Bottom right, 16dp margin
- **Color**: Primary color
- **Elevation**: 6dp
- **Tap**: Opens Event Form

---

## Week View Wireframe

### Layout (Portrait Phone)

```
┌────────────────────────────────────┐
│ ◀ Week of Jan 13      [Day] [⚙️]   │
├────────────────────────────────────┤
│ Mon Tue Wed Thu Fri Sat Sun        │ ← Day headers
│  13  14  15 [16] 17  18  19        │
├────┬───┬───┬───┬───┬───┬────┤
│  ▓ │   │ ▓ │▓▓▓│ ▓ │   │    │ 9am
│    │ ▓ │ ▓ │   │   │   │    │ 10
│  ▓ │ ▓ │   │ ▓ │ ▓ │   │    │ 11
│    │   │   │   │   │   │    │ 12pm
│  ▓ │ ▓ │ ▓ │ ▓ │ ▓ │ ▓ │    │ 1
│  ▓ │ ▓ │   │▓▓ │ ▓ │   │    │ 2
│    │   │ ▓ │   │   │   │    │ 3
│  ▓ │   │   │ ▓ │   │   │    │ 4
│    │   │   │   │   │   │    │ 5
└────┴───┴───┴───┴───┴───┴────┘
```

### Components

#### Day Headers
- **Height**: 60dp
- **Layout**: 7 equal-width columns
- **Each cell**:
  - Day name (Mon, Tue, ...)
  - Date number
- **Current day**: Highlighted with circle background
- **Selected day**: Bold text
- **Tap**: Navigates to Day View for that date

#### Time Grid
- **Rows**: Each hour (8 AM - 8 PM)
- **Columns**: 7 days
- **Cell**: Represents 1-hour block
- **Event representation**: 
  - Filled block (▓) = scheduled
  - Color matches category
  - Height proportional to duration
- **Tap cell**: Opens Quick Add for that time
- **Tap event**: Opens Event Detail

---

## Event Detail Bottom Sheet

### Layout

```
┌────────────────────────────────────┐
│             ─────                  │ ← Drag handle
│                                    │
│ Deep Work Session                  │ ← Title (Headline6)
│                                    │
│ 📅 Thursday, January 16, 2026      │
│ 🕐 9:00 AM - 10:30 AM (1h 30m)     │
│ 📁 Work                            │
│ 📍 Home Office                     │
│ 👤 Solo                            │
│                                    │
│ ─────────────────────────────────  │
│                                    │
│ Focus on the new feature           │ ← Description
│ implementation without             │
│ interruptions.                     │
│                                    │
│ ─────────────────────────────────  │
│                                    │
│ ┌────────┬─────────┬──────┬─────┐ │
│ │  Edit  │ Reschedule│ Done │ ••• │ │ ← Action buttons
│ └────────┴─────────┴──────┴─────┘ │
└────────────────────────────────────┘
```

### Specifications

- **Type**: Modal bottom sheet
- **Initial Height**: Wrap content (max 60% screen)
- **Drag to expand**: Full screen on drag
- **Drag handle**: 32x4dp, gray
- **Padding**: 24dp horizontal, 16dp vertical
- **Background**: Surface color
- **Border radius**: Top corners 16dp

#### Title Section
- **Font**: Headline6 (20sp), bold
- **Color**: On-surface

#### Details Section
- **Layout**: Vertical list
- **Each row**:
  - Icon (24dp) + Text (Body1, 16sp)
  - 8dp spacing between rows
- **Icons**: Outlined style, primary color
- **Text**: On-surface color (87% opacity)

#### Description Section
- **Divider**: 1dp, divider color
- **Font**: Body2 (14sp)
- **Color**: On-surface (60% opacity)
- **Max lines**: 4 (collapsed), Unlimited (expanded)

#### Action Buttons
- **Layout**: Horizontal row, equal width
- **Buttons**:
  - Edit: Text button
  - Reschedule: Text button
  - Done: Filled tonal button (primary)
  - More (•••): Icon button (opens menu)
- **Height**: 40dp
- **Spacing**: 8dp between buttons

---

## Quick Add Modal

### Layout

```
┌────────────────────────────────────┐
│ Quick Add Event                    │
│                                    │
│ Title                              │
│ ┌────────────────────────────────┐ │
│ │ [Input field]                  │ │
│ └────────────────────────────────┘ │
│                                    │
│ 🕐 2:00 PM │ Duration: [1 hour ▼] │
│                                    │
│ 📁 Category: [Work ▼]              │
│                                    │
│ ┌──────────────┬───────────────┐  │
│ │     Add      │ More Options  │  │
│ └──────────────┴───────────────┘  │
└────────────────────────────────────┘
```

### Specifications

- **Type**: Modal dialog
- **Width**: 90% screen width (max 400dp)
- **Padding**: 24dp
- **Background**: Surface color
- **Border radius**: 16dp

#### Input Field
- **Label**: "Title"
- **Type**: Text field
- **Max length**: 100 characters
- **Validation**: Required

#### Time Row
- **Layout**: Horizontal
- **Left**: Time display (read-only, tappable)
- **Right**: Duration dropdown
- **Dropdown options**: 15min, 30min, 45min, 1hr, 2hr, Custom

#### Category Row
- **Layout**: Horizontal
- **Icon**: Category icon
- **Dropdown**: Category selector with colors

#### Buttons
- **Add**: Filled button, primary color
- **More Options**: Text button, opens full Event Form

---

## Full Event Form

### Layout (Scrollable)

```
┌────────────────────────────────────┐
│ ◀ New Event              [Save]    │ ← App bar
├────────────────────────────────────┤
│                                    │
│ Basic Information                  │ ← Section header
│ ─────────────────────────────────  │
│                                    │
│ Title *                            │
│ ┌────────────────────────────────┐ │
│ │ [Input field]                  │ │
│ └────────────────────────────────┘ │
│                                    │
│ Description                        │
│ ┌────────────────────────────────┐ │
│ │ [Multi-line input]             │ │
│ │                                │ │
│ └────────────────────────────────┘ │
│                                    │
│ Category                           │
│ ┌────────────────────────────────┐ │
│ │ [Work ▼]                       │ │
│ └────────────────────────────────┘ │
│                                    │
│ Timing                             │ ← Section header
│ ─────────────────────────────────  │
│                                    │
│ Event Type                         │
│ ┌─────────────┬─────────────────┐  │
│ │[✓] Fixed Time│  Flexible      │  │ ← Segmented button
│ └─────────────┴─────────────────┘  │
│                                    │
│ Start                              │
│ ┌─────────────┬─────────────────┐  │
│ │ Jan 16, 2026│  2:00 PM       │  │
│ └─────────────┴─────────────────┘  │
│                                    │
│ End                                │
│ ┌─────────────┬─────────────────┐  │
│ │ Jan 16, 2026│  3:00 PM       │  │
│ └─────────────┴─────────────────┘  │
│                                    │
│ Details                            │ ← Section header (expandable)
│ ─────────────────────────────────  │
│ > Location                   [Add] │
│ > People                     [Add] │
│ > Goals                      [Add] │
│                                    │
│ Constraints                        │ ← Section header (expandable)
│ ─────────────────────────────────  │
│ > Advanced options                 │
│                                    │
│ [Delete Event]                     │ ← If editing
│                                    │
└────────────────────────────────────┘
```

### Specifications

#### Form Sections
- **Spacing**: 24dp between sections
- **Headers**: Subtitle1 (16sp), medium weight
- **Divider**: 1dp under each header

#### Text Fields
- **Style**: Outlined text field
- **Height**: 56dp (single line), 120dp (multi-line)
- **Label**: Floating label
- **Required**: Asterisk (*) in label

#### Segmented Button (Event Type)
- **Height**: 40dp
- **Options**: Fixed Time | Flexible
- **Selected**: Filled background, primary color
- **Unselected**: Outlined

#### Date/Time Pickers
- **Style**: Outlined text field
- **Tap**: Opens native picker
- **Format**: "MMM dd, yyyy" for date, "h:mm a" for time

#### Expandable Sections
- **Collapsed**: Single line with chevron
- **Expanded**: Shows fields
- **Tap header**: Toggle expand/collapse

#### Save Button
- **Position**: App bar, right side
- **Style**: Text button
- **Color**: Primary
- **Enabled**: When form valid
- **Disabled**: 38% opacity

---

## Plan Review Screen

### Layout

```
┌────────────────────────────────────┐
│ ◀ Your Schedule                    │
├────────────────────────────────────┤
│ Strategy: Balanced                 │
│                                    │
│ Goal Progress                      │
│ ┌────────────────────────────────┐ │
│ │ 🎯 Work: 35/40 hours           │ │
│ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░ 87%        │ │
│ │                                │ │
│ │ 🎯 Health: 3/5 hours           │ │
│ │ ▓▓▓▓▓▓▓▓▓░░░░░░░░ 60%         │ │
│ └────────────────────────────────┘ │
│                                    │
│ This Week                          │
│ ┌────────────────────────────────┐ │
│ │ Mon Jan 13  [6 events] >       │ │
│ ├────────────────────────────────┤ │
│ │ Tue Jan 14  [8 events] >       │ │
│ ├────────────────────────────────┤ │
│ │ Wed Jan 15  [5 events] >       │ │
│ ├────────────────────────────────┤ │
│ │ Thu Jan 16  [7 events] >       │ │
│ ├────────────────────────────────┤ │
│ │ ...                            │ │
│ └────────────────────────────────┘ │
│                                    │
│ ⚠️ Unscheduled (2 events)          │
│ • Low priority task                │
│ • Optional meeting                 │
│                                    │
│ ┌────────────────────────────────┐ │
│ │      Accept Schedule           │ │
│ └────────────────────────────────┘ │
│                                    │
│ [Try Different Strategy]           │
└────────────────────────────────────┘
```

---

## Goals Dashboard

### Layout

```
┌────────────────────────────────────┐
│ ◀ Goals                   [+ Add]  │
├────────────────────────────────────┤
│ This Week                          │
│                                    │
│ ┌────────────────────────────────┐ │
│ │ 🎯 Work                        │ │
│ │ 35/40 hours                    │ │
│ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░ 87%        │ │
│ │ On Track                    ✅ │ │
│ └────────────────────────────────┘ │
│                                    │
│ ┌────────────────────────────────┐ │
│ │ 🎯 Health                      │ │
│ │ 3/5 hours                      │ │
│ │ ▓▓▓▓▓▓▓▓▓░░░░░░░░ 60%         │ │
│ │ At Risk                     ⚠️ │ │
│ └────────────────────────────────┘ │
│                                    │
│ ┌────────────────────────────────┐ │
│ │ 🎯 Family Time                 │ │
│ │ 2/8 hours                      │ │
│ │ ▓▓▓░░░░░░░░░░░░░░ 25%         │ │
│ │ Behind                      ❌ │ │
│ └────────────────────────────────┘ │
│                                    │
└────────────────────────────────────┘
```

---

## People View

### Layout

```
┌────────────────────────────────────┐
│ ◀ People                  [+ Add]  │
├────────────────────────────────────┤
│ 🔍 [Search people...]              │
│                                    │
│ ┌────────────────────────────────┐ │
│ │ 👤 Alice Johnson              >│ │
│ │    alice@example.com           │ │
│ │    4 upcoming events           │ │
│ ├────────────────────────────────┤ │
│ │ 👤 Bob Smith                  >│ │
│ │    bob@example.com             │ │
│ │    2 upcoming events           │ │
│ └────────────────────────────────┘ │
└────────────────────────────────────┘
```

---

## Settings Screen

### Layout

```
┌────────────────────────────────────┐
│ ◀ Settings                         │
├────────────────────────────────────┤
│ General                            │
│ ┌────────────────────────────────┐ │
│ │ Work Hours                    >│ │
│ │ Week Start                    >│ │
│ │ Default Event Duration        >│ │
│ └────────────────────────────────┘ │
│                                    │
│ Scheduling                         │
│ ┌────────────────────────────────┐ │
│ │ Default Strategy              >│ │
│ │ Time Slot Size                >│ │
│ └────────────────────────────────┘ │
│                                    │
│ Appearance                         │
│ ┌────────────────────────────────┐ │
│ │ Theme                         >│ │
│ │ Show Completed Events    [✓]  │ │
│ └────────────────────────────────┘ │
│                                    │
│ Notifications                      │
│ ┌────────────────────────────────┐ │
│ │ Event Reminders          [✓]  │ │
│ │ Reminder Time                 >│ │
│ │ Goal Updates             [✓]  │ │
│ └────────────────────────────────┘ │
│                                    │
│ Data                               │
│ ┌────────────────────────────────┐ │
│ │ Export Data                   >│ │
│ │ Clear All Data                >│ │
│ └────────────────────────────────┘ │
│                                    │
│ About                              │
│ ┌────────────────────────────────┐ │
│ │ Version 1.0.0                  │ │
│ │ Licenses                      >│ │
│ └────────────────────────────────┘ │
└────────────────────────────────────┘
```

---

## Design Tokens

### Colors

**Light Theme**:
```dart
primary: Color(0xFF2196F3),        // Blue
primaryVariant: Color(0xFF1976D2),
secondary: Color(0xFF4CAF50),      // Green
secondaryVariant: Color(0xFF388E3C),
surface: Color(0xFFFFFFFF),
background: Color(0xFFFAFAFA),
error: Color(0xFFB00020),
onPrimary: Color(0xFFFFFFFF),
onSecondary: Color(0xFFFFFFFF),
onSurface: Color(0xFF000000),
onBackground: Color(0xFF000000),
onError: Color(0xFFFFFFFF),
```

**Dark Theme**:
```dart
primary: Color(0xFF64B5F6),
primaryVariant: Color(0xFF42A5F5),
secondary: Color(0xFF81C784),
secondaryVariant: Color(0xFF66BB6A),
surface: Color(0xFF121212),
background: Color(0xFF121212),
error: Color(0xFFCF6679),
onPrimary: Color(0xFF000000),
onSecondary: Color(0xFF000000),
onSurface: Color(0xFFFFFFFF),
onBackground: Color(0xFFFFFFFF),
onError: Color(0xFF000000),
```

**Category Colors**:
```dart
work: Color(0xFF2196F3),      // Blue
personal: Color(0xFF4CAF50),  // Green
family: Color(0xFFFF9800),    // Orange
health: Color(0xFFF44336),    // Red
creative: Color(0xFF9C27B0),  // Purple
chores: Color(0xFF795548),    // Brown
social: Color(0xFFE91E63),    // Pink
```

### Typography

```dart
headline1: TextStyle(fontSize: 96, fontWeight: FontWeight.w300),
headline2: TextStyle(fontSize: 60, fontWeight: FontWeight.w300),
headline3: TextStyle(fontSize: 48, fontWeight: FontWeight.w400),
headline4: TextStyle(fontSize: 34, fontWeight: FontWeight.w400),
headline5: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
headline6: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
subtitle1: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
subtitle2: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
body1: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
body2: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
button: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
caption: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
overline: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
```

### Spacing

```dart
// Base unit: 8dp
extraSmall: 4.0,
small: 8.0,
medium: 16.0,
large: 24.0,
extraLarge: 32.0,

// Component specific
cardPadding: 16.0,
listItemPadding: 16.0,
screenPadding: 24.0,
buttonHeight: 40.0,
inputHeight: 56.0,
appBarHeight: 56.0,
```

### Elevation

```dart
level0: 0.0,   // Surface
level1: 1.0,   // Cards at rest
level2: 2.0,   // Event cards
level3: 4.0,   // App bar
level4: 6.0,   // FAB
level5: 8.0,   // Nav drawer
```

### Border Radius

```dart
small: 4.0,    // Buttons
medium: 8.0,   // Cards
large: 16.0,   // Modals
extraLarge: 24.0,  // Bottom sheets
```

---

## Responsive Considerations

### Phone (< 600dp width)

- Single column layout
- Bottom navigation or drawer
- Stack modals full screen
- Hide secondary information
- Larger touch targets (48dp minimum)

### Tablet (600dp - 840dp width)

- Two column layout where applicable
- Permanent drawer navigation
- Modal sheets at 60% width
- Show more detail in list items
- Side-by-side views (master-detail)

### Desktop (> 840dp width)

- Three column layout
- Permanent navigation rail
- Modal dialogs centered (max 600dp width)
- Hover states on interactive elements
- Keyboard shortcuts

---

## Accessibility Requirements

### WCAG 2.1 Level AA Compliance

**Color Contrast**:
- Normal text: 4.5:1 minimum
- Large text (18pt+): 3:1 minimum
- UI components: 3:1 minimum

**Touch Targets**:
- Minimum: 44x44 points
- Spacing: 8dp between targets
- Visible focus indicators

**Screen Reader Support**:
- Semantic labels for all interactive elements
- Meaningful accessibility hints
- Proper heading hierarchy
- Announce dynamic content changes

**Keyboard Navigation**:
- Tab order follows visual flow
- All features accessible via keyboard
- Clear focus indicators
- Escape key dismisses modals

---

*Last updated: 2026-01-16*
