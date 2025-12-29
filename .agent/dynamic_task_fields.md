# Dynamic Task Data Fields

## ✅ Fixed: task_id, make, and model

Changed from static values to dynamic values from task API data.

## 🔧 Changes Made

### Before (Static):
```dart
request.fields['task_id'] = widget.taskId;  // ❌ This was vehicle_number
request.fields['make'] = 'MAHINDRA & MAHINDRA';  // ❌ Static
request.fields['model'] = 'BOLERO';  // ❌ Static
```

### After (Dynamic):
```dart
request.fields['task_id'] = widget.driverDetails?['task_id']?.toString() ?? widget.accidentId;  // ✅ From task
request.fields['make'] = widget.driverDetails?['make']?.toString() ?? 'MAHINDRA & MAHINDRA';  // ✅ From task
request.fields['model'] = widget.driverDetails?['model']?.toString() ?? 'BOLERO';  // ✅ From task
```

## 📊 Task API Response

```json
{
  "task_id": "20ef0336-e0f8-4223-bc1d-7338d0669db3",
  "vehicle_number": "MH02DD9870",
  "accident_id": "4e4414b9-8dfd-405c-9a8c-c4a6759af19c",
  "make": "MAHINDRA & MAHINDRA",
  "model": "BOLERO",
  "surveyor_id": "6f77c862-1798-4158-bb45-8dc58b9314df",
  ...
}
```

## 🔄 Data Flow

```
Task API Response
    ↓
{
  "task_id": "20ef0336-...",
  "make": "MAHINDRA & MAHINDRA",
  "model": "BOLERO",
  "vehicle_number": "MH02DD9870"
}
    ↓
TasksListScreen
    ↓
taskData: task (entire object)
    ↓
DriverDetailsScreen
    ↓
allDetails['task_id'] = task['task_id']
allDetails['make'] = task['make']
allDetails['model'] = task['model']
allDetails['vehicle_number'] = task['vehicle_number']
    ↓
AccidentIntimationScreen
    ↓
widget.driverDetails['task_id'] = "20ef0336-..."
widget.driverDetails['make'] = "MAHINDRA & MAHINDRA"
widget.driverDetails['model'] = "BOLERO"
widget.driverDetails['vehicle_number'] = "MH02DD9870"
    ↓
API Request
    ↓
{
  "task_id": "20ef0336-...",
  "make": "MAHINDRA & MAHINDRA",
  "model": "BOLERO",
  "vehicle_number": "MH02DD9870"
}
```

## 📝 Fields Updated

| Field | Before | After |
|-------|--------|-------|
| `task_id` | `widget.taskId` (vehicle_number) | `task['task_id']` (actual task ID) |
| `make` | Static "MAHINDRA & MAHINDRA" | From `task['make']` |
| `model` | Static "BOLERO" | From `task['model']` |
| `vehicle_number` | Already dynamic ✅ | Already from task ✅ |

## 🎯 Example

### Task Data:
```json
{
  "task_id": "20ef0336-e0f8-4223-bc1d-7338d0669db3",
  "vehicle_number": "MH02DD9870",
  "make": "TATA",
  "model": "NEXON",
  "accident_id": "4e4414b9-..."
}
```

### API Request (Before):
```json
{
  "task_id": "MH02DD9870",  // ❌ Wrong! This is vehicle_number
  "make": "MAHINDRA & MAHINDRA",  // ❌ Static
  "model": "BOLERO",  // ❌ Static
  "vehicle_number": "MH02DD9870"
}
```

### API Request (After):
```json
{
  "task_id": "20ef0336-e0f8-4223-bc1d-7338d0669db3",  // ✅ Correct task ID
  "make": "TATA",  // ✅ From task
  "model": "NEXON",  // ✅ From task
  "vehicle_number": "MH02DD9870"
}
```

## 📋 DriverDetailsScreen Changes

Added to `allDetails` map:

```dart
// Add task_id from task data
if (widget.taskData != null && widget.taskData!['task_id'] != null) {
  allDetails['task_id'] = widget.taskData!['task_id'];
}

// Add make from task data
if (widget.taskData != null && widget.taskData!['make'] != null) {
  allDetails['make'] = widget.taskData!['make'];
}

// Add model from task data
if (widget.taskData != null && widget.taskData!['model'] != null) {
  allDetails['model'] = widget.taskData!['model'];
}
```

## 🔍 Debug Logs

When data is added:

```
Added vehicle_number from task: MH02DD9870
Added task_id from task: 20ef0336-e0f8-4223-bc1d-7338d0669db3
Added make from task: TATA
Added model from task: NEXON
```

## ⚠️ Fallback Values

If task data is missing:

```dart
task_id: widget.accidentId  // Falls back to accident_id
make: 'MAHINDRA & MAHINDRA'  // Default value
model: 'BOLERO'  // Default value
```

## ✅ Summary

**Fixed**:
1. ✅ `task_id` - Now uses actual task ID from task data
2. ✅ `make` - Now uses vehicle make from task data
3. ✅ `model` - Now uses vehicle model from task data

**Source**: All from `taskData` passed from TasksListScreen

**Fallback**: Default values if task data is missing

**Result**: API receives correct dynamic values instead of static data! 🎉
