# Document Keys in ZIP File - Final Implementation

## ✅ Updated ZIP File Structure

### Document Naming Convention
All documents in the ZIP file now use **standardized keys** with their file extensions:

```
images.zip
├── DRIVING_LICENSE.jpg          ← Driver's License (from DriverDetailsScreen)
├── FIR_COPY.jpg                 ← FIR Copy (from DriverDetailsScreen)
├── RC_BOOK.jpg                  ← RC Book (from AccidentIntimationScreen)
├── INSURANCE_POLICY.jpg         ← Insurance Policy
├── PAN_CARD.jpg                 ← PAN Card
├── AADHAR_CARD.jpg              ← Aadhar Card
├── POLICE_REPORT.jpg            ← Police Report
├── OTHER_DOCUMENT.jpg           ← Other Document
├── EXTRA_IMAGE_1.jpg            ← Vehicle Image 1
├── EXTRA_IMAGE_2.jpg            ← Vehicle Image 2
├── EXTRA_IMAGE_3.jpg            ← Vehicle Image 3
├── EXTRA_IMAGE_4.jpg            ← Vehicle Image 4
├── EXTRA_IMAGE_5.jpg            ← Vehicle Image 5
├── EXTRA_IMAGE_6.jpg            ← Vehicle Image 6
└── signature.png                ← Signature
```

## 📋 Document Type Keys

### Driver Details Documents
| Document | Key | Source |
|----------|-----|--------|
| Driver's License | `DRIVING_LICENSE` | DriverDetailsScreen |
| FIR Copy | `FIR_COPY` | DriverDetailsScreen |

### Accident Intimation Documents
| Document | Key | Source |
|----------|-----|--------|
| RC Book | `RC_BOOK` | AccidentIntimationScreen |
| Insurance Policy | `INSURANCE_POLICY` | AccidentIntimationScreen |
| PAN Card | `PAN_CARD` | AccidentIntimationScreen |
| Aadhar Card | `AADHAR_CARD` | AccidentIntimationScreen |
| Police Report | `POLICE_REPORT` | AccidentIntimationScreen |
| Other Document | `OTHER_DOCUMENT` | AccidentIntimationScreen |

### Vehicle Images
| Image | Key |
|-------|-----|
| Extra Image 1 | `EXTRA_IMAGE_1` |
| Extra Image 2 | `EXTRA_IMAGE_2` |
| Extra Image 3 | `EXTRA_IMAGE_3` |
| Extra Image 4 | `EXTRA_IMAGE_4` |
| Extra Image 5 | `EXTRA_IMAGE_5` |
| Extra Image 6 | `EXTRA_IMAGE_6` |

### Other Files
| File | Key |
|------|-----|
| Signature | `signature.png` |

## 🔧 Implementation Details

### Code Changes in `AccidentIntimationScreen.dart`

#### Before (with random filenames):
```dart
// ❌ OLD - Appended original filename
final fileName = 'DL_IMAGE_${path.basename(dlFile.path)}';
// Result: DL_IMAGE_image_picker_123456789.jpg

final fileName = '${docType}_${path.basename(file.path)}';
// Result: AADHAR_CARD_image_picker_987654321.jpg
```

#### After (with standardized keys):
```dart
// ✅ NEW - Use standardized key with extension
final extension = path.extension(dlFile.path);
final fileName = 'DRIVING_LICENSE$extension';
// Result: DRIVING_LICENSE.jpg

final extension = path.extension(file.path);
final fileName = '${docType}$extension';
// Result: AADHAR_CARD.jpg
```

### Updated ZIP Creation Logic

