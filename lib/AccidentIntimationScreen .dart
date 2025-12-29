import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // ✅ ADDED: Required for Uint8List
import 'package:damagedetection1/helpers/APIConstants.dart';
import 'package:damagedetection1/surveyor/ClaimPreviewScreen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'services/DocumentValidationService.dart';

import 'ClaimSucceessPage.dart';

class AccidentIntimationScreen extends StatefulWidget {
  final String taskId;
  final String accidentId;
  final Map<String, dynamic>? driverDetails;

  const AccidentIntimationScreen({
    super.key,
    required this.taskId,
    required this.accidentId,
    this.driverDetails,
  });

  @override
  State<AccidentIntimationScreen> createState() =>
      _AccidentIntimationScreenState();
}

class _AccidentIntimationScreenState extends State<AccidentIntimationScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String? _surveyorId;

  final TextEditingController _remarksController = TextEditingController();

  // Store captured images
  final Map<String, File?> _carImages = {
    'EXTRA_IMAGE_1': null,
    'EXTRA_IMAGE_2': null,
    'EXTRA_IMAGE_3': null,
    'EXTRA_IMAGE_4': null,
    'EXTRA_IMAGE_5': null,
    'EXTRA_IMAGE_6': null,
  };

  // Store multiple document images with their types
  final Map<String, File?> _documentImages = {};

  // Document options
  final List<String> _documentTypes = [
    'RC_BOOK',
    'INSURANCE_POLICY',
    'PAN_CARD',
    'AADHAR_CARD',
    'FIR_COPY',
    'POLICE_REPORT',
    'OTHER_DOCUMENT',
  ];

  @override
  void initState() {
    super.initState();
    _loadSurveyorId();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadSurveyorId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _surveyorId = prefs.getString('surveyor_id');
    });

    print('========== SURVEYOR ID LOADED ==========');
    print('Surveyor ID: $_surveyorId');
    print('========================================');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Accident Intimation',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.directions_car_outlined,
                          color: Colors.blue.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Submit Accident Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Task ID: ${widget.taskId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_surveyorId != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Surveyor: $_surveyorId',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Documents Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Documents (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddDocumentDialog,
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: const Text('Add Document'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Display added documents
                  if (_documentImages.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No documents added yet. Tap "Add Document" to upload.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _documentImages.length,
                      itemBuilder: (context, index) {
                        final docType = _documentImages.keys.elementAt(index);
                        final docImage = _documentImages[docType];
                        return _buildDocumentCard(docType, docImage);
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Car Images Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 20,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Vehicle Images (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capture images from different angles',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 15),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _carImages.length,
                    itemBuilder: (context, index) {
                      String key = _carImages.keys.elementAt(index);
                      return _buildImageCard(key, index + 1);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Remarks Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remarks',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _remarksController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter remarks (optional)',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.note_alt_outlined,
                          color: Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Submit Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Submit Claim',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Show dialog to select and add document
  void _showAddDocumentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.document_scanner, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              const Text('Add Document'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select document type to upload',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    children: _documentTypes.map((docType) {
                      final isAdded = _documentImages.containsKey(docType);
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isAdded
                                ? Colors.green.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isAdded ? Icons.check_circle : Icons.document_scanner_outlined,
                            color: isAdded ? Colors.green : Colors.blue.shade700,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          docType.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isAdded ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        trailing: isAdded
                            ? Icon(Icons.edit, color: Colors.blue.shade700, size: 20)
                            : Icon(Icons.add_circle_outline,
                            color: Colors.grey, size: 20),
                        onTap: () {
                          Navigator.pop(context);
                          _captureDocumentImage(docType);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Build document card widget
  Widget _buildDocumentCard(String docType, File? docImage) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Document Image Thumbnail
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200, width: 2),
              ),
              child: docImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  docImage,
                  fit: BoxFit.cover,
                ),
              )
                  : const Icon(
                Icons.document_scanner,
                color: Colors.grey,
                size: 32,
              ),
            ),

            const SizedBox(width: 12),

            // Document Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    docType.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    docImage != null ? 'Image captured' : 'No image',
                    style: TextStyle(
                      fontSize: 12,
                      color: docImage != null ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.blue.shade700, size: 20),
                  onPressed: () => _captureDocumentImage(docType),
                  tooltip: 'Capture/Replace',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () {
                    setState(() {
                      _documentImages.remove(docType);
                    });
                  },
                  tooltip: 'Remove',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Capture document image
  Future<void> _captureDocumentImage(String docType) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Capture ${docType.replaceAll('_', ' ')}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        title: const Text(
                          'Take Photo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text('Use camera'),
                        onTap: () {
                          Navigator.pop(context);
                          _captureImage(docType, ImageSource.camera, isDocument: true);
                        },
                      ),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.photo_library,
                            color: Colors.green.shade700,
                          ),
                        ),
                        title: const Text(
                          'Choose from Gallery',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text('Select existing photo'),
                        onTap: () {
                          Navigator.pop(context);
                          _captureImage(docType, ImageSource.gallery, isDocument: true);
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageCard(String imageKey, int imageNumber) {
    File? image = _carImages[imageKey];
    bool hasImage = image != null;

    return GestureDetector(
      onTap: () => _showImageSourceDialog(imageKey),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? Colors.blue.shade200 : Colors.grey.shade300,
            width: hasImage ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: hasImage
            ? Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(
                image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _carImages[imageKey] = null;
                    });
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Image $imageNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 36,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 10),
            Text(
              'Image $imageNumber',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to add',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog(String imageKey) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Add Vehicle Image',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        title: const Text(
                          'Take Photo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text('Use camera'),
                        onTap: () {
                          Navigator.pop(context);
                          _captureImage(imageKey, ImageSource.camera);
                        },
                      ),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.photo_library,
                            color: Colors.green.shade700,
                          ),
                        ),
                        title: const Text(
                          'Choose from Gallery',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text('Select existing photo'),
                        onTap: () {
                          Navigator.pop(context);
                          _captureImage(imageKey, ImageSource.gallery);
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _captureImage(String imageKey, ImageSource source, {bool isDocument = false}) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          _showPermissionDialog();
        }
        return;
      }
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final capturedFile = File(pickedFile.path);

        // If it's a document, validate it first
        if (isDocument) {
          await _validateAndStoreDocument(imageKey, capturedFile);
        } else {
          // For vehicle images, store directly
          setState(() {
            _carImages[imageKey] = capturedFile;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Image captured successfully'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Camera Permission Required'),
          content: const Text(
            'Please grant camera permission to capture images. You can enable it from app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Validate and store document
  Future<void> _validateAndStoreDocument(String docType, File documentFile) async {
    // Show validation progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Validating document...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      // Validate using API
      final validationResult = await DocumentValidationService.validateDocument(
        documentFile,
        docType,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      print('Validation Result: $validationResult');

      if (validationResult['success'] == true) {
        if (validationResult['validated'] == true) {
          // Document validated successfully
          setState(() {
            _documentImages[docType] = documentFile;
          });

          _showSuccessSnackbar(
            validationResult['message'] ?? 'Document validated successfully',
          );
        } else if (validationResult['askUser'] == true) {
          // Ask user if they want to continue
          _showConfirmationDialog(
            docType,
            documentFile,
            validationResult['message'] ?? 'Unable to validate document',
            validationResult['confidence'],
          );
        } else {
          // Validation failed
          _showErrorDialog(
            validationResult['message'] ?? 'Document validation failed',
            docType,
          );
        }
      } else {
        // API failed, use fallback
        if (validationResult['useFallback'] == true) {
          await _useFallbackValidation(docType, documentFile);
        } else {
          _showErrorDialog(
            validationResult['message'] ?? 'Validation failed',
            docType,
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      print('Validation exception: $e');

      // Use fallback validation
      await _useFallbackValidation(docType, documentFile);
    }
  }

  /// Use fallback validation when API fails
  Future<void> _useFallbackValidation(String docType, File documentFile) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Using local validation...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final localResult = await DocumentValidationService.validateDocumentLocally(
        documentFile,
        docType,
      );

      if (mounted) Navigator.pop(context);

      if (localResult['validated'] == true) {
        // Local validation passed
        setState(() {
          _documentImages[docType] = documentFile;
        });

        _showSuccessSnackbar('Document added (validated locally)');
      } else {
        // Local validation also failed, ask user
        _showConfirmationDialog(
          docType,
          documentFile,
          'Unable to verify document automatically. Do you still want to continue with this document?',
          null,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      // Even fallback failed, ask user
      _showConfirmationDialog(
        docType,
        documentFile,
        'Unable to verify document. Do you still want to continue with this document?',
        null,
      );
    }
  }

  /// Show confirmation dialog to user
  void _showConfirmationDialog(
      String docType,
      File documentFile,
      String message,
      double? confidence,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Confirm Document',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (confidence != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Do you still want to continue with this document?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Don't store the document
                _showErrorSnackbar('Document not added');
              },
              child: const Text('Retake'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Store the document anyway
                setState(() {
                  _documentImages[docType] = documentFile;
                });
                _showSuccessSnackbar('Document added');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Continue Anyway'),
            ),
          ],
        );
      },
    );
  }

  /// Show error dialog
  void _showErrorDialog(String message, String docType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Validation Failed'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _captureDocumentImage(docType);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
              ),
              child: const Text('Retake'),
            ),
          ],
        );
      },
    );
  }

  /// Show success snackbar
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_surveyorId == null || _surveyorId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Surveyor ID not found. Please login again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Navigate to preview screen instead of directly submitting
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClaimPreviewScreen(
          taskId: widget.taskId,
          accidentId: widget.accidentId,
          driverDetails: widget.driverDetails ?? {},
          carImages: _carImages,
          documentImages: _documentImages,
          remarks: _remarksController.text,
          onSubmit: _handleActualSubmit,
        ),
      ),
    );
  }

  // ✅ FIXED: Accept Uint8List signature parameter
  Future<void> _handleActualSubmit(Uint8List signature) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Store or upload the signature if needed
      // Example: Save signature to file
      // final signatureFile = await _saveSignatureToFile(signature);

      await _uploadToAPI();
      await _markTaskCompleted();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<File> _createZipFile() async {
    print('========== CREATING ZIP FILE ==========');

    final tempDir = await getTemporaryDirectory();
    final zipFilePath =
        '${tempDir.path}/images_${DateTime.now().millisecondsSinceEpoch}.zip';

    final encoder = ZipFileEncoder();
    encoder.create(zipFilePath);

    int addedCount = 0;

    // ADD FIR COPY IF EXISTS
    if (widget.driverDetails != null &&
        widget.driverDetails!['fir_copy_image_path'] != null) {
      final firFile = File(widget.driverDetails!['fir_copy_image_path']);
      if (await firFile.exists()) {
        final fileName = 'FIR_COPY_${path.basename(firFile.path)}';
        print('Adding FIR copy to zip: $fileName');
        encoder.addFile(firFile, fileName);
        addedCount++;
      }
    }

    // ADD DL IMAGE IF EXISTS
    if (widget.driverDetails != null &&
        widget.driverDetails!['dl_image_path'] != null) {
      final dlFile = File(widget.driverDetails!['dl_image_path']);
      if (await dlFile.exists()) {
        final fileName = 'DRIVING_LICENSE_${path.basename(dlFile.path)}';
        print('Adding DL image to zip: $fileName');
        encoder.addFile(dlFile, fileName);
        addedCount++;
      }
    }

    // Add all document images with their specific types
    for (var entry in _documentImages.entries) {
      if (entry.value != null) {
        final docType = entry.key;
        final file = entry.value!;
        final fileName = '${docType}_${path.basename(file.path)}';
        print('Adding document to zip: $fileName');
        encoder.addFile(file, fileName);
        addedCount++;
      }
    }

    // Add all vehicle images to zip
    for (var entry in _carImages.entries) {
      if (entry.value != null) {
        final file = entry.value!;
        final fileName = '${entry.key}_${path.basename(file.path)}';
        print('Adding vehicle image to zip: $fileName');
        encoder.addFile(file, fileName);
        addedCount++;
      }
    }

    encoder.close();

    print('Zip file created: $zipFilePath');
    print('Total images added: $addedCount');
    print('Documents: ${_documentImages.length}, Vehicle images: ${_carImages.values.where((f) => f != null).length}, FIR: ${widget.driverDetails?['fir_copy_image_path'] != null ? 1 : 0}, DL: ${widget.driverDetails?['dl_image_path'] != null ? 1 : 0}');
    print('Zip file size: ${File(zipFilePath).lengthSync()} bytes');
    print('=======================================');

    return File(zipFilePath);
  }

  Future<void> _markTaskCompleted() async {
    final String apiUrl = '${APIConstants.baseUrl}/fw_damage/task_completed';

    print('========== MARKING TASK COMPLETED ==========');
    print('API URL: $apiUrl');
    print('Accident ID: ${widget.accidentId}');
    print('Surveyor ID: $_surveyorId');
    print('Remarks: ${_remarksController.text}');
    print('============================================');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTczNDQyMTM4MCwianRpIjoiMDJiZmNkNTItNDJhYS00NWNjLWI5ZTUtNjNkYTQ2YTY5ZWY0IiwidHlwZSI6ImFjY2VzcyIsInN1YiI6eyJ1c2VyX2lkIjoiNmY3N2M4NjItMTc5OC00MTU4LWJiNDUtOGRjNThiOTMxNGRmIiwidXNlcl9uYW1lIjoiU2FxdWliIEFuc2FyaSIsInVzZXJfZW1haWwiOiJzYXF1aWIuYW5zYXJpQGlhaWwuaW4iLCJ1c2VyX3JvbGUiOiJzdXJ2ZXlvciIsInVzZXJfcGhvbmUiOiI5MzIxMDI0MDg0In0sIm5iZiI6MTczNDQyMTM4MCwiY3NyZiI6ImNjOWU1YzRlLWYyYjUtNGNmYS05OWJhLTNhNTRhMjIxNGIzZCIsImV4cCI6MTczNzAxMzM4MH0.yzKBUKGdxdcPWZzSdPmXbmTiMovement4sABmGLzlDkTGdY", // TODO: Replace with dynamic token
        },
        body: json.encode({
          'accident_id': widget.accidentId,
          'surveyor_id': _surveyorId,
          'remarks': _remarksController.text.trim(),
        }),
      );

      print('========== TASK COMPLETION RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==============================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Task marked as completed successfully');
        return;
      } else {
        throw Exception(
            'Failed to mark task as completed: ${response.statusCode}');
      }
    } catch (e) {
      print('========== TASK COMPLETION ERROR ==========');
      print('Error: $e');
      print('===========================================');
      throw Exception('Error marking task completed: $e');
    }
  }

  Future<bool> _showPayloadPreviewDialog(Map<String, String> fields, List<String> files) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.preview, color: Colors.blue.shade700),
              SizedBox(width: 12),
              Text('Review Payload'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 500),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Please review the data before submission:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  
                  // Request Fields
                  Text(
                    'Request Fields:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: fields.entries.map((entry) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${entry.key}:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  entry.value.length > 100 
                                      ? '${entry.value.substring(0, 100)}...' 
                                      : entry.value,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Files
                  Text(
                    'Files to Upload:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: files.map((file) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.attach_file, size: 16, color: Colors.grey.shade600),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  file,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
              ),
              child: Text('Submit to API'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _uploadToAPI() async {
    const String apiUrl =
        'https://uat.goclaims.in/motor_claim_api/accident_intimation_motor';

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    // Send all driver details as single JSON object
    if (widget.driverDetails != null) {
      request.fields['surveyor_details'] = json.encode(widget.driverDetails);
      print('========== SURVEYOR DETAILS ==========');
      print(json.encode(widget.driverDetails));
      print('======================================');
    }

    // Add all required fields
    request.fields['task_id'] = widget.driverDetails?['task_id']?.toString() ?? widget.accidentId; // From task data
    request.fields['suv_id'] = _surveyorId!;
    request.fields['location'] = 'Mumbai';
    request.fields['status'] = 'Survey Completed';
    request.fields['make'] = widget.driverDetails?['make']?.toString() ?? 'MAHINDRA & MAHINDRA'; // From task data
    request.fields['model'] = widget.driverDetails?['model']?.toString() ?? 'BOLERO'; // From task data
    request.fields['body_type'] = 'four_wheeler';
    request.fields['variant'] = 'Car';
    request.fields['mfg_year'] = '2024';
    request.fields['city_category'] = 'Tier 1';
    request.fields['paint_type'] = 'Solid';
    request.fields['registration_date'] = 'Dummy';
    request.fields['vehicle_number'] = widget.driverDetails?['vehicle_number']?.toString() ?? widget.taskId; // From task data
    request.fields['compulsory_excess'] = 'Test';
    request.fields['odometer'] = '1234567';
    request.fields['incident_location'] = 'Mumbai';
    request.fields['intimation_date'] = '2024-11-11';
    request.fields['customer_id'] = '6f77c862-1798-4158-bb99-8dc58b9314df';
    request.fields['accident_reference_id'] = widget.accidentId;
    request.fields['claim_amount'] = '10000';

    // Add remarks if available
    if (_remarksController.text.trim().isNotEmpty) {
      request.fields['remarks'] = _remarksController.text.trim();
    }

    // Add garage_id if network garage selected
    if (widget.driverDetails?['garage_id'] != null) {
      request.fields['garage_id'] = widget.driverDetails!['garage_id'].toString();
      print('Added garage_id: ${widget.driverDetails!['garage_id']}');
    }

    // Add non_network_garages if non-network garage selected
    if (widget.driverDetails?['non_network_garages'] != null) {
      request.fields['non_network_garages'] = json.encode(widget.driverDetails!['non_network_garages']);
      print('Added non_network_garages: ${widget.driverDetails!['non_network_garages']}');
    }

    // Add document types as JSON array
    if (_documentImages.isNotEmpty) {
      request.fields['document_types'] =
          json.encode(_documentImages.keys.toList());
    }

    print('========== REQUEST FIELDS ==========');
    request.fields.forEach((key, value) {
      print('$key: $value');
    });
    print('====================================');

    final hasVehicleImages = _carImages.values.any((file) => file != null);
    final hasDocumentImages = _documentImages.isNotEmpty;
    final hasFIRCopy = widget.driverDetails != null &&
        widget.driverDetails!['fir_copy_image_path'] != null;
    final hasAnyImages = hasVehicleImages || hasDocumentImages || hasFIRCopy;

    if (hasAnyImages) {
      final zipFile = await _createZipFile();

      final multipartFile = await http.MultipartFile.fromPath(
        'zip_file',
        zipFile.path,
        filename: 'images.zip',
      );
      request.files.add(multipartFile);

      print('========== ZIP FILE ADDED ==========');
      print('Key: zip_file');
      print('Filename: images.zip');
      print('File size: ${zipFile.lengthSync()} bytes');
      print('Document images included: ${_documentImages.length}');
      print('Vehicle images included: ${_carImages.values.where((f) => f != null).length}');
      print('FIR copy included: $hasFIRCopy');
      print('====================================');
    } else {
      print('No images to upload');
    }

    // Show payload preview dialog
    // TODO: Uncomment to enable payload preview before submission
    /*
    final filesList = <String>[];
    if (hasAnyImages) {
      filesList.add('images.zip (${_documentImages.length} documents, ${_carImages.values.where((f) => f != null).length} vehicle images)');
    }
    
    final shouldProceed = await _showPayloadPreviewDialog(request.fields, filesList);
    if (!shouldProceed) {
      print('User cancelled submission');
      return; // User cancelled
    }
    */

    try {
      print('Sending request...');
      var response = await request.send();

      print('========== API RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('==================================');

      if (response.statusCode != 200 && response.statusCode != 201) {
        var responseBody = await response.stream.bytesToString();
        print('Error Response Body: $responseBody');
        throw Exception(
            'Failed to upload: ${response.statusCode} - $responseBody');
      }

      var responseBody = await response.stream.bytesToString();
      print('Success Response: $responseBody');

      final responseData = json.decode(responseBody);

      if (hasAnyImages) {
        final tempDir = await getTemporaryDirectory();
        final zipFiles =
        tempDir.listSync().where((file) => file.path.endsWith('.zip'));
        for (var file in zipFiles) {
          file.deleteSync();
        }
        print('Temporary zip files cleaned up');
      }

      if (mounted && responseData['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClaimSuccessPage(
              refId: responseData['ref_id'] ?? 'N/A',
              result: responseData['result'] ?? 'Processing started',
              taskId: widget.driverDetails?['task_id']?.toString() ?? widget.accidentId, // Use actual task_id
            ),
          ),
        );
      }
    } catch (e) {
      print('========== UPLOAD ERROR ==========');
      print('Error: $e');
      print('==================================');
      rethrow;
    }
  }
}
