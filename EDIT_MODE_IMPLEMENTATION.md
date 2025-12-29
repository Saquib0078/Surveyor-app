# Edit Mode Implementation - Preview Screen

## ✅ What's Been Done

### 1. **ClaimPreviewScreen** - Added Edit Buttons
- ✅ Updated `_buildSection()` to accept optional `onEdit` callback
- ✅ Added Edit icon button to section headers
- ✅ Added `_editDriverDetails()` method to navigate back to edit mode
- ✅ All driver detail sections now have Edit buttons:
  - Accident Snapshot
  - Driver Verification
  - Police & Third Party
  - Additional Information

### 2. **DriverDetailsScreen** - Added Edit Mode Parameters
- ✅ Added `isEditMode` boolean parameter
- ✅ Added `existingDetails` to pass current data
- ✅ Added `existingCarImages` to pass current images
- ✅ Added `existingDocumentImages` to pass current documents
- ✅ Added `existingRemarks` to pass current remarks

## 🔧 What Needs To Be Completed

### 1. **Pre-fill Data in Edit Mode** (DriverDetailsScreen)

Add this to `initState()`:

```dart
@override
void initState() {
  super.initState();
  _animationController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 400),
  );
  _animationController.forward();
  
  // ✅ PRE-FILL DATA IN EDIT MODE
  if (widget.isEditMode && widget.existingDetails != null) {
    _prefillExistingData();
  }
}

void _prefillExistingData() {
  final details = widget.existingDetails!;
  
  // Accident Snapshot
  _accidentDateTimeController.text = details['accident_datetime'] ?? '';
  _accidentLocationController.text = details['accident_location'] ?? '';
  _causeOfAccident = details['cause_of_accident'];
  _vehicleCurrentLocationController.text = details['vehicle_current_location'] ?? '';
  _damageBriefController.text = details['damage_brief_description'] ?? '';
  
  // Driver Verification
  _wasPolicyHolderDriving = details['was_policyholder_driving'];
  _driverNameController.text = details['driver_name'] ?? '';
  _licenseNumberController.text = details['license_number'] ?? '';
  _licenseExpiryController.text = details['license_expiry'] ?? '';
  _travellingSpeedController.text = details['travelling_speed']?.toString() ?? '';
  
  // Police & Third Party
  _policeInformed = details['police_informed'];
  _policeParticularsTaken = details['police_particulars_taken'];
  _firNumberController.text = details['fir_number'] ?? '';
  _policeStationController.text = details['police_station'] ?? '';
  _thirdPartyInvolved = details['third_party_involved'];
  _thirdPartyNameController.text = details['third_party_name'] ?? '';
  
  // Other Details
  _injuryOrDeath = details['injury_or_death'];
  if (details['injury_details'] != null) {
    _injuryDetails.addAll(List<Map<String, dynamic>>.from(details['injury_details']));
  }
  _independentWitnesses = details['independent_witnesses'];
  _witnessNameController.text = details['witness_name'] ?? '';
  _witnessContactController.text = details['witness_contact'] ?? '';
  
  // Garage Selection
  if (details.containsKey('garage_id')) {
    _garageType = 'network';
    // Load garage details if needed
  } else if (details.containsKey('non_network_garage')) {
    _garageType = 'non-network';
    final garage = details['non_network_garage'];
    _nonNetworkGarageNameController.text = garage['name'] ?? '';
    _nonNetworkGarageAddressController.text = garage['address'] ?? '';
    _nonNetworkGarageContactController.text = garage['contact'] ?? '';
    _nonNetworkGarageEmailController.text = garage['email'] ?? '';
  }
  
  // Images (if paths are stored)
  if (details['dl_image_path'] != null) {
    _dlImage = File(details['dl_image_path']);
  }
  if (details['fir_copy_image_path'] != null) {
    _firCopyImage = File(details['fir_copy_image_path']);
  }
}
```

### 2. **Update Navigation Logic** (DriverDetailsScreen)

Replace `_navigateToAccidentIntimation()` with:

```dart
void _navigateToAccidentIntimation() {
  Map<String, dynamic> allDetails = {
    'accident_datetime': _accidentDateTimeController.text,
    'accident_location': _accidentLocationController.text.trim(),
    'cause_of_accident': _causeOfAccident,
    'vehicle_current_location': _vehicleCurrentLocationController.text.trim(),
    'damage_brief_description': _damageBriefController.text.trim(),
    'was_policyholder_driving': _wasPolicyHolderDriving,
    'driver_name': _driverNameController.text.trim(),
    'license_number': _licenseNumberController.text.trim(),
    'license_expiry': _licenseExpiryController.text,
    'travelling_speed': _travellingSpeedController.text,
    'police_informed': _policeInformed,
    'police_particulars_taken': _policeParticularsTaken,
    'fir_number': _firNumberController.text.trim(),
    'police_station': _policeStationController.text.trim(),
    'third_party_involved': _thirdPartyInvolved,
    'third_party_name': _thirdPartyNameController.text.trim(),
    'fir_copy_image_path': _firCopyImage?.path,
    'dl_image_path': _dlImage?.path,
    'injury_or_death': _injuryOrDeath,
    'injury_details': _injuryDetails,
    'independent_witnesses': _independentWitnesses,
    'witness_name': _witnessNameController.text.trim(),
    'witness_contact': _witnessContactController.text.trim(),
  };

  // Add garage data
  if (_garageType == 'network' && _selectedGarage != null) {
    allDetails['garage_id'] = _selectedGarage!['id'];
  } else if (_garageType == 'non-network') {
    allDetails['non_network_garage'] = {
      'name': _nonNetworkGarageNameController.text.trim(),
      'address': _nonNetworkGarageAddressController.text.trim(),
      'contact': _nonNetworkGarageContactController.text.trim(),
      'email': _nonNetworkGarageEmailController.text.trim(),
    };
  }

  // ✅ IF IN EDIT MODE, GO BACK TO PREVIEW
  if (widget.isEditMode) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ClaimPreviewScreen(
          taskId: widget.taskId,
          accidentId: widget.accidentId,
          driverDetails: allDetails,
          carImages: widget.existingCarImages ?? {},
          documentImages: widget.existingDocumentImages ?? {},
          remarks: widget.existingRemarks ?? '',
          onSubmit: (signature) {
            // This will be handled by the preview screen
          },
        ),
      ),
    );
  } else {
    // ✅ NORMAL FLOW - GO TO ACCIDENT INTIMATION
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AccidentIntimationScreen(
          taskId: widget.taskId,
          accidentId: widget.accidentId,
          driverDetails: allDetails,
        ),
      ),
    );
  }
}
```

