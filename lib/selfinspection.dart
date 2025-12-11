import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cameraimageupload.dart';
import 'package:path/path.dart';
import 'helpers/getCurrentPosition.dart';

class SelfInspection extends StatefulWidget {
  // final Map<String, dynamic> data; // Receive the data
  // SelfInspection({required this.data});
  final Function(List<String>) onImagesUpdated;
  SelfInspection({Key? key, required this.onImagesUpdated}) : super(key: key);

  @override
  State<SelfInspection> createState() => _SelfInspectionState();
}

class _SelfInspectionState extends State<SelfInspection> {
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    // Print the received data
    // print("Received data: ${widget.data}");
    }
  // Image data
  String frontSide = "";
  String frontRightHandSide = "";
  String driverSide = "";
  String rearRightHandSide = "";
  String rearSide = "";
  String rearLeftHandSide = "";
  String passengerSide = "";
  String frontLeftHandSide = "";
  String engineCompart = "";
  String chassisNo = "";
  String odometerCar = "";
  String regCert = "";
  String inspectionCert = "";
  String optional1 = "";
  String optional2 = "";

  // Timestamps and locations
  Map<String, DateTime> timestamps = {};
  Map<String, String> locations = {};

  bool showSubmit = false;
  bool uploading = false;

  Future<String?> fetchJwtToken() async {
    final String authApiUrl = "YOUR_AUTH_API_ENDPOINT_HERE";

    try {
      final response = await http.post(Uri.parse(authApiUrl));
      if (response.statusCode == 200) {
        final responseMap = json.decode(response.body);
        return responseMap["token"];
      } else {
        print('Failed to fetch JWT token. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching JWT token: $e');
      return null;
    }
  }

  Future<http.Response> sendImageToApi(String imagePath, String jwtToken) async {
    final String apiUrl = "http://164.52.202.251/fw_damage/create_fw_claim";

    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    final requestData = jsonEncode({'image': base64Image});

    return await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: requestData,
    );
  }



  final Map<String, String> staticImagePaths = {
    'frontSide': 'assets/IMG_20240710_162627_DRO.jpg',
    'frontRightHandSide': 'assets/IMG_20240710_162650_DRO.jpg',
    'driverSide': 'assets/IMG_20240710_162728_DRO.jpg',
    'rearRightHandSide': 'assets/TimePhoto_20240528_140150.jpg',
    'rearSide': 'assets/TimePhoto_20240528_140155.jpg',
    'rearLeftHandSide': 'assets/TimePhoto_20240528_140202.jpg',
    'passengerSide': 'assets/TimePhoto_20240528_140210.jpg',
    'frontLeftHandSide': 'assets/TimePhoto_20240713_181337.jpg',
    'engineCompart': 'assets/TimePhoto_20240713_181400.jpg',
    'chassisNo': 'assets/TimePhoto_20240713_181406.jpg',
    'odometerCar': 'assets/TimePhoto_20240713_181526.jpg',
  };
  Future<void> _submitImages() async {
    // Example data from the received data
    // Map<String, String> requestData = {
    //   "datepicker_date": widget.data['datepicker_date'] ?? '2024-08-19',
    //   "claim_number": widget.data[''] ?? 'IAIL APITest - 4',
    //   "location": widget.data['registered_at'] ?? 'Mumbai',
    //   "make": widget.data['maker_description'] ?? 'M & M',
    //   "select_model": widget.data['select_model'] ?? 'MARAZZO 7STR M8 MAR',
    //   "select_body_type": widget.data['body_type'] ?? 'Metallic',
    //   "select_variant": widget.data['maker_model'] ?? 'Car',
    //   "mfg_year": widget.data['manufacturing_date_formatted'] ?? '2024',
    //   "select_city": widget.data['registered_at'] ?? 'Tire 1',
    //   "paint_type": widget.data['color'] ?? 'Solid',
    //   "reg_date": widget.data['registration_date'] ?? '2014-08-19',
    //   "vehicle_number": widget.data['rc_number'] ?? 'MH02DD8596',
    //   "compulsory_excess": widget.data['compulsory_excess'] ?? 'Some value',
    //   "odometer": widget.data['odometer'] ?? '5000',
    //   "incident_location": widget.data['incident_location'] ?? 'Mumbai, khar',
    // };

    var uri = Uri.parse("http://164.52.202.251/fw_damage/create_fw_claim");
    var request = http.MultipartRequest('POST', uri);

    // Adding the fields to the request
    // requestData.forEach((key, value) {
    //   request.fields[key] = value;
    // });

    // Adding the images to the request
    for (var entry in staticImagePaths.entries) {
      var fileBytes = await rootBundle.load(entry.value);
      var file = http.MultipartFile.fromBytes(
        'images[]',
        fileBytes.buffer.asUint8List(),
        filename: basename(entry.value),
      );
      print('File path: ${entry.value}');
      // print('File path: ${requestData}');
      print('File path: ${file}');

      request.files.add(file);
    }

    request.headers.addAll({
      'Authorization': 'Bearer hii', // Replace with the actual token if needed
      'Content-Type': 'multipart/form-data',
    });

    try {
    var response = await request.send();

        if (response.statusCode == 200) {
          print('Successfully uploaded all images and data.');
          response.stream.transform(utf8.decoder).listen((value) {
            print('Response body: $value');
          });
        } else {
          response.stream.transform(utf8.decoder).listen((value) {
            print('Response body: $value');
          });
          print('Failed to upload data. Status: ${response.statusCode}');
        }
      } catch (e) {
        print('Error occurred while uploading data: $e');
      }

  }
  void disableSubmit() {
    if (frontSide.isNotEmpty &&
        frontRightHandSide.isNotEmpty &&
        driverSide.isNotEmpty &&
        rearRightHandSide.isNotEmpty &&
        rearSide.isNotEmpty &&
        rearLeftHandSide.isNotEmpty &&
        passengerSide.isNotEmpty &&
        frontLeftHandSide.isNotEmpty &&
        engineCompart.isNotEmpty &&
        chassisNo.isNotEmpty &&
        odometerCar.isNotEmpty) {
      setState(() {
        showSubmit = true;
      });
    }
  }

  Future<String> uploadImageToFirebase(String imagePath) async {
    try {
      final file = File(imagePath);

      // Create a reference to the Firebase Storage location
      final storageRef = FirebaseStorage.instance.ref().child(
          'images/${basename(file.path)}');

      // Upload the file
      final uploadTask = storageRef.putFile(file);

      // Wait for the upload to complete
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }
  void updateCameraImages(List<Map<String, String>> imageData) async {
    List<String> imageUrls = [];
    for (var data in imageData) {
      String imgPath = data["imgPath"] ?? "";
      DateTime timestamp = DateTime.parse(data["timestamp"] ?? "");
      String location = data["location"] ?? "";

      String downloadUrl = await uploadImageToFirebase(imgPath);
      print('Image uploaded to Firebase: $downloadUrl');
      imageUrls.add(downloadUrl);

      // Update local state with download URLs
      if (frontSide.isEmpty) frontSide = downloadUrl;
      else if (frontRightHandSide.isEmpty) frontRightHandSide = downloadUrl;
      else if (driverSide.isEmpty) driverSide = downloadUrl;
      else if (rearRightHandSide.isEmpty) rearRightHandSide = downloadUrl;
      else if (rearSide.isEmpty) rearSide = downloadUrl;
      else if (rearLeftHandSide.isEmpty) rearLeftHandSide = downloadUrl;
      else if (passengerSide.isEmpty) passengerSide = downloadUrl;
      else if (frontLeftHandSide.isEmpty) frontLeftHandSide = downloadUrl;
      else if (engineCompart.isEmpty) engineCompart = downloadUrl;
      else if (chassisNo.isEmpty) chassisNo = downloadUrl;
      else if (odometerCar.isEmpty) odometerCar = downloadUrl;

      timestamps[downloadUrl] = timestamp;
      locations[downloadUrl] = location;
    }

    // Update the parent with the list of image URLs
    widget.onImagesUpdated(imageUrls);
    disableSubmit();
  }
  void printImagePaths() {
    final imagePaths = getAllImagePaths();
    print('final Map<String, String> dynamicImagePaths = {');
    imagePaths.forEach((key, value) {
      print("  '$key': '$value',");
    });
    print('};');
  }
  Future<void> updateSingleImage(int idx, String path, DateTime time, String location) async {
    String downloadUrl = await uploadImageToFirebase(path);
    setState(() {
      switch (idx) {
        case 0: frontSide = downloadUrl; break;
        case 1: frontRightHandSide = downloadUrl; break;
        case 2: driverSide = downloadUrl; break;
        case 3: rearRightHandSide = downloadUrl; break;
        case 4: rearSide = downloadUrl; break;
        case 5: rearLeftHandSide = downloadUrl; break;
        case 6: passengerSide = downloadUrl; break;
        case 7: frontLeftHandSide = downloadUrl; break;
        case 8: engineCompart = downloadUrl; break;
        case 9: chassisNo = downloadUrl; break;
        case 10: odometerCar = downloadUrl; break;
      }
      widget.onImagesUpdated(getAllImagePaths().values.toList());
      timestamps[downloadUrl] = time;
      locations[downloadUrl] = location;
    });
    printImagePaths();
    disableSubmit();
  }
  Map<String, String> getAllImagePaths() {
    return {
      'frontSide': frontSide,
      'frontRightHandSide': frontRightHandSide,
      'driverSide': driverSide,
      'rearRightHandSide': rearRightHandSide,
      'rearSide': rearSide,
      'rearLeftHandSide': rearLeftHandSide,
      'passengerSide': passengerSide,
      'frontLeftHandSide': frontLeftHandSide,
      'engineCompart': engineCompart,
      'chassisNo': chassisNo,
      'odometerCar': odometerCar,
    };
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text("Are you sure you want to go back?"),
            content: Text("Going back will revert all your progress done till now"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text("Yes"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text("No"),
              ),
            ],
          ),
        ) ?? false;
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Text(
                    "Take the vehicle image using camera",
                    style: TextStyle(fontSize: 16, color: Colors.blue[900]),
                  ),
                  ElevatedButton(
                    child: Text(
                      odometerCar.isEmpty ? 'Take Images' : 'Retake Images',
                      style: TextStyle(fontSize: 16, color: Colors.blue[900]),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: Text("Image Upload Instructions"),
                          content: Text(
                            "The photos to be captured in proper day-light and open area only. Please do not click the photos in covered area such as garages, underground & parking areas etc.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CameraImageUpload(
                                      updateImageData: updateCameraImages,
                                      showTopBanner: false,
                                      appBarTitle: "",
                                      updateSingleImageData: (_, __, ___, ____) {},
                                      singleImageIndex: 0,
                                    ),
                                  ),
                                );
                              },
                              child: Text("Continue"),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.yellow),
                    ),
                  ),
                  if (odometerCar.isNotEmpty) ...[
                    buildImageSection("Front Side", frontSide, 0),
                    buildImageSection("Front RightHand Side", frontRightHandSide, 1),
                    buildImageSection("Driver Side", driverSide, 2),
                    buildImageSection("Rear RightHand Side", rearRightHandSide, 3),
                    buildImageSection("Rear Side", rearSide, 4),
                    buildImageSection("Rear LeftHand Side", rearLeftHandSide, 5),
                    buildImageSection("Passenger Side", passengerSide, 6),
                    buildImageSection("Front LeftHand Side", frontLeftHandSide, 7),
                    buildImageSection("Engine Compart", engineCompart, 8),
                    buildImageSection("Chassis Number", chassisNo, 9),
                    buildImageSection("Odometer Car", odometerCar, 10),
                  ],
                  SizedBox(height: 35),
                  if (showSubmit)
                    ElevatedButton(
                      child: Text(
                        "Submit Form",
                        style: TextStyle(fontSize: 16, color: Colors.blue[900]),
                      ),
                      onPressed: () async {
                        setState(() {
                          uploading = true;
                        });
                        await _submitImages();
                        setState(() {
                          uploading = false;
                        });
                        // Navigate to next screen or show success message
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.yellow),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (uploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.yellow),
                    SizedBox(height: 15),
                    Text(
                      "Uploading Images...",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildImageSection(String title, String imagePath, int index) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue[900]),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.yellow),
                  elevation: MaterialStateProperty.all(0),
                ),
                onPressed: () {
                  navigateToCameraImageUpload(isSingle: true, title: title, index: index);
                },
                child: Text("Retake", style: TextStyle(color: Colors.blue[900])),
              )
            ],
          ),
          if (imagePath.isNotEmpty) ...[
            imagePath.startsWith('http')
                ? Image.network(imagePath)
                : Image.file(File(imagePath)),
            Text(
              "Timestamp: ${timestamps[imagePath]}",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Location: ${locations[imagePath]}",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          SizedBox(height: 24),
        ],
      ),
    );
  }  void navigateToCameraImageUpload({required bool isSingle, required String title, required int index}) {
    Navigator.of(context as BuildContext).push(
      MaterialPageRoute(
        builder: (context) => CameraImageUpload(
          updateImageData: updateCameraImages,
          showTopBanner: !isSingle,
          appBarTitle: title,
          updateSingleImageData: updateSingleImage,
          singleImageIndex: index,
        ),
      ),
    );
  }
}
