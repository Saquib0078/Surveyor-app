import 'package:flutter/material.dart';
import 'ClaimStatus.dart';
import 'FirestoreService.dart';
import 'helpers/ClaimReportScreen.dart'; // Import the FirestoreService

class Claimoverview extends StatefulWidget {
  final String refId;
  final String formId;
  final String userId;

  const Claimoverview({
    Key? key,
    required this.refId,
    required this.formId,
    required this.userId,
  }) : super(key: key);

  @override
  State<Claimoverview> createState() => _ClaimoverviewState();
}

class _ClaimoverviewState extends State<Claimoverview> {
  late Future<ClaimStatus> _claimStatusFuture;
  final FirestoreService _firestoreService = FirestoreService(); // Initialize FirestoreService

  @override
  void initState() {
    super.initState();
    // Fetch claim status using userId and formId from Firestore
    _claimStatusFuture = _loadClaimStatus();
  }

  Future<ClaimStatus> _loadClaimStatus() async {
    final snapshot = await _firestoreService.getClaimStatus(widget.userId, widget.formId);

    // Print the raw snapshot data for debugging
    print('Snapshot: ${snapshot.data()}');

    // Assuming your FirestoreService.getClaimStatus returns a DocumentSnapshot
    if (snapshot.exists && snapshot.data() != null) {
      // Extract the 'status' field from the snapshot data
      final statusData = snapshot.data()!['status'];

      // Print the extracted 'status' field for debugging
      print('Status Data: $statusData');

      // Convert the 'status' field to ClaimStatus object
      return ClaimStatus.fromMap(statusData);
    } else {
      throw Exception('Claim status not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Claim Overview')),
      body: FutureBuilder<ClaimStatus>(
        future: _claimStatusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final claimStatus = snapshot.data!;

            // If the status is 'Pending', display the uncancellable dialog
            if (claimStatus.overallStatus == 'Pending') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  barrierDismissible: false, // Make dialog uncancellable
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Claim Status Pending'),
                      content: Text(
                        'For your Form ID: ${widget.formId}\n'
                            'Reference ID: ${widget.refId}\n\n'
                            'Your claim is currently pending. We will notify you as soon as it is verified.',
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            // No action, dialog remains until status changes
                          },
                          child: Text('Waiting for Verification'),
                        ),
                      ],
                    );
                  },
                );
              });
            }

            // If the status is 'Verified', display an actionable button
            else if (claimStatus.overallStatus == 'Verified') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  barrierDismissible: true, // Dialog can be dismissed
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Claim Verified'),
                      content: Text(
                        'For your Form ID: ${widget.formId}\n'
                            'Reference ID: ${widget.refId}\n\n'
                            'Your claim has been verified. You can now view the report.',
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                            // Navigate to claim report page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClaimReportScreen(refId: widget.refId),
                              ),
                            );
                          },
                          child: Text('See Claim Report'),
                        ),
                      ],
                    );
                  },
                );
              });
            }

            // Return an empty container since the dialog is handling the display
            return Container();
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

}
