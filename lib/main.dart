import 'package:damagedetection1/ClaimStepperForm.dart';
import 'package:damagedetection1/SplahScreen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'AvailableClaims.dart';
import 'GoogleMapScreen.dart';
import 'Login.dart';
import 'SurveyorMapScreen.dart';
import 'otp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Firebase initialization commented out - not needed currently
  // bool firebaseInitialized = false;
  // 
  // try {
  //   if (kIsWeb) {
  //     await Firebase.initializeApp(
  //       options: FirebaseOptions(
  //         apiKey: "AIzaSyCj1qGhCQkAVwfciZ4m7EtCRfMNZPQsyWg",
  //         authDomain: "fir-ffb17.firebaseapp.com",
  //         projectId: "fir-ffb17",
  //         storageBucket: "fir-ffb17.appspot.com",
  //         messagingSenderId: "671277342571",
  //         appId: "1:671277342571:web:dfd03c005cf8834f05362e",
  //         measurementId: "G-7TR6JYMBT4",
  //       ),
  //     );
  //   } else {
  //     await Firebase.initializeApp();
  //   }
  //   firebaseInitialized = true;
  //   print('Firebase initialized successfully');
  // } catch (e) {
  //   print('Failed to initialize Firebase: $e');
  //   print('App will continue without Firebase features');
  // }

  try {
    // final user = firebaseInitialized ? FirebaseAuth.instance.currentUser : null;
    runApp(MyApp(initialRoute: '/splash'));
  } catch (e) {
    print('Error starting app: $e');
    // Fallback: run app anyway
    runApp(MyApp(initialRoute: '/splash'));
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Damage Detection',
      theme: _buildAppTheme(),
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/SurveyorMapScreen', page: () => SurveyorMapScreen()),
        GetPage(name: '/splash', page: () => SurveyorSplashScreen()),
        GetPage(
          name: '/map',
          page: () => GoogleMapScreen(
            onLocationSelected: (LatLng, bool) {},
          ),
        ),
      ],
    );
  }

  ThemeData _buildAppTheme() {
    const Color primaryBlue = Color(0xFF2196F3);
    const Color darkBlue = Color(0xFF1976D2);
    const Color lightBlue = Color(0xFF64B5F6);
    const Color accentOrange = Color(0xFFFF9800);
    const Color successGreen = Color(0xFF4CAF50);
    const Color errorRed = Color(0xFFF44336);
    const Color warningYellow = Color(0xFFFFC107);
    const Color backgroundColor = Color(0xFFF5F5F5);

    return ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        primaryContainer: lightBlue,
        secondary: accentOrange,
        secondaryContainer: Color(0xFFFFCC80),
        surface: Colors.white,
        background: backgroundColor,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF212121),
        onBackground: Color(0xFF212121),
        onError: Colors.white,
        brightness: Brightness.light,
      ),

      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundColor,

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF212121),
        titleTextStyle: TextStyle(
          color: Color(0xFF212121),
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(
          color: Color(0xFF212121),
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ✅ FIXED - Elevated Button Theme with proper text color
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white, // ✅ Ensures white text
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white, // ✅ Explicit white color
          ),
        ),
      ),

      // ✅ FIXED - Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue, // ✅ Blue text
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: primaryBlue, // ✅ Explicit blue color
          ),
        ),
      ),

      // ✅ FIXED - Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue, // ✅ Blue text
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
            color: primaryBlue, // ✅ Explicit blue color
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorRed, width: 2),
        ),
        labelStyle: TextStyle(
          fontSize: 14,
          color: Color(0xFF757575),
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          color: Color(0xFFBDBDBD),
        ),
        prefixIconColor: primaryBlue,
        suffixIconColor: Color(0xFF757575),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Color(0xFF9E9E9E),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFFE3F2FD),
        selectedColor: primaryBlue,
        secondarySelectedColor: primaryBlue,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: primaryBlue,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF757575),
        ),
      ),


      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF323232),
        contentTextStyle: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actionTextColor: accentOrange,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryBlue,
        linearTrackColor: Color(0xFFE3F2FD),
        circularTrackColor: Color(0xFFE3F2FD),
      ),

      dividerTheme: DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
        space: 1,
      ),

      iconTheme: IconThemeData(
        color: primaryBlue,
        size: 24,
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF212121),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF212121),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF757575),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF757575),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF212121),
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF212121),
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF757575),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryBlue;
          return Color(0xFFBDBDBD);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryBlue.withOpacity(0.5);
          return Color(0xFFE0E0E0);
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryBlue;
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryBlue;
          return Color(0xFF757575);
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlue,
        inactiveTrackColor: Color(0xFFE3F2FD),
        thumbColor: primaryBlue,
        overlayColor: primaryBlue.withOpacity(0.2),
        valueIndicatorColor: primaryBlue,
        valueIndicatorTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      tabBarTheme: TabBarTheme(
        labelColor: primaryBlue,
        unselectedLabelColor: const Color(0xFF757575),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryBlue, width: 3),
        ),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 8,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: primaryBlue,
        textColor: Color(0xFF212121),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}


