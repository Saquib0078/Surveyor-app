import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'DriverDetailsScreen.dart';

class ClaimPreviewScreen extends StatefulWidget {
  final String taskId;
  final String accidentId;
  final Map<String, dynamic> driverDetails;
  final Map<String, File?> carImages;
  final Map<String, File?> documentImages;  final String remarks;
  final Function(Uint8List signature) onSubmit;

  const ClaimPreviewScreen({
    Key? key,
    required this.taskId,
    required this.accidentId,
    required this.driverDetails,
    required this.carImages,
    required this.documentImages,
    required this.remarks,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<ClaimPreviewScreen> createState() => _ClaimPreviewScreenState();
}

class _ClaimPreviewScreenState extends State<ClaimPreviewScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.blue.shade900,
    exportBackgroundColor: Colors.white,
  );

  bool _hasSignature = false;
  bool _acceptDeclaration = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _signatureController.addListener(() {
      setState(() {
        _hasSignature = _signatureController.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  void _clearSignature() {
    _signatureController.clear();
    setState(() {
      _hasSignature = false;
    });
  }

  Future<void> _submitClaim() async {
    if (!_hasSignature) {
      _showErrorSnackBar('Please provide your signature');
      return;
    }

    if (!_acceptDeclaration) {
      _showErrorSnackBar('Please accept the declaration');
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Confirm Submission'),
          ],
        ),
        content: Text(
          'Are you sure you want to submit this claim? This action cannot be undone.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isSubmitting = true;
      });

      // Get signature as image
      final signatureImage = await _signatureController.toPngBytes();

      if (signatureImage != null) {
        // Call the submit function from parent with signature
        widget.onSubmit(signatureImage);
      } else {
        setState(() {
          _isSubmitting = false;
        });
        _showErrorSnackBar('Failed to capture signature. Please try again.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _editDriverDetails(int step) async {
    // Navigate back to DriverDetailsScreen in edit mode with specific step
    final result = await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DriverDetailsScreen(
          taskId: widget.taskId,
          accidentId: widget.accidentId,
          isEditMode: true,
          editStep: step, // Jump to specific step
          existingDetails: widget.driverDetails,
          existingCarImages: widget.carImages,
          existingDocumentImages: widget.documentImages,
          existingRemarks: widget.remarks,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Preview & Submit',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.preview, color: Colors.white, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'Claim Preview',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please review all details before submission',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Accident Snapshot
                  if (_hasAccidentDetails())
                    _buildSection(
                      'Accident Snapshot',
                      Icons.event_note,
                      Colors.orange,
                      [
                        _buildDetailRow('Date & Time', widget.driverDetails['accident_datetime'] ?? 'Not provided'),
                        _buildDetailRow('Location', widget.driverDetails['accident_location'] ?? 'Not provided'),
                        _buildDetailRow('Cause', widget.driverDetails['cause_of_accident'] ?? 'Not provided'),
                        // _buildDetailRow('Vehicle Location', widget.driverDetails['vehicle_current_location'] ?? 'Not provided'),
                        // _buildDetailRow('Damage Description', widget.driverDetails['damage_brief_description'] ?? 'Not provided', maxLines: 3),
                      ],
                      onEdit: () => _editDriverDetails(0), // Step 0: Accident Snapshot
                    ),

                  // Driver Verification
                  if (_hasDriverDetails())
                    _buildSection(
                      'Driver Verification',
                      Icons.person,
                      Colors.blue,
                      [
                        _buildDetailRow('Policyholder Driving', widget.driverDetails['was_policyholder_driving'] == true ? 'Yes' : widget.driverDetails['was_policyholder_driving'] == false ? 'No' : 'Not specified'),
                        _buildDetailRow('Driver Name', widget.driverDetails['driver_name'] ?? 'Not provided'),
                        _buildDetailRow('License Number', widget.driverDetails['license_number'] ?? 'Not provided'),
                        _buildDetailRow('License Expiry', widget.driverDetails['license_expiry'] ?? 'Not provided'),
                        _buildDetailRow('Travelling Speed', widget.driverDetails['travelling_speed'] != null && widget.driverDetails['travelling_speed'].toString().isNotEmpty ? '${widget.driverDetails['travelling_speed']} km/h' : 'Not provided'),
                      ],
                      onEdit: () => _editDriverDetails(1), // Step 1: Driver Verification
                    ),

                  // Police & Third Party
                  if (_hasPoliceDetails())
                    _buildSection(
                      'Police & Third Party',
                      Icons.local_police,
                      Colors.red,
                      [
                        _buildDetailRow('Police Informed', widget.driverDetails['police_informed'] == true ? 'Yes' : widget.driverDetails['police_informed'] == false ? 'No' : 'Not specified'),
                        if (widget.driverDetails['police_informed'] == true) ...[
                          _buildDetailRow('Particulars Taken', widget.driverDetails['police_particulars_taken'] == true ? 'Yes' : widget.driverDetails['police_particulars_taken'] == false ? 'No' : 'Not specified'),
                          _buildDetailRow('FIR Number', widget.driverDetails['fir_number'] ?? 'Not provided'),
                          _buildDetailRow('Police Station', widget.driverDetails['police_station'] ?? 'Not provided'),
                        ],
                        _buildDetailRow('Third Party Involved', widget.driverDetails['third_party_involved'] == true ? 'Yes' : widget.driverDetails['third_party_involved'] == false ? 'No' : 'Not specified'),
                        if (widget.driverDetails['third_party_involved'] == true)
                          _buildDetailRow('Third Party Name', widget.driverDetails['third_party_name'] ?? 'Not provided'),
                      ],
                      onEdit: () => _editDriverDetails(2), // Step 2: Police & Third Party
                    ),

                  // Other Details
                  if (_hasOtherDetails())
                    _buildSection(
                      'Additional Information',
                      Icons.info,
                      Colors.purple,
                      [
                        _buildDetailRow('Injury/Death', widget.driverDetails['injury_or_death'] == true ? 'Yes' : widget.driverDetails['injury_or_death'] == false ? 'No' : 'Not specified'),
                        if (widget.driverDetails['injury_details'] != null && (widget.driverDetails['injury_details'] as List).isNotEmpty)
                          _buildInjuryList(widget.driverDetails['injury_details'] as List),
                        _buildDetailRow('Independent Witnesses', widget.driverDetails['independent_witnesses'] == true ? 'Yes' : widget.driverDetails['independent_witnesses'] == false ? 'No' : 'Not specified'),
                        if (widget.driverDetails['independent_witnesses'] == true) ...[
                          _buildDetailRow('Witness Name', widget.driverDetails['witness_name'] ?? 'Not provided'),
                          _buildDetailRow('Witness Contact', widget.driverDetails['witness_contact'] ?? 'Not provided'),
                        ],
                      ],
                      onEdit: () => _editDriverDetails(3), // Step 3: Additional Information
                    ),

                  // Vehicle Images
                  _buildImagesSection(
                    'Vehicle Images',
                    Icons.directions_car,
                    Colors.green,
                    widget.carImages,
                  ),

                  // Document Images
                  if (widget.documentImages.isNotEmpty)
                    _buildImagesSection(
                      'Document Images',
                      Icons.description,
                      Colors.indigo,
                      widget.documentImages,
                    ),

                  // Remarks
                  if (widget.remarks.isNotEmpty)
                    _buildSection(
                      'Remarks',
                      Icons.notes,
                      Colors.brown,
                      [
                        _buildDetailRow('Comments', widget.remarks, maxLines: 5),
                      ],
                    ),

                  SizedBox(height: 24),

                  // Digital Signature
                  _buildSignatureSection(),

                  SizedBox(height: 24),

                  // Declaration Checkbox
                  _buildDeclarationCheckbox(),

                  SizedBox(height: 120), // Space for submit button
                ],
              ),
            ),
          ),

          // Submit Button (Fixed at bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _hasSignature && _acceptDeclaration && !_isSubmitting
                    ? _submitClaim
                    : null,
                icon: _isSubmitting
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : Icon(Icons.send, size: 20),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Claim',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  margin: EdgeInsets.all(40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(
                          'Submitting Claim...',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please wait',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasAccidentDetails() {
    return widget.driverDetails['accident_datetime'] != null ||
        widget.driverDetails['accident_location'] != null ||
        widget.driverDetails['cause_of_accident'] != null;
  }

  bool _hasDriverDetails() {
    return widget.driverDetails['driver_name'] != null ||
        widget.driverDetails['license_number'] != null;
  }

  bool _hasPoliceDetails() {
    return widget.driverDetails['police_informed'] != null ||
        widget.driverDetails['third_party_involved'] != null;
  }

  bool _hasOtherDetails() {
    return widget.driverDetails['injury_or_death'] != null ||
        widget.driverDetails['independent_witnesses'] != null;
  }

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children, {VoidCallback? onEdit}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit, color: color),
                    tooltip: 'Edit',
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInjuryList(List injuries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Injury Details:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        ...List.generate(injuries.length, (index) {
          final injury = injuries[index];
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. ${injury['name']}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text('Age: ${injury['age']} | ${injury['injury_nature']}', style: TextStyle(fontSize: 12)),
                if (injury['address'] != null && injury['address'].toString().isNotEmpty)
                  Text('Address: ${injury['address']}', style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildImagesSection(String title, IconData icon, Color color, Map<String, dynamic> images) {
    final imageCount = images.values.where((img) => img != null).length;

    if (imageCount == 0) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$imageCount',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: images.entries
                  .where((entry) => entry.value != null)
                  .map((entry) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      entry.value as File,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasSignature ? Colors.green : Colors.red.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.draw, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Digital Signature *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please sign below to confirm the accuracy of all information provided',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                SizedBox(height: 16),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Signature(
                    controller: _signatureController,
                    backgroundColor: Colors.grey.shade50,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _hasSignature ? '✓ Signature captured' : 'Sign in the box above',
                      style: TextStyle(
                        fontSize: 12,
                        color: _hasSignature ? Colors.green : Colors.grey.shade600,
                        fontWeight: _hasSignature ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _clearSignature,
                      icon: Icon(Icons.clear, size: 18),
                      label: Text('Clear'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclarationCheckbox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _acceptDeclaration ? Colors.green : Colors.orange.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: CheckboxListTile(
        value: _acceptDeclaration,
        onChanged: (value) {
          setState(() {
            _acceptDeclaration = value ?? false;
          });
        },
        activeColor: Colors.green,
        title: Text(
          'Declaration',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'I hereby declare that all the information provided above is true and accurate to the best of my knowledge. I understand that any false information may result in rejection of the claim.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
