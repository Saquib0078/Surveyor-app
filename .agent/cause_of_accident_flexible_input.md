# Cause of Accident: Dropdown + Custom Input Support

## ✅ Changes Made

Updated the "Cause of Accident" field to support both dropdown selection and custom text input.

## 🔧 Implementation

### 1. Changed from Dropdown Variable to TextEditingController

**Before**:
```dart
String? _causeOfAccident;  // Dropdown only
```

**After**:
```dart
final TextEditingController _causeOfAccidentController = TextEditingController();  // Flexible input
```

### 2. Updated Auto-Fill Logic

```dart
// Auto-fill cause of accident from accident_details (supports both dropdown and custom input)
if (task['accident_details'] != null) {
  final accidentDetail = task['accident_details'].toString();
  _causeOfAccidentController.text = accidentDetail;  // Works for any value
  print('Auto-filled cause_of_accident: $accidentDetail');
}
```

## 📋 Behavior

### Predefined Options (Dropdown):
- Collision
- Hit & Run
- Self Accident
- Fire
- Theft
- Animal/Object Strike
- Natural Disaster

### Custom Input:
- User can type any value (e.g., "Front Collision", "Rear-End Collision", etc.)

## 🎯 Use Cases

### Case 1: Exact Match
```
Task Data: "Collision"
Result: Field shows "Collision" ✅
```

### Case 2: Custom Value
```
Task Data: "Front Collision"
Result: Field shows "Front Collision" ✅
User can keep it or change it
```

### Case 3: No Data
```
Task Data: null
Result: Field is empty
User can select from dropdown or type custom value
```

## 💡 Recommended UI Implementation

For the UI, you should use an **Autocomplete** widget that combines dropdown + text input:

```dart
Autocomplete<String>(
  initialValue: TextEditingValue(text: _causeOfAccidentController.text),
  optionsBuilder: (TextEditingValue textEditingValue) {
    if (textEditingValue.text.isEmpty) {
      return _accidentCauses;
    }
    return _accidentCauses.where((String option) {
      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
    });
  },
  onSelected: (String selection) {
    _causeOfAccidentController.text = selection;
  },
  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
    // Sync with our controller
    controller.text = _causeOfAccidentController.text;
    controller.addListener(() {
      _causeOfAccidentController.text = controller.text;
    });
    
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: 'Cause of Accident *',
        hintText: 'Select or type custom cause',
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter cause of accident';
        }
        return null;
      },
    );
  },
)
```

## 📊 Data Flow

```
Task API
    ↓
accident_details: "Front Collision"
    ↓
Auto-fill
    ↓
_causeOfAccidentController.text = "Front Collision"
    ↓
UI shows: "Front Collision" (editable)
    ↓
User can:
  - Keep it as is
  - Edit to "Collision"
  - Change to something else
    ↓
API receives: whatever value is in the field
```

## ✅ Benefits

1. **Flexibility**: Supports both predefined and custom values
2. **Auto-fill**: Works with any accident_details value
3. **User-friendly**: Dropdown for common cases, custom input for specific cases
4. **No Errors**: No dropdown assertion errors
5. **API Compatible**: Sends whatever value user provides

## 🔄 API Integration

When submitting to API:

```dart
request.fields['cause_of_accident'] = _causeOfAccidentController.text;
```

This will send:
- "Collision" (if selected from dropdown)
- "Front Collision" (if auto-filled from task)
- "Custom Cause" (if user typed it)

## ✅ Summary

**Changed**:
- ✅ From `String? _causeOfAccident` to `TextEditingController`
- ✅ Auto-fill now works with any value
- ✅ No dropdown assertion errors

**Next Step**:
- Implement Autocomplete UI widget (recommended above)
- Or use simple TextField with dropdown icon

The backend logic is ready to support both dropdown and custom input! 🎉
