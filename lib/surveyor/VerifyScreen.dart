import 'package:flutter/material.dart';
import 'EstimateVerificationListScreen.dart';

class VerifyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verification'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildVerificationCard(
              context,
              title: 'Estimate Verification',
              icon: Icons.calculate_outlined,
              color: Colors.blue.shade50,
              iconColor: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EstimateVerificationListScreen(
                      taskType: 'estimate_verification',
                      pageTitle: 'Estimate Verification Tasks',
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            _buildVerificationCard(
              context,
              title: 'Invoice Verification',
              icon: Icons.receipt_long_outlined,
              color: Colors.green.shade50,
              iconColor: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EstimateVerificationListScreen(
                      taskType: 'invoice_verification',
                      pageTitle: 'Invoice Verification Tasks',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: iconColor),
            ),
            SizedBox(width: 24),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
