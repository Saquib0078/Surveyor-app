# Vehicle Number from Task Data

## ✅ Implementation Complete

Updated the flow to pass vehicle_number from task data through to the API, similar to how surveyor_id is handled.

## 🔄 Data Flow

```
Task API Response
    ↓
{
  "vehicle_number": "MH02DD9870",
  "accident_id": "4e4414b9-...",
  "surveyor_id": "6f77c862-...",
  ...
}
    ↓
TasksListScreen
    ↓
taskData: task (entire task object)
    ↓
DriverDetailsScreen
    ↓
widget.taskData['vehicle_number'] = "MH02DD9870"
    ↓
allDetails map
    ↓
allDetails['vehicle_number'] = "MH02DD9870"
    ↓
AccidentIntimationScreen
    ↓
widget.driverDetails['vehicle_number'] = "MH02DD9870"
    ↓
API Request
    ↓
vehicle_number: "MH02DD9870" ✅
```

## 📝 Code Changes

### 1. DriverDetailsScreen - Add to allDetails

**File**: `DriverDetailsScreen.dart` (Line 1031)

```dart
// Add vehicle_number from task data if available
if (widget.taskData != null && widget.taskData!['vehicle_number'] != null) {
  allDetails['vehicle_number'] = widget.taskData!['vehicle_number'];
  print('Added vehicle_number from task: ${widget.taskData!['vehicle_number']}');
}
```

### 2. AccidentIntimationScreen - Use from driverDetails

**File**: `AccidentIntimationScreen.dart` (Line 1502)

```dart
request.fields['vehicle_number'] = widget.driverDetails?['vehicle_number']?.toString() ?? widget.taskId;
```

**Fallback**: Uses `widget.taskId` if `vehicle_number` is not in driverDetails

## 📊 Comparison with Surveyor ID

### Surveyor ID Flow:
```
SharedPreferences
    ↓
_surveyorId = "6f77c862-..."
    ↓
API: suv_id = "6f77c862-..."
```

### Vehicle Number Flow (NEW):
```
Task Data
    ↓
taskData['vehicle_number'] = "MH02DD9870"
    ↓
allDetails['vehicle_number'] = "MH02DD9870"
    ↓
driverDetails['vehicle_number'] = "MH02DD9870"
    ↓
API: vehicle_number = "MH02DD9870"
```

## 🎯 Example

### Task Data:
```json
{
  "vehicle_number": "MH02DD9870",
  "policy_number": "POL56780",
  "accident_id": "4e4414b9-8dfd-405c-9a8c-c4a6759af19c",
  "surveyor_id": "6f77c862-1798-4158-bb45-8dc58b9314df"
}
```

### allDetails Map:
```dart
{
  'accident_datetime': '2025-12-23 10:54',
  'accident_location': 'Akola',
  'vehicle_number': 'MH02DD9870',  // ✅ From task
  'driver_name': 'John Doe',
  ...
}
```

### API Request:
```json
{
  "vehicle_number": "MH02DD9870",
  "accident_reference_id": "4e4414b9-8dfd-405c-9a8c-c4a6759af19c",
  "task_id": "MH02DD9870",
  "suv_id": "6f77c862-1798-4158-bb45-8dc58b9314df",
  ...
}
```

## 🔍 Debug Logs

When the flow runs, you'll see:

```
Added vehicle_number from task: MH02DD9870
```

## ⚠️ Fallback Mechanism

If `vehicle_number` is not in `driverDetails`:
```dart
widget.driverDetails?['vehicle_number']?.toString() ?? widget.taskId
```

**Result**: Falls back to `widget.taskId` (which also contains vehicle_number)

## ✅ Summary

**Changes Made**:
1. ✅ Added `vehicle_number` to `allDetails` map in `DriverDetailsScreen`
2. ✅ Updated API request to use `vehicle_number` from `driverDetails`
3. ✅ Added fallback to `taskId` for safety
4. ✅ Added debug logging

**Data Source**: Task API response → `taskData` → `allDetails` → `driverDetails` → API

**Result**: Vehicle number from task is now correctly sent to the accident intimation API! 🎉
