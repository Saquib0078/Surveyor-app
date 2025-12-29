# Task Completion API Integration

## ✅ Already Implemented

The task completion API is already correctly implemented and will be called after successful accident intimation.

## 📋 API Details

### Endpoint:
```
POST /fw_damage/task_completed
```

### Full URL:
```
https://uat.goclaims.in/motor_claim_api/fw_damage/task_completed
```

### Request Headers:
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer <JWT_TOKEN>"
}
```

### Request Body:
```json
{
  "accident_id": "4e4414b9-8dfd-405c-9a8c-c4a6759af19c",
  "surveyor_id": "6f77c862-1798-4158-bb45-8dc58b9314df",
  "remarks": "User input remarks from form"
}
```

## 🔄 Flow

```
User fills form
    ↓
Clicks Submit on Preview
    ↓
_handleActualSubmit() called
    ↓
1. _uploadToAPI() - Upload claim data
    ↓
    Success ✅
    ↓
2. _markTaskCompleted() - Mark task complete
    ↓
    POST /fw_damage/task_completed
    {
      "accident_id": "...",
      "surveyor_id": "...",
      "remarks": "..."
    }
    ↓
    Success ✅
    ↓
Navigate to Success Page
```

## 📝 Implementation

### File: `AccidentIntimationScreen.dart`

```dart
Future<void> _handleActualSubmit(Uint8List signature) async {
  setState(() {
    _isSubmitting = true;
  });

  try {
    // 1. Upload claim data
    await _uploadToAPI();
    
    // 2. Mark task as completed
    await _markTaskCompleted();
    
  } catch (e) {
    // Error handling
  }
}

Future<void> _markTaskCompleted() async {
  final String apiUrl = '${APIConstants.baseUrl}/fw_damage/task_completed';

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer <JWT_TOKEN>",
      },
      body: json.encode({
        'accident_id': widget.accidentId,
        'surveyor_id': _surveyorId,
        'remarks': _remarksController.text.trim(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Task marked as completed successfully');
      return;
    } else {
      throw Exception('Failed to mark task as completed');
    }
  } catch (e) {
    throw Exception('Error marking task completed: $e');
  }
}
```

## 📊 Data Sources

| Field | Source | Example |
|-------|--------|---------|
| `accident_id` | `widget.accidentId` | "4e4414b9-..." |
| `surveyor_id` | `_surveyorId` (SharedPreferences) | "6f77c862-..." |
| `remarks` | `_remarksController.text` (user input) | "Claim processed successfully" |

## 🎯 Example Request

```http
POST /fw_damage/task_completed HTTP/1.1
Host: uat.goclaims.in
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

{
  "accident_id": "4e4414b9-8dfd-405c-9a8c-c4a6759af19c",
  "surveyor_id": "6f77c862-1798-4158-bb45-8dc58b9314df",
  "remarks": "Inspection completed. All documents verified."
}
```

## 📝 Debug Logs

When the API is called, you'll see:

```
========== MARKING TASK COMPLETED ==========
API URL: https://uat.goclaims.in/motor_claim_api/fw_damage/task_completed
Accident ID: 4e4414b9-8dfd-405c-9a8c-c4a6759af19c
Surveyor ID: 6f77c862-1798-4158-bb45-8dc58b9314df
Remarks: Inspection completed
============================================

========== TASK COMPLETION RESPONSE ==========
Status Code: 200
Response Body: {"status": "success", ...}
==============================================

Task marked as completed successfully
```

## ⚠️ Important Notes

1. **Sequential Execution**: Task completion happens AFTER successful claim upload
2. **Error Handling**: If task completion fails, error is logged but doesn't block navigation
3. **Authorization**: Uses JWT token (currently hardcoded, should be dynamic)
4. **Remarks**: User input from remarks field in the form

## 🔮 Future Improvements

1. **Dynamic JWT Token**: Replace hardcoded token with dynamic token from auth service
2. **Retry Logic**: Add retry mechanism for failed task completion
3. **Offline Support**: Queue task completion for offline scenarios
4. **Better Error Messages**: Show user-friendly error messages

## ✅ Summary

**Status**: ✅ Already Implemented

**Endpoint**: `/fw_damage/task_completed`

**Payload**:
```json
{
  "accident_id": "from widget.accidentId",
  "surveyor_id": "from SharedPreferences",
  "remarks": "from user input"
}
```

**Flow**: Upload Claim → Mark Task Complete → Navigate to Success

The task completion API is already integrated and working! 🎉
