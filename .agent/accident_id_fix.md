# Fixed: Accident ID Mapping

## ✅ Issue Fixed

Updated the `accidentId` parameter to use the correct `accident_id` from task data instead of `policy_number`.

## 📋 Task Data Structure

```json
{
  "accident_id": "4e4414b9-8dfd-405c-9a8c-c4a6759af19c",  // ← This is what we need
  "policy_number": "POL56780",
  "vehicle_number": "MH02DD9870",
  "task_id": "20ef0336-e0f8-4223-bc1d-7338d0669db3",
  ...
}
```

## 🔧 Fix Applied

### File: `TasksListScreen.dart`

**Before**:
```dart
DriverDetailsScreen(
  taskId: task['vehicle_number']?.toString() ?? '',
  accidentId: task['policy_number']?.toString() ?? '',  // ❌ Wrong field
  taskData: task,
)
```

**After**:
```dart
DriverDetailsScreen(
  taskId: task['vehicle_number']?.toString() ?? '',
  accidentId: task['accident_id']?.toString() ?? '',  // ✅ Correct field
  taskData: task,
)
```

## 🔄 Data Flow

```
Task API Response
    ↓
accident_id: "4e4414b9-8dfd-405c-9a8c-c4a6759af19c"
    ↓
TasksListScreen passes to DriverDetailsScreen
    ↓
widget.accidentId = "4e4414b9-8dfd-405c-9a8c-c4a6759af19c"
    ↓
AccidentIntimationScreen._uploadToAPI()
    ↓
request.fields['accident_reference_id'] = widget.accidentId
    ↓
API receives: accident_reference_id = "4e4414b9-8dfd-405c-9a8c-c4a6759af19c"
```

## 📊 Field Mapping

| Task Field | Parameter Name | API Field Name | Value |
|------------|---------------|----------------|-------|
| `accident_id` | `accidentId` | `accident_reference_id` | "4e4414b9-..." |
| `vehicle_number` | `taskId` | `task_id` | "MH02DD9870" |
| `policy_number` | - | - | "POL56780" |

## ✅ Verification

### In AccidentIntimationScreen.dart (Line 1508):
```dart
request.fields['accident_reference_id'] = widget.accidentId;
```

This will now correctly send:
```
accident_reference_id: "4e4414b9-8dfd-405c-9a8c-c4a6759af19c"
```

Instead of the incorrect:
```
accident_reference_id: "POL56780"  // ❌ This was policy_number
```

## 🎯 Summary

**Fixed**: Changed `accidentId` parameter source from `policy_number` to `accident_id`

**Impact**: The API will now receive the correct accident reference ID from the task data

**Files Modified**:
- ✅ `TasksListScreen.dart` - Line 507

The accident reference ID is now correctly mapped! 🎉
