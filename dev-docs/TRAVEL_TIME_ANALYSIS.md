# Travel Time Feature Analysis

**Date**: 2026-01-23  
**Purpose**: Analysis of travel time implementation status vs. user requirements

## Executive Summary

**Good news: Your app has NOT been incorrectly designed.** The travel time feature has been **designed but not yet implemented**, which means there's no incorrect implementation to undo. The design documents are well-thought-out and align with your requirements, with some minor clarifications needed.

## User Requirements (Restated)

The user wants travel time to be **manual user entry only** (no GPS/distance calculations for now):

### Requirement 1: Dedicated Locations Menu
- User can assign travel times manually between any two locations
- Choose Location A (from user's list or add new)
- Choose Location B (from user's list or add new)
- Enter travel time manually
- System remembers this for future use

### Requirement 2: Event Entry/Reordering Prompt
- When consecutive events have different locations
- If travel time for that location pair hasn't been set
- Prompt user to enter travel time
- Remember the assignment for future use

### Requirement 3: Future GPS Integration
- Nice to have for future, but NOT needed now

---

## Current Implementation Status

### ✅ What's ALREADY Implemented

| Component | Status | Notes |
|-----------|--------|-------|
| **Locations Table** | ✅ Complete | Full CRUD, with lat/lon fields (optional) |
| **Location Entity** | ✅ Complete | Domain model ready |
| **LocationRepository** | ✅ Complete | All CRUD operations |
| **Locations Management UI** | ✅ Complete | Create, edit, delete locations |
| **LocationPicker Widget** | ✅ Complete | Integrated into Event Form |
| **Events.locationId** | ✅ Complete | Events can have location associations |

### ❌ What's NOT Yet Implemented

| Component | Status | Notes |
|-----------|--------|-------|
| **TravelTimePairs Table** | ❌ Not created | Database table doesn't exist |
| **TravelTimePairs Entity** | ❌ Not created | Domain model doesn't exist |
| **TravelTimePairs Repository** | ❌ Not created | No CRUD operations |
| **Travel Time Entry UI** | ❌ Not created | No UI for entering times |
| **Travel Time Prompt** | ❌ Not created | No prompt on consecutive events |
| **Scheduler Integration** | ❌ Not created | Scheduler doesn't block for travel |

---

## Analysis of Documentation

### ALGORITHM.md (Lines 569-605)

The algorithm documentation describes a `TravelTimeHandler` class that:
- Looks up pre-computed travel times from `Map<(String, String), Duration>`
- Has a fallback `_estimateTravelTime()` method for distance-based estimation
- Can insert "travel events" into the availability grid

**Assessment**: The design is **compatible** with manual entry. The "estimation" fallback can simply return zero or prompt the user instead of doing distance calculations. No changes needed to the algorithm design.

### DATA_MODEL.md (Lines 273-288)

The data model specifies a `TravelTimePairs` table:
```dart
class TravelTimePairs extends Table {
  TextColumn get fromLocationId => text().references(Locations, #id);
  TextColumn get toLocationId => text().references(Locations, #id);
  IntColumn get travelTimeMinutes => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {fromLocationId, toLocationId};
}
```

**Assessment**: This design is **perfect** for manual entry. No GPS-specific fields exist. The design simply stores: From Location → To Location → Duration. This is exactly what's needed.

### ROADMAP.md (Phase 7)

The roadmap lists:
- [ ] Calculate travel time between locations
- [ ] Auto-schedule travel buffer
- [ ] Travel time in schedule generation

**Assessment**: The wording "calculate travel time" could be interpreted as GPS-based calculation, which may have caused confusion. However, this can also mean "calculate from stored values" which aligns with manual entry. The roadmap should be clarified.

### Location Entity (latitude/longitude fields)

The Location entity has optional `latitude` and `longitude` fields.

**Assessment**: These are **correctly optional**. They were added for potential future GPS features. They don't need to be used for the manual travel time feature.

---

## Conclusion: Is There a Misunderstanding?

**Minor documentation ambiguity exists**, but no incorrect implementation:

1. **The phrase "calculate travel time"** in the roadmap could imply GPS distance calculation, but the actual data model supports pure manual entry.

2. **The `_estimateTravelTime()` fallback** in ALGORITHM.md suggests distance-based estimation, but this is clearly marked as a fallback for when no entry exists - it can easily be replaced with "prompt user" behavior.

3. **Latitude/longitude fields exist** in the Location entity but are optional. They don't force GPS usage.

---

## Recommended Implementation Plan

Since the travel time feature is **not yet implemented**, we can implement it correctly from the start:

### Step 1: Data Layer (Backend)
1. Create `TravelTimePair` domain entity
2. Create `TravelTimePairs` database table
3. Create `TravelTimePairRepository` with CRUD operations
4. Add database migration (v9 → v10)
5. Write repository tests

### Step 2: Travel Time Entry UI (Locations Menu)
1. Add "Manage Travel Times" option to Locations screen
2. Create `TravelTimeEntryScreen` with:
   - From Location dropdown (with "Add New" option)
   - To Location dropdown (with "Add New" option)  
   - Travel time input (minutes)
   - Save button
3. Create list view of existing travel time entries
4. Allow editing/deleting travel time entries

### Step 3: Event Prompt Feature
1. Detect when consecutive events have different locations
2. Check if travel time exists for that pair (either direction)
3. If not, show dialog prompting user to enter travel time
4. Store the entry for future use
5. Apply to schedule generation

### Step 4: Scheduler Integration
1. Use stored travel times in schedule generation
2. Block time slots for travel between consecutive events
3. Show conflicts if insufficient travel time

### Step 5: Documentation Updates
1. Update ROADMAP.md to clarify "manual travel time entry"
2. Update ALGORITHM.md to clarify no GPS required for initial implementation
3. Mark GPS integration as "Future Enhancement"

---

## Suggested Documentation Clarifications

### ROADMAP.md - Suggested Update

Change:
```
- [ ] Calculate travel time between locations
```

To:
```
- [ ] Store and use manual travel time between locations
- [ ] (Future) GPS-based travel time estimation
```

### ALGORITHM.md - Suggested Update

Add note to TravelTimeHandler section:
```
Note: Initial implementation uses manual user entry only. 
GPS-based estimation is planned for a future release.
```

---

## Summary

| Question | Answer |
|----------|--------|
| **Has the app been incorrectly designed?** | ❌ No |
| **Is there code to undo?** | ❌ No (feature not implemented) |
| **Does the data model support manual entry?** | ✅ Yes |
| **Are docs misleading?** | ⚠️ Slightly ambiguous |
| **Can we proceed with manual entry?** | ✅ Yes |

**Recommendation**: Proceed with implementing the manual travel time entry feature as described above. The existing design supports this approach perfectly.

---

*Analysis complete: 2026-01-23*