```dart
Future<File> _createZipFile() async {
  final encoder = ZipFileEncoder();
  encoder.create(zipFilePath);
  
  // ✅ FIR COPY
  if (widget.driverDetails?['fir_copy_image_path'] != null) {
    final firFile = File(widget.driverDetails!['fir_copy_image_path']);
    final extension = path.extension(firFile.path);
    final fileName = 'FIR_COPY$extension';  // ← Standardized key
    encoder.addFile(firFile, fileName);
  }
  
  // ✅ DRIVING LICENSE
  if (widget.driverDetails?['dl_image_path'] != null) {
    final dlFile = File(widget.driverDetails!['dl_image_path']);
    final extension = path.extension(dlFile.path);
    final fileName = 'DRIVING_LICENSE$extension';  // ← Standardized key
    encoder.addFile(dlFile, fileName);
  }
  
  // ✅ DOCUMENT IMAGES (RC_BOOK, AADHAR_CARD, PAN_CARD, etc.)
  for (var entry in _documentImages.entries) {
    final docType = entry.key;  // Already standardized: RC_BOOK, AADHAR_CARD, etc.
    final file = entry.value!;
    final extension = path.extension(file.path);
    final fileName = '${docType}$extension';  // ← Standardized key
    encoder.addFile(file, fileName);
  }
  
  // ✅ VEHICLE IMAGES (EXTRA_IMAGE_1, EXTRA_IMAGE_2, etc.)
  for (var entry in _carImages.entries) {
    final imageKey = entry.key;  // Already standardized: EXTRA_IMAGE_1, etc.
    final file = entry.value!;
    final extension = path.extension(file.path);
    final fileName = '${imageKey}$extension';  // ← Standardized key
    encoder.addFile(file, fileName);
  }
  
  // ✅ SIGNATURE
  if (_signatureBytes != null) {
    final signatureFile = File('${tempDir.path}/signature.png');
    await signatureFile.writeAsBytes(_signatureBytes!);
    encoder.addFile(signatureFile, 'signature.png');  // ← Fixed name
  }
  
  encoder.close();
  return File(zipFilePath);
}
```

## 📊 Example ZIP Contents

### Scenario 1: Full Submission
```
images.zip (2.5 MB)
├── DRIVING_LICENSE.jpg          (450 KB)
├── FIR_COPY.jpg                 (380 KB)
├── RC_BOOK.jpg                  (420 KB)
├── INSURANCE_POLICY.jpg         (390 KB)
├── AADHAR_CARD.jpg              (350 KB)
├── EXTRA_IMAGE_1.jpg            (200 KB)
├── EXTRA_IMAGE_2.jpg            (210 KB)
├── EXTRA_IMAGE_3.jpg            (195 KB)
└── signature.png                (15 KB)
```

### Scenario 2: Minimal Submission
```
images.zip (1.2 MB)
├── DRIVING_LICENSE.jpg          (450 KB)
├── RC_BOOK.jpg                  (420 KB)
├── EXTRA_IMAGE_1.jpg            (200 KB)
└── signature.png                (15 KB)
```

## ✅ Benefits

### 1. **Consistent Naming**
- No random filenames like `image_picker_123456789.jpg`
- Easy to identify document types
- Predictable file structure

### 2. **API Processing**
- API can easily extract specific documents by key
- No need to parse filenames
- Standardized across all submissions

### 3. **File Extension Preservation**
- Maintains original file extension (.jpg, .png, .pdf, etc.)
- Ensures compatibility with image viewers
- Preserves file format information

### 4. **Debugging**
- Easy to verify which documents are included
- Clear console logs showing exact filenames
- Simple to track missing documents

## 🧪 Testing

### Console Output Example
```
========== CREATING ZIP FILE ==========
Adding FIR copy to zip: FIR_COPY.jpg
Adding DL image to zip: DRIVING_LICENSE.jpg
Adding document to zip: RC_BOOK.jpg
Adding document to zip: AADHAR_CARD.jpg
Adding document to zip: PAN_CARD.jpg
Adding vehicle image to zip: EXTRA_IMAGE_1.jpg
Adding vehicle image to zip: EXTRA_IMAGE_2.jpg
Adding signature to zip: signature.png
Zip file created: /path/to/images_1234567890.zip
Total images added: 8
=======================================
```

### Verification Steps
1. ✅ Capture all required documents
2. ✅ Submit the claim
3. ✅ Check console logs for ZIP creation
4. ✅ Verify document keys in logs
5. ✅ Confirm API receives ZIP file
6. ✅ Extract ZIP to verify contents (optional)

## 📝 Summary

All documents in the ZIP file now use **standardized keys**:
- ✅ `DRIVING_LICENSE` (not `DL_IMAGE_...`)
- ✅ `AADHAR_CARD` (not `AADHAR_CARD_...`)
- ✅ `PAN_CARD` (not `PAN_CARD_...`)
- ✅ `RC_BOOK` (not `RC_BOOK_...`)
- ✅ And so on...

This ensures consistent, predictable naming that's easy for the API to process.
