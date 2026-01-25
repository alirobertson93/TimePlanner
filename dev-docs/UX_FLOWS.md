# UX Flows

User journey documentation for TimePlanner.

## Overview

This document defines all user interactions and workflows in TimePlanner. Use this as a reference when implementing features or designing UI.

**Last Updated**: 2026-01-25

---

## Layer 1: Initial Setup Flow

### Enhanced Onboarding Wizard (First Launch)

**Entry Point**: App first launch

**Purpose**: Guide users through establishing their recurring week-by-week schedule, including fixed events, people they want to spend time with, activity goals, and locations.

**Progress Indicator**: Linear progress bar showing completion percentage across all steps

**Steps**:

1. **Welcome Screen**
   - Welcome message with app logo/icon
   - Brief explanation of what the wizard will help set up:
     - Recurring events (work, gym, etc.)
     - People you want to spend time with
     - Activity goals (exercise, reading, etc.)
     - Main locations
   - "Get Started" button (Next)
   - "Skip" option (goes to main app with defaults)

2. **Recurring Fixed Events Setup**
   - Header: "Recurring Fixed Events" with repeat icon
   - Description: "Add events that happen at the same time each week"
   - List of added recurring events (with delete option)
   - "Add Recurring Event" button opens dialog:
     - Event Name (required)
     - Description (optional)
     - Start time picker
     - End time picker
     - Day selector chips (S, M, T, W, T, F, S)
   - Empty state: "No recurring events added yet. You can skip this step or add them later."
   - Back/Next navigation

3. **People & Time Goals Setup**
   - Header: "People & Time Goals" with people icon
   - Description: "Add important people and set goals for time with them"
   - List of added people with their time goals
   - "Add Person" button opens dialog:
     - Name (required)
     - Email (optional)
     - Phone (optional)
     - Time Goal section:
       - Hours dropdown (0-20, 0 = "No goal")
       - Period dropdown (Per week / Per month)
   - Examples: "Mum - 5 hours per week", "Girlfriend - 8 hours per week"
   - Back/Next navigation

4. **Activity Goals Setup**
   - Header: "Activity Goals" with flag icon
   - Description: "Set goals for activities you want to make time for"
   - List of added activity goals
   - "Add Activity Goal" button opens dialog:
     - Activity Name (required)
     - Hours dropdown (1-20)
     - Period dropdown (Per week / Per month)
   - Suggested activities as quick-add chips:
     - Exercise (3 hrs/week)
     - Reading (2 hrs/week)
     - Learning (2 hrs/week)
     - Meditation (1 hr/week)
     - Hobbies (3 hrs/week)
     - Side Project (5 hrs/week)
   - Back/Next navigation

5. **Places Setup**
   - Header: "Your Places" with location icon
   - Description: "Add your main locations with optional time goals"
   - List of added locations with their time goals
   - "Add Location" button opens dialog:
     - Location Name (required)
     - Address (optional)
     - Time Goal section:
       - Hours dropdown (0-40, 0 = "No goal")
       - Period dropdown (Per week / Per month)
   - Quick-add chips for common locations:
     - Home
     - Office
     - Gym
     - Coffee Shop
   - Back/Next navigation

6. **Summary & Completion**
   - Success icon and "You're All Set!" message
   - Summary counts:
     - Recurring Events: X
     - People Added: X
     - Activity Goals: X
     - Locations: X
   - Tip: "Use the Planning Wizard to automatically schedule your flexible events around your fixed commitments."
   - "Get Started" button → Saves all data and goes to main app

**Data Created**:
- Recurring events are saved with weekly recurrence rules
- People are saved with associated time goals (GoalType.person)
- Activity goals are saved as custom goals (GoalType.custom)
- Locations are saved with optional time goals

**Exit Points**:
- ✅ Complete onboarding → Day View (all data saved)
- ⏭️ Skip → Day View (no data created, defaults used)
- Can replay via Settings > "Replay Onboarding"

**Time Goal Periods**:
- **Per Week**: Progress tracked against current week (Monday-Sunday)
- **Per Month**: Progress tracked against current calendar month
  - The app calculates boundaries and aggregates events accordingly
  - See `goal_providers.dart` for implementation details

---

### Settings Access

