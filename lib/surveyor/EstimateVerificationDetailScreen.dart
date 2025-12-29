import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import '../helpers/APIConstants.dart';

class EstimateVerificationDetailScreen extends StatefulWidget {
  final String claimId;
  final String claimNumber;
  final String taskType;

  const EstimateVerificationDetailScreen({
    Key? key,
    required this.claimId,
    required this.claimNumber,
    this.taskType = 'estimate_verification',
  }) : super(key: key);

  @override
  _EstimateVerificationDetailScreenState createState() => _EstimateVerificationDetailScreenState();
}

class _EstimateVerificationDetailScreenState extends State<EstimateVerificationDetailScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _lineItems = [];
  String? _errorMessage;

  // Store verification status: 'yes', 'no', or null (unselected)
  Map<String, String?> _verificationStatus = {};
  
  // Store images for each item (item_id -> list of images)
  Map<String, List<File>> _itemImages = {};
  
  // Image picker
  final ImagePicker _picker = ImagePicker();
  
  // Signature, selfie, and declaration for final submission
  File? _signatureImage;
  File? _selfieImage;
  bool _declarationAccepted = false;

  @override
  void initState() {
    super.initState();
    _fetchEstimateItems();
  }

  Future<void> _fetchEstimateItems() async {
    try {
      Uri url;
      
      if (widget.taskType == 'invoice_verification') {
        url = Uri.parse('${APIConstants.motorBaseUrl}/get_invoice_items/${widget.claimId}');
      } else {
        url = Uri.parse('${APIConstants.motorBaseUrl}/get_estimate_items/${widget.claimId}');
      }
      
      print('Fetching items from: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = List<Map<String, dynamic>>.from(data['line_items'] ?? []);
        
        setState(() {
          _lineItems = items;
          // Initialize verification status
          for (var item in items) {
            _verificationStatus[item['id']] = null; 
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load items: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _captureImageForItem(String itemId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          if (_itemImages[itemId] == null) {
            _itemImages[itemId] = [];
          }
          _itemImages[itemId]!.add(File(image.path));
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image captured successfully (${_itemImages[itemId]!.length} total)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture image: $e')),
      );
    }
  }

  void _showImageSelectionDialog(String itemId) {
    // Get all captured images from all items
    List<File> allImages = [];
    _itemImages.forEach((key, images) {
      allImages.addAll(images);
    });

    if (allImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No images captured yet. Please capture images first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Images'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: allImages.length,
              itemBuilder: (context, index) {
                final image = allImages[index];
                final isSelected = _itemImages[itemId]?.contains(image) ?? false;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_itemImages[itemId] == null) {
                        _itemImages[itemId] = [];
                      }
                      
                      if (isSelected) {
                        _itemImages[itemId]!.remove(image);
                      } else {
                        _itemImages[itemId]!.add(image);
                      }
                    });
                    Navigator.pop(context);
                    _showImageSelectionDialog(itemId); // Refresh dialog
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.green : Colors.grey,
                            width: isSelected ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check, color: Colors.white, size: 16),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitVerification() async {
    // Check if any items are verified
    final verifiedItems = _verificationStatus.entries
        .where((entry) => entry.value != null)
        .toList();

    if (verifiedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please verify at least one item')),
      );
      return;
    }

    // Show final submission dialog with signature, selfie, and declaration
    _showFinalSubmissionDialog();
  }

  void _showFinalSubmissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.blue.shade700),
                  SizedBox(width: 12),
                  Expanded(child: Text('Final Verification')),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please complete the following to submit:',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                    SizedBox(height: 20),
                    
                    // Signature Section
                    Text('1. Signature *', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final signature = await _captureSignature();
                        if (signature != null) {
                          setDialogState(() {
                            _signatureImage = signature;
                          });
                        }
                      },
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: _signatureImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(_signatureImage!, fit: BoxFit.contain),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.draw, color: Colors.grey.shade400, size: 32),
                                    SizedBox(height: 4),
                                    Text('Tap to add signature', style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Selfie Section
                    Text('2. Selfie *', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final selfie = await _captureSelfie();
                        if (selfie != null) {
                          setDialogState(() {
                            _selfieImage = selfie;
                          });
                        }
                      },
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: _selfieImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(_selfieImage!, fit: BoxFit.cover),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, color: Colors.grey.shade400, size: 32),
                                    SizedBox(height: 4),
                                    Text('Tap to take selfie', style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Declaration Checkbox
                    Text('3. Declaration *', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _declarationAccepted,
                            onChanged: (value) {
                              setDialogState(() {
                                _declarationAccepted = value ?? false;
                              });
                            },
                            activeColor: Colors.blue.shade700,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                'I hereby declare that all the information provided is true and accurate to the best of my knowledge.',
                                style: TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_signatureImage != null && _selfieImage != null && _declarationAccepted)
                            ? () {
                                Navigator.pop(context);
                                _performFinalSubmit();
                              }
                            : null,
                        child: Text('Submit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<File?> _captureSignature() async {
    final SignatureController controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Draw Your Signature'),
          content: Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Signature(
              controller: controller,
              backgroundColor: Colors.white,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.clear();
              },
              child: Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Done'),
            ),
          ],
        );
      },
    );

    if (result == true && controller.isNotEmpty) {
      final signature = await controller.toPngBytes();
      if (signature != null) {
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(signature);
        return file;
      }
    }
    
    return null;
  }

  Future<File?> _captureSelfie() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture selfie: $e')),
      );
    }
    return null;
  }

  Future<void> _performFinalSubmit() async {
    // Check if any items are verified
    final verifiedItems = _verificationStatus.entries
        .where((entry) => entry.value != null)
        .toList();

    if (verifiedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please verify at least one item')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Log captured data
      print('========== VERIFICATION DATA TO SEND ==========');
      print('Signature: ${_signatureImage?.path ?? "Not captured"}');
      print('Selfie: ${_selfieImage?.path ?? "Not captured"}');
      print('Declaration Accepted: $_declarationAccepted');
      
      // Log images per item
      int totalImages = 0;
      _itemImages.forEach((itemId, images) {
        print('Item $itemId: ${images.length} images');
        totalImages += images.length;
      });
      print('Total Images: $totalImages');
      print('================================================');
      
      // Construct payload for verification status
      List<Map<String, String>> itemsPayload = [];
      
      for (var entry in verifiedItems) {
        final itemId = entry.key;
        final action = entry.value!; // 'yes' or 'no' from UI
        
        // Map to "Yes"/"No" as per API requirement
        final apiAction = action == 'yes' ? 'Yes' : 'No';

        itemsPayload.add({
          "id": itemId,
          "action": apiAction
        });
      }

      Uri url;
      
      if (widget.taskType == 'invoice_verification') {
        url = Uri.parse('${APIConstants.motorBaseUrlnew}/approve_invoice_surveyor');
      } else {
        url = Uri.parse('${APIConstants.motorBaseUrlnew}/approve_estimate_surveyor');
      }

      print('Submitting to URL: $url');
      print('Items Payload: ${json.encode(itemsPayload)}');

      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add items JSON as a field
      request.fields['items'] = json.encode(itemsPayload);
      
      // Add declaration status (send as lowercase boolean string)
      request.fields['declaration'] = _declarationAccepted ? 'True' : 'False';
      
      // Add all item images with naming format: itemId.extension
      int imageCounter = 0;
      for (var entry in _itemImages.entries) {
        final itemId = entry.key;
        final images = entry.value;
        
        for (var i = 0; i < images.length; i++) {
          final image = images[i];
          final extension = image.path.split('.').last;
          final fileName = '$itemId.$extension';
          
          request.files.add(
            await http.MultipartFile.fromPath(
              'images',
              image.path,
              filename: fileName,
            ),
          );
          imageCounter++;
          print('Added image: $fileName');
        }
      }
      
      // Add signature
      if (_signatureImage != null) {
        final signatureExtension = _signatureImage!.path.split('.').last;
        request.files.add(
          await http.MultipartFile.fromPath(
            'signature',
            _signatureImage!.path,
            filename: 'signature.$signatureExtension',
          ),
        );
        print('Added signature with filename: signature.$signatureExtension');
      }
      
      // Add selfie
      if (_selfieImage != null) {
        final selfieExtension = _selfieImage!.path.split('.').last;
        request.files.add(
          await http.MultipartFile.fromPath(
            'selfie',
            _selfieImage!.path,
            filename: 'selfie.$selfieExtension',
          ),
        );
        print('Added selfie with filename: selfie.$selfieExtension');
      }
      
      print('Total files attached: ${request.files.length}');
      print('Fields: ${request.fields}');
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      // Show payload dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Payload Sent'),
          content: SingleChildScrollView(
            child: SelectableText(
              'URL: $url\n\nItems: ${json.encode(itemsPayload)}\n\nDeclaration: ${_declarationAccepted ? "True" : "False"}\n\nResponse: ${response.statusCode}',
              style: TextStyle(fontSize: 11, fontFamily: 'Courier'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close'),
            ),
          ],
        ),
      );

      if (response.statusCode == 200) {
        // Parse the response JSON
        final responseData = json.decode(response.body);
        final message = responseData['message'] ?? 'Verification submitted successfully!';
        final success = responseData['success'] ?? false;
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$message ($totalImages images, signature & selfie sent)'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context); // Go back to list
        } else {
          // API returned 200 but success is false
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Handle 400 and other errors
        String errorMessage = 'Failed to submit: ${response.statusCode}';
        
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // If JSON parsing fails, use default error message
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error submitting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  double get _totalAmount {
    return _lineItems.fold(0.0, (sum, item) {
      // Handle both estimate (part_amount) and invoice (unit_price) fields
      String amountStr = item['part_amount']?.toString() ?? item['unit_price']?.toString() ?? '0';
      return sum + (double.tryParse(amountStr) ?? 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.taskType == 'invoice_verification' ? 'Invoice Verification' : 'Estimate Verification',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              widget.claimNumber,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _fetchEstimateItems,
                          child: Text('Retry'),
                        )
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Summary Header
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Items', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              SizedBox(height: 4),
                              Text('${_lineItems.length}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Total Estimate', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              SizedBox(height: 4),
                              Text(
                                '₹${_totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[800]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // List of Items
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(12),
                        itemCount: _lineItems.length,
                        itemBuilder: (context, index) {
                          final item = _lineItems[index];
                          final itemId = item['id'];
                          final status = _verificationStatus[itemId];
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                )
                              ],
                              border: Border.all(
                                color: status == null 
                                    ? Colors.transparent 
                                    : (status == 'yes' ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                                width: 1.5
                              )
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['part_name'] ?? 'Unknown Part',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            '₹${item['part_amount'] ?? item['unit_price'] ?? '0'}',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _buildTag('Part #: ${item['part_number'] ?? 'N/A'}', Colors.grey[100]!, Colors.grey[700]!),
                                          SizedBox(width: 8),
                                          _buildTag('Qty: ${item['qty'] ?? '0'}', Colors.blue[50]!, Colors.blue[700]!),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildSelectionButton(
                                          title: 'Approve',
                                          isSelected: status == 'yes',
                                          color: Colors.green,
                                          icon: Icons.check_circle_outline,
                                          onTap: () {
                                            setState(() {
                                              _verificationStatus[itemId] = 'yes';
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: _buildSelectionButton(
                                          title: 'Reject',
                                          isSelected: status == 'no',
                                          color: Colors.red,
                                          icon: Icons.cancel_outlined,
                                          onTap: () {
                                            setState(() {
                                              _verificationStatus[itemId] = 'no';
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Camera and Select Image buttons (only show if approved)
                                if (status == 'yes')
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: Icon(Icons.camera_alt, size: 18),
                                            label: Text('Camera'),
                                            onPressed: () => _captureImageForItem(itemId),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.blue.shade700,
                                              side: BorderSide(color: Colors.blue.shade300),
                                              padding: EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                Icon(Icons.photo_library, size: 18),
                                                if (_itemImages[itemId] != null && _itemImages[itemId]!.isNotEmpty)
                                                  Positioned(
                                                    right: -8,
                                                    top: -8,
                                                    child: Container(
                                                      padding: EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      constraints: BoxConstraints(
                                                        minWidth: 18,
                                                        minHeight: 18,
                                                      ),
                                                      child: Text(
                                                        '${_itemImages[itemId]!.length}',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            label: Text('Select'),
                                            onPressed: () => _showImageSelectionDialog(itemId),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.blue.shade700,
                                              side: BorderSide(color: Colors.blue.shade300),
                                              padding: EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Submit Button Area
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: Offset(0, -4),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitVerification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Submit Verification',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSelectionButton({
    required String title,
    required bool isSelected,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : icon,
              size: 18,
              color: isSelected ? color : Colors.grey[500],
            ),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
