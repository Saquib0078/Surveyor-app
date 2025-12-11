import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../AccidentIntimationScreen .dart';
import '../extractionapi.dart';
import '../services/DocumentValidationService.dart';

class DriverDetailsScreen extends StatefulWidget {
  final String taskId;
  final String accidentId;

  const DriverDetailsScreen({
    Key? key,
    required this.taskId,
    required this.accidentId,
  }) : super(key: key);

  @override
  State<DriverDetailsScreen> createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isValidating = false;
  late AnimationController _animationController;

  // Step 1: Accident Snapshot
  final TextEditingController _accidentDateTimeController = TextEditingController();
  final TextEditingController _accidentLocationController = TextEditingController();
  String? _causeOfAccident;
  final TextEditingController _vehicleCurrentLocationController = TextEditingController();
  final TextEditingController _damageBriefController = TextEditingController();

  // Step 2: Driver Verification
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _licenseExpiryController = TextEditingController();
  final TextEditingController _travellingSpeedController = TextEditingController();
  File? _dlImage;
  bool? _wasPolicyHolderDriving = false;
  bool? _policeInformed = false;
  bool? _policeParticularsTaken = false;
  bool? _thirdPartyInvolved = false;
  bool? _injuryOrDeath = false;
  bool? _independentWitnesses = false;
  double _travellingSpeed = 40.0; // Speed slider value (0-100 KMPH)

  // Step 3: Police & Third Party
  final TextEditingController _firNumberController = TextEditingController();
  final TextEditingController _policeStationController = TextEditingController();
  final TextEditingController _thirdPartyNameController = TextEditingController();
  File? _firCopyImage;

  // Step 4: Other Details
  final List<Map<String, dynamic>> _injuryDetails = [];
  final TextEditingController _witnessNameController = TextEditingController();
  final TextEditingController _witnessContactController = TextEditingController();

  // Garage Selection
  String? _garageType; // 'network' or 'non-network'
  Map<String, dynamic>? _selectedGarage;
  final TextEditingController _garageSearchController = TextEditingController();
  final TextEditingController _nonNetworkGarageNameController = TextEditingController();
  final TextEditingController _nonNetworkGarageAddressController = TextEditingController();
  final TextEditingController _nonNetworkGarageContactController = TextEditingController();
  final TextEditingController _nonNetworkGarageEmailController = TextEditingController();
  List<Map<String, dynamic>> _garageList = [];
  bool _isLoadingGarages = false;
  int _garagePage = 1;
  int _garageTotalPages = 1;

  final ImagePicker _picker = ImagePicker();

  final List<String> _accidentCauses = [
    'Collision',
    'Hit & Run',
    'Self Accident',
    'Fire',
    'Theft',
    'Animal/Object Strike',
    'Natural Disaster',
  ];