**Entry Point**: Settings icon in app bar

**Options**:
- Work Hours
- Categories
- Goals
- Notifications
- Theme (Light/Dark/System)
- About

**Exit**: Back button or navigation

---

## Layer 2: Weekly Planning Flow

### Planning Wizard (4 Steps)

**Entry Point**: 
- "Plan Week" button on Day View
- "Create Schedule" from Week View
- Automatic prompt on Sunday evening

#### Step 1: Date Range Selection

**Screen**: Date range picker

**Elements**:
- "Plan your week" header
- Week selector (defaults to upcoming week)
- Start date: [Date Picker] (defaults to next Monday)
- End date: [Date Picker] (defaults to next Sunday)
- Info: Shows count of existing events in range
- "Next" button

**Validation**:
- End must be after start
- Range should be 1-14 days
- Warn if range > 7 days

**Next**: Goes to Step 2

---

#### Step 2: Goals Review

**Screen**: Goal status and adjustment

**Elements**:
- "Your goals for this period" header
- List of active goals:
  - Goal name
  - Target (e.g., "10 hours on Work")
  - Current progress if rescheduling
  - Edit/Remove options
- "Add Goal" button
- Info: "The scheduler will try to meet these goals"
- "Back" and "Next" buttons

**Actions**:
- Tap goal → Edit goal modal
- "Add Goal" → Goal creation modal
- Toggle goal active/inactive

**Next**: Goes to Step 3

---

#### Step 3: Strategy Selection

**Screen**: Choose scheduling strategy

**Elements**:
- "How should we schedule your week?" header
- Strategy cards (selectable):
  - **Balanced** (Recommended)
    - Icon: scales
    - Description: "Evenly distribute work throughout the week"
  - **Front-Loaded**
    - Icon: calendar with early dates highlighted
    - Description: "Schedule tasks early in the week"
  - **Max Free Time**
    - Icon: calendar with blocks
    - Description: "Create large uninterrupted blocks"
- Info: "You can generate multiple options to compare"
- "Generate" button
- "Back" button

**Next**: Generates schedule(s) → Step 4

---

#### Step 4: Plan Review

**Screen**: Review and accept/reject schedule

**Elements**:
- "Your schedule is ready" header
- Strategy used badge
- Goal progress summary:
  - Each goal with progress bar
  - Green (on track), Yellow (at risk), Red (behind)
- Schedule preview:
  - Day-by-day view
  - Event count per day
  - Visual timeline
- Expand button for each day → Shows all events
- Conflicts/Warnings section (if any):
  - "3 events couldn't be scheduled"
  - List of unscheduled events
  - Suggested actions
- "Accept Schedule" button (primary)
- "Try Different Strategy" button (secondary)
- "Cancel" button

**Actions**:
- Accept → Saves schedule, goes to Week View
- Try Different → Goes back to Step 3
- Tap day → Expand to show events
- Tap unscheduled event → Options to remove/shorten

**Exit Points**:
- ✅ Accept → Week View with new schedule
- ❌ Cancel → Returns to previous view

---

### Alternative Plans View

**Entry Point**: From Plan Review, "See Alternatives" button

**Screen**: Compare 3 schedule variations

**Elements**:
- "Compare schedule options" header
- 3 columns (side-by-side on tablet, swipe on phone):
  - Strategy name
  - Goal progress chart
  - Events scheduled count
  - Free time total
  - Preview timeline
- Select radio button for each
- "Accept Selected" button

**Actions**:
- Tap plan → Expands to full preview
- Select plan → Highlights
- Accept → Saves selected schedule

---

## Layer 3: Daily/Live Adjustment Flows

### Day View (Main Screen)

**Entry Point**: App launch, or tap date in Week View

**Screen Layout**:
```
┌──────────────────────────────┐
│ < Thu, Jan 16    [Week] [⚙️] │ ← App Bar
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ [Goals summary card]     │ │ ← Optional goal widget
│ └──────────────────────────┘ │
├──────────────────────────────┤
│ 9:00 AM ┌──────────────────┐ │
│         │ Deep Work        │ │
│ 10:00   │                  │ │
│         └──────────────────┘ │
│ 11:00   ──────────────────── │ ← Free time
│ 12:00   ┌──────────────────┐ │
│         │ Lunch            │ │
│ 1:00 PM └──────────────────┘ │
│         ...                  │
└──────────────────────────────┘
         [+ Add Event] ← FAB
```

