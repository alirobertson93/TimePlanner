# User Guide

**TimePlanner - Smart Time Planning Application**

Welcome to TimePlanner! This guide will help you make the most of the app's intelligent scheduling features.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [The Day View](#the-day-view)
3. [Creating Events](#creating-events)
4. [Week View](#week-view)
5. [Planning Wizard](#planning-wizard)
6. [Goals](#goals)
7. [People & Locations](#people--locations)
8. [Recurring Events](#recurring-events)
9. [Notifications](#notifications)
10. [Settings](#settings)
11. [Tips & Best Practices](#tips--best-practices)
12. [Troubleshooting](#troubleshooting)

---

## Getting Started

### First Launch

When you first open TimePlanner, you'll see a **5-page onboarding wizard** that introduces you to the key features:

1. **Welcome** - Overview of TimePlanner
2. **Smart Scheduling** - How the scheduling algorithm works
3. **Track Your Goals** - Setting and monitoring goals
4. **Plan Ahead** - Using the Planning Wizard
5. **Stay Notified** - Notification options

At the end of onboarding, you can choose to **install sample data** to see how the app looks with events, goals, and people already set up. This is great for exploring features before entering your own data.

### Key Concepts

- **Fixed Events**: Events with specific times that cannot move (meetings, appointments)
- **Flexible Events**: Tasks that need to be scheduled but can happen at any time
- **Categories**: Organize events by type (Work, Personal, Health, etc.)
- **Goals**: Track time spent on categories or with specific people

---

## The Day View

The Day View is your home screen and shows a **24-hour scrollable timeline** of your day.

### Navigation

- **← Previous Day**: Tap the left arrow to go back a day
- **Today Button**: Tap "Today" to jump to the current date
- **→ Next Day**: Tap the right arrow to go forward a day

### Features

- **Current Time Indicator**: A red line shows the current time
- **Event Cards**: Your events appear as colored cards on the timeline
- **Category Colors**: Each event is color-coded by its category

### Actions

- **Tap an Event**: Opens the event detail sheet with full information
- **+ Button (FAB)**: Creates a new event
- **Top Navigation Buttons**:
  - 📊 Goals Dashboard
  - 👥 People Management
  - 📍 Locations Management
  - 🔔 Notifications
  - ⚙️ Settings
  - 📅 Week View
  - 🗓️ Plan Week

---

## Creating Events

Tap the **+** button to create a new event.

### Event Types

**Fixed Events** (📌)
- Have a specific start and end time
- Cannot be moved by the scheduler
- Examples: Meetings, doctor appointments, classes

**Flexible Events** (🔄)
- Have a duration but no specific time
- The Planning Wizard can schedule these optimally
- Examples: Deep work, exercise, reading

### Event Fields

| Field | Description |
|-------|-------------|
| **Title** | Name of the event (required) |
| **Description** | Additional details |
| **Category** | Event type for organization |
| **Date** | Which day the event occurs |
| **Start Time** | When the event begins (fixed events) |
| **End Time** | When the event ends (fixed events) |
| **Duration** | How long the event takes (flexible events) |
| **Location** | Where the event takes place |
| **People** | Who is involved in this event |
| **Recurrence** | If the event repeats |

### Constraints (Advanced)

- **Movable**: Can the scheduler move this event?
- **Resizable**: Can the scheduler adjust the duration?
- **Locked**: Should this event stay exactly as scheduled?

---

## Week View

Access the Week View by tapping the calendar icon in the Day View.

### Layout

- Shows **7 days** in a grid
- Events appear as colored blocks
- Each day shows a summary of events

### Navigation

- **← Previous Week**: View the previous week
- **Today**: Jump to the current week
- **→ Next Week**: View the next week
- **Tap a Day**: Opens that day in Day View

---

## Planning Wizard

The Planning Wizard is TimePlanner's **intelligent scheduling engine**. Access it by tapping "Plan Week" in the Day View.

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
| **Least Disruption** | Minimizes changes to existing events |

#### Step 4: Schedule Preview
- Review the generated schedule
- See which events were scheduled, conflicts, and unscheduled items
- **Accept**: Save the schedule to your calendar
- **Reject**: Go back and adjust parameters

### Understanding Results

- **Scheduled Events**: Events successfully placed on your calendar
- **Conflicts**: Events that overlap with existing commitments
- **Unscheduled**: Events that couldn't be scheduled (not enough time)

---

## Goals

Access Goals by tapping the chart icon in the Day View.

### Types of Goals

**Category Goals**
- Track time spent on a category
- Example: "10 hours of Work per week"

**Relationship Goals**
- Track time spent with a specific person
- Example: "2 hours with Family per week"

### Creating Goals

1. Tap **+** in the Goals Dashboard
2. Choose goal type (Category or Person)
3. Set your target time
4. Choose the period (Daily, Weekly, Monthly)
5. Save

### Tracking Progress

The Goals Dashboard shows:
- Progress bars for each goal
- Percentage completed
- Status: On Track, At Risk, Completed
- Goals at risk are highlighted for attention

---

## People & Locations

### Managing People

Access via the People icon in Day View.

- Add contacts associated with your events
- Track relationship goals
- Associate people with events

### Managing Locations

Access via the Locations icon in Day View.

- Save frequently used locations
- Set travel times between locations
- The app prompts for travel times when you schedule consecutive events at different locations

### Travel Times

1. Go to Locations → Manage Travel Times
2. Select two locations
3. Enter the travel time between them
4. Travel times are bidirectional (same time both ways)

---

## Recurring Events

Create events that repeat on a schedule.

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

- **Never**: Event repeats indefinitely
- **After N occurrences**: Stops after a set number
- **On date**: Stops on a specific date

### Identifying Recurring Events

- Recurring events show a 🔄 repeat icon
- The event detail shows the recurrence pattern

---

## Notifications

Access the Notifications screen via the bell icon.

### Notification Types

| Type | Description |
|------|-------------|
| **Event Reminder** | Upcoming event alerts |
| **Schedule Change** | When your schedule is modified |
| **Goal Progress** | Updates on goal achievement |
| **Conflict Warning** | Overlapping events detected |
| **Goal At Risk** | When you're falling behind on a goal |
| **Goal Completed** | Celebration when you hit a goal |

### Managing Notifications

- Swipe to dismiss individual notifications
- Tap "Mark All Read" to clear unread status
- Tap a notification to go to the related event or goal

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

### Default Event Settings

- **Default Duration**: For new events
- **Default Movable**: Can scheduler move new events?
- **Default Resizable**: Can scheduler resize new events?

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

### Scheduling Strategy Tips

- **Balanced**: Good for consistent workloads
- **Front-Loaded**: Use when you want to get important work done early and have flexibility later
- **Max Free Time**: Great when you need focused blocks for deep work
- **Least Disruption**: Best when you've already committed to a schedule

### Goal Setting Tips

- Start with 2-3 goals, not 10
- Weekly goals are easier to track than daily
- Include both work and personal goals for balance

---

## Troubleshooting

### Common Issues

**Events aren't appearing**
- Check the date - you may be viewing the wrong day
- Pull down to refresh the view
- Verify the event was saved

**Planning Wizard shows many conflicts**
- You may have too many fixed events
- Try a longer planning period
- Reduce the number of goals or their targets

**Notifications not working**
- Check Settings → Notifications
- Verify device notification permissions for TimePlanner
- Check Do Not Disturb settings

**App is slow**
- Try closing and reopening the app
- Large numbers of events (100+) may take longer to process
- Consider archiving old completed events

### Getting Help

- **GitHub Issues**: Report bugs or request features at https://github.com/alirobertson93/TimePlanner/issues
- **Email**: support@timeplanner.app

---

## Keyboard Shortcuts (Future Feature)

*Keyboard navigation support is planned for a future update.*

---

*Last Updated: 2026-01-24*

*Thank you for using TimePlanner! We hope it helps you make the most of your time.*
