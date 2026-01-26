# UX Flows

User journey documentation for TimePlanner.

## Overview

This document defines all user interactions and workflows in TimePlanner. Use this as a reference when implementing features or designing UI.

> **Note**: This document uses the term "Activity" as the unified model for all calendar items. The term "Event" may still appear in the current codebase but will be renamed to "Activity" as part of the Activity Model Refactor (see `ACTIVITY_REFACTOR_IMPLEMENTATION.md`).

**Last Updated**: 2026-01-26

---

## Layer 1: Initial Setup Flow

### Enhanced Onboarding Wizard (First Launch)

**Entry Point**: App first launch

**Purpose**: Guide users through establishing their recurring week-by-week schedule, including recurring activities, people they want to spend time with, unscheduled activities (activity bank), and locations.

**Progress Indicator**: Linear progress bar showing completion percentage across all steps

**Steps**:

1. **Welcome Screen**
   - Welcome message with app logo/icon
   - Brief explanation of what the wizard will help set up:
     - Recurring activities (work, gym, etc.)
     - People you want to spend time with
     - Unscheduled activities (activity bank)
     - Main locations
   - "Get Started" button (Next)
   - "Skip" option (goes to main app with defaults)

2. **Recurring Activities Setup**
   - Header: "Recurring Activities" with repeat icon
   - Description: "Add activities that happen at the same time each week"
   - List of added recurring activities (with delete option)
   - "Add Recurring Activity" button opens dialog:
     - Activity Name (required)
     - Description (optional)
     - Start time picker
     - End time picker
     - Day selector chips (S, M, T, W, T, F, S)
   - Empty state: "No recurring activities added yet. You can skip this step or add them later."
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

4. **Unscheduled Activities Setup** (Activity Bank)
   - Header: "Unscheduled Activities" with flag icon
   - Description: "Add activities you want to make time for. These go into your activity bank for the planning wizard to schedule."
   - List of added unscheduled activities with optional time goals
   - "Add Activity" button opens dialog:
     - Activity Name (required)
     - Duration (optional) - default duration for when scheduled
     - Category (optional)
     - Time Goal section (optional):
       - Hours dropdown (0-20, 0 = "No goal")
       - Period dropdown (Per week / Per month)
   - Suggested activities as quick-add chips:
     - Exercise (3 hrs/week)
     - Reading (2 hrs/week)
     - Learning (2 hrs/week)
     - Meditation (1 hr/week)
     - Hobbies (3 hrs/week)
     - Side Project (5 hrs/week)
   - Back/Next navigation
   - **Data Created**: Unscheduled Activity entities (no startTime/endTime) + optional associated Goals

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
     - Recurring Activities: X
     - People Added: X
     - Unscheduled Activities: X
     - Locations: X
   - Tip: "Use the Planning Wizard to automatically schedule your flexible activities around your fixed commitments."
   - "Get Started" button → Saves all data and goes to main app

**Data Created**:
- Recurring activities are saved with weekly recurrence rules
- People are saved with associated time goals (GoalType.person)
- Unscheduled activities are saved as Activity entities WITHOUT dates (activity bank) + optional time goals (GoalType.activity)
- Locations are saved with optional time goals (GoalType.location)

**Exit Points**:
- ✅ Complete onboarding → Day View (all data saved)
- ⏭️ Skip → Day View (no data created, defaults used)
- Can replay via Settings > "Replay Onboarding"

**Time Goal Periods**:
- **Per Week**: Progress tracked against current week (Monday-Sunday)
- **Per Month**: Progress tracked against current calendar month
  - The app calculates boundaries and aggregates activities accordingly
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

**Source Activities**:
The wizard draws from ALL activities:
- **Unscheduled activities** (the activity bank) - Activities without dates/times
- **Previously scheduled activities** (historical) - Can suggest scheduling again
- **Recurring activities** - Expanded based on recurrence rules

**Series Integration**:
When the wizard schedules an activity:
1. Check for series matches (same title OR 2+ property matches)
2. If match found → show series prompt (add to series or standalone)
3. Create new Activity record with appropriate seriesId

**Important**: Each scheduled instance is its own Activity record. The wizard doesn't create "instances" of a template - it creates new Activities that may or may not be linked via seriesId.

#### Step 1: Date Range Selection

**Screen**: Date range picker

**Elements**:
- "Plan your week" header
- Week selector (defaults to upcoming week)
- Start date: [Date Picker] (defaults to next Monday)
- End date: [Date Picker] (defaults to next Sunday)
- Info: Shows count of existing activities in range
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
  - Activity count per day
  - Visual timeline
- Expand button for each day → Shows all activities
- Conflicts/Warnings section (if any):
  - "3 activities couldn't be scheduled"
  - List of unscheduled activities
  - Suggested actions
- "Accept Schedule" button (primary)
- "Try Different Strategy" button (secondary)
- "Cancel" button

