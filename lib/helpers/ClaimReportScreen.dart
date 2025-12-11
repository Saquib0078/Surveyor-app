import 'package:flutter/material.dart';

class ClaimReportScreen extends StatelessWidget {
  final String refId;

  ClaimReportScreen({required this.refId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Claim Report')),
      body: Center(
        child: Text('Displaying report for Claim Reference ID: $refId'),
      ),
    );
  }
}
