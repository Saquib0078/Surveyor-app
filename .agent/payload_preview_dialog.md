# Payload Preview Dialog

## ✅ Feature Added

Added a payload preview dialog that shows all request data before submission to the API.

## 🎯 Purpose

Allows you to review the complete payload before sending to the API to ensure no garbage data is sent.

## 📋 Dialog Contents

### 1. Request Fields
Shows all form fields being sent:
- `task_id`
- `suv_id`
- `vehicle_number`
- `accident_reference_id`
- `surveyor_details` (JSON)
- `garage_id` or `non_network_garages`
- All other fields

### 2. Files to Upload
Shows files being uploaded:
- `images.zip` (with count of documents and vehicle images)

## 🎨 Dialog UI

```
┌─────────────────────────────────────┐
│ 🔍 Review Payload                   │
├─────────────────────────────────────┤
│ Please review the data before       │
│ submission:                          │
│                                      │
│ Request Fields:                      │
│ ┌─────────────────────────────────┐ │
│ │ task_id: MH02DD9870             │ │
│ │ suv_id: 6f77c862-...            │ │
│ │ vehicle_number: MH02DD9870      │ │
│ │ accident_reference_id: 4e44...  │ │
│ │ surveyor_details: {"accident... │ │
│ │ garage_id: 1                    │ │
│ │ ...                             │ │
│ └─────────────────────────────────┘ │
│                                      │
│ Files to Upload:                     │
│ ┌─────────────────────────────────┐ │
│ │ 📎 images.zip (5 documents,     │ │
│ │    6 vehicle images)            │ │
│ └─────────────────────────────────┘ │
│                                      │
│         [Cancel]  [Submit to API]    │
└─────────────────────────────────────┘
```

## 🔄 Flow

```
User clicks Submit on Preview Screen
    ↓
_handleActualSubmit() called
    ↓
_uploadToAPI() starts
    ↓
Prepare request fields
    ↓
Create zip file (if images exist)
    ↓
Show Payload Preview Dialog ✅ NEW
    ↓
User Reviews:
├─ All request fields
├─ Files to upload
└─ Can verify data is correct
    ↓
User Choice:
├─ Click "Cancel" → Return without submitting
└─ Click "Submit to API" → Proceed with submission
    ↓
If confirmed:
    ↓
Send request to API
    ↓
Mark task completed
    ↓
Navigate to success page
```

## 📝 Example Payload Display

### Request Fields:
```
task_id: MH02DD9870
suv_id: 6f77c862-1798-4158-bb45-8dc58b9314df
location: Mumbai
status: Survey Completed
make: MAHINDRA & MAHINDRA
model: BOLERO
body_type: four_wheeler
vehicle_number: MH02DD9870
accident_reference_id: 4e4414b9-8dfd-405c-9a8c-c4a6759af19c
garage_id: 1
surveyor_details: {"accident_datetime":"2025-12-23 10:54","accident_location":"Akola",...}
remarks: Inspection completed successfully
```

### Files:
```
📎 images.zip (3 documents, 6 vehicle images)
```

## 💡 Features

### 1. Long Text Truncation
- If a field value is > 100 characters, it shows first 100 chars + "..."
- Prevents dialog from being too large
- Full data is still sent to API

### 2. Scrollable Content
- Dialog content is scrollable
- Max height: 500px
- Can review all fields even if many

### 3. Non-Dismissible
- Can't dismiss by tapping outside
- Must click Cancel or Submit
- Ensures user makes conscious choice

### 4. Clear Actions
- **Cancel**: Stops submission, returns to preview
- **Submit to API**: Proceeds with API call

## 🎯 Benefits

1. ✅ **Verify Data**: See exactly what's being sent
2. ✅ **Catch Errors**: Spot incorrect data before submission
3. ✅ **No Garbage**: Ensure clean data goes to API
4. ✅ **Confidence**: Know what you're submitting
5. ✅ **Debug**: Easy to see payload structure

## 📊 Example Scenarios

### Scenario 1: Network Garage
```
garage_id: 1
vehicle_number: MH02DD9870
accident_location: Akola
```
✅ Looks good → Submit

### Scenario 2: Missing Data
```
garage_id: null
vehicle_number: 
accident_location: 
```
❌ Data missing → Cancel and fix

### Scenario 3: Wrong Garage
```
garage_id: 999
```
❌ Wrong garage selected → Cancel and reselect

## ⚠️ Important Notes

1. **Blocking**: User must respond to dialog
2. **Cancel Safe**: Cancelling doesn't lose data, can fix and retry
3. **Full Payload**: Shows ALL fields being sent
4. **File Summary**: Shows file count, not individual files in zip

## ✅ Summary

**Added**: Payload preview dialog before API submission

**Shows**:
- All request fields
- Files to upload
- Allows cancel or confirm

**Purpose**: Prevent garbage data from being sent to API

**Result**: User can review and verify payload before submission! 🎉