// class LoginPage extends StatefulWidget {
//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _phoneController = TextEditingController();
//   bool _isLoading = false;
//
//   Future<void> _login() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });
//
//       final phoneNumber = "+91${_phoneController.text}";
//       final apiUrl = "http://164.52.211.138:6001/login/check-number";
//
//       try {
//         final response = await http.post(
//           Uri.parse(apiUrl),
//           headers: <String, String>{
//             'Content-Type': 'application/json; charset=UTF-8',
//           },
//           body: jsonEncode(<String, String>{
//             'CUST_MOBILE': phoneNumber,
//           }),
//         );
//
//         if (response.statusCode == 200) {
//           print(response.body);
//           final responseBody = jsonDecode(response.body);
//           if (responseBody['status'] == 'OTP sent') {
//             Get.to(() => otpenter(mobileNumber: phoneNumber));
//           } else {
//             _showErrorDialog(responseBody['message'] ?? 'Login failed');
//           }
//         } else {
//           _showErrorDialog('Your Number is not associated with any policies');
//         }
//       } catch (e) {
//         _showErrorDialog('An error occurred: $e');
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
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
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: SingleChildScrollView(
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: <Widget>[
//                   SizedBox(height: 30),
//                   Text(
//                     'Please Enter Your Phone Number',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue[900],
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   TextFormField(
//                     controller: _phoneController,
//                     decoration: InputDecoration(
//                       filled: true,
//                       fillColor: Colors.grey[200],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12.0),
//                         borderSide: BorderSide.none,
//                       ),
//                       prefix: Text("+91  "),
//                       prefixIcon: Icon(Icons.phone, color: Colors.blue[900]),
//                       labelText: 'Phone Number',
//                       labelStyle: TextStyle(color: Colors.blue[900]),
//                     ),
//                     keyboardType: TextInputType.phone,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your phone number';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 20),
//                   _isLoading
//                       ? CircularProgressIndicator(
//                           color: Colors.yellow,
//                         )
//                       : FloatingActionButton.extended(
//                           label: Text(
//                             'Enter',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                           backgroundColor: Colors.blue[900],
//                           onPressed: _login,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30.0),
//                           ),
//                         ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
// class _LoginPageState extends State<LoginPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _phoneController = TextEditingController();
//   bool _isLoading = false;
//
//   Future<void> _login() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });
//
//       final phoneNumber = "+91${_phoneController.text}";
//
//       try {
//         await FirebaseAuth.instance.verifyPhoneNumber(
//           phoneNumber: phoneNumber,
//           verificationCompleted: (PhoneAuthCredential credential) async {
//             // Auto-resolution of OTP
//             await FirebaseAuth.instance.signInWithCredential(credential);
//             Get.to(() => AvailableClaims(taskId: '',));
//           },
//           verificationFailed: (FirebaseAuthException e) {
//             _showErrorDialog(e.message ?? 'Verification failed');
//           },
//           codeSent: (String verificationId, int? resendToken) {
//             // Navigate to OTP screen with verificationId
//             Get.to(() => otpenter(
//                 verificationId: verificationId, mobileNumber: phoneNumber));
//           },
//           codeAutoRetrievalTimeout: (String verificationId) {},
//         );
//       } catch (e) {
//         _showErrorDialog('An error occurred: $e');
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
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
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: SingleChildScrollView(
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: <Widget>[
//                   SizedBox(height: 30),
//                   Text(
//                     'Please Enter Your Phone Number',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue[900],
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   TextFormField(
//                     controller: _phoneController,
//                     decoration: InputDecoration(
//                       filled: true,
//                       fillColor: Colors.grey[200],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12.0),
//                         borderSide: BorderSide.none,
//                       ),
//                       prefix: Text("+91  "),
//                       prefixIcon: Icon(Icons.phone, color: Colors.blue[900]),
//                       labelText: 'Phone Number',
//                       labelStyle: TextStyle(color: Colors.blue[900]),
//                     ),
//                     keyboardType: TextInputType.phone,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your phone number';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 20),
//                   _isLoading
//                       ? CircularProgressIndicator(
//                           color: Colors.yellow,
//                         )
//                       : FloatingActionButton.extended(
//                           label: Text(
//                             'Enter',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                           backgroundColor: Colors.blue[900],
//                           onPressed: _login,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30.0),
//                           ),
//                         ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
