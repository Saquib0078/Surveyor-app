// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:open_file/open_file.dart';
//
// class PDFOverlay {
//   static Future<File> createOverlay(Map<String, Map<String, dynamic>> formData) async {
//     final pdf = pw.Document();
//
//     // Load the asset PDF file as bytes
//     final ByteData assetData = await rootBundle.load('assets/KotakForm.pdf');
//     final Uint8List assetBytes = assetData.buffer.asUint8List();
//
//     // Add the background PDF as a template
//     final pdfPage = pw.MemoryImage(assetBytes);
//
//     pdf.addPage(
//       pw.Page(
//         build: (pw.Context context) {
//           return pw.Stack(
//             children: [
//               pw.Positioned.fill(
//                 child: pw.Image(pdfPage, fit: pw.BoxFit.contain),
//               ),
//               pw.Positioned(
//                 left: 150,
//                 top: 100,
//                 child: pw.Text(formData['Insured Details']?['Policy / Cover Note No'] ?? ''),
//               ),
//               pw.Positioned(
//                 left: 150,
//                 top: 130,
//                 child: pw.Text(formData['Insured Details']?['Name'] ?? ''),
//               ),
//               // Add more positioned widgets for other form fields
//             ],
//           );
//         },
//       ),
//     );
//
//     // Save the generated PDF file to a temporary directory
//     final output = await getTemporaryDirectory();
//     final file = File('${output.path}/claim_form_overlay.pdf');
//     await file.writeAsBytes(await pdf.save());
//
//     return file;
//   }
// }
//
// class PDFViewerPage extends StatelessWidget {
//   final File pdfFile;
//
//   PDFViewerPage({required this.pdfFile});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Claim Form PDF')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('PDF Created Successfully'),
//             SizedBox(height: 20),
//             ElevatedButton(
//               child: Text('Open PDF'),
//               onPressed: () {
//                 OpenFile.open(pdfFile.path);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
