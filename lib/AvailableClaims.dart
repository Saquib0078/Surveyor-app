// import 'dart:convert';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:damagedetection1/ClaimStepperForm.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
//
// import 'main.dart';
//
// class AvailableClaims extends StatefulWidget {
//   final String taskId; // Add taskId parameter
//
//   // Constructor
//   AvailableClaims({required this.taskId});
//
//   @override
//   _AvailableClaimsState createState() => _AvailableClaimsState();
// }
//
// class _AvailableClaimsState extends State<AvailableClaims> {
//
//   List<Map<String, String>> claims = [];
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore =
//       FirebaseFirestore.instance;
//   // Initialize Firestore
//
//   @override
//   void initState() {
//     super.initState();
//     String? userId = "TPAEuGVudySSi8dWgNKePq5behp1";
//
//     // final userId = _auth.currentUser?.uid;
//     // addSurveyors();
//     // uploadClaimsToFirestore(userId);
//     fetchClaimsFromFirestore(userId);
//   }
//
//
//   Future<void> addSurveyors() async {
//     CollectionReference surveyorsCollection = FirebaseFirestore.instance.collection('surveyors');
//
//     // Data for each surveyor
//     List<Map<String, dynamic>> surveyorsData = [
//       {
//         "email": "surveyor1@gmail.com",
//         "displayName": "Arjun Sharma",
//         "phoneNumber": "+919876543210",
//         "status": "available",
//         "location": {"lat": 28.613939, "long": 77.209021},
//         "assigned_tasks": 0,
//       },
//       {
//         "email": "surveyor2@gmail.com",
//         "displayName": "Pooja Nair",
//         "phoneNumber": "+919898765432",
//         "status": "available",
//         "location": {"lat": 19.076090, "long": 72.877426},
//         "assigned_tasks": 0,
//       },
//       {
//         "email": "surveyor3@gmail.com",
//         "displayName": "Rajesh Kumar",
//         "phoneNumber": "+918765432109",
//         "status": "available",
//         "location": {"lat": 12.971599, "long": 77.594566},
//         "assigned_tasks": 0,
//       },
//       {
//         "email": "surveyor4@gmail.com",
//         "displayName": "Sneha Verma",
//         "phoneNumber": "+919123456789",
//         "status": "available",
//         "location": {"lat": 13.082680, "long": 80.270718},
//         "assigned_tasks": 0,
//       },
//     ];
//
//     // Add each surveyor to Firestore
//     for (var surveyor in surveyorsData) {
//       await surveyorsCollection.add(surveyor);
//     }
//
//     print("Surveyors added successfully with auto-generated IDs");
//   }
//
//   void uploadClaimsToFirestore(String userId) async {
//     // Replace this with your JSON data
//     List<Map<String, dynamic>> claimsData = [
//       {
//         "ADD_INFO1": "Additional info 1",
//         "ADD_INFO3": "Additional info 3",
//         "BREAKIN_CREATED_DATE": "02-09-2024 10:00:00",
//         "BREAKIN_ID": "Testn1",
//         "BREAKIN_INSPECTION_BY": "Inspector X",
//         "BREAKIN_INSPECTION_VALID_UPTO": "14-08-2025 10:00:00",
//         "CASE_SOURCE_BY": "POSP",
//         "CHASSIS_NO": "CHASSIS123456",
//         "COMMUNICATION_ADDRESS": "Same Warangal",
//         "COMM_CITY": "Mumbai",
//         "COMM_STATE": "Maharashtra",
//         "CONTRACT_ADDRESS": "123, Main Street",
//         "CUST_CITY_NAME": "Mumbai",
//         "CUST_EMAIL": "harsha@gmail.com",
//         "CUST_MOBILE": "+919700905643",
//         "CUST_NAME": "Harsha",
//         "CUST_STATE_NAME": "Maharashtra",
//         "DOB": "02-08-1996",
//         "ENGINE_NO": "ENG123456",
//         "FINANCIER_NAME": "Financier Y",
//         "GENDER": "Male",
//         "IDV_AMT": "500000",
//         "INSURANCE_COMPANY": "ABC Insurance",
//         "MAKE_NAME": "Honda",
//         "MODEL_NAME": "City",
//         "PIN_CODE": "400001",
//         "POLICY_EFFECTIVE_DATE": "02-09-2024",
//         "POLICY_EXPIRY_DATE": "12-08-2025",
//         "POLICY_TYPE": "Comprehensive",
//         "POSP_EMAIL": "saquib@iail.com",
//         "POSP_ENROLLMENT_NO": "POSP12345",
//         "POSP_MOBILE_NO": "+919394851817",
//         "POSP_NAME": "Saquib",
//         "PREMIUM_AMOUNT": "15000",
//         "PREVIOUS_POLICY_NO": "P1234567890",
//         "PRE_INSURANCE_COMPANY": "Kotak Insurance",
//         "PRE_POLICY_TYPE": "Third Party",
//         "QUOTATION_ID": "Q123",
//         "REGISTRATION_NO": "AP363214",
//         "RM_EMAIL_ID": "mahir@iail.com",
//         "RM_MOBILE_NO": "+919876543212",
//         "RM_NAME": "Mahir",
//         "ROLE": "User",
//         "RTO_CITY": "Mumbai",
//         "SOURCE_NAME": "Referral",
//         "VARIANT_NAME": "EX",
//         "VECHILE_MAKE": "Honda",
//         "VECHILE_MODEL": "City",
//         "VECHILE_REG_NO": "AP363214",
//         "VEHICLE_TYPE": "Car",
//         "YEAR_OF_MANUFACTURE": "2020"
//       },
//       {
//         "ADD_INFO1": "Additional info 2",
//         "ADD_INFO3": "Additional info 4",
//         "BREAKIN_CREATED_DATE": "03-09-2024 11:00:00",
//         "BREAKIN_ID": "Testn2",
//         "BREAKIN_INSPECTION_BY": "Inspector Y",
//         "BREAKIN_INSPECTION_VALID_UPTO": "15-08-2025 11:00:00",
//         "CASE_SOURCE_BY": "POSP",
//         "CHASSIS_NO": "CHASSIS234567",
//         "COMMUNICATION_ADDRESS": "Different Address",
//         "COMM_CITY": "Pune",
//         "COMM_STATE": "Maharashtra",
//         "CONTRACT_ADDRESS": "456, Main Street",
//         "CUST_CITY_NAME": "Pune",
//         "CUST_EMAIL": "neha@gmail.com",
//         "CUST_MOBILE": "+919876543210",
//         "CUST_NAME": "Neha",
//         "CUST_STATE_NAME": "Maharashtra",
//         "DOB": "05-09-1990",
//         "ENGINE_NO": "ENG234567",
//         "FINANCIER_NAME": "Financier Z",
//         "GENDER": "Female",
//         "IDV_AMT": "600000",
//         "INSURANCE_COMPANY": "XYZ Insurance",
//         "MAKE_NAME": "Toyota",
//         "MODEL_NAME": "Corolla",
//         "PIN_CODE": "411001",
//         "POLICY_EFFECTIVE_DATE": "03-09-2024",
//         "POLICY_EXPIRY_DATE": "13-08-2025",
//         "POLICY_TYPE": "Third Party",
//         "POSP_EMAIL": "neha@iail.com",
//         "POSP_ENROLLMENT_NO": "POSP23456",
//         "POSP_MOBILE_NO": "+919493848181",
//         "POSP_NAME": "Neha",
//         "PREMIUM_AMOUNT": "20000",
//         "PREVIOUS_POLICY_NO": "P2345678901",
//         "PRE_INSURANCE_COMPANY": "ICICI Insurance",
//         "PRE_POLICY_TYPE": "Comprehensive",
//         "QUOTATION_ID": "Q124",
//         "REGISTRATION_NO": "MH12AB1234",
//         "RM_EMAIL_ID": "ravi@iail.com",
//         "RM_MOBILE_NO": "+919765432109",
//         "RM_NAME": "Ravi",
//         "ROLE": "Admin",
//         "RTO_CITY": "Pune",
//         "SOURCE_NAME": "Referral",
//         "VARIANT_NAME": "ZX",
//         "VECHILE_MAKE": "Toyota",
//         "VECHILE_MODEL": "Corolla",
//         "VECHILE_REG_NO": "MH12AB1234",
//         "VEHICLE_TYPE": "Car",
//         "YEAR_OF_MANUFACTURE": "2021"
//       },
//       {
//         "ADD_INFO1": "Additional info 3",
//         "ADD_INFO3": "Additional info 5",
//         "BREAKIN_CREATED_DATE": "04-09-2024 12:00:00",
//         "BREAKIN_ID": "Testn3",
//         "BREAKIN_INSPECTION_BY": "Inspector Z",
//         "BREAKIN_INSPECTION_VALID_UPTO": "16-08-2025 12:00:00",
//         "CASE_SOURCE_BY": "POSP",
//         "CHASSIS_NO": "CHASSIS345678",
//         "COMMUNICATION_ADDRESS": "Another Address",
//         "COMM_CITY": "Nagpur",
//         "COMM_STATE": "Maharashtra",
//         "CONTRACT_ADDRESS": "789, Main Street",
//         "CUST_CITY_NAME": "Nagpur",
//         "CUST_EMAIL": "aman@gmail.com",
//         "CUST_MOBILE": "+919998877665",
//         "CUST_NAME": "Aman",
//         "CUST_STATE_NAME": "Maharashtra",
//         "DOB": "06-10-1992",
//         "ENGINE_NO": "ENG345678",
//         "FINANCIER_NAME": "Financier A",
//         "GENDER": "Male",
//         "IDV_AMT": "700000",
//         "INSURANCE_COMPANY": "LMN Insurance",
//         "MAKE_NAME": "Ford",
//         "MODEL_NAME": "Fiesta",
//         "PIN_CODE": "440001",
//         "POLICY_EFFECTIVE_DATE": "04-09-2024",
//         "POLICY_EXPIRY_DATE": "14-08-2025",
//         "POLICY_TYPE": "Comprehensive",
//         "POSP_EMAIL": "aman@iail.com",
//         "POSP_ENROLLMENT_NO": "POSP34567",
//         "POSP_MOBILE_NO": "+919595959595",
//         "POSP_NAME": "Aman",
//         "PREMIUM_AMOUNT": "18000",
//         "PREVIOUS_POLICY_NO": "P3456789012",
//         "PRE_INSURANCE_COMPANY": "HDFC Insurance",
//         "PRE_POLICY_TYPE": "Comprehensive",
//         "QUOTATION_ID": "Q125",
//         "REGISTRATION_NO": "MH13CD5678",
//         "RM_EMAIL_ID": "preet@iail.com",
//         "RM_MOBILE_NO": "+919876543210",
//         "RM_NAME": "Preet",
//         "ROLE": "User",
//         "RTO_CITY": "Nagpur",
//         "SOURCE_NAME": "Online",
//         "VARIANT_NAME": "Trend",
//         "VECHILE_MAKE": "Ford",
//         "VECHILE_MODEL": "Fiesta",
//         "VECHILE_REG_NO": "MH13CD5678",
//         "VEHICLE_TYPE": "Car",
//         "YEAR_OF_MANUFACTURE": "2022"
//       },
//       {
//         "ADD_INFO1": "Additional info 4",
//         "ADD_INFO3": "Additional info 6",
//         "BREAKIN_CREATED_DATE": "05-09-2024 13:00:00",
//         "BREAKIN_ID": "Testn4",
//         "BREAKIN_INSPECTION_BY": "Inspector A",
//         "BREAKIN_INSPECTION_VALID_UPTO": "17-08-2025 13:00:00",
//         "CASE_SOURCE_BY": "POSP",
//         "CHASSIS_NO": "CHASSIS456789",
//         "COMMUNICATION_ADDRESS": "Different Address 2",
//         "COMM_CITY": "Aurangabad",
//         "COMM_STATE": "Maharashtra",
//         "CONTRACT_ADDRESS": "101, Main Street",
//         "CUST_CITY_NAME": "Aurangabad",
//         "CUST_EMAIL": "deepak@gmail.com",
//         "CUST_MOBILE": "+919876543211",
//         "CUST_NAME": "Deepak",
//         "CUST_STATE_NAME": "Maharashtra",
//         "DOB": "07-11-1985",
//         "ENGINE_NO": "ENG456789",
//         "FINANCIER_NAME": "Financier B",
//         "GENDER": "Male",
//         "IDV_AMT": "800000",
//         "INSURANCE_COMPANY": "PQR Insurance",
//         "MAKE_NAME": "Hyundai",
//         "MODEL_NAME": "i20",
//         "PIN_CODE": "431001",
//         "POLICY_EFFECTIVE_DATE": "05-09-2024",
//         "POLICY_EXPIRY_DATE": "15-08-2025",
//         "POLICY_TYPE": "Third Party",
//         "POSP_EMAIL": "deepak@iail.com",
//         "POSP_ENROLLMENT_NO": "POSP45678",
//         "POSP_MOBILE_NO": "+919676565656",
//         "POSP_NAME": "Deepak",
//         "PREMIUM_AMOUNT": "16000",
//         "PREVIOUS_POLICY_NO": "P4567890123",
//         "PRE_INSURANCE_COMPANY": "SBI Insurance",
//         "PRE_POLICY_TYPE": "Comprehensive",
//         "QUOTATION_ID": "Q126",
//         "REGISTRATION_NO": "MH14EF6789",
//         "RM_EMAIL_ID": "sita@iail.com",
//         "RM_MOBILE_NO": "+919565656565",
//         "RM_NAME": "Sita",
//         "ROLE": "User",
//         "RTO_CITY": "Aurangabad",
//         "SOURCE_NAME": "Direct",
//         "VARIANT_NAME": "Sportz",
//         "VECHILE_MAKE": "Hyundai",
//         "VECHILE_MODEL": "i20",
//         "VECHILE_REG_NO": "MH14EF6789",
//         "VEHICLE_TYPE": "Car",
//         "YEAR_OF_MANUFACTURE": "2023"
//       },
//       {
//         "ADD_INFO1": "Additional info 5",
//         "ADD_INFO3": "Additional info 7",
//         "BREAKIN_CREATED_DATE": "06-09-2024 14:00:00",
//         "BREAKIN_ID": "Testn5",
//         "BREAKIN_INSPECTION_BY": "Inspector B",
//         "BREAKIN_INSPECTION_VALID_UPTO": "18-08-2025 14:00:00",
//         "CASE_SOURCE_BY": "POSP",
//         "CHASSIS_NO": "CHASSIS567890",
//         "COMMUNICATION_ADDRESS": "New Address",
//         "COMM_CITY": "Kolhapur",
//         "COMM_STATE": "Maharashtra",
//         "CONTRACT_ADDRESS": "202, Main Street",
//         "CUST_CITY_NAME": "Kolhapur",
//         "CUST_EMAIL": "anu@gmail.com",
//         "CUST_MOBILE": "+919876543212",
//         "CUST_NAME": "Anu",
//         "CUST_STATE_NAME": "Maharashtra",
//         "DOB": "08-12-1988",
//         "ENGINE_NO": "ENG567890",
//         "FINANCIER_NAME": "Financier C",
//         "GENDER": "Female",
//         "IDV_AMT": "900000",
//         "INSURANCE_COMPANY": "STU Insurance",
//         "MAKE_NAME": "Maruti",
//         "MODEL_NAME": "Swift",
//         "PIN_CODE": "416001",
//         "POLICY_EFFECTIVE_DATE": "06-09-2024",
//         "POLICY_EXPIRY_DATE": "16-08-2025",
//         "POLICY_TYPE": "Comprehensive",
//         "POSP_EMAIL": "anu@iail.com",
//         "POSP_ENROLLMENT_NO": "POSP56789",
//         "POSP_MOBILE_NO": "+919656565656",
//         "POSP_NAME": "Anu",
//         "PREMIUM_AMOUNT": "17000",
//         "PREVIOUS_POLICY_NO": "P5678901234",
//         "PRE_INSURANCE_COMPANY": "Axis Insurance",
//         "PRE_POLICY_TYPE": "Third Party",
//         "QUOTATION_ID": "Q127",
//         "REGISTRATION_NO": "MH15GH8901",
//         "RM_EMAIL_ID": "komal@iail.com",
//         "RM_MOBILE_NO": "+919575757575",
//         "RM_NAME": "Komal",
//         "ROLE": "User",
//         "RTO_CITY": "Kolhapur",
//         "SOURCE_NAME": "Direct",
//         "VARIANT_NAME": "VXI",
//         "VECHILE_MAKE": "Maruti",
//         "VECHILE_MODEL": "Swift",
//         "VECHILE_REG_NO": "MH15GH8901",
//         "VEHICLE_TYPE": "Car",
//         "YEAR_OF_MANUFACTURE": "2024"
//       },
//       {
//         "ADD_INFO1": "Additional info 6",
//         "ADD_INFO3": "Additional info 8",
//         "BREAKIN_CREATED_DATE": "07-09-2024 15:00:00",
//         "BREAKIN_ID": "Testn6",
//         "BREAKIN_INSPECTION_BY": "Inspector C",
//         "BREAKIN_INSPECTION_VALID_UPTO": "19-08-2025 15:00:00",
//         "CASE_SOURCE_BY": "POSP",
//         "CHASSIS_NO": "CHASSIS678901",
//         "COMMUNICATION_ADDRESS": "Another Address 3",
//         "COMM_CITY": "Solapur",
//         "COMM_STATE": "Maharashtra",
//         "CONTRACT_ADDRESS": "303, Main Street",
//         "CUST_CITY_NAME": "Solapur",
//         "CUST_EMAIL": "pallavi@gmail.com",
//         "CUST_MOBILE": "+919343434343",
//         "CUST_NAME": "Pallavi",
//         "CUST_STATE_NAME": "Maharashtra",
//         "DOB": "09-01-1994",
//         "ENGINE_NO": "ENG678901",
//         "FINANCIER_NAME": "Financier D",
//         "GENDER": "Female",
//         "IDV_AMT": "1000000",
//         "INSURANCE_COMPANY": "UVW Insurance",
//         "MAKE_NAME": "Chevrolet",
//         "MODEL_NAME": "Sail",
//         "PIN_CODE": "413001",
//         "POLICY_EFFECTIVE_DATE": "07-09-2024",
//         "POLICY_EXPIRY_DATE": "17-08-2025",
//         "POLICY_TYPE": "Comprehensive",
//         "POSP_EMAIL": "pallavi@iail.com",
//         "POSP_ENROLLMENT_NO": "POSP67890",
//         "POSP_MOBILE_NO": "+919737373737",
//         "POSP_NAME": "Pallavi",
//         "PREMIUM_AMOUNT": "19000",
//         "PREVIOUS_POLICY_NO": "P6789012345",
//         "PRE_INSURANCE_COMPANY": "Kotak Insurance",
//         "PRE_POLICY_TYPE": "Comprehensive",
//         "QUOTATION_ID": "Q128",
//         "REGISTRATION_NO": "MH16IJ9012",
//         "RM_EMAIL_ID": "anil@iail.com",
//         "RM_MOBILE_NO": "+919262626262",
//         "RM_NAME": "Anil",
//         "ROLE": "Admin",
//         "RTO_CITY": "Solapur",
//         "SOURCE_NAME": "Online",
//         "VARIANT_NAME": "LTZ",
//         "VECHILE_MAKE": "Chevrolet",
//         "VECHILE_MODEL": "Sail",
//         "VECHILE_REG_NO": "MH16IJ9012",
//         "VEHICLE_TYPE": "Car",
//         "YEAR_OF_MANUFACTURE": "2022"
//       },
//       {
//         "ADD_INFO1": "Additional info 7",
//         "ADD_INFO3": "Additional info 9",
//         "BREAKIN_CREATED_DATE": "08-09-2024 16:00:00",
//         "BREAKIN_ID": "Testn7",
//         "BREAKIN_INSPECTION_BY": "Inspector D",
//         "BREAKIN_INSPECTION_VALID_UPTO": "20-08-2025 16:00:00",
//         "CASE_SOURCE_BY": "POSP",
//         "CHASSIS_NO": "CHASSIS789012",
//         "COMMUNICATION_ADDRESS": "New Address 2",
//         "COMM_CITY": "Nashik",
//         "COMM_STATE": "Maharashtra",
//         "CONTRACT_ADDRESS": "404, Main Street",
//         "CUST_CITY_NAME": "Nashik",
//         "CUST_EMAIL": "raj@gmail.com",
//         "CUST_MOBILE": "+919292929292",
//         "CUST_NAME": "Raj",
//         "CUST_STATE_NAME": "Maharashtra",
//         "DOB": "10-02-1987",
//         "ENGINE_NO": "ENG789012",
//         "FINANCIER_NAME": "Financier E",
//         "GENDER": "Male",
//         "IDV_AMT": "1100000",
//         "INSURANCE_COMPANY": "XYZ Insurance",
//         "MAKE_NAME": "Nissan",
//         "MODEL_NAME": "Altima",
//         "PIN_CODE": "422001",
//         "POLICY_EFFECTIVE_DATE": "08-09-2024",
//         "POLICY_EXPIRY_DATE": "18-08-2025",
//         "POLICY_TYPE": "Third Party",
//         "POSP_EMAIL": "raj@iail.com",
//         "POSP_ENROLLMENT_NO": "POSP78901",
//         "POSP_MOBILE_NO": "+919838383838",
//         "POSP_NAME": "Raj",
//         "PREMIUM_AMOUNT": "20000",
//         "PREVIOUS_POLICY_NO": "P7890123456",
//         "PRE_INSURANCE_COMPANY": "HDFC Insurance",
//         "PRE_POLICY_TYPE": "Third Party",
//         "QUOTATION_ID": "Q129",
//         "REGISTRATION_NO": "MH17JK0123",
//         "RM_EMAIL_ID": "simran@iail.com",
//         "RM_MOBILE_NO": "+919383838383",
//         "RM_NAME": "Simran",
//         "ROLE": "User",
//         "RTO_CITY": "Nashik",
//         "SOURCE_NAME": "Direct",
//         "VARIANT_NAME": "SL",
//         "VECHILE_MAKE": "Nissan",
//         "VECHILE_MODEL": "Altima",
//         "VECHILE_REG_NO": "MH17JK0123",
//         "VEHICLE_TYPE": "Car",
//         "YEAR_OF_MANUFACTURE": "2023"
//       },
//       {
//         "ADD_INFO1": "Additional info 8",
//         "ADD_INFO3": "Additional info 10",
//         "BREAKIN_CREATED_DATE": "09-09-2024 17:00:00",
//         "BREAKIN_ID": "Testn8",
//         "BREAKIN_INSPECTION_BY": "Inspector E",
//         "BREAKIN_INSPECTION_VALID_UPTO": "21-08-2025 17:00:00",
//         "CASE_SOURCE_BY": "POSP",
//         "CHASSIS_NO": "CHASSIS890123",
//         "COMMUNICATION_ADDRESS": "Another Address 4",
//         "COMM_CITY": "Satara",
//         "COMM_STATE": "Maharashtra",
//         "CONTRACT_ADDRESS": "505, Main Street",
//         "CUST_CITY_NAME": "Satara",
//         "CUST_EMAIL": "sanjay@gmail.com",
//         "CUST_MOBILE": "+919191919191",
//         "CUST_NAME": "Sanjay",
//         "CUST_STATE_NAME": "Maharashtra",
//         "DOB": "11-03-1995",
//         "ENGINE_NO": "ENG890123",
//         "FINANCIER_NAME": "Financier F",
//         "GENDER": "Male",
//         "IDV_AMT": "1200000",
//         "INSURANCE_COMPANY": "RST Insurance",
//         "MAKE_NAME": "Tata",
//         "MODEL_NAME": "Hexa",
//         "PIN_CODE": "415001",
//         "POLICY_EFFECTIVE_DATE": "09-09-2024",
//         "POLICY_EXPIRY_DATE": "19-08-2025",
//         "POLICY_TYPE": "Comprehensive",
//         "POSP_EMAIL": "sanjay@iail.com",
//         "POSP_ENROLLMENT_NO": "POSP89012",
//         "POSP_MOBILE_NO": "+919272727272",
//         "POSP_NAME": "Sanjay",
//         "PREMIUM_AMOUNT": "21000",
//         "PREVIOUS_POLICY_NO": "P8901234567",
//         "PRE_INSURANCE_COMPANY": "Axis Insurance",
//         "PRE_POLICY_TYPE": "Comprehensive",
//         "QUOTATION_ID": "Q130",
//         "REGISTRATION_NO": "MH18LM3456",
//         "RM_EMAIL_ID": "neeta@iail.com",
//         "RM_MOBILE_NO": "+919191919191",
//         "RM_NAME": "Neeta",
//         "ROLE": "Admin",
//         "RTO_CITY": "Satara",
//         "SOURCE_NAME": "Referral",
//         "VARIANT_NAME": "XTA",
//         "VECHILE_MAKE": "Tata",
//         "VECHILE_MODEL": "Hexa",
//         "VECHILE_REG_NO": "MH18LM3456",
//         "VEHICLE_TYPE": "SUV",
//         "YEAR_OF_MANUFACTURE": "2022"
//       },
//       {
//         "ADD_INFO1": "Additional info 9",
//         "ADD_INFO3": "Additional info 11",
//         "BREAKIN_CREATED_DATE": "10-09-2024 18:00:00",
//         "BREAKIN_ID": "Testn9",
//         "BREAKIN_INSPECTION_BY": "Inspector F",
//         "BREAKIN_INSPECTION_VALID_UPTO": "22-08-2025 18:00:00",
//         "CASE_SOURCE_BY": "POSP",
//         "CHASSIS_NO": "CHASSIS901234",
//         "COMMUNICATION_ADDRESS": "Different Address 3",
//         "COMM_CITY": "Latur",
//         "COMM_STATE": "Maharashtra",
//         "CONTRACT_ADDRESS": "606, Main Street",
//         "CUST_CITY_NAME": "Latur",
//         "CUST_EMAIL": "vikas@gmail.com",
//         "CUST_MOBILE": "+919292929292",
//         "CUST_NAME": "Vikas",
//         "CUST_STATE_NAME": "Maharashtra",
//         "DOB": "12-04-1989",
//         "ENGINE_NO": "ENG901234",
//         "FINANCIER_NAME": "Financier G",
//         "GENDER": "Male",
//         "IDV_AMT": "1300000",
//         "INSURANCE_COMPANY": "UVWX Insurance",
//         "MAKE_NAME": "Renault",
//         "MODEL_NAME": "Duster",
//         "PIN_CODE": "413002",
//         "POLICY_EFFECTIVE_DATE": "10-09-2024",
//         "POLICY_EXPIRY_DATE": "20-08-2025",
//         "POLICY_TYPE": "Third Party",
//         "POSP_EMAIL": "vikas@iail.com",
//         "POSP_ENROLLMENT_NO": "POSP90123",
//         "POSP_MOBILE_NO": "+919383838383",
//         "POSP_NAME": "Vikas",
//         "PREMIUM_AMOUNT": "22000",
//         "PREVIOUS_POLICY_NO": "P9012345678",
//         "PRE_INSURANCE_COMPANY": "Kotak Insurance",
//         "PRE_POLICY_TYPE": "Third Party",
//         "QUOTATION_ID": "Q131",
//         "REGISTRATION_NO": "MH19NO4567",
//         "RM_EMAIL_ID": "ravi@iail.com",
//         "RM_MOBILE_NO": "+919262626262",
//         "RM_NAME": "Ravi",
//         "ROLE": "User",
//         "RTO_CITY": "Latur",
//         "SOURCE_NAME": "Online",
//         "VARIANT_NAME": "RXZ",
//         "VECHILE_MAKE": "Renault",
//         "VECHILE_MODEL": "Duster",
//         "VECHILE_REG_NO": "MH19NO4567",
//         "VEHICLE_TYPE": "SUV",
//         "YEAR_OF_MANUFACTURE": "2023"
//       },
//       {
//         "ADD_INFO1": "Additional info 10",
//         "ADD_INFO3": "Additional info 12",
//         "BREAKIN_CREATED_DATE": "11-09-2024 19:00:00",
//         "BREAKIN_ID": "Testn10",
//         "BREAKIN_INSPECTION_BY": "Inspector G",
//         "BREAKIN_INSPECTION_VALID_UPTO": "23-08-2025 19:00:00",
//         "CASE_SOURCE_BY": "POSP",
//         "CHASSIS_NO": "CHASSIS012345",
//         "COMMUNICATION_ADDRESS": "New Address 4",
//         "COMM_CITY": "Jalgaon",
//         "COMM_STATE": "Maharashtra",
//         "CONTRACT_ADDRESS": "707, Main Street",
//         "CUST_CITY_NAME": "Jalgaon",
//         "CUST_EMAIL": "deepika@gmail.com",
//         "CUST_MOBILE": "+919101010101",
//         "CUST_NAME": "Deepika",
//         "CUST_STATE_NAME": "Maharashtra",
//         "DOB": "13-05-1983",
//         "ENGINE_NO": "ENG012345",
//         "FINANCIER_NAME": "Financier H",
//         "GENDER": "Female",
//         "IDV_AMT": "1400000",
//         "INSURANCE_COMPANY": "XYZ Insurance",
//         "MAKE_NAME": "BMW",
//         "MODEL_NAME": "X1",
//         "PIN_CODE": "425001",
//         "POLICY_EFFECTIVE_DATE": "11-09-2024",
//         "POLICY_EXPIRY_DATE": "21-08-2025",
//         "POLICY_TYPE": "Comprehensive",
//         "POSP_EMAIL": "deepika@iail.com",
//         "POSP_ENROLLMENT_NO": "POSP01234",
//         "POSP_MOBILE_NO": "+919171717171",
//         "POSP_NAME": "Deepika",
//         "PREMIUM_AMOUNT": "25000",
//         "PREVIOUS_POLICY_NO": "P0123456789",
//         "PRE_INSURANCE_COMPANY": "HDFC Insurance",
//         "PRE_POLICY_TYPE": "Comprehensive",
//         "QUOTATION_ID": "Q132",
//         "REGISTRATION_NO": "MH20PQ7890",
//         "RM_EMAIL_ID": "anu@iail.com",
//         "RM_MOBILE_NO": "+919565656565",
//         "RM_NAME": "Anu",
//         "ROLE": "Admin",
//         "RTO_CITY": "Jalgaon",
//         "SOURCE_NAME": "Referral",
//         "VARIANT_NAME": "Sport",
//         "VECHILE_MAKE": "BMW",
//         "VECHILE_MODEL": "X1",
//         "VECHILE_REG_NO": "MH20PQ7890",
//         "VEHICLE_TYPE": "SUV",
//         "YEAR_OF_MANUFACTURE": "2022"
//       }
//
//     ];
//
//
//     for (var claim in claimsData) {
//       // Generate a new document ID for each claim
//       String claimId = claim['BREAKIN_ID'];
//       final claimDocRef = _firestore
//           .collection('claims')
//           .doc(userId)
//           .collection('userClaims')
//           .doc(claimId);
//
//       // Set the data in Firestore
//       await claimDocRef.set(claim);
//     }
//
//     print('All claims uploaded successfully!');
//   }
//   Future<void> fetchClaimsFromFirestore(String userId) async {
//     try {
//       // Reference to the user's claims collection
//       final claimsRef = _firestore.collection('claims').doc(userId).collection('userClaims');
//
//       // Fetch all documents in the user's claims collection
//       final querySnapshot = await claimsRef.get();
//
//       // Check if there are any documents
//       if (querySnapshot.docs.isNotEmpty) {
//         // Update the local state with the claims data
//         setState(() {
//           claims = querySnapshot.docs.map((doc) {
//             final breakinData = doc.data() as Map<String, dynamic>;
//             return {
//               'claimId': breakinData['BREAKIN_ID']?.toString() ?? 'N/A',
//               'claimName': breakinData['CUST_NAME']?.toString() ?? 'N/A',
//               'insuranceCompany': breakinData['INSURANCE_COMPANY']?.toString() ?? 'N/A',
//               'policyEffectiveDate': breakinData['POLICY_EFFECTIVE_DATE']?.toString() ?? 'N/A',
//               'policyExpiryDate': breakinData['POLICY_EXPIRY_DATE']?.toString() ?? 'N/A',
//               'engineNo': breakinData['ENGINE_NO']?.toString() ?? 'N/A',
//               'chassisNo': breakinData['CHASSIS_NO']?.toString() ?? 'N/A',
//               'email': breakinData['CUST_EMAIL']?.toString() ?? 'N/A',
//               'mobile': breakinData['CUST_MOBILE']?.toString() ?? 'N/A',
//               'pincode': breakinData['PIN_CODE']?.toString() ?? 'N/A',
//               'state': breakinData['CUST_STATE_NAME']?.toString() ?? 'N/A',
//               'city': breakinData['CUST_CITY_NAME']?.toString() ?? 'N/A',
//               'dob': breakinData['DOB']?.toString() ?? 'N/A',
//               'dor': breakinData['BREAKIN_CREATED_DATE']?.toString() ?? 'N/A',
//               'gender': breakinData['GENDER']?.toString() ?? 'N/A',
//               'vehiclemake': breakinData['VECHILE_MAKE']?.toString() ?? 'N/A',
//               'vehicle_rno': breakinData['VECHILE_REG_NO']?.toString() ?? 'N/A',
//               'model': breakinData['VECHILE_MODEL']?.toString() ?? 'N/A',
//               'Caddress': breakinData['COMMUNICATION_ADDRESS']?.toString() ?? 'N/A',
//             };
//           }).toList();
//         });
//       } else {
//         print('No claims found for this user.');
//       }
//     } catch (error) {
//       print('Failed to fetch claims: $error');
//     }
//   }
//
//   // Future<void> fetchClaims() async {
//   //   // final user = _auth.currentUser;
//   //   // if (user == null) return;
//   //
//   //   final userId = "TPAEuGVudySSi8dWgNKePq5behp1";
//   //   uploadClaimsToFirestore(userId);
//   //   try {
//   //     // Check if claims exist in Firebase for this user
//   //     final snapshot = await _firestore.collection('claims').doc(userId).get();
//   //
//   //     if (snapshot.exists) {
//   //       // Claims exist in Firebase, load them
//   //       final claimsData = snapshot.data();
//   //       if (claimsData != null) {
//   //         setState(() {
//   //           claims = (claimsData['claims'] as List<dynamic>)
//   //               .map((claim) => Map<String, String>.from(claim))
//   //               .toList();
//   //         });
//   //       }
//   //     } else {
//   //       // Claims do not exist, fetch from API
//   //       await fetchClaimsFromAPI(userId);
//   //     }
//   //   } catch (error) {
//   //     print('Failed to load claims: $error');
//   //   }
//   // }
//   //
//   // Future<void> fetchClaimsFromAPI(String userId) async {
//   //   final url =
//   //       'http://164.52.211.138:6001/breakins?mobile_number=%2B919700905643';
//   //   // final token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJtb2JpbGVfbnVtYmVyIjoiKzkxOTcwMDkwNTY0MyIsImV4cCI6MTcyNTE3NjUxNX0.ZryEmbSDcCvNf_TFzBGaRqNSxvQfEgSU3IEgI_Q-pP4";
//   //
//   //   try {
//   //     final response = await http.get(
//   //       Uri.parse(url),
//   //       // headers: {
//   //       //   'Authorization': 'Bearer $token',
//   //       // },
//   //     );
//   //
//   //     if (response.statusCode == 200) {
//   //       final data = jsonDecode(response.body) as Map<String, dynamic>;
//   //
//   //       if (data['breakins'] != null &&
//   //           data['breakins'] is Map<String, dynamic>) {
//   //         final breakins = data['breakins'] as Map<String, dynamic>;
//   //
//   //         // Create a batch to handle multiple writes efficiently
//   //         final batch = _firestore.batch();
//   //
//   //         for (var entry in breakins.entries) {
//   //           final breakinData = entry.value as Map<String, dynamic>;
//   //           final claimId = breakinData['BREAKIN_ID']?.toString() ?? 'N/A';
//   //
//   //           // Reference to the specific claim document
//   //           final claimDocRef = _firestore
//   //               .collection('claims')
//   //               .doc(userId)
//   //               .collection('userClaims')
//   //               .doc(claimId);
//   //
//   //           // Add the set operation to the batch
//   //           batch.set(claimDocRef, breakinData);
//   //         }
//   //
//   //         // Commit the batch
//   //         await batch.commit();
//   //
//   //         // Update the local state with the claims data
//   //         setState(() {
//   //           claims = breakins.entries.map((entry) {
//   //             final breakinData = entry.value as Map<String, dynamic>;
//   //             return {
//   //               'claimId': breakinData['BREAKIN_ID']?.toString() ?? 'N/A',
//   //               'claimName': breakinData['CUST_NAME']?.toString() ?? 'N/A',
//   //               'insuranceCompany':
//   //                   breakinData['INSURANCE_COMPANY']?.toString() ?? 'N/A',
//   //               'policyEffectiveDate':
//   //                   breakinData['POLICY_EFFECTIVE_DATE']?.toString() ?? 'N/A',
//   //               'policyExpiryDate':
//   //                   breakinData['POLICY_EXPIRY_DATE']?.toString() ?? 'N/A',
//   //               'engineNo': breakinData['ENGINE_NO']?.toString() ?? 'N/A',
//   //               'chassisNo': breakinData['CHASSIS_NO']?.toString() ?? 'N/A',
//   //               'email': breakinData['CUST_EMAIL']?.toString() ?? 'N/A',
//   //               'mobile': breakinData['CUST_MOBILE']?.toString() ?? 'N/A',
//   //               'pincode': breakinData['PIN_CODE']?.toString() ?? 'N/A',
//   //               'state': breakinData['CUST_STATE_NAME']?.toString() ?? 'N/A',
//   //               'city': breakinData['CUST_CITY_NAME']?.toString() ?? 'N/A',
//   //               'dob': breakinData['DOB']?.toString() ?? 'N/A',
//   //               'dor': breakinData['BREAKIN_CREATED_DATE']?.toString() ?? 'N/A',
//   //               'gender': breakinData['GENDER']?.toString() ?? 'N/A',
//   //               'vehiclemake': breakinData['VECHILE_MAKE']?.toString() ?? 'N/A',
//   //               'vehicle_rno':
//   //                   breakinData['VECHILE_REG_NO']?.toString() ?? 'N/A',
//   //               'model': breakinData['VECHILE_MODEL']?.toString() ?? 'N/A',
//   //               'Caddress':
//   //                   breakinData['COMMUNICATION_ADDRESS']?.toString() ?? 'N/A',
//   //             };
//   //           }).toList();
//   //         });
//   //       } else {
//   //         print('Unexpected data format: ${data['breakins']}');
//   //       }
//   //     } else {
//   //       print('Failed to load claims: ${response.statusCode}');
//   //     }
//   //   } catch (error) {
//   //     print('Failed to load claims: $error');
//   //   }
//   // }
//
//   Future<void> _logout() async {
//     try {
//       await FirebaseAuth.instance.signOut();
//       Get.offAll(() => LoginPage());
//     } catch (e) {
//       print('Error logging out: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: claims.isNotEmpty
//             ? Text(
//                 'Hello ${claims[0]['claimName']}',
//                 style:
//                     TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               )
//             : Text(
//                 'Hello',
//                 style:
//                     TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//         backgroundColor: Colors.blue[900],
//         actions: [
//           IconButton(
//             icon: Icon(Icons.logout, color: Colors.white),
//             onPressed: _logout,
//             tooltip: 'Logout',
//           ),
//         ],
//       ),
//       body: claims.isEmpty
//           ? Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               itemCount: claims.length,
//               itemBuilder: (context, index) {
//                 final claim = claims[index];
//                 return Card(
//                   elevation: 4,
//                   margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Claim ID: ${claim['claimId']}',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                             color: Colors.blue[900],
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         _buildDetailRow('Customer Name', claim['claimName']),
//                         _buildDetailRow(
//                             'Insurance Company', claim['insuranceCompany']),
//                         _buildDetailRow('Policy Effective Date',
//                             claim['policyEffectiveDate']),
//                         _buildDetailRow(
//                             'Policy Expiry Date', claim['policyExpiryDate']),
//                         _buildDetailRow('Engine No', claim['engineNo']),
//                         _buildDetailRow('Chassis No', claim['chassisNo']),
//                         _buildDetailRow('Email', claim['email']),
//                         _buildDetailRow('City', claim['city']),
//                         _buildDetailRow('State', claim['state']),
//                         _buildDetailRow('Mobile', claim['mobile']),
//                         SizedBox(height: 12),
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: ElevatedButton(
//                             onPressed: () {
//                               Get.to(() => ClaimFormStepper(),
//                                   arguments: {'claim': claim});
//                             },
//                             child: Text('Claim',
//                                 style: TextStyle(color: Colors.white)),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue[900],
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 24, vertical: 12),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
//
//   Widget _buildDetailRow(String label, String? value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             '$label:',
//             style: TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//               color: Colors.black87,
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value ?? 'N/A',
//               textAlign: TextAlign.right,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.black54,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