**Actions**:
- Accept → Saves schedule, goes to Week View
- Try Different → Goes back to Step 3
- Tap day → Expand to show activities
- Tap unscheduled activity → Options to remove/shorten

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

### Series Matching Prompt (NEW - Activity Model Refactor)

**Entry Point**: 
- When saving a new activity (from activity form)
- When scheduling an activity (from planning wizard)

**Trigger Conditions** (prompt if ANY are true):
- Same title (case-insensitive) as an existing activity
- At least 2 matches among: person(s), location, category

**Screen** (Bottom Sheet):
```
┌─────────────────────────────────────────────────┐
│  This looks similar to an existing activity     │
│                                                 │
│  "Cinema with Girlfriend" (3 previous times)    │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  Add to this series                     │   │
│  │  Changes to shared properties will      │   │
│  │  apply to all activities in the series  │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  Keep as standalone                     │   │
│  │  This activity won't be linked to      │   │
│  │  any others                             │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Actions**:
- "Add to this series" → Sets `seriesId` to match existing series
- "Keep as standalone" → Creates activity with unique `seriesId` (or null)

**Logic**:
```dart
// SeriesMatchingService.findMatchingSeries(Activity)
bool isMatch(Activity newActivity, Activity existing) {
  // Title match (case-insensitive)
  if (newActivity.title?.toLowerCase() == existing.title?.toLowerCase() &&
      newActivity.title != null) {
    return true;
  }
  
  // Property match (2+ of: person, location, category)
  int matchCount = 0;
  if (newActivity.categoryId != null && 
      newActivity.categoryId == existing.categoryId) matchCount++;
  if (newActivity.locationId != null && 
      newActivity.locationId == existing.locationId) matchCount++;
  if (hasSamePerson(newActivity, existing)) matchCount++;
  
  return matchCount >= 2;
}
```

---

### Edit Scope Prompt (NEW - Activity Model Refactor)

**Entry Point**: When editing an activity that belongs to a series (`seriesId` is not null AND other activities share the same `seriesId`)

**Screen** (Dialog):
```
┌─────────────────────────────────────────────────┐
│  Edit Activity                                  │
│                                                 │
│  This activity is part of a series (5 total)   │
│                                                 │
│  What would you like to edit?                   │
│                                                 │
│  ○ This activity only                          │
│  ○ All activities in this series               │
│  ○ This and all future activities              │  ← only if recurring
│                                                 │
│           [Cancel]    [Continue]                │
└─────────────────────────────────────────────────┘
```

**Options**:
1. **This activity only** → Normal edit, doesn't affect other activities
2. **All activities in this series** → Bulk edit all activities with same `seriesId`
3. **This and all future activities** → Only shown for recurring activities; edits this and future instances

**Property Variance Handling** (when "All in series" selected):

If properties vary across activities in the series, show a second step:

```
┌─────────────────────────────────────────────────┐
│  Some properties differ across this series:     │
│                                                 │
│  • Duration: varies (30min, 45min, 1hr)        │
│  • Location: varies (Cinema A, Cinema B)        │
│                                                 │
│  ☑ Update Duration to match (1hr)              │
│  ☐ Update Location to match (Cinema A)          │
│                                                 │
│           [Cancel]    [Save Changes]            │
└─────────────────────────────────────────────────┘
```

**Logic**:
- Detect which properties vary across series
- For checked properties: update all activities to match current values
- For unchecked properties: leave unchanged in each activity

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
         [+ Add Activity] ← FAB
```

**Interactions**:
- Swipe left/right → Next/previous day
- Tap activity → Opens Activity Detail modal
- Long press activity → Quick actions menu
- Tap empty space → Quick Add at that time
- [+] FAB → Full Activity Form
- [Week] button → Week View
- Pull to refresh → Reload activities

**Status Indicators**:
- Current time marker (red line)
- Activity status:
  - Pending (default)
  - In Progress (green border)
  - Completed (checkmark, dimmed)
  - Cancelled (strikethrough, dimmed)

---

### Activity Tap Actions (Activity Detail Modal)

**Trigger**: Tap activity in Day View

**Modal Content** (Bottom Sheet):
```
┌──────────────────────────────┐
│         [Activity Title]     │
│                              │
│ 📅 Thu, Jan 16               │
│ 🕐 10:00 AM - 11:30 AM       │
│ 📁 Category: Work            │
│ 📍 Location: Office          │
│ 👤 With: Alice, Bob          │
│ 🔗 Part of series (5 total)  │  ← Only if seriesId exists
│                              │
│ [Description text...]        │
│                              │
│ ┌──────┬──────┬──────┬─────┐│
│ │ Edit │ Move │ Done │ Del ││
│ └──────┴──────┴──────┴─────┘│
└──────────────────────────────┘
```

