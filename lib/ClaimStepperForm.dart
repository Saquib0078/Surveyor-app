// import 'dart:convert';
// import 'dart:io';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:damagedetection1/AvailableClaims.dart';
// import 'package:damagedetection1/GoogleMapScreen.dart';
// import 'package:damagedetection1/ImageUploadPreview.dart';
// import 'package:damagedetection1/selfinspection.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'ClaimOverview.dart';
// import 'ClaimStatus.dart';
// import 'FirestoreService.dart';
// import 'FormPreview.dart';
// import 'form_sections.dart';
// import 'helpers/APIConstants.dart';
//
// class ClaimFormStepper extends StatefulWidget {
//   @override
//   _ClaimFormStepperState createState() => _ClaimFormStepperState();
// }
//
// class _ClaimFormStepperState extends State<ClaimFormStepper> {
//   final FirestoreService _firestoreService = FirestoreService();
//
//   // String? userId = FirebaseAuth.instance.currentUser?.uid;
//   String? userId = "TPAEuGVudySSi8dWgNKePq5behp1";
//   String? formId;
//   late ClaimStatus _claimStatus;
//   bool _previewScrolled = false;
//   Position? _currentPosition;
//   String? _address;
//   late String locationString;
//   List<String> selfInspectionImages = [];
//   bool _isLoading = true;
//   int _currentStep = 0;
//   bool _agreeToTerms = false;
//   final ScrollController _scrollController = ScrollController();
//   late Map<String, Map<String, dynamic>> _formData = {};
//   List<Map<String, dynamic>> selfInspectionData = [];
//   var claimMap;
//   List<String> _dynamicImagePaths = [];
//
//   // New Variables for Radio Button Selection
//   String _driveBySelection = 'Drive by Me';
//   Map<String, dynamic>? claim;
//   late String claimId;
//   bool _isSubmitting = false;
//   var _isFetchingLocation = false;
//   var _locationFetched = false;
//
//   @override
//   void initState() {
//     super.initState();
//     var arguments = Get.arguments;
//     _claimStatus = ClaimStatus();
//     _loadClaimStatus();
//     if (arguments is Map<String, dynamic>) {
//       claimMap = arguments['claim'] as Map<String, dynamic>;
//       print(claimMap);
//       claimId = claimMap['claimId'] ?? 'No Claim ID';
//       var reg = claimMap['dor'] ?? 'No date_of_registration';
//       print(reg);
//       print('Claim ID: $claimId');
//       // User? user = FirebaseAuth.instance.currentUser;
//       //
//       // if (user != null) {
//       //   String? phoneNumber = user.phoneNumber;
//       //   print("User's phone number: $phoneNumber");
//       //
//       //   // Use the phone number as needed
//       // } else {
//       //   print("No user is currently signed in.");
//       // }
//     } else {
//       print('Arguments are not in the expected format.');
//     }
//     _initializeFormData();
//     _listenToFirestoreUpdates();
//     // _loadFormData();
//   }
//
//   Future<void> _loadClaimStatus() async {
//     DocumentSnapshot<Map<String, dynamic>> snapshot =
//         await _firestoreService.getClaimStatus(userId!, formId!);
//     if (snapshot.exists && snapshot.data() != null) {
//       setState(() {
//         _claimStatus = ClaimStatus.fromMap(snapshot.data()!);
//       });
//     }
//   }
//
//   Future<void> uploadImages(List<String> imagePaths) async {
//     final url = Uri.parse('http://164.52.202.251/fw_damage/create_fw_claim');
//     final headers = {
//       'Authorization': 'Bearer hii'
//     }; // Replace with the actual token if needed
//
//     final files = <http.MultipartFile>[];
//     for (final imagePath in imagePaths) {
//       final file = await http.MultipartFile.fromPath('images[]', imagePath);
//       files.add(file);
//     }
//
//     final request = http.MultipartRequest('POST', url)
//       ..headers.addAll(headers)
//       ..files.addAll(files);
//
//     final response = await request.send();
//     if (response.statusCode == 200) {
//       print('Images uploaded successfully');
//     } else {
//       print('Failed to upload images. Status code: ${response.statusCode}');
//     }
//   }
//
//   final Map<String, String> staticImagePaths = {
//   'frontSide': 'assets/IMG_20240710_162627_DRO.jpg',
//   'frontRightHandSide': 'assets/IMG_20240710_162650_DRO.jpg',
//   'driverSide': 'assets/IMG_20240710_162728_DRO.jpg',
//   'rearRightHandSide': 'assets/TimePhoto_20240528_140150.jpg',
//   'rearSide': 'assets/TimePhoto_20240528_140155.jpg',
//   'rearLeftHandSide': 'assets/TimePhoto_20240528_140202.jpg',
//   'passengerSide': 'assets/TimePhoto_20240528_140210.jpg',
//   'frontLeftHandSide': 'assets/TimePhoto_20240713_181337.jpg',
//   'engineCompart': 'assets/TimePhoto_20240713_181400.jpg',
//   'chassisNo': 'assets/TimePhoto_20240713_181406.jpg',
//   'odometerCar': 'assets/TimePhoto_20240713_181526.jpg',
//   };
//
//   void _updateDynamicImagePaths(List<String> paths) {
//   setState(() {
//   _dynamicImagePaths = paths;
//   });
//   _printAllPaths();
//   }
//
//   void _printAllPaths() {
//   print('Static Image Paths:');
//   staticImagePaths.forEach((key, value) {
//   print('$key: $value');
//   });
//
//   print('\nDynamic Image Paths:');
//   for (int i = 0; i < _dynamicImagePaths.length; i++) {
//   print('Dynamic Image ${i + 1}: ${_dynamicImagePaths[i]}');
//   }
//   }
//
//   void _updateClaimStatus(String refId) {
//     bool isPartiallyFilled = _formData.values
//         .any((section) => section.values.any((value) => value != null));
//
//     _claimStatus.overallStatus = isPartiallyFilled ? 'Processing' : 'Initiated';
//
//     _claimStatus.accidentDetailsCompleted =
//         _isSectionComplete('Accident Details');
//     _claimStatus.garageDetailsCompleted = _isSectionComplete('Garage Details');
//     _claimStatus.driverDetailsCompleted = _isSectionComplete('Driver Details');
//
//     _firestoreService.saveClaimStatus(userId!, formId!, _claimStatus.toMap());
//   }
//
//   bool _isSectionComplete(String sectionName) {
//     return _formData[sectionName]?.values.every((value) => value != null) ??
//         false;
//   }
//
//   Future<void> _initializeFormData() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     for (var section in formSections) {
//       String sectionTitle = section.keys.first;
//       _formData[sectionTitle] = {};
//       for (var field in section.values.first) {
//         String fieldName = field is Map ? field['field'] : field;
//         _formData[sectionTitle]![fieldName] = null;
//       }
//     }
//
//     formId = claimId;
//
//     await _loadFormData();
//     _populateFormDataFromClaim();
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   void _populateFormDataFromClaim() {
//     print("loaded");
//     if (claimMap != null) {
//       // Populate Insured Details
//       _formData['Insured Details']?['Name'] = claimMap?['claimName'];
//       _formData['Insured Details']?['Policy / Cover Note No'] =
//           claimMap?['claimId'];
//       _formData['Insured Details']?['Permanent Address'] =
//           claimMap?['permanent_address_line1'];
//       _formData['Insured Details']?['City'] = claimMap?['city'];
//       _formData['Insured Details']?['State'] = claimMap?['state'];
//       _formData['Insured Details']?['Pin Code'] = claimMap?['pincode'];
//       _formData['Insured Details']?['Mobile No'] = claimMap?['mobile'];
//       _formData['Insured Details']?['Email ID'] = claimMap?['email'];
//       _formData['Insured Details']?['Gender'] = claimMap?['gender'];
//       // _formData['Insured Details']?['Date of Birth'] = claimMap?['dob'];
//       _formData['Insured Details']?['Communication Address (if different)'] =
//           claimMap?['Caddress'];
//       // _formData['Insured Details']?['Gender'] = claimMap?['gender'];
//       if (claimMap?['dob'] is Timestamp) {
//         Timestamp? dateOfBirthTimestamp = claimMap?['dob'];
//         if (dateOfBirthTimestamp != null) {
//           DateTime dateOfBirth = dateOfBirthTimestamp.toDate();
//           _formData['Insured Details']?['Date of Birth'] =
//               _formatDateForIndia(dateOfBirth);
//         }
//       }
//       // Populate Vehicle Details
//       _formData['Vehicle Details']?['Registration Number'] =
//           claimMap?['vehicle_rno'];
//       _formData['Vehicle Details']?['Engine Number'] = claimMap?['engineNo'];
//       _formData['Vehicle Details']?['Chassis Number'] = claimMap?['chassisNo'];
//       _formData['Vehicle Details']?['Make of Vehicle'] =
//           claimMap?['vehiclemake'];
//       _formData['Vehicle Details']?['Model'] = claimMap?['model'];
//       _formData['Vehicle Details']?['Odometer Reading'] =
//           claimMap?['odometer_reading']?.toString();
//
//       // Handle date fields
//       if (claimMap?['dor'] is Timestamp) {
//         Timestamp? dateOfRegistrationTimestamp = claimMap?['dor'];
//         if (dateOfRegistrationTimestamp != null) {
//           DateTime dateOfRegistration = dateOfRegistrationTimestamp.toDate();
//           _formData['Vehicle Details']?['Date of Registration'] =
//               _formatDateForIndia(dateOfRegistration);
//         }
//       }
//
//       // You can add more fields as needed
//
//       // After populating, update the form data in Firestore
//       _firestoreService.saveFormData(userId!, formId!, _formData).then((_) {
//         print('Prepopulated data saved successfully to Firebase');
//       }).catchError((error) {
//         print('Failed to save prepopulated data: $error');
//       });
//     }
//   }
//
//
//   Future<void> captureImages() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.camera);
//
//     if (pickedFile != null) {
//       setState(() {
//         _dynamicImagePaths.add(pickedFile.path);  // Add captured image path
//       });
//     } else {
//       print('No image selected.');
//     }
//   }
//
//   void _updateFormField(String section, String field, dynamic value) {
//     print('Updating $section - $field: $value');
//     _updateClaimStatus("");
//
//     setState(() {
//       if (value is DateTime) {
//         _formData[section]![field] = _formatDateForIndia(value);
//       } else if (value is TimeOfDay) {
//         _formData[section]![field] = _formatTimeForIndia(value);
//       } else {
//         _formData[section]![field] = value;
//       }
//     });
//     _firestoreService.saveFormData(userId!, formId!, _formData).then((_) {
//       print('Data saved successfully to Firebase');
//     }).catchError((error) {
//       print('Failed to save data: $error');
//     });
//   }
//
//   String _formatDateForIndia(DateTime date) {
//     final indianFormat = DateFormat('dd-MM-yyyy');
//     return indianFormat.format(date);
//   }
//
//   String _formatTimeForIndia(TimeOfDay time) {
//     final now = DateTime.now();
//     final dateTime =
//         DateTime(now.year, now.month, now.day, time.hour, time.minute);
//     return DateFormat('HH:mm').format(dateTime);
//   }
//
//   Map<String, Map<String, dynamic>> processFormData(Map<String, Map<String, dynamic>> originalData) {
//     Map<String, Map<String, dynamic>> updatedData = {};
//
//     originalData.forEach((section, fields) {
//       // Check for Driver Details section specifically
//       if (section == 'Driver Details') {
//         if (fields.containsKey('Driving License Number') && fields['Driving License Number'] == null) {
//           fields['Driving License Number'] = fields['Driver License Number']; // Fix key mismatch
//           fields.remove('Driver License Number'); // Remove duplicate
//         }
//         if (fields.containsKey('License Date of Expiry') && fields['License Date of Expiry'] == null) {
//           fields['License Date of Expiry'] = fields['License Expiry Date']; // Fix key mismatch
//           fields.remove('License Expiry Date'); // Remove duplicate
//         }
//       }
//       updatedData[section] = fields;
//     });
//
//     return updatedData;
//   }
//
//
//   void _listenToFirestoreUpdates() {
//     _firestoreService.streamFormData(userId!, formId!).listen((snapshot) {
//       if (snapshot.exists) {
//         setState(() {
//           _formData = Map<String, Map<String, dynamic>>.from(
//               snapshot.data() as Map<String, dynamic>);
//         });
//         print('Form data updated from Firestore: $_formData');
//       }
//     });
//   }
//
//   List<Map<String, Object>> _getSteps() {
//     List<Map<String, Object>> steps = formSections.asMap().entries.map((entry) {
//       int idx = entry.key;
//       Map<String, List<dynamic>> section = entry.value;
//       String title = section.keys.first;
//       return {
//         'title': title,
//         'fields': section.values.first,
//         'index': idx,
//       };
//     }).toList();
//
//     steps.insert(5, {
//       'title': 'Self Inspection',
//       'isSelfInspection': true,
//       'index': 5,
//     });
//
//     steps.add({
//       'title': 'Declaration',
//       'isDeclaration': true,
//       'index': steps.length,
//     });
//     return steps;
//   }
//
//
//
//   Future<String> uploadImageToFirebase(
//       String imagePath, String fileName) async {
//     final storageRef = FirebaseStorage.instance.ref();
//     final fileRef = storageRef.child('images/$fileName');
//
//     final uploadTask = fileRef.putFile(File(imagePath));
//     final snapshot = await uploadTask.whenComplete(() {});
//     final downloadUrl = await snapshot.ref.getDownloadURL();
//
//     return downloadUrl;
//   }
//
//   Widget _buildStepContent(Map<String, Object> step) {
//     if (step['isSelfInspection'] == true) {
//       return SizedBox(
//         height: MediaQuery.of(context).size.height - 200,
//         child: ImageUploadPreview(
//           onImagesSelected: (List<String> paths) {
//             setState(() {
//               _dynamicImagePaths = paths;
//               print(paths);
//             });
//           },
//         ),
//       );
//     } else if (step['isDeclaration'] == true) {
//       return _buildDeclarationSection();
//     } else if (step['title'] == 'Driver Details') {
//       return _buildDriverDetailsSection();
//     } else {
//       String sectionTitle = step['title'] as String;
//       return Column(
//         children: ((step['fields'] as List<dynamic>?) ?? []).map((field) {
//           String fieldName = field is Map<String, dynamic>
//               ? field['field'] as String
//               : field.toString();
//           String fieldType =
//               field is Map<String, dynamic> ? field['type'] as String : 'text';
//
//           switch (fieldType) {
//             case 'boolean':
//               return CheckboxListTile(
//                 title: Text(fieldName),
//                 value: _formData[sectionTitle]![fieldName] ?? false,
//                 onChanged: (bool? value) {
//                   setState(() {
//                     _formData[sectionTitle]![fieldName] = value;
//                     print('Updated $fieldName in $sectionTitle to $value');
//                   });
//                 },
//               );
//             case 'date':
//               return buildDateField(sectionTitle, fieldName);
//             case 'time':
//               return _buildTimeField(sectionTitle, fieldName);
//             case 'button':
//               return _buildField(sectionTitle, fieldName, fieldType);
//             case 'location':
//               return _buildField(sectionTitle, fieldName, fieldType);
//             default:
//               return _buildTextField(sectionTitle, fieldName, fieldType);
//           }
//         }).toList(),
//       );
//     }
//   }
//
//   String _selectedLocation = 'current'; // Default selection
//   bool _locationTaken = false; // Track if the location has been taken
//
//   Widget _buildField(String sectionTitle, String fieldName, String fieldType) {
//     switch (fieldType) {
//       case 'button':
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: ElevatedButton(
//             onPressed: () {
//               // Implement button action here
//             },
//             style: ElevatedButton.styleFrom(
//               foregroundColor: Colors.white,
//               backgroundColor: Colors.blue, // Text color
//               padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12.0),
//               ),
//             ),
//             child: Text('Action Button'), // Customize button text as needed
//           ),
//         );
//       case 'location':
//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setState) {
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Radio<String>(
//                       value: 'current',
//                       groupValue: _selectedLocation,
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedLocation = value!;
//                         });
//                       },
//                     ),
//                     Text('Select Your Current Location'),
//                   ],
//                 ),
//                 Row(
//                   children: [
//                     Radio<String>(
//                       value: 'accident',
//                       groupValue: _selectedLocation,
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedLocation = value!;
//                         });
//                       },
//                     ),
//                     Text('Select Accident Location on Map'),
//                   ],
//                 ),
//                 if (_selectedLocation == 'current')
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 8.0),
//                     child: ElevatedButton(
//                       onPressed: _locationTaken
//                           ? null
//                           : () async {
//                               setState(() {
//                                 _isFetchingLocation = true; // Start loader
//                               });
//                               await _getCurrentLocation(setState);
//                               setState(() {
//                                 _isFetchingLocation = false; // Stop loader
//                                 _locationFetched = true; // Location fetched
//                                 _locationTaken = true; // Mark location as taken
//                               });
//                             },
//                       style: ElevatedButton.styleFrom(
//                         foregroundColor: Colors.white,
//                         backgroundColor: _locationTaken
//                             ? Colors.grey
//                             : Colors
//                                 .blue, // Change to grey if location is taken
//                         padding: EdgeInsets.symmetric(
//                             vertical: 14.0, horizontal: 16.0),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12.0),
//                         ),
//                       ),
//                       child: _isFetchingLocation
//                           ? CircularProgressIndicator(
//                               valueColor:
//                                   AlwaysStoppedAnimation<Color>(Colors.white),
//                             )
//                           : Text(_locationFetched
//                               ? 'Live Location Taken'
//                               : 'Select Your Live Location'),
//                     ),
//                   )
//                 else
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 8.0),
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Get.to(() => GoogleMapScreen(
//                           onLocationSelected: (LatLng selectedLocation, bool confirmed) {
//                             if (confirmed) {
//                               _updateFormField('Accident Details', 'Exact Location of Accident', [
//                                 selectedLocation.latitude.toStringAsFixed(6),
//                                 selectedLocation.longitude.toStringAsFixed(6),
//                               ]);
//                               print("Selected Location: ${selectedLocation.latitude}, ${selectedLocation.longitude}");
//                               // You can also update your form data with the selected location here
//                             }
//                           },
//                         ));
//
//                         // Implement different button action for accident location here
//                       },
//                       style: ElevatedButton.styleFrom(
//                         foregroundColor: Colors.white,
//                         backgroundColor: Colors.red,
//                         // Different color for accident location
//                         padding: EdgeInsets.symmetric(
//                             vertical: 14.0, horizontal: 16.0),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12.0),
//                         ),
//                       ),
//                       child: Text('Select Accident Location on Map'),
//                     ),
//                   ),
//               ],
//             );
//           },
//         );
//       default:
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: TextFormField(
//             key: Key('${sectionTitle}_$fieldName'),
//             decoration: InputDecoration(
//               labelText: fieldName,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12.0),
//                 borderSide: BorderSide(color: Colors.grey.shade400),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12.0),
//                 borderSide: BorderSide(color: Color(0xFF1A237E)),
//               ),
//               contentPadding:
//                   EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
//               filled: true,
//               fillColor: Colors.white,
//               hintStyle: TextStyle(color: Colors.grey.shade600),
//             ),
//             initialValue: _formData[sectionTitle]![fieldName]?.toString(),
//             onChanged: (value) {
//               _updateFormField(sectionTitle, fieldName, value);
//             },
//             keyboardType: _getKeyboardType(fieldType),
//             validator: _getValidator(fieldType),
//           ),
//         );
//     }
//   }
//
//   Future<void> _getCurrentLocation(StateSetter setState) async {
//     try {
//       // Request location permissions and get the current position
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//
//       setState(() {
//         _currentPosition = position;
//       });
//
//       // Get address from coordinates
//       await _getAddressFromLatLng(setState);
//
//       // Update the form field with location data
//       _updateFormField('Accident Details', 'Exact Location of Accident', [
//         _currentPosition!.latitude.toStringAsFixed(6),
//         _currentPosition!.longitude.toStringAsFixed(6),
//       ]);
//     } catch (e) {
//       print('Error getting location: $e');
//     }
//   }
//
//   Future<void> _getAddressFromLatLng(StateSetter setState) async {
//     if (_currentPosition != null) {
//       try {
//         List<Placemark> placemarks = await placemarkFromCoordinates(
//           _currentPosition!.latitude,
//           _currentPosition!.longitude,
//         );
//         if (placemarks.isNotEmpty) {
//           final Placemark place = placemarks[0];
//           setState(() {
//             _address =
//                 '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
//           });
//         }
//       } catch (e) {
//         print('Error occurred while getting the address: $e');
//       }
//     }
//   }
//
//   var _buttonState = false;
//
//   void _onLocationSelected(LatLng location, bool confirmed) {
//     if (confirmed) {
//       setState(() {
//         _buttonState = true; // Update your button state here
//       });
//     }
//   }
//
//   Widget _buildDriverDetailsSection() {
//     return Column(
//       children: [
//         // Radio Buttons for "Drive by Me" and "Drive by Other"
//         ListTile(
//           title: const Text('Driven by Me'),
//           leading: Radio<String>(
//             value: 'Drive by Me',
//             groupValue: _driveBySelection,
//             onChanged: (String? value) {
//               setState(() {
//                 _driveBySelection = value!;
//               });
//             },
//           ),
//         ),
//         ListTile(
//           title: const Text('Driven by Other'),
//           leading: Radio<String>(
//             value: 'Drive by Other',
//             groupValue: _driveBySelection,
//             onChanged: (String? value) {
//               setState(() {
//                 _driveBySelection = value!;
//               });
//             },
//           ),
//         ),
//
//         // Conditional Form Section based on Radio Button Selection
//         if (_driveBySelection == 'Drive by Other')
//           Column(
//             children: [
//               _buildTextField('Driver Details', 'Driver Name', 'text'),
//               _buildTextField(
//                   'Driver Details', 'Driver License Number', 'text'),
//               buildDateField('Driver Details', 'License Expiry Date'),
//               _buildTextField(
//                   'Driver Details', 'License Issuing Authority', 'text'),
//               _buildTextField(
//                   'Driver Details', 'License for Type of Vehicle', 'text'),
//               _buildTextField(
//                   'Driver Details', 'Was the license temporary?', 'text'),
//               _buildTextField(
//                   'Driver Details', 'Relation with Insured', 'text'),
//               _buildTextField(
//                   'Driver Details',
//                   'If paid driver, how long has he been in your employment?',
//                   'number'),
//               _buildTextField(
//                   'Driver Details',
//                   'Was he under the influence of intoxicating liquor or drugs?',
//                   'text'),
//             ],
//           ),
//       ],
//     );
//   }
//
//   final Map<String, int> sectionIndexMap = {
//     'Insured Details': 0,
//     'Vehicle Details': 1,
//     'Driver Details': 2,
//     'Garage Details': 3,
//     'Accident Details': 4,
//     'Bank Details': 5,
//   };
//
//   Widget _buildDeclarationSection() {
//     return Column(
//       children: [
//         Text(
//           'Form Preview',
//           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//         ),
//         // SizedBox(height: 20),
//         Container(
//           height: MediaQuery.of(context).size.height * 0.6, // Adjust as needed
//           child: FormPreview(
//             formData: processFormData(_formData),
//             onScrollComplete: (bool scrolledToEnd) {
//               setState(() {
//                 _previewScrolled = scrolledToEnd;
//                 print("Preview scrolled: $_formData"); // Debugging print
//               });
//             },
//             onSectionTap: (String sectionKey) {
//               int? stepIndex = sectionIndexMap[sectionKey];
//               if (stepIndex != null) {
//                 setState(() {
//                   _currentStep = stepIndex;
//                 });
//                 _scrollToStep(stepIndex);
//               }
//             },
//             excludedFields: ['Odometer Reading'],
//           ),
//         ),
//         SizedBox(height: 10),
//         if (_previewScrolled)
//           Column(
//             children: [
//               Text(
//                 'I hereby declare that the information provided is true and accurate to the best of my knowledge.',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 10),
//               CheckboxListTile(
//                 title: Text('I agree to the terms and conditions'),
//                 value: _agreeToTerms,
//                 onChanged: (value) {
//                   setState(() {
//                     _agreeToTerms = value ?? false;
//                   });
//                 },
//                 activeColor: Colors.blue,
//               ),
//             ],
//           ),
//         if (!_previewScrolled)
//           Text(
//             'Please scroll through the entire preview to proceed.',
//             style: TextStyle(color: Colors.red),
//           ),
//       ],
//     );
//   }
//
//   @override
//   Widget _buildTextField(
//       String sectionTitle, String fieldName, String fieldType) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: TextFormField(
//         key: Key('${sectionTitle}_$fieldName'),
//         decoration: InputDecoration(
//           labelText: fieldName,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12.0),
//             borderSide: BorderSide(color: Colors.grey.shade400),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12.0),
//             borderSide: BorderSide(color: Color(0xFF1A237E)),
//           ),
//           contentPadding:
//               EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
//           filled: true,
//           fillColor: Colors.white,
//           hintStyle: TextStyle(color: Colors.grey.shade600),
//         ),
//         initialValue: _formData[sectionTitle]![fieldName]?.toString(),
//         onChanged: (value) {
//           _updateFormField(sectionTitle, fieldName, value);
//         },
//         keyboardType: _getKeyboardType(fieldType),
//         validator: _getValidator(fieldType),
//       ),
//     );
//   }
//
//   Widget buildDateField(String sectionTitle, String fieldName) {
//     bool isVerified = false;
//
//     return StatefulBuilder(
//       builder: (BuildContext context, StateSetter setState) {
//         return ListTile(
//           title: Text(
//             fieldName,
//             style: TextStyle(color: Colors.blue),
//           ),
//           subtitle: Text(
//             _formData[sectionTitle]![fieldName] ?? 'Select Date',
//             style: TextStyle(color: Colors.black),
//           ),
//           trailing: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text("Verify date"),
//               Checkbox(
//                 value: isVerified,
//                 onChanged: (bool? value) {
//                   setState(() {
//                     isVerified = value ?? false;
//                     if (isVerified) {
//                       _formData[sectionTitle]![fieldName + '_verified'] =
//                           _formatDateForIndia(DateTime.now());
//                       print(
//                           'Verified $fieldName in $sectionTitle with date ${_formData[sectionTitle]![fieldName + '_verified']}');
//                     } else {
//                       _formData[sectionTitle]![fieldName + '_verified'] = null;
//                     }
//                   });
//                 },
//               ),
//             ],
//           ),
//           onTap: () async {
//             final DateTime? picked = await showDatePicker(
//               context: context,
//               initialDate: DateTime.now(),
//               firstDate: DateTime(1900),
//               lastDate: DateTime(2100),
//             );
//             if (picked != null) {
//               setState(() {
//                 String formattedDate = _formatDateForIndia(picked);
//                 _formData[sectionTitle]![fieldName] = formattedDate;
//                 print('Updated $fieldName in $sectionTitle to $formattedDate');
//                 if (isVerified) {
//                   _formData[sectionTitle]![fieldName + '_verified'] =
//                       formattedDate;
//                   print('Updated verified date to $formattedDate');
//                 }
//               });
//             }
//           },
//         );
//       },
//     );
//   }
//
//   Widget _buildTimeField(String sectionTitle, String fieldName) {
//     bool isVerified = false;
//
//     return StatefulBuilder(
//       builder: (BuildContext context, StateSetter setState) {
//         return ListTile(
//           title: Text(
//             fieldName,
//             style: TextStyle(color: Colors.blue),
//           ),
//           subtitle: Text(
//             _formData[sectionTitle]![fieldName] ?? 'Select Time',
//             style: TextStyle(color: Colors.black),
//           ),
//           trailing: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text("Verify time"),
//               Checkbox(
//                 value: isVerified,
//                 onChanged: (bool? value) {
//                   setState(() {
//                     isVerified = value ?? false;
//                     if (isVerified) {
//                       if (_formData[sectionTitle]![fieldName] != null) {
//                         _formData[sectionTitle]![fieldName + '_verified'] =
//                             _formatTimeForIndia(TimeOfDay.now());
//                         print('Verified $fieldName in $sectionTitle');
//                       } else {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                               content: Text(
//                                   'Please select a time before verifying')),
//                         );
//                         isVerified = false;
//                       }
//                     } else {
//                       _formData[sectionTitle]![fieldName + '_verified'] = null;
//                     }
//                   });
//                 },
//               ),
//             ],
//           ),
//           onTap: () async {
//             final TimeOfDay? picked = await showTimePicker(
//               context: context,
//               initialTime: TimeOfDay.now(),
//             );
//             if (picked != null) {
//               setState(() {
//                 _formData[sectionTitle]![fieldName] =
//                     _formatTimeForIndia(picked);
//                 print(
//                     'Updated $fieldName in $sectionTitle to ${_formData[sectionTitle]![fieldName]}');
//               });
//             }
//           },
//         );
//       },
//     );
//   }
//
//   TextInputType _getKeyboardType(String fieldType) {
//     switch (fieldType) {
//       case 'number':
//         return TextInputType.number;
//       case 'email':
//         return TextInputType.emailAddress;
//       default:
//         return TextInputType.text;
//     }
//   }
//
//   String? Function(String?)? _getValidator(String fieldType) {
//     switch (fieldType) {
//       case 'email':
//         return (value) {
//           if (value == null ||
//               value.isEmpty ||
//               !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//             return 'Please enter a valid email address';
//           }
//           return null;
//         };
//       case 'number':
//         return (value) {
//           if (value == null || value.isEmpty || int.tryParse(value) == null) {
//             return 'Please enter a valid number';
//           }
//           return null;
//         };
//       default:
//         return null;
//     }
//   }
//
//   void _scrollToStep(int stepIndex) {
//     final RenderBox renderBox = context.findRenderObject() as RenderBox;
//     final stepWidth =
//         renderBox.size.width / 4; // Assuming 4 steps visible at a time
//     _scrollController.animateTo(
//       stepIndex * stepWidth,
//       duration: Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//     );
//   }
//
//   Map<String, dynamic> mapFormDataToApiFormat(
//       Map<String, Map<String, dynamic>> formData) {
//     String? formatDateTime(dynamic value) {
//       if (value is DateTime) {
//         return value.toIso8601String();
//       }
//       return null; // Return null if the value is not a DateTime
//     }
//
//     String formatTimeOfDay(TimeOfDay timeOfDay) {
//       final now = DateTime.now();
//       final dateTime = DateTime(
//           now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
//       return DateFormat('HH:mm').format(dateTime);
//     }
//
//     return {
//       "policy_number":
//           formData["Insured Details"]?["Policy / Cover Note No"] ?? "",
//       "full_name": formData["Insured Details"]?["Name"] ?? "",
//       "loss_type": "Accident", // Set as appropriate
//       "claim_number": formData["Insured Details"]?["Policy / Cover Note No"] ??
//           "", // Adjust as needed
//       "permanent_address_line1":
//           formData["Insured Details"]?["Permanent Address"] ?? "",
//       "permanent_address_line2": "", // Not present in form data
//       "city_district": formData["Insured Details"]?["City"] ?? "",
//       "select_city": formData["Insured Details"]?["City"] ?? "",
//       "state": formData["Insured Details"]?["State"] ?? "",
//       "location": formData["Insured Details"]?["State"] ?? "",
//       "country": "India", // Adjust as needed
//       "pincode": formData["Insured Details"]?["Pin Code"] ?? "",
//       "mobile": formData["Insured Details"]?["Mobile No"] ?? "",
//       "email": formData["Insured Details"]?["Email ID"] ?? "",
//       "date_of_registration":
//           formatDateTime(formData["Vehicle Details"]?["Date of Registration"]),
//       "reg_date":
//           formatDateTime(formData["Vehicle Details"]?["Date of Registration"]),
//       "vehicle_number":
//           formData["Vehicle Details"]?["Registration Number"] ?? "",
//       "engine_number": formData["Vehicle Details"]?["Engine Number"] ?? "",
//       "chassis_number": formData["Vehicle Details"]?["Chassis Number"] ?? "",
//       "make": formData["Vehicle Details"]?["Make of Vehicle"] ?? "",
//       "select_model":
//           formData["Vehicle Details"]?["Model"] ?? "MARAZZO 7STR M8 MAR",
//       "odometer": formData["Vehicle Details"]?["Odometer Reading"] ?? 0,
//       "driver_full_name": formData["Driver Details"]?["Driver Name"] ?? "",
//       "gender": formData["Insured Details"]?["Gender"] ?? "",
//       "date_of_birth":
//           formatDateTime(formData["Insured Details"]?["Date of Birth"]),
//       "driving_license_number":
//           formData["Driver Details"]?["Driving License Number"] ?? "",
//       "license_issuing_authority":
//           formData["Driver Details"]?["License Issuing Authority"] ?? "",
//       "license_expiry_date":
//           formatDateTime(formData["Driver Details"]?["License Date of Expiry"]),
//       "license_for_vehicle_type":
//           formData["Driver Details"]?["License for Type of Vehicle"] ?? "",
//       "temporary_license":
//           formData["Driver Details"]?["Was the license temporary?"] ?? false,
//       "relation_with_insured":
//           formData["Driver Details"]?["Relation with Insured"] ?? "",
//       "employment_duration": formData["Driver Details"]
//               ?["If paid driver, how long has he been in your employment?"] ??
//           0,
//       "under_influence": formData["Driver Details"]?[
//               "Was he under the influence of intoxicating liquor or drugs?"] ??
//           false,
//       "endorsements_or_suspensions": "", // Not present in form data
//       "date_of_accident":
//           formatDateTime(formData["Accident Details"]?["Date of Accident"]),
//       "time_of_accident": formData["Accident Details"]?["Time of Accident"]
//               is TimeOfDay
//           ? formatTimeOfDay(formData["Accident Details"]?["Time of Accident"])
//           : (formData["Accident Details"]?["Time of Accident"] ?? ""),
//       "speed_of_vehicle":
//           formData["Accident Details"]?["Speed of Vehicle (Kmph)"] ?? "",
//       "number_of_occupants": formData["Accident Details"]
//               ?["No. of Occupants / Pillion rider"] ??
//           "",
//       "incident_location":
//           formData["Accident Details"]?["Exact Location of Accident"] ?? "",
//       "location_of_accident": formData["Accident Details"]
//               ?["Exact Location of Accident"] ??
//           "", // Add if available
//       "description_of_accident": "", // Add if available
//       "reported_to_police": false, // Add if available
//       "not_reported_reason": "", // Add if available
//       "police_station_name": "", // Add if available
//       "fir_number": "", // Add if available
//       "garage_name": formData["Garage Details"]?["Garage Name"] ?? "",
//       "garage_contact_person": formData["Garage Details"]
//               ?["Garage Contact Person and Address"] ??
//           "",
//       "garage_address": "", // Not present in form data
//       "garage_phone_number":
//           formData["Garage Details"]?["Garage Phone Number"] ?? "",
//       "theft_reported_to_police": false, // Add if available
//       "signature_thumb_impression": null, // Add if available
//       "declaration_date": DateTime.now().toIso8601String(),
//       "declaration_place": "Your City", // Set as needed
//       "address": formData["Insured Details"]?["Permanent Address"] ?? "",
//       "datepicker_date": DateTime.now().toIso8601String(),
//       "compulsory_excess": "none",
//       "paint_type": "none",
//       "mfg_year": "none",
//       "select_variant": "none",
//       "select_body_type": "none",
//       // Added address field
//     };
//   }
//
//   List<String> validateForm() {
//     List<String> errors = [];
//
//     // Helper function to check if a value should be validated
//     bool shouldValidate(dynamic value) {
//       return value != null &&
//           value != "" &&
//           value != "none" &&
//           value != "Not present in form data";
//     }
//
//     // Helper function to add error if validation fails
//     void addErrorIfInvalid(bool condition, String errorMessage) {
//       if (condition) {
//         errors.add(errorMessage);
//       }
//     }
//
//     addErrorIfInvalid(
//         shouldValidate(_formData['policy_number']) &&
//             _formData['policy_number']!.isEmpty,
//         'Policy Number is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['full_name']) &&
//             _formData['full_name']!.isEmpty,
//         'Full Name is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['permanent_address_line1']) &&
//             _formData['permanent_address_line1']!.isEmpty,
//         'Permanent Address is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['city_district']) &&
//             _formData['city_district']!.isEmpty,
//         'City/District is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['state']) && _formData['state']!.isEmpty,
//         'State is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['pincode']) &&
//             !RegExp(r'^\d{6}$').hasMatch(_formData['pincode'] as String),
//         'Please enter a valid 6-digit pincode.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['mobile']) &&
//             !RegExp(r'^\d{10}$').hasMatch(_formData['mobile'] as String),
//         'Please enter a valid 10-digit mobile number.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['email']) &&
//             !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
//                 .hasMatch(_formData['email'] as String),
//         'Please enter a valid email address.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['date_of_registration']) &&
//             _formData['date_of_registration']!.isEmpty,
//         'Date of Registration is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['vehicle_number']) &&
//             _formData['vehicle_number']!.isEmpty,
//         'Vehicle Number is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['engine_number']) &&
//             _formData['engine_number']!.isEmpty,
//         'Engine Number is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['chassis_number']) &&
//             _formData['chassis_number']!.isEmpty,
//         'Chassis Number is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['make']) && _formData['make']!.isEmpty,
//         'Make of Vehicle is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['select_model']) &&
//             _formData['select_model']!.isEmpty,
//         'Vehicle Model is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['driver_full_name']) &&
//             _formData['driver_full_name']!.isEmpty,
//         'Driver Full Name is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['gender']) && _formData['gender']!.isEmpty,
//         'Gender is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['date_of_birth']) &&
//             _formData['date_of_birth']!.isEmpty,
//         'Date of Birth is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['driving_license_number']) &&
//             _formData['driving_license_number']!.isEmpty,
//         'Driving License Number is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['license_issuing_authority']) &&
//             _formData['license_issuing_authority']!.isEmpty,
//         'License Issuing Authority is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['license_expiry_date']) &&
//             _formData['license_expiry_date']!.isEmpty,
//         'License Expiry Date is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['date_of_accident']) &&
//             _formData['date_of_accident']!.isEmpty,
//         'Date of Accident is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['time_of_accident']) &&
//             _formData['time_of_accident']!.isEmpty,
//         'Time of Accident is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['incident_location']) &&
//             _formData['incident_location']!.isEmpty,
//         'Incident Location is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['garage_name']) &&
//             _formData['garage_name']!.isEmpty,
//         'Garage Name is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['garage_contact_person']) &&
//             _formData['garage_contact_person']!.isEmpty,
//         'Garage Contact Person is required.');
//     addErrorIfInvalid(
//         shouldValidate(_formData['garage_phone_number']) &&
//             !RegExp(r'^\d{10}$')
//                 .hasMatch(_formData['garage_phone_number'] as String),
//         'Please enter a valid 10-digit garage phone number.');
//
//     return errors;
//   }
//
//   Future<void> _loadFormData() async {
//     print('called');
//     print(userId);
//     print(formId);
//     try {
//       DocumentSnapshot<Map<String, dynamic>> snapshot =
//           await _firestoreService.getFormData(userId!, formId!);
//
//       if (snapshot.exists && snapshot.data() != null) {
//         Map<String, dynamic>? data = snapshot.data();
//         if (data != null) {
//           setState(() {
//             _formData = _convertTimestampToDateTime(
//                 Map<String, Map<String, dynamic>>.from(data));
//           });
//           print('Form data loaded: $_formData');
//         }
//       }
//     } catch (e) {
//       print("Error loading form data: $e");
//     }
//   }
//
//   Map<String, Map<String, dynamic>> _convertTimestampToDateTime(
//       Map<String, Map<String, dynamic>> data) {
//     data.forEach((sectionKey, sectionData) {
//       sectionData.forEach((fieldKey, fieldValue) {
//         if (fieldValue is Timestamp) {
//           data[sectionKey]![fieldKey] = fieldValue.toDate();
//         }
//       });
//     });
//     return data;
//   }
//
//   Future<void> saveFormData(Map<String, Map<String, dynamic>> formData) async {
//     final prefs = await SharedPreferences.getInstance();
//
//     // Create a new map to store the serialized data
//     Map<String, Map<String, dynamic>> serializedData = {};
//
//     // Iterate through the form data and serialize DateTime and TimeOfDay objects
//     formData.forEach((sectionKey, sectionData) {
//       serializedData[sectionKey] = {};
//       sectionData.forEach((fieldKey, fieldValue) {
//         if (fieldValue is DateTime) {
//           serializedData[sectionKey]![fieldKey] = fieldValue.toIso8601String();
//         } else if (fieldValue is TimeOfDay) {
//           serializedData[sectionKey]![fieldKey] =
//               '${fieldValue.hour}:${fieldValue.minute}';
//         } else {
//           serializedData[sectionKey]![fieldKey] = fieldValue;
//         }
//       });
//     });
//
//     // Convert serialized data to JSON and save
//     String jsonData = jsonEncode(serializedData);
//     await prefs.setString('formData', jsonData);
//     print(jsonData);
//   }
//
//   Future<File> _loadAssetAsFile(String assetPath, String fileName) async {
//     final ByteData data = await rootBundle.load(assetPath);
//     final Uint8List bytes = data.buffer.asUint8List();
//     final Directory tempDir = await getTemporaryDirectory();
//     final File file = File('${tempDir.path}/$fileName');
//     await file.writeAsBytes(bytes);
//     return file;
//   }
//
//
//
//   Future<void> _submitForm(BuildContext context) async {
//     List<String> errors = validateForm();
//     if (errors.isNotEmpty) {
//       showErrors(context, errors);
//       return;
//     }
//     setState(() {
//       _isSubmitting = true;
//     });
//
//     final url = Uri.parse('https://damage-detection.goclaims.in/fw_damage/create_fw_claim');
//     final headers = {
//       'Authorization': 'Bearer hii',
//       'Content-Type': 'multipart/form-data',
//     };
//
//     final formDataForApi = mapFormDataToApiFormat(_formData);
//     final request = http.MultipartRequest('POST', url);
//     request.headers.addAll(headers);
//
//     formDataForApi.forEach((key, value) {
//       request.fields[key] = value.toString();
//     });
//
//     // Add captured images as files
//     for (String imagePath in _dynamicImagePaths) {
//       var file = await http.MultipartFile.fromPath('images[]', imagePath);
//       request.files.add(file);
//     }
//
//     try {
//       final response = await request.send();
//       setState(() {
//         _isSubmitting = false;
//       });
//
//       if (response.statusCode == 200) {
//         final responseBody = await response.stream.bytesToString();
//         final responseData = json.decode(responseBody);
//         final refId = responseData['ref_id'];
//         print(refId);
//         _updateClaimStatus(refId);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Claim submitted successfully. Ref ID: $refId'), backgroundColor: Colors.green),
//         );
//
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => AvailableClaims(taskId: '',)),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to send data and images.'), backgroundColor: Colors.red),
//         );
//         final responseBody = await response.stream.bytesToString();
//         print('Response body: $responseBody');
//       }
//     } catch (e) {
//       setState(() {
//         _isSubmitting = false;
//       });
//       print('Error occurred while uploading data: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('An error occurred while submitting the form.'), backgroundColor: Colors.red),
//       );
//     }
//   }
//
//
//
//   void showErrors(BuildContext context, List<String> errors) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Form Errors'),
//           content: SingleChildScrollView(
//             child: ListBody(
//               children: errors.map((error) => Text('• $error')).toList(),
//             ),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: Text('OK'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final steps = _getSteps();
//     print(userId);
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Claim Form', style: TextStyle(color: Colors.white)),
//         backgroundColor: Color(0xFF1A237E),
//         elevation: 0,
//       ),
//       backgroundColor: Colors.white,
//       body: _isLoading ||
//               _isSubmitting // Show loading indicator during both states
//           ? Center(
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
//               ),
//             )
//           : Column(
//               children: [
//                 Container(
//                   height: 80,
//                   child: ListView.builder(
//                     controller: _scrollController,
//                     scrollDirection: Axis.horizontal,
//                     itemCount: steps.length,
//                     itemBuilder: (context, index) {
//                       return Container(
//                         width: MediaQuery.of(context).size.width / 4,
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             CircleAvatar(
//                               backgroundColor: _currentStep >= index
//                                   ? Color(0xFF1A237E)
//                                   : Colors.grey,
//                               child: Text('${index + 1}',
//                                   style: TextStyle(color: Colors.white)),
//                             ),
//                             SizedBox(height: 4),
//                             Text(
//                               steps[index]['title'].toString(),
//                               style: TextStyle(fontSize: 12),
//                               textAlign: TextAlign.center,
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 Expanded(
//                   child: SingleChildScrollView(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: _currentStep == steps.length - 1
//                           ? _buildDeclarationSection()
//                           : _buildStepContent(steps[_currentStep]),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             if (_currentStep > 0)
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     _currentStep--;
//                     _scrollToStep(_currentStep);
//                   });
//                 },
//                 child: Text('Back', style: TextStyle(color: Colors.white)),
//                 style: ElevatedButton.styleFrom(
//                     backgroundColor: Color(0xFF1A237E)),
//               ),
//             ElevatedButton(
//               onPressed: (_currentStep < steps.length - 1 ||
//                       (_previewScrolled && _agreeToTerms))
//                   ? () {
//                       if (_currentStep < steps.length - 1) {
//                         setState(() {
//                           _currentStep++;
//                           _scrollToStep(_currentStep);
//                         });
//                       } else {
//                         _submitForm(context); // Pass context here
//                       }
//                     }
//                   : null,
//               child: Text(_currentStep < steps.length - 1 ? 'Next' : 'Submit',
//                   style: TextStyle(color: Colors.white)),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Color(0xFF1A237E),
//                 disabledBackgroundColor: Colors.grey,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // Future<void> _submitForm(BuildContext context) async {
// //   List<String> errors = validateForm();
// //   if (errors.isNotEmpty) {
// //     showErrors(context, errors);
// //     return;
// //   }
// //   setState(() {
// //     _isSubmitting = true; // Start loading
// //   });
// //
// //   // Prepare the URL and headers
// //   final url = Uri.parse('${APIConstants.baseUrl}/fw_damage/create_fw_claim');
// //   final headers = {
// //     'Authorization': 'Bearer hii', // Replace with the actual token if needed
// //     'Content-Type': 'multipart/form-data',
// //   };
// //
// //   // Convert form data to the required format
// //   final formDataForApi = mapFormDataToApiFormat(_formData);
// //
// //   // Create a multipart request
// //   final request = http.MultipartRequest('POST', url);
// //   request.headers.addAll(headers);
// //
// //   // Add the form data as fields
// //   formDataForApi.forEach((key, value) {
// //     request.fields[key] = value.toString();
// //   });
// //
// //   final Map<String, String> staticImagePaths = {
// //     // 'frontSide': 'assets/IMG_20240710_162627_DRO.jpg',
// //     // 'frontRightHandSide': 'assets/IMG_20240710_162650_DRO.jpg',
// //     // 'driverSide': 'assets/IMG_20240710_162728_DRO.jpg',
// //     // 'rearRightHandSide': 'assets/TimePhoto_20240528_140150.jpg',
// //     // 'rearSide': 'assets/TimePhoto_20240528_140155.jpg',
// //     // 'rearLeftHandSide': 'assets/TimePhoto_20240528_140202.jpg',
// //     // 'passengerSide': 'assets/TimePhoto_20240528_140210.jpg',
// //     // 'frontLeftHandSide': 'assets/TimePhoto_20240713_181337.jpg',
// //     // 'engineCompart': 'assets/TimePhoto_20240713_181400.jpg',
// //     // 'chassisNo': 'assets/TimePhoto_20240713_181406.jpg',
// //     // 'odometerCar': 'assets/TimePhoto_20240713_181526.jpg',
// //
// //     'frontSide': 'assets/vx4_09_09_2024 1.jpg',
// //     'frontRightHandSide': 'assets/vxi1_09_09_2024 1.jpg',
// //     'driverSide': 'assets/vxi2_09_09_2024 1.jpg',
// //     'rearRightHandSide': 'assets/vxi3_09_09_2024 1.jpg',
// //     'rearSide': 'assets/vxi_09_09_2024 1.jpg',
// //   };
// //
// //   // Add the images as files
// //   for (var entry in staticImagePaths.entries) {
// //     var fileBytes = await rootBundle.load(entry.value);
// //     var file = http.MultipartFile.fromBytes(
// //       'images[]',
// //       fileBytes.buffer.asUint8List(),
// //       filename: path.basename(entry.value),
// //     );
// //     request.files.add(file);
// //   }
// //
// //   try {
// //     // Send the request
// //     final response = await request.send();
// //
// //     setState(() {
// //       _isSubmitting = false; // End loading
// //     });
// //
// //     if (_formData["Vehicle Details"]?["Model"] == null ||
// //         _formData["Vehicle Details"]?["Model"].isEmpty) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //             content: Text('Please enter the vehicle model'),
// //             backgroundColor: Colors.red),
// //       );
// //       return;
// //     }
// //
// //     // Handle the response
// //     if (response.statusCode == 200) {
// //       final responseBody = await response.stream.bytesToString();
// //       final responseData = json.decode(responseBody);
// //       final refId = responseData['ref_id'];
// //
// //       // Update claim status
// //       _updateClaimStatus(refId);
// //
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Claim submitted successfully. Ref ID: $refId'),
// //           backgroundColor: Colors.green,
// //         ),
// //       );
// //
// //       // Navigate to the claim overview page
// //       Navigator.push(
// //         context,
// //         MaterialPageRoute(
// //             builder: (context) => AvailableClaims(taskId: '',)
// //         ),
// //       );
// //     } else {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Failed to send data and images.'),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //       print(
// //           'Failed to send data and images. Status code: ${response.statusCode}');
// //       final responseBody = await response.stream.bytesToString();
// //       print('Response body: $responseBody');
// //     }
// //   } catch (e) {
// //     setState(() {
// //       _isSubmitting = false; // End loading
// //     });
// //     print('Error occurred while uploading data: $e');
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text('An error occurred while submitting the form.'),
// //         backgroundColor: Colors.red,
// //       ),
// //     );
// //   }
// // }
//
//
//
//
// // Future<void> _submitForm(BuildContext context) async {
// //   // Save form data to Firestore
// //   await _firestoreService.saveFormData(userId!, formId!, _formData);
// //   _claimStatus.overallStatus = 'Pending';
// //   await _firestoreService.saveClaimStatus(userId!, formId!, _claimStatus.toMap());
// //
// //   // Define static image paths for each required image
// //   final Map<String, String> staticImagePaths = {
// //     'frontSide': 'assets/IMG_20240710_162627_DRO.jpg',
// //     'frontRightHandSide': 'assets/IMG_20240710_162650_DRO.jpg',
// //     'driverSide': 'assets/IMG_20240710_162728_DRO.jpg',
// //     // Add other image paths here...
// //   };
// //
// //   final url = Uri.parse('${APIConstants.baseUrl}/fw_damage/create_fw_claim');
// //   final headers = {
// //     'Authorization': 'Bearer hii', // Replace with your actual token if needed
// //   };
// //
// //   // Convert form data to the required API format
// //   final formDataForApi = mapFormDataToApiFormat(_formData);
// //
// //   // Create the multipart request
// //   final request = http.MultipartRequest('POST', url)
// //     ..headers.addAll(headers);
// //
// //   // Add form data to the request as fields
// //   formDataForApi.forEach((key, value) {
// //     request.fields[key] = value.toString();
// //   });
// //
// //   // Add images to the request as files
// //   for (final entry in staticImagePaths.entries) {
// //     final file = File(entry.value);
// //     if (await file.exists()) {
// //       request.files.add(await http.MultipartFile.fromPath(
// //         'images[${entry.key}]',  // Key format can vary by API requirement
// //         entry.value,
// //       ));
// //     }
// //   }
// //
// //   // Send the request and await the response
// //   try {
// //     final response = await request.send();
// //     final responseData = await response.stream.bytesToString();
// //
// //     // Check if the response was successful
// //     if (response.statusCode == 200) {
// //       print('Data and images uploaded successfully');
// //       print('Response: $responseData');
// //       // Navigate to Claimoverview if needed
// //       final String refId = jsonDecode(responseData)['refId'];
// //       Navigator.push(
// //         context,
// //         MaterialPageRoute(
// //           builder: (context) => Claimoverview(
// //             refId: refId,
// //             formId: formId!,
// //             userId: userId!,
// //           ),
// //         ),
// //       );
// //     } else {
// //       print('Failed to upload data. Status: ${response.statusCode}');
// //     }
// //   } catch (e) {
// //     print('Error occurred: $e');
// //   }
// // }
//
//
//
//
//
//
//
// // Future<void> _submitForm(BuildContext context) async {
// //   await _firestoreService.saveFormData(userId!, formId!, _formData);
// //   _claimStatus.overallStatus = 'Pending';
// //   await _firestoreService.saveClaimStatus(userId!, formId!, _claimStatus.toMap());
// //
// //   final url = Uri.parse('http://164.52.202.251/fw_damage/create_fw_claim');
// //   final headers = {
// //     'Authorization': 'Bearer hii', // Replace with the actual token if needed
// //     'Content-Type': 'multipart/form-data',
// //   };
// //
// //   final formDataForApi = mapFormDataToApiFormat(_formData);
// //   final request = http.MultipartRequest('POST', url);
// //   request.headers.addAll(headers);
// //
// //   print('Form Data:');
// //   print(jsonEncode(formDataForApi));
// //
// //   print('Dynamic Image Paths:');
// //   for (final path in _dynamicImagePaths) {
// //     print(path);
// //     // Add image files to the request
// //     request.files.add(await http.MultipartFile.fromPath('images', path));
// //   }
// //
// //   final combinedData = {
// //     ...formDataForApi,
// //     'images': _dynamicImagePaths,
// //   };
// //   print('Combined Data (form + images):');
// //   print(jsonEncode(combinedData));
// //
// //   // Add form data to the request
// //   formDataForApi.forEach((key, value) {
// //     request.fields[key] = value.toString();
// //   });
// //
// //   try {
// //     final response = await request.send();
// //     if (response.statusCode == 200) {
// //       print('Form submitted successfully');
// //       // Handle successful submission
// //     } else {
// //       print('Form submission failed');
// //       // Handle submission failure
// //     }
// //   } catch (e) {
// //     print('Error submitting form: $e');
// //     // Handle error
// //   }
// //
// //   final String refId = 'someGeneratedOrFetchedRefId'; // Replace with your logic
// //
// //   Navigator.push(
// //     context,
// //     MaterialPageRoute(
// //       builder: (context) => Claimoverview(
// //         refId: refId,
// //         formId: formId!,
// //         userId: userId!,
// //       ),
// //     ),
// //   );
// // }