  final List<String> _injuryNatures = [
    'Minor',
    'Moderate',
    'Severe',
    'Critical',
    'Fatal',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _accidentDateTimeController.dispose();
    _accidentLocationController.dispose();
    _vehicleCurrentLocationController.dispose();
    _damageBriefController.dispose();
    _driverNameController.dispose();
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
    _travellingSpeedController.dispose();
    _firNumberController.dispose();
    _policeStationController.dispose();
    _thirdPartyNameController.dispose();
    _witnessNameController.dispose();
    _witnessContactController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _accidentDateTimeController.text = DateFormat('dd/MM/yyyy hh:mm a').format(fullDateTime);
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _captureDL() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickDLImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickDLImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDLImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _dlImage = File(image.path);
          _isValidating = true;
        });

        await _extractDLDetails();

        setState(() {
          _isValidating = false;
        });
      }
    } catch (e) {
      print('Error capturing DL: $e');
      _showErrorSnackBar('Failed to capture image: $e');
      setState(() {
        _isValidating = false;
      });
    }
  }

  Future<void> _extractDLDetails() async {
    if (_dlImage == null) return;

    try {
      // Step 1: Validate the DL document first
      _showWarningSnackBar('Validating document...');
      
      final validationResult = await DocumentValidationService.validateDocument(
        _dlImage!,
        'DRIVING_LICENSE',
      );

      if (!validationResult['isValid']) {
        setState(() {
          _dlImage = null;
          _isValidating = false;
        });
        _showErrorSnackBar(
          validationResult['message'] ?? 'Invalid DL. Please capture a clear image of the Driving License.',
        );
        return;
      }

      // Step 2: Upload and extract DL details
      final uploadResponse = await ImageUploadService().uploadDlImage(_dlImage!);
      print('DL Upload Response: $uploadResponse');

      String? dlNumber;
      String? dob;

      if (uploadResponse is Map<String, dynamic>) {
        if (uploadResponse.containsKey('dl_number')) {
          dlNumber = uploadResponse['dl_number'];
        } else if (uploadResponse.containsKey('result') &&
            uploadResponse['result'] is Map &&
            uploadResponse['result']['output'] is Map) {
          dlNumber = uploadResponse['result']['output']['dl_number'];
          dob = uploadResponse['result']['output']['dob'];
        }
      }

      if (dlNumber != null) {
        setState(() {
          _licenseNumberController.text = dlNumber!;
        });

        final detailsResponse = await ImageUploadService().sendDlNumber(dlNumber, dob ?? '');
        
        if (detailsResponse.containsKey('result') && detailsResponse['result'] is Map) {
             var details = detailsResponse['result'];
             if (details['name'] != null) {
                 setState(() {
                   _driverNameController.text = details['name'];
                 });
             }
             if (details['validity'] != null && details['validity']['non-transport'] != null) {
                 String expiry = details['validity']['non-transport']['to'];
                 setState(() {
                   _licenseExpiryController.text = expiry;
                 });
             }
        }
        
        _showSuccessSnackBar('DL Details Extracted Successfully!');

      } else {
        throw Exception('Could not extract DL Number from image');
      }
    } catch (e) {
      print('DL Extraction Error: $e');
      _showWarningSnackBar('Failed to fetch DL details: $e. Please enter manually.');
    }
  }

  Future<void> _captureFIRCopy() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFIRImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFIRImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFIRImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _firCopyImage = File(image.path);
        });
        _showSuccessSnackBar('FIR copy captured successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture FIR copy');
    }
  }

  Future<void> _searchGarages(String query, {int page = 1}) async {
    setState(() {
      _isLoadingGarages = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://uat.goclaims.in/motor_iail/garage/search'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'page': page,
          'limit': 10,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _garageList = List<Map<String, dynamic>>.from(data['data']);
            _garagePage = data['page'];
            _garageTotalPages = (data['total'] / data['limit']).ceil();
            _isLoadingGarages = false;
          });
        }
      } else {
        throw Exception('Failed to load garages');
      }
    } catch (e) {
      print('Error searching garages: $e');
      setState(() {
        _isLoadingGarages = false;
      });
      _showErrorSnackBar('Failed to search garages: $e');
    }
  }

  bool _validateStep1() {
    return true;
  }

  bool _validateStep2() {
    return true;
  }

  bool _validateStep3() {
    return true;
  }

  bool _validateStep4() {
    return true;
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
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
        duration: Duration(seconds: 4),
      ),
    );
  }

  Widget _buildYesNoButtons({
    required String question,
    required bool? value,
    required Function(bool) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => onChanged(true),
                style: OutlinedButton.styleFrom(
                  backgroundColor: value == true ? Colors.green : Colors.white,
                  foregroundColor: value == true ? Colors.white : Colors.green,
                  side: BorderSide(
                    color: Colors.green,
                    width: 2,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Yes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () => onChanged(false),
                style: OutlinedButton.styleFrom(
                  backgroundColor: value == false ? Colors.red : Colors.white,
                  foregroundColor: value == false ? Colors.white : Colors.red,
                  side: BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'No',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  void _showAddInjuryDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController ageController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    String? selectedInjuryNature;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.person_add, color: Colors.blue.shade700),
                  SizedBox(width: 12),
                  Text('Add Injury/Fatality Details'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: ageController,
                      decoration: InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.home_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: 16),
                    Text('Nature of Injury', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _injuryNatures.map((nature) {
                        final isSelected = selectedInjuryNature == nature;
                        return ChoiceChip(
                          label: Text(nature),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedInjuryNature = selected ? nature : null;
                            });
                          },
                          selectedColor: Colors.blue.shade700,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      setState(() {
                        _injuryDetails.add({
                          'name': nameController.text,
                          'age': ageController.text,
                          'address': addressController.text,
                          'injury_nature': selectedInjuryNature ?? 'Not specified',
                        });
                      });
                      Navigator.pop(context);
                      _showSuccessSnackBar('Injury details added');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onStepContinue() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      _navigateToAccidentIntimation();
    }
  }

  void _skipCurrentStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _showWarningSnackBar('Step ${_currentStep} skipped');
    } else {
      _navigateToAccidentIntimation();
    }
  }

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
      'injury_or_death': _injuryOrDeath,
      'injury_details': _injuryDetails,
      'independent_witnesses': _independentWitnesses,
      'witness_name': _witnessNameController.text.trim(),
      'witness_contact': _witnessContactController.text.trim(),
    };

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

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getStepTitle(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
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
      body: FadeTransition(
        opacity: _animationController,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : 16,
              vertical: 20,
            ),
            child: Column(
              children: [
                _buildProgressIndicator(),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'All fields are optional. You can skip any step.',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                _buildCurrentStepContent(),
                SizedBox(height: 32),
                _buildActionButtons(),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Accident Snapshot';
      case 1:
        return 'Driver Verification';
      case 2:
        return 'Police & Third Party';
      case 3:
        return 'Additional Info';
      default:
        return 'Accident Details';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildAccidentSnapshotStep();
      case 1:
        return _buildDriverVerificationStep();
      case 2:
        return _buildPoliceThirdPartyStep();
      case 3:
        return _buildAdditionalInfoStep();
      default:
        return Container();
    }
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(4, (index) {
        final isCompleted = index < _currentStep;
        final isCurrent = index == _currentStep;

        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            decoration: BoxDecoration(
              gradient: isCompleted || isCurrent
                  ? LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
              )
                  : null,
              color: isCompleted || isCurrent ? null : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActionButtons() {
    final isLastStep = _currentStep == 3;

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

  // Step 1: Accident Snapshot - What, When, Where, Why
  Widget _buildAccidentSnapshotStep() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.blue.shade700, size: 28),
                SizedBox(width: 12),
                Text(
                  'Accident Snapshot',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'When, Where & Why',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            Divider(height: 32),
            
            // When - Accident Date & Time
            Text('When did the incident occur?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            SizedBox(height: 8),
            TextField(
              controller: _accidentDateTimeController,
              decoration: InputDecoration(
                labelText: 'Accident Date, Time & Location (as per Claimant)',
                prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
                suffixIcon: IconButton(
                  icon: Icon(Icons.edit_calendar, color: Colors.blue.shade700),
                  onPressed: () => _selectDateTime(context),
                ),
              ),
              readOnly: true,
              onTap: () => _selectDateTime(context),
            ),
            SizedBox(height: 20),
            
            // Where - Location
            Text('Where exactly did the incident happen?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            SizedBox(height: 8),
            TextField(
              controller: _accidentLocationController,
              decoration: InputDecoration(
                labelText: 'Accident Location',
                hintText: 'Enter location details',
                prefixIcon: Icon(Icons.location_on, color: Colors.blue.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 2,
            ),
            SizedBox(height: 20),
            
            // Why - Cause of Accident
            Text('What was the primary cause?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _causeOfAccident,
              decoration: InputDecoration(
                labelText: 'Cause of Accident',
                prefixIcon: Icon(Icons.info_outline, color: Colors.blue.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: _accidentCauses.map((cause) {
                return DropdownMenuItem(value: cause, child: Text(cause));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _causeOfAccident = value;
                });
              },
            ),
            SizedBox(height: 20),
            
            // Vehicle Current Location
            Text('Where is the vehicle currently?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            SizedBox(height: 8),
            TextField(
              controller: _vehicleCurrentLocationController,
              decoration: InputDecoration(
                labelText: 'Current Location (Garage/Home Address)',
                hintText: 'Enter current vehicle location',
                prefixIcon: Icon(Icons.garage, color: Colors.blue.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 2,
            ),
            SizedBox(height: 20),
            
            // Damage Description
            Text('In 2-3 lines, briefly describe the damage:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            SizedBox(height: 8),
            TextField(
              controller: _damageBriefController,
              decoration: InputDecoration(
                labelText: 'Brief Description of Damage',
                hintText: 'Describe the damage to your vehicle',
                prefixIcon: Icon(Icons.description, color: Colors.blue.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  // Step 2: Driver Verification
  Widget _buildDriverVerificationStep() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.blue.shade700, size: 28),
                SizedBox(width: 12),
                Text(
                  'Driver Verification',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Key Verification Details',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            Divider(height: 32),
            
            // Was Policy Holder Driving
            _buildYesNoButtons(
              question: 'Was the policyholder driving?',
              value: _wasPolicyHolderDriving,
              onChanged: (value) {
                setState(() {
                  _wasPolicyHolderDriving = value;
                });
              },
            ),
            SizedBox(height: 20),
            
            // Driver Name
            Text(
              _wasPolicyHolderDriving == false ? 'Name of the driver at the time of accident:' : 'Confirm Driver Name:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _driverNameController,
              decoration: InputDecoration(
                labelText: 'Driver Name',
                hintText: 'Enter driver\'s full name',
                prefixIcon: Icon(Icons.person, color: Colors.blue.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            SizedBox(height: 20),
            
            // License Number with Scan Button
            Text('Driver\'s Licence Number:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _licenseNumberController,
                    decoration: InputDecoration(
                      labelText: 'Licence Number',
                      hintText: 'Enter or scan DL',
                      prefixIcon: Icon(Icons.badge, color: Colors.blue.shade700),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.white, size: 24),
                    onPressed: _captureDL,
                    tooltip: 'Scan Driving License',
                  ),
                ),
              ],
            ),
            if (_dlImage != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'DL image captured successfully',
                      style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            if (_isValidating)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange.shade700),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Extracting DL details...',
                        style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 20),
            
            // License Expiry
            Text('Please confirm the Licence Expiry Date:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            SizedBox(height: 8),
            TextField(
              controller: _licenseExpiryController,
              decoration: InputDecoration(
                labelText: 'Driver Licence Expiry Date',
                prefixIcon: Icon(Icons.event, color: Colors.blue.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today, color: Colors.blue.shade700),
                  onPressed: () => _selectDate(context, _licenseExpiryController),
                ),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, _licenseExpiryController),
            ),
            SizedBox(height: 20),
            
            // Travelling Speed
            Text('What was the approximate speed just before impact?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            SizedBox(height: 8),
            TextField(
              controller: _travellingSpeedController,
              decoration: InputDecoration(
                labelText: 'Speed (KMPH)',
                hintText: 'Enter speed in KMPH',
                prefixIcon: Icon(Icons.speed, color: Colors.blue.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
                suffixText: 'km/h',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  // Step 3: Police & Third Party - Liability Check
  Widget _buildPoliceThirdPartyStep() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_police, color: Colors.blue.shade700, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Police & Legal',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                      ),
                      Text(
                        'Liability Check',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 32),
            
            // Police Informed
            _buildYesNoButtons(
              question: 'Did you report the incident to the Police (File FIR/GD)?',
              value: _policeInformed,
              onChanged: (value) {
                setState(() {
                  _policeInformed = value;
                });
              },
            ),
            
            if (_policeInformed == true) ...[
              SizedBox(height: 20),
              
              // Police Particulars Taken
              _buildYesNoButtons(
                question: 'Did the Police take particulars (FIR/GD Number)?',
                value: _policeParticularsTaken,
                onChanged: (value) {
                  setState(() {
                    _policeParticularsTaken = value;
                  });
                },
              ),
              
              if (_policeParticularsTaken == true) ...[
                SizedBox(height: 20),
                Text(
                  'Please share the FIR / General Diary (GD) Number and Police Station name:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _firNumberController,
                  decoration: InputDecoration(
                    labelText: 'FIR/GD Number',
                    hintText: 'Enter FIR or GD number',
                    prefixIcon: Icon(Icons.description, color: Colors.blue.shade700),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _policeStationController,
                  decoration: InputDecoration(
                    labelText: 'Police Station Name',
                    hintText: 'Enter police station name',
                    prefixIcon: Icon(Icons.location_city, color: Colors.blue.shade700),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _captureFIRCopy,
                  icon: Icon(_firCopyImage == null ? Icons.upload_file : Icons.check_circle),
                  label: Text(_firCopyImage == null ? 'Upload FIR Copy' : 'FIR Copy Uploaded ✓'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _firCopyImage == null ? Colors.blue.shade700 : Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ],
            ],
            
            Divider(height: 40),
            
            // Third Party Involved
            _buildYesNoButtons(
              question: 'Was any other vehicle, property, or person involved?',
              value: _thirdPartyInvolved,
              onChanged: (value) {
                setState(() {
                  _thirdPartyInvolved = value;
                });
              },
            ),
            
            if (_thirdPartyInvolved == true) ...[
              SizedBox(height: 20),
              Text(
                'Please provide the other vehicle\'s Registration Number (or owner name if property/person):',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _thirdPartyNameController,
                decoration: InputDecoration(
                  labelText: 'Third Party Details',
                  hintText: 'Registration No. / Owner Name',
                  prefixIcon: Icon(Icons.person_outline, color: Colors.blue.shade700),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Step 4: Additional Info
  Widget _buildAdditionalInfoStep() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 28),
                SizedBox(width: 12),
                Text(
                  'Additional Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Witnesses & Injury Details',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            Divider(height: 32),
            
            // Injury or Death
            _buildYesNoButtons(
              question: 'Was there any injury or fatality involved (including the driver)?',
              value: _injuryOrDeath,
              onChanged: (value) {
                setState(() {
                  _injuryOrDeath = value;
                });
              },
            ),
            
            if (_injuryOrDeath == true) ...[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Injury/Fatality Details',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        Text(
                          '${_injuryDetails.length} record(s) added',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddInjuryDialog,
                      icon: Icon(Icons.add, size: 18),
                      label: Text('Add Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              if (_injuryDetails.isNotEmpty) ...[
                SizedBox(height: 12),
                ..._injuryDetails.asMap().entries.map((entry) {
                  final index = entry.key;
                  final detail = entry.value;
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        child: Icon(Icons.person, color: Colors.red.shade700, size: 20),
                      ),
                      title: Text(detail['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Age: ${detail['age']}, Nature: ${detail['injury_nature']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _injuryDetails.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                }).toList(),
              ],
            ],
            
            Divider(height: 40),
            
            // Independent Witnesses
            _buildYesNoButtons(
              question: 'Are there any independent witnesses?',
              value: _independentWitnesses,
              onChanged: (value) {
                setState(() {
                  _independentWitnesses = value;
                });
              },
            ),
            
            if (_independentWitnesses == true) ...[
              SizedBox(height: 20),
              Text('Witness Details:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              SizedBox(height: 12),
              TextField(
                controller: _witnessNameController,
                decoration: InputDecoration(
                  labelText: 'Witness Name',
                  hintText: 'Enter witness full name',
                  prefixIcon: Icon(Icons.person, color: Colors.blue.shade700),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _witnessContactController,
                decoration: InputDecoration(
                  labelText: 'Witness Contact Number',
                  hintText: 'Enter contact number',
                  prefixIcon: Icon(Icons.phone, color: Colors.blue.shade700),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
            
            Divider(height: 40),
            
            // Garage Selection Header with blue left border
            Container(
              padding: EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.blue.shade700, width: 4),
                ),
              ),
              child: Text(
                'Garage Selection',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
              ),
            ),
            SizedBox(height: 20),
            
            // Garage Type Selection with improved UI
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _garageType = 'network';
                          _selectedGarage = null;
                          _garageList = [];
                          _garageSearchController.clear();
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _garageType == 'network' ? Colors.blue.shade700 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _garageType == 'network' ? Colors.blue.shade700 : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.business,
                              color: _garageType == 'network' ? Colors.white : Colors.grey.shade600,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Network Garage',
                                style: TextStyle(
                                  color: _garageType == 'network' ? Colors.white : Colors.grey.shade600,
                                  fontWeight: _garageType == 'network' ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _garageType = 'non-network';
                          _selectedGarage = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _garageType == 'non-network' ? Colors.orange.shade700 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _garageType == 'non-network' ? Colors.orange.shade700 : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store,
                              color: _garageType == 'non-network' ? Colors.white : Colors.grey.shade600,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Non-Network',
                                style: TextStyle(
                                  color: _garageType == 'non-network' ? Colors.white : Colors.grey.shade600,
                                  fontWeight: _garageType == 'non-network' ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Network Garage Search
            if (_garageType == 'network') ...[
              TextField(
                controller: _garageSearchController,
                decoration: InputDecoration(
                  labelText: 'Search Network Garage',
                  hintText: 'Enter garage name or location',
                  prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) {
                  _searchGarages(value);
                },
              ),
              SizedBox(height: 16),
              
              if (_isLoadingGarages)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
              
              if (!_isLoadingGarages && _garageList.isNotEmpty)
                Container(
                  constraints: BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _garageList.length,
                    itemBuilder: (context, index) {
                      final garage = _garageList[index];
                      final isSelected = _selectedGarage?['id'] == garage['id'];
                      
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Colors.blue.shade50,
                        leading: Icon(
                          Icons.garage,
                          color: isSelected ? Colors.blue.shade700 : Colors.grey,
                        ),
                        title: Text(
                          garage['garage_name'] ?? '',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${garage['garage_city']}, ${garage['garage_state']}'),
                            Text('Phone: ${garage['garage_phn_no']}'),
                            if (garage['distance_km'] != null)
                              Text('Distance: ${garage['distance_km'].toStringAsFixed(2)} km'),
                          ],
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Colors.blue.shade700)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedGarage = garage;
                          });
                        },
                      );
                    },
                  ),
                ),
              
              if (_selectedGarage != null)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Selected: ${_selectedGarage!['garage_name']}',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            
            // Non-Network Garage Manual Entry
            if (_garageType == 'non-network') ...[
              TextField(
                controller: _nonNetworkGarageNameController,
                decoration: InputDecoration(
                  labelText: 'Garage Name',
                  hintText: 'Enter garage name',
                  prefixIcon: Icon(Icons.store, color: Colors.orange.shade700),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nonNetworkGarageAddressController,
                decoration: InputDecoration(
                  labelText: 'Garage Address',
                  hintText: 'Enter complete address',
                  prefixIcon: Icon(Icons.location_on, color: Colors.orange.shade700),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nonNetworkGarageContactController,
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                  hintText: 'Enter garage contact number',
                  prefixIcon: Icon(Icons.phone, color: Colors.orange.shade700),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nonNetworkGarageEmailController,
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  hintText: 'Enter garage email',
                  prefixIcon: Icon(Icons.email, color: Colors.orange.shade700),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