**Actions**:
1. **Edit** → Opens Activity Form (edit mode); shows Edit Scope Prompt if part of series
2. **Move** → Opens Reschedule flow
3. **Done** → Marks complete, reschedules remaining
4. **Delete** → Confirmation dialog → Deletes (with series options if applicable)

**Variations**:
- Fixed activities: "Move" button disabled or warning
- Locked activities: "Edit" and "Move" disabled
- Recurring activities: "Edit This" vs "Edit Series"
- Series activities: Shows "Part of series (N total)" indicator

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
│ Quick Add Activity       │
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
- Title (optional - see validation rules)
- Time (pre-filled from tap location)
- Duration dropdown (15min, 30min, 1hr, 2hr, custom)
- Category dropdown

**Actions**:
- "Add" → Creates activity (with series matching check), closes modal
- "More Options" → Opens full Activity Form with prefilled data

---

### Activity Completion

**Trigger**: Tap "Done" on activity

**Actions**:
1. Marks activity as completed
2. Prompts: "Reschedule remaining flexible activities?"
   - "Yes" → Triggers rescheduling in background
   - "No" → Just marks complete
3. Updates goal progress (contributes to ALL relevant goals)
4. Shows brief success message

**Goal Contribution** (when activity completes):
A completed activity contributes to ALL matching goals:
- Title goal (if `GoalType.activity` with matching `activityTitle`)
- Person goal (if `GoalType.person` with matching person via ActivityPeople)
- Location goal (if `GoalType.location` with matching `locationId`)
- Category goal (if `GoalType.category` with matching `categoryId`)

**Visual Feedback**:
- Activity dims and shows checkmark
- Confetti animation (optional)
- Goal progress updates

---

### Full Activity Form

**Entry Point**: 
- FAB (+) button
- "More Options" from Quick Add
- "Edit" from Activity Detail

**Form Fields**:

**Basic**:
- Title (text input) - **OPTIONAL** (see validation)
- Description (text area)
- Category (dropdown) - can satisfy minimum requirement

**Timing**:
- Type selector:
  - [Fixed Time] [Flexible] [Unscheduled]
- If Fixed:
  - Start Date/Time picker
  - End Date/Time picker
- If Flexible:
  - Duration picker (hours, minutes)
  - Preferred time of day (morning/afternoon/evening)
- If Unscheduled:
  - Default Duration picker (for when scheduled)
  - Goes into Activity Bank

**Details**:
- Location (dropdown + create new) - can satisfy minimum requirement
- People (multi-select + create new) - can satisfy minimum requirement
- Goals (multi-select from active goals)

**Constraints** (Expandable):
- Movable (toggle)
- Resizable (toggle)
- Lock this activity (toggle)
- Must occur between (time window picker)

**Recurrence** (Expandable):
- Repeat (None/Daily/Weekly/Monthly)
- Every [N] [weeks]
- On [days of week]
- Ends [Never/On date/After N times]

**Validation**:
- Must have at least ONE of: title, person, location, category
- Invalid if none of the above are provided
- Conflict warning if fixed time overlaps
- Invalid time range errors

**Series Integration**:
- On save, check for series matches
- Show Series Matching Prompt if match found

**Actions**:
- "Save" button (primary)
- "Cancel" button (secondary)
- "Delete" button (if editing, destructive style)

---

## Conflict Handling Flow

### Conflict Detection

**When**: 
- Creating fixed activity
- Moving activity
- Accepting schedule

**Alert**:
```
┌──────────────────────────────┐
│ ⚠️ Scheduling Conflict       │
│                              │
│ "New Activity" (2:00 - 3:00) │
│        conflicts with        │
│ "Meeting" (2:30 - 3:30 PM)   │
│                              │
│ How would you like to        │
│ resolve this?                │
│                              │
│ ┌──────────────────────────┐ │
│ │ Move "New Activity"      │ │
│ │ Move "Meeting"           │ │
│ │ Shorten "New Activity"   │ │
│ │ Cancel                   │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

**Resolution Options**:
1. **Move newer activity** → Opens time picker
2. **Move existing activity** → Opens time picker (if movable)
3. **Shorten activity** → Adjusts duration to fit
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

**Trigger**: 15 minutes before activity (configurable)

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
- "View" → Opens Activity Detail
- "Snooze" → Reminds again in 5 minutes

---

### Schedule Ready

**Trigger**: After generating weekly schedule

**Notification**:
```
TimePlanner
──────────────────
✅ Your schedule is ready!
   15 activities scheduled
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

### No Activities

**Day View**:
```
┌──────────────────────────────┐
│                              │
│      📅                      │
│                              │
│  No activities today         │
│                              │
│  [Add Activity]              │
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
│ • Remove some activities     │
│ • Relax time constraints     │
│ • Extend the time window     │
│                              │
│ [Try Again] [Adjust Activities]│
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

*Last updated: 2026-01-26 (Activity Model Refactor documentation)*
