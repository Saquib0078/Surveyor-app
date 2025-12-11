# Document Validation Implementation

## Overview
Implemented automatic document validation for the Accident Intimation screen using the KYC Vision API with ML Kit as a fallback mechanism.

## Features Implemented

### 1. **Primary Validation - KYC Vision API**
- Uploads captured document to `https://iassistlabs.com/kyc-vision/predict`
- Receives prediction and confidence score
- Validates if document type matches expected type
- Confidence threshold: **85%**

### 2. **Fallback Validation - ML Kit Image Labeling**
- Activates when API fails or times out
- Uses Google ML Kit for local document detection
- Checks if image contains document-like features

### 3. **User Confirmation Flow**
When validation is uncertain:
- Shows dialog with validation details
- Displays confidence score if available
- Offers two options:
  - **Retake**: Capture document again
  - **Continue Anyway**: Proceed with current document

## Validation Flow

```
Document Captured
    ↓
Show "Validating..." Dialog
    ↓
Call KYC Vision API
    ↓
┌─────────────────────────────────┐
│  API Response Analysis          │
├─────────────────────────────────┤
│ ✓ High Confidence (≥85%)        │ → Accept Document
│   & Type Match                  │
├─────────────────────────────────┤
│ ⚠ Low Confidence (<85%)         │ → Ask User
├─────────────────────────────────┤
│ ✗ Type Mismatch                 │ → Show Error + Ask User
├─────────────────────────────────┤
│ ✗ API Failed/Timeout            │ → Use ML Kit Fallback
└─────────────────────────────────┘
    ↓
ML Kit Fallback (if needed)
    ↓
┌─────────────────────────────────┐
│  Local Validation               │
├─────────────────────────────────┤
│ ✓ Document Detected             │ → Accept Document
│                                 │
│ ✗ Not Detected                  │ → Ask User
└─────────────────────────────────┘
```

## Supported Document Types

The system validates the following document types:
1. **RC_BOOK** - Registration Certificate
2. **DRIVING_LICENSE** - Driving License
3. **INSURANCE_POLICY** - Insurance Policy
4. **PAN_CARD** - PAN Card
5. **AADHAR_CARD** - Aadhaar Card (front/back)
6. **FIR_COPY** - FIR Copy
7. **POLICE_REPORT** - Police Report
8. **OTHER_DOCUMENT** - Other Documents

## Document Type Matching

The system intelligently matches document types with variations:
- **Aadhaar**: Matches "aadhar", "aadhaar", "aadhar_front", "aadhar_back"
- **PAN**: Matches "pan", "pancard"
- **Driving License**: Matches "dl", "license", "driving_license"
- **RC Book**: Matches "rc", "rcbook", "registration"

## API Response Format

### Success Response
```json
{
    "results": [
        {
            "1": {
                "confidence": 0.9999959468841553,
                "prediction": "aadhar_back"
            }
        }
    ]
}
```

### Validation Result
```dart
{
  'success': true,
  'validated': true,
  'prediction': 'aadhar_back',
  'confidence': 0.9999959468841553,
  'message': 'Document validated successfully'
}
```

## User Experience

### 1. **High Confidence Match**
- ✅ Green snackbar: "Document validated successfully"
- Document automatically added

### 2. **Low Confidence**
- ⚠️ Orange warning dialog
- Shows confidence percentage
- User can retake or continue

### 3. **Type Mismatch**
- ⚠️ Warning dialog with mismatch details
- Example: "Expected: Aadhaar Card, Got: PAN Card"
- User can retake or continue anyway

### 4. **API Failure**
- Shows "Using local validation..." message
- Attempts ML Kit validation
- Falls back to user confirmation if needed

### 5. **Complete Failure**
- Shows confirmation dialog
- User decides whether to proceed
- Prevents blocking the workflow

## Files Modified

1. **`pubspec.yaml`**
   - Added `google_mlkit_image_labeling: ^0.12.0`

2. **`lib/services/DocumentValidationService.dart`** (NEW)
   - API validation logic
   - Local validation fallback
   - Document type matching

3. **`lib/AccidentIntimationScreen.dart`**
   - Integrated validation into capture flow
   - Added validation dialogs
   - User confirmation handling

## Configuration

### Confidence Threshold
Located in `DocumentValidationService.dart`:
```dart
static const double confidenceThreshold = 0.85;
```

### API Timeout
```dart
var response = await request.send().timeout(
  const Duration(seconds: 30),
);
```

## Testing Checklist

- [ ] Capture valid Aadhaar card → Should validate automatically
- [ ] Capture PAN card when expecting Aadhaar → Should show mismatch warning
- [ ] Capture blurry document → Should show low confidence warning
- [ ] Test with API offline → Should use ML Kit fallback
- [ ] Test "Retake" button → Should allow recapture
- [ ] Test "Continue Anyway" → Should accept document
- [ ] Verify all 8 document types work correctly

## Logs

The implementation includes detailed logging:
```
========== DOCUMENT VALIDATION START ==========
Expected Document Type: AADHAR_CARD
Image Path: /path/to/image.jpg
Sending request to API...
Response Status Code: 200
Prediction: aadhar_back
Confidence: 0.9999959468841553
Document Match: true
========== VALIDATION SUCCESS ==========
```

## Future Enhancements

1. **Cache API responses** to avoid re-validation
2. **Add document quality checks** (blur detection, lighting)
3. **Support multiple languages** for document types
4. **Add document cropping** before validation
5. **Store validation metadata** with the document
