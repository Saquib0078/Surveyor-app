// import 'dart:convert';
// import 'package:damagedetection1/AvailableClaims.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class otpenter extends StatefulWidget {
//   final String verificationId;
//   final String mobileNumber;
//
//   const otpenter({Key? key, required this.verificationId, required this.mobileNumber}) : super(key: key);
//
//   @override
//   State<otpenter> createState() => _otpenterState();
// }
//
// class _otpenterState extends State<otpenter> {
//   final otpControllers = List.generate(6, (_) => TextEditingController());
//   bool _isLoading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         child: SafeArea(
//           child: Container(
//             width: double.infinity,
//             height: MediaQuery.of(context).size.height,
//             padding: EdgeInsets.symmetric(horizontal: 30, vertical: 50),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: <Widget>[
//                 Align(
//                   alignment: Alignment.topLeft,
//                   child: GestureDetector(
//                     onTap: () {
//                       Get.back();
//                     },
//                     child: Icon(Icons.arrow_back, color: Colors.blue[900]),
//                   ),
//                 ),
//                 SizedBox(height: 30),
//                 Text(
//                   "OTP VERIFICATION",
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 25,
//                     color: Colors.blue[900],
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 Text(
//                   "Please Enter the OTP sent to your Mobile Number",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: Colors.blue[900],
//                     fontSize: 15,
//                   ),
//                 ),
//                 SizedBox(height: 30),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: List.generate(6, (index) {
//                     return Flexible(
//                       child: _textFieldOTP(index: index),
//                     );
//                   }),
//                 ),
//                 SizedBox(height: 30),
//                 _isLoading
//                     ? CircularProgressIndicator(color: Colors.yellow)
//                     : FloatingActionButton.extended(
//                   label: Text('Verify', style: TextStyle(color: Colors.blue[900])),
//                   backgroundColor: Colors.yellow,
//                   onPressed: _validateOTP,
//                   shape: RoundedRectangleBorder(
//                     side: BorderSide(color: Colors.blue[900]!, width: 2.0),
//                     borderRadius: BorderRadius.circular(30.0),
//                   ),
//                 ),
//                 SizedBox(height: 16),
//                 Text(
//                   "Did Not Receive OTP?",
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blue[900],
//                   ),
//                 ),
//                 SizedBox(height: 16),
//                 GestureDetector(
//                   onTap: () {
//                     // Implement resend OTP functionality here
//                   },
//                   child: Text(
//                     "Resend OTP",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue[900],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   Widget _textFieldOTP({required int index}) {
//     return Container(
//       height: 85,
//       child: AspectRatio(
//         aspectRatio: 0.7, // Adjusted aspect ratio
//         child: TextField(
//           controller: otpControllers[index],
//           autofocus: index == 0,
//           onChanged: (value) {
//             if (value.length == 1) {
//               FocusScope.of(context).nextFocus();
//             }
//             if (value.length == 0 && index != 0) {
//               FocusScope.of(context).previousFocus();
//             }
//           },
//           showCursor: false,
//           textAlign: TextAlign.center,
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
//           keyboardType: TextInputType.number,
//           maxLength: 1,
//           decoration: InputDecoration(
//             counter: Offstage(),
//             enabledBorder: OutlineInputBorder(
//               borderSide: BorderSide(width: 2, color: Colors.black12),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderSide: BorderSide(width: 2, color: Colors.blue[900]!),
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _validateOTP() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     final otp = otpControllers.map((controller) => controller.text).join();
//     final credential = PhoneAuthProvider.credential(
//       verificationId: widget.verificationId,
//       smsCode: otp,
//     );
//
//     try {
//       final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
//       if (userCredential.user != null) {
//         // Store user details in Firestore if needed
//         // Navigate to next page
//         Get.offAll(() => AvailableClaims(taskId: '',));
//       }
//     } catch (e) {
//       _showErrorDialog('Invalid OTP or an error occurred: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) => AlertDialog(
//         title: Text("Error", style: TextStyle(color: Colors.red)),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text("OK"),
//           ),
//         ],
//       ),
//     );
//   }
// }
