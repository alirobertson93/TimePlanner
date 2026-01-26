# User Guide

**TimePlanner - Smart Time Planning Application**

Welcome to TimePlanner! This guide will help you make the most of the app's intelligent scheduling features.

> **Note**: TimePlanner uses the term "Activity" for all calendar items - whether they're scheduled appointments, flexible tasks, or items in your planning bank.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [The Day View](#the-day-view)
3. [Creating Activities](#creating-activities)
4. [Week View](#week-view)
5. [Planning Wizard](#planning-wizard)
6. [Goals](#goals)
7. [People & Locations](#people--locations)
8. [Recurring Activities](#recurring-activities)
9. [Activity Series](#activity-series)
10. [Notifications](#notifications)
11. [Settings](#settings)
12. [Tips & Best Practices](#tips--best-practices)
13. [Troubleshooting](#troubleshooting)

---

## Getting Started

### First Launch

When you first open TimePlanner, you'll see a **6-page onboarding wizard** that introduces you to the key features:

1. **Welcome** - Overview of TimePlanner
2. **Recurring Activities** - Set up activities that repeat weekly
3. **People & Time Goals** - Add people and set time goals with them
4. **Unscheduled Activities** - Build your activity bank for planning
5. **Places** - Add your common locations
6. **Summary** - Review and get started

At the end of onboarding, you can choose to **install sample data** to see how the app looks with activities, goals, and people already set up. This is great for exploring features before entering your own data.

### Key Concepts

- **Scheduled Activities**: Activities with specific times that appear on your calendar
- **Unscheduled Activities**: Activities in your "activity bank" waiting to be scheduled
- **Fixed Activities**: Activities that cannot be moved (meetings, appointments)
- **Flexible Activities**: Tasks that can be scheduled at any available time
- **Categories**: Organize activities by type (Work, Personal, Health, etc.)
- **Goals**: Track time spent on categories, people, locations, or specific activities
- **Series**: Groups of related activities that can be edited together

---

## The Day View

The Day View is your home screen and shows a **24-hour scrollable timeline** of your day.

### Navigation

- **← Previous Day**: Tap the left arrow to go back a day
- **Today Button**: Tap "Today" to jump to the current date
- **→ Next Day**: Tap the right arrow to go forward a day

### Features

- **Current Time Indicator**: A red line shows the current time
- **Activity Cards**: Your activities appear as colored cards on the timeline
- **Category Colors**: Each activity is color-coded by its category

### Actions

- **Tap an Activity**: Opens the activity detail sheet with full information
- **+ Button (FAB)**: Creates a new activity
- **Top Navigation Buttons**:
  - 📊 Goals Dashboard
  - 👥 People Management
  - 📍 Locations Management
  - 🔔 Notifications
  - ⚙️ Settings
  - 📅 Week View
  - 🗓️ Plan Week

---

## Creating Activities

Tap the **+** button to create a new activity.

### Activity Types

**Fixed Activities** (📌)
- Have a specific start and end time
- Cannot be moved by the scheduler
- Examples: Meetings, doctor appointments, classes

**Flexible Activities** (🔄)
- Have a duration but no specific time
- The Planning Wizard can schedule these optimally
- Examples: Deep work, exercise, reading

**Unscheduled Activities** (📋)
- No date or time assigned yet
- Live in your "Activity Bank"
- The Planning Wizard suggests when to schedule them

### Activity Fields

| Field | Description |
|-------|-------------|
| **Title** | Name of the activity (optional - see below) |
| **Description** | Additional details |
| **Category** | Activity type for organization |
| **Date** | Which day the activity occurs |
| **Start Time** | When the activity begins (fixed activities) |
| **End Time** | When the activity ends (fixed activities) |
| **Duration** | How long the activity takes (flexible activities) |
| **Location** | Where the activity takes place |
| **People** | Who is involved in this activity |
| **Recurrence** | If the activity repeats |

### Minimum Requirements

An activity must have **at least one** of:
- Title
- Person
- Location
- Category

This means you can create an activity with just a person (e.g., "time with Mom") or just a location (e.g., "at the gym") without needing a title.

### Constraints (Advanced)

- **Movable**: Can the scheduler move this activity?
- **Resizable**: Can the scheduler adjust the duration?
- **Locked**: Should this activity stay exactly as scheduled?

---

## Week View

Access the Week View by tapping the calendar icon in the Day View.

### Layout

- Shows **7 days** in a grid
- Activities appear as colored blocks
- Each day shows a summary of activities

### Navigation

- **← Previous Week**: View the previous week
- **Today**: Jump to the current week
- **→ Next Week**: View the next week
- **Tap a Day**: Opens that day in Day View

---

## Planning Wizard

The Planning Wizard is TimePlanner's **intelligent scheduling engine**. Access it by tapping "Plan Week" in the Day View.

### Source Activities

The wizard draws from **all your activities**:
- **Unscheduled activities** from your activity bank
- **Previously scheduled activities** that might need rescheduling
- **Recurring activities** expanded based on their patterns

### The 4-Step Process

#### Step 1: Date Range Selection
- Choose the start and end dates for your planning period
- Quick select buttons: This Week, Next Week, Custom

#### Step 2: Goals Review
- Select which goals should be considered
- Check the goals you want to prioritize
- The scheduler will try to meet these goals

#### Step 3: Strategy Selection
- Choose how you want your schedule optimized:

| Strategy | Description |
|----------|-------------|
| **Balanced** | Spreads work evenly across the week |
| **Front-Loaded** | Schedules important work early in the week |
| **Max Free Time** | Creates larger blocks of free time |
| **Least Disruption** | Minimizes changes to existing activities |

#### Step 4: Schedule Preview
- Review the generated schedule
- See which activities were scheduled, conflicts, and unscheduled items
- **Accept**: Save the schedule to your calendar
- **Reject**: Go back and adjust parameters

### Understanding Results

- **Scheduled Activities**: Activities successfully placed on your calendar
- **Conflicts**: Activities that overlap with existing commitments
- **Unscheduled**: Activities that couldn't be scheduled (not enough time)

---

## Goals

Access Goals by tapping the chart icon in the Day View.

### Types of Goals

**Category Goals**
- Track time spent on a category
- Example: "10 hours of Work per week"

**Relationship Goals (Person)**
- Track time spent with a specific person
- Example: "2 hours with Family per week"

**Location Goals**
- Track time spent at a specific place
- Example: "15 hours at Home Office per week"

**Activity Goals**
- Track time spent on a specific recurring activity
- Example: "3 hours on Guitar Practice per week"

### Creating Goals

1. Tap **+** in the Goals Dashboard
2. Choose what to track (Category, Person, Location, or Activity)
3. Set your target time
4. Choose the period (Weekly, Monthly)
5. Save

### Tracking Progress

The Goals Dashboard shows:
- Progress bars for each goal
- Percentage completed
- Status: On Track, At Risk, Completed
- Goals at risk are highlighted for attention

### How Activities Contribute

When you complete a scheduled activity, it automatically contributes to **all relevant goals**:

**Example**: Activity "Cinema" with person "Girlfriend" and category "Relaxation"
- ✅ Contributes to "Cinema" activity goal (if exists)
- ✅ Contributes to "Girlfriend" person goal (if exists)
- ✅ Contributes to "Relaxation" category goal (if exists)

---

## People & Locations

### Managing People

Access via the People icon in Day View.

- Add contacts associated with your activities
- Track relationship goals
- Associate people with activities

### Managing Locations

Access via the Locations icon in Day View.

- Save frequently used locations
- Set travel times between locations
- The app prompts for travel times when you schedule consecutive activities at different locations

### Travel Times

1. Go to Locations → Manage Travel Times
2. Select two locations
3. Enter the travel time between them
4. Travel times are bidirectional (same time both ways)

---

## Recurring Activities

Create activities that repeat on a schedule.

### Recurrence Options

| Pattern | Description |
|---------|-------------|
| **Daily** | Every day |
| **Weekly** | Same day every week |
| **Biweekly** | Every two weeks |
| **Monthly** | Same date each month |
| **Yearly** | Same date each year |
| **Custom** | Advanced patterns |

### End Conditions

- **Never**: Activity repeats indefinitely
- **After N occurrences**: Stops after a set number
- **On date**: Stops on a specific date

### Identifying Recurring Activities

- Recurring activities show a 🔄 repeat icon
- The activity detail shows the recurrence pattern

---

## Activity Series

**Series** group related activities together, letting you edit them as a unit.

### What is a Series?

A series links activities that represent "the same thing" done multiple times:
- "Cinema with Girlfriend" on different dates
- "Weekly Team Meeting" instances
- "Guitar Practice" sessions

### How Series Work

**Automatic Detection**: When you create an activity similar to existing ones, TimePlanner asks if you want to link them:

```
"This looks similar to 'Cinema with Girlfriend' (3 previous times)"

[ Add to this series ]
[ Keep as standalone ]
```

**Matching Criteria** (triggers the prompt):
- Same title (case-insensitive), OR
- 2+ matching properties (person, location, category)

### Editing Series

When editing an activity in a series, you can choose:
- **This activity only** - Normal edit
- **All activities in this series** - Bulk edit
- **This and all future** - For recurring activities

### Property Variance

If you edit all activities in a series and some properties differ:
- TimePlanner shows which properties vary
- You choose which to sync across all activities
- Unchecked properties keep their individual values

---

## Notifications

Access the Notifications screen via the bell icon.

### Notification Types

| Type | Description |
|------|-------------|
| **Activity Reminder** | Upcoming activity alerts |
| **Schedule Change** | When your schedule is modified |
| **Goal Progress** | Updates on goal achievement |
| **Conflict Warning** | Overlapping activities detected |
| **Goal At Risk** | When you're falling behind on a goal |
| **Goal Completed** | Celebration when you hit a goal |

### Managing Notifications

- Swipe to dismiss individual notifications
- Tap "Mark All Read" to clear unread status
- Tap a notification to go to the related activity or goal

### Notification Settings

Configure notification preferences in Settings:
- Enable/disable reminder notifications
- Enable/disable schedule alerts
- Adjust default reminder times

---

## Settings

Access Settings via the gear icon.

### Schedule Settings

- **Time Slot Duration**: Granularity of scheduling (default: 15 minutes)
- **Work Day Start/End**: Your typical working hours
- **First Day of Week**: Sunday or Monday

### Default Activity Settings

- **Default Duration**: For new activities
- **Default Movable**: Can scheduler move new activities?
- **Default Resizable**: Can scheduler resize new activities?

### Notification Settings

- **Enable Reminders**: Turn notifications on/off
- **Default Reminder**: How early to notify

### Appearance

- **Theme**: Light or Dark mode

### About

- Version information
- Terms of Service
- Privacy Policy

---

## Tips & Best Practices

### For Best Results

1. **Be realistic with time estimates** - Underestimating tasks leads to impossible schedules

2. **Use categories consistently** - Makes goal tracking more meaningful

3. **Set achievable goals** - Start small and increase as you build habits

4. **Review your schedule daily** - The Day View helps you stay on track

5. **Use the Planning Wizard weekly** - Sunday planning sets up your week

6. **Build your Activity Bank** - Add unscheduled activities you want to make time for

### Scheduling Strategy Tips

- **Balanced**: Good for consistent workloads
- **Front-Loaded**: Use when you want to get important work done early and have flexibility later
- **Max Free Time**: Great when you need focused blocks for deep work
- **Least Disruption**: Best when you've already committed to a schedule

### Goal Setting Tips

- Start with 2-3 goals, not 10
- Weekly goals are easier to track than daily
- Include both work and personal goals for balance
- Use different goal types (category, person, activity) for variety

### Series Tips

- Let TimePlanner detect similar activities automatically
- Use series for recurring social activities (dinners with friends, etc.)
- Edit all in a series when you want to update a recurring commitment

---

## Troubleshooting

### Common Issues

**Activities aren't appearing**
- Check the date - you may be viewing the wrong day
- Pull down to refresh the view
- Verify the activity was saved

**Planning Wizard shows many conflicts**
- You may have too many fixed activities
- Try a longer planning period
- Reduce the number of goals or their targets

**Notifications not working**
- Check Settings → Notifications
- Verify device notification permissions for TimePlanner
- Check Do Not Disturb settings

**App is slow**
- Try closing and reopening the app
- Large numbers of activities (100+) may take longer to process
- Consider archiving old completed activities

**Series not detecting matches**
- Make sure activities have similar properties (2+ of: title, person, location, category)
- Check that titles are spelled consistently

### Getting Help

- **GitHub Issues**: Report bugs or request features at https://github.com/alirobertson93/TimePlanner/issues
- **Email**: support@timeplanner.app

---

## Keyboard Shortcuts (Future Feature)

*Keyboard navigation support is planned for a future update.*

---

*Last Updated: 2026-01-26 (Activity Model Refactor documentation)*

*Thank you for using TimePlanner! We hope it helps you make the most of your time.*