### 3. **Update UI for Edit Mode** (DriverDetailsScreen)

Update the action buttons to show "Back" and "Save" in edit mode:

```dart
Widget _buildActionButtons() {
  final isLastStep = _currentStep == 3;

  // ✅ IN EDIT MODE, SHOW DIFFERENT BUTTONS
  if (widget.isEditMode) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Go back to preview without saving
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ClaimPreviewScreen(
                    taskId: widget.taskId,
                    accidentId: widget.accidentId,
                    driverDetails: widget.existingDetails ?? {},
                    carImages: widget.existingCarImages ?? {},
                    documentImages: widget.existingDocumentImages ?? {},
                    remarks: widget.existingRemarks ?? '',
                    onSubmit: (signature) {},
                  ),
                ),
              );
            },
            icon: Icon(Icons.arrow_back, size: 18),
            label: Text('Back'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _navigateToAccidentIntimation, // This will save and go back
            icon: Icon(Icons.save, size: 18),
            label: Text(
              'Save Changes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ NORMAL MODE - SHOW STEPPER BUTTONS
  return Column(
    children: [
      Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: TextButton.icon(
          onPressed: _skipCurrentStep,
          icon: Icon(Icons.skip_next, size: 20),
          label: Text('Skip this step'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.orange.shade700,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            backgroundColor: Colors.orange.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _onStepCancel,
              icon: Icon(Icons.arrow_back, size: 18),
              label: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _onStepContinue,
              icon: Icon(isLastStep ? Icons.check : Icons.arrow_forward, size: 18),
              label: Text(
                isLastStep ? 'Continue to Images' : 'Next Step',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
```

### 4. **Update AppBar Title** (DriverDetailsScreen)

Show different title in edit mode:

```dart
appBar: AppBar(
  title: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.isEditMode ? 'Edit Details' : _getStepTitle(),  // ✅ Different title
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      if (!widget.isEditMode)  // ✅ Hide step indicator in edit mode
        Text(
          'Step ${_currentStep + 1} of 4 (All Optional)',
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
        ),
    ],
  ),
  backgroundColor: Colors.blue.shade700,
  elevation: 0,
  iconTheme: IconThemeData(color: Colors.white),
),
```

## 📋 User Flow

### Normal Flow (New Claim):
```
DriverDetailsScreen (Stepper) 
  → AccidentIntimationScreen (Images) 
  → ClaimPreviewScreen (Review) 
  → Submit
```

### Edit Flow (From Preview):
```
ClaimPreviewScreen 
  → Click "Edit" button 
  → DriverDetailsScreen (Edit Mode - Single Page)
  → Click "Save" 
  → ClaimPreviewScreen (Updated Data)
  → Submit
```

## 🎨 UI Differences

### Normal Mode:
- Shows stepper with 4 steps
- Shows "Skip", "Back", "Next" buttons
- Shows step progress indicator
- Title: "Accident Snapshot", "Driver Verification", etc.

### Edit Mode:
- Shows all fields on single scrollable page
- Shows only "Back" and "Save Changes" buttons
- No step progress indicator
- Title: "Edit Details"
- Pre-filled with existing data

## ✅ Benefits

1. **User-Friendly**: Easy to edit specific sections
2. **Data Preservation**: Back button keeps original data
3. **Clear Actions**: Save vs Back buttons are obvious
4. **Consistent Flow**: Returns to preview after save
5. **No Data Loss**: All existing data is preserved

## 🧪 Testing Checklist

- [ ] Fill driver details in normal flow
- [ ] Navigate to preview
- [ ] Click Edit on "Accident Snapshot"
- [ ] Verify data is pre-filled
- [ ] Modify some fields
- [ ] Click "Save Changes"
- [ ] Verify preview shows updated data
- [ ] Click Edit again
- [ ] Click "Back" without saving
- [ ] Verify preview shows original data
- [ ] Submit claim successfully

## 📝 Summary

The edit functionality allows users to:
1. ✅ Review all details in preview
2. ✅ Click Edit on any section
3. ✅ Modify data in edit mode
4. ✅ Save and return to preview OR
5. ✅ Cancel and keep original data
6. ✅ Submit when satisfied

All the foundation is in place - just need to implement the pre-fill logic and update the navigation/UI based on edit mode!