**Interactions**:
- Swipe left/right → Next/previous day
- Tap event → Opens Event Detail modal
- Long press event → Quick actions menu
- Tap empty space → Quick Add at that time
- [+] FAB → Full Event Form
- [Week] button → Week View
- Pull to refresh → Reload events

**Status Indicators**:
- Current time marker (red line)
- Event status:
  - Pending (default)
  - In Progress (green border)
  - Completed (checkmark, dimmed)
  - Cancelled (strikethrough, dimmed)

---

### Event Tap Actions (Event Detail Modal)

**Trigger**: Tap event in Day View

**Modal Content** (Bottom Sheet):
```
┌──────────────────────────────┐
│         [Event Title]        │
│                              │
│ 📅 Thu, Jan 16               │
│ 🕐 10:00 AM - 11:30 AM       │
│ 📁 Category: Work            │
│ 📍 Location: Office          │
│ 👤 With: Alice, Bob          │
│                              │
│ [Description text...]        │
│                              │
│ ┌──────┬──────┬──────┬─────┐│
│ │ Edit │ Move │ Done │ Del ││
│ └──────┴──────┴──────┴─────┘│
└──────────────────────────────┘
```

**Actions**:
1. **Edit** → Opens Event Form (edit mode)
2. **Move** → Opens Reschedule flow
3. **Done** → Marks complete, reschedules remaining
4. **Delete** → Confirmation dialog → Deletes

**Variations**:
- Fixed events: "Move" button disabled or warning
- Locked events: "Edit" and "Move" disabled
- Recurring events: "Edit This" vs "Edit Series"

---

### Reschedule Flow

**Trigger**: "Move" button in Event Detail

**Step 1: Choose New Time**

**Options**:
- **Suggest Times** (default)
  - Shows 3-5 suggested time slots
  - Based on availability and constraints
  - Tap to select
- **Pick Manually**
  - Opens date/time picker
  - Validates against conflicts

**Step 2: Conflict Resolution (if applicable)**

If new time conflicts:
```
⚠️ Conflict Detected

Your new time overlaps with:
• "Team Meeting" (2:00 PM - 3:00 PM)

Options:
┌────────────────────────────┐
│ Move "Team Meeting" instead │
│ Shorten this event          │
│ Choose different time       │
└────────────────────────────┘
```

**Actions**:
- Select option
- Apply changes
- Return to Day View

---

### Quick Add (Tap Empty Space)

**Trigger**: Tap empty slot in Day View timeline

**Modal** (Small):
```
┌──────────────────────────┐
│ Quick Add Event          │
│                          │
│ Title: [_____________]   │
│                          │
│ 🕐 2:00 PM - [Duration ▼]│
│                          │
│ 📁 [Category ▼]          │
│                          │
│ [Add] [More Options...]  │
└──────────────────────────┘
```

**Fields**:
- Title (required)
- Time (pre-filled from tap location)
- Duration dropdown (15min, 30min, 1hr, 2hr, custom)
- Category dropdown

**Actions**:
- "Add" → Creates event, closes modal
- "More Options" → Opens full Event Form with prefilled data

---

### Event Completion

**Trigger**: Tap "Done" on event

**Actions**:
1. Marks event as completed
2. Prompts: "Reschedule remaining flexible events?"
   - "Yes" → Triggers rescheduling in background
   - "No" → Just marks complete
3. Updates goal progress
4. Shows brief success message

**Visual Feedback**:
- Event dims and shows checkmark
- Confetti animation (optional)
- Goal progress updates

---

### Full Event Form

**Entry Point**: 
- FAB (+) button
- "More Options" from Quick Add
- "Edit" from Event Detail

**Form Fields**:

**Basic**:
- Title* (text input)
- Description (text area)
- Category (dropdown)

**Timing**:
- Type selector:
  - [Fixed Time] [Flexible]
- If Fixed:
  - Start Date/Time picker
  - End Date/Time picker
- If Flexible:
  - Duration picker (hours, minutes)
  - Preferred time of day (morning/afternoon/evening)

