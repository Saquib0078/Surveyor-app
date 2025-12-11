class ClaimStatus {
  String overallStatus;
  bool accidentDetailsCompleted;
  bool garageDetailsCompleted;
  bool driverDetailsCompleted;

  ClaimStatus({
    this.overallStatus = 'Initiated',
    this.accidentDetailsCompleted = false,
    this.garageDetailsCompleted = false,
    this.driverDetailsCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'overallStatus': overallStatus,
      'accidentDetailsCompleted': accidentDetailsCompleted,
      'garageDetailsCompleted': garageDetailsCompleted,
      'driverDetailsCompleted': driverDetailsCompleted,
    };
  }

  factory ClaimStatus.fromMap(Map<String, dynamic> map) {
    return ClaimStatus(
      overallStatus: map['overallStatus'] ?? 'Initiated',
      accidentDetailsCompleted: map['accidentDetailsCompleted'] ?? false,
      garageDetailsCompleted: map['garageDetailsCompleted'] ?? false,
      driverDetailsCompleted: map['driverDetailsCompleted'] ?? false,
    );
  }
}