**Details**:
- Location (dropdown + create new)
- People (multi-select + create new)
- Goals (multi-select from active goals)

**Constraints** (Expandable):
- Movable (toggle)
- Resizable (toggle)
- Lock this event (toggle)
- Must occur between (time window picker)

**Recurrence** (Expandable):
- Repeat (None/Daily/Weekly/Monthly)
- Every [N] [weeks]
- On [days of week]
- Ends [Never/On date/After N times]

**Actions**:
- "Save" button (primary)
- "Cancel" button (secondary)
- "Delete" button (if editing, destructive style)

**Validation**:
- Required fields highlighted
- Conflict warning if fixed time overlaps
- Invalid time range errors

---

## Conflict Handling Flow

### Conflict Detection

**When**: 
- Creating fixed event
- Moving event
- Accepting schedule

**Alert**:
```
┌──────────────────────────────┐
│ ⚠️ Scheduling Conflict       │
│                              │
│ "New Event" (2:00 - 3:00 PM) │
│        conflicts with        │
│ "Meeting" (2:30 - 3:30 PM)   │
│                              │
│ How would you like to        │
│ resolve this?                │
│                              │
│ ┌──────────────────────────┐ │
│ │ Move "New Event"         │ │
│ │ Move "Meeting"           │ │
│ │ Shorten "New Event"      │ │
│ │ Cancel                   │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

**Resolution Options**:
1. **Move newer event** → Opens time picker
2. **Move existing event** → Opens time picker (if movable)
3. **Shorten event** → Adjusts duration to fit
4. **Cancel** → Discards changes

---

## Navigation Structure

### App Bar (Persistent)

**Left**: 
- Back arrow (when applicable)
- Hamburger menu (main screens)

**Center**: 
- Screen title or date

**Right**:
- Settings icon
- Search icon (future)
- More options (context menu)

### Bottom Nav / Main Screens

**Option 1: Bottom Navigation Bar**
```
┌─────┬─────┬─────┬─────┐
│ Day │Week │Goals│More │
└─────┴─────┴─────┴─────┘
```

**Option 2: Drawer Menu**
```
☰ Menu
├─ 📅 Day View
├─ 📆 Week View
├─ 🎯 Goals
├─ 👥 People
├─ 📍 Locations
├─ ⚙️ Settings
└─ ℹ️ About
```

**Recommendation**: Bottom nav for MVP (simpler)

---

## Notification Flows

### Event Reminders

**Trigger**: 15 minutes before event (configurable)

**Notification**:
```
TimePlanner
──────────────────
📅 Upcoming: Deep Work
   Starts at 2:00 PM
   
[Snooze] [View]
```

**Actions**:
- Tap notification → Opens app to Day View
- "View" → Opens Event Detail
- "Snooze" → Reminds again in 5 minutes

---

### Schedule Ready

**Trigger**: After generating weekly schedule

**Notification**:
```
TimePlanner
──────────────────
✅ Your schedule is ready!
   15 events scheduled
   2 goals on track
   
[View Schedule]
```

**Actions**:
- Tap → Opens Plan Review screen

---

### Goal Progress Updates

**Trigger**: 
- End of day (if goal at risk)
- End of week (summary)

**Notification**:
```
TimePlanner
──────────────────
🎯 Goal Update: Work
   8/10 hours completed this week
   
[View Progress]
```

---

## Error States

### No Events

**Day View**:
```
┌──────────────────────────────┐
│                              │
│      📅                      │
│                              │
│  No events today             │
│                              │
│  [Add Event]                 │
│                              │
└──────────────────────────────┘
```

### Scheduling Failed

**Plan Review**:
```
┌──────────────────────────────┐
│ ❌ Scheduling Failed          │
│                              │
│ We couldn't create a         │
│ schedule that meets all      │
│ your requirements.           │
│                              │
│ Suggestions:                 │
│ • Remove some events         │
│ • Relax time constraints     │
│ • Extend the time window     │
│                              │
│ [Try Again] [Adjust Events]  │
└──────────────────────────────┘
```

### Network Error (Future)

**General**:
```
⚠️ Connection Error
Unable to sync data.
Changes saved locally.

[Retry] [Dismiss]
```

---

*Last updated: 2026-01-16*
