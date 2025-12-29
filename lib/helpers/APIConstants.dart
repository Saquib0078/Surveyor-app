class APIConstants {
  // Base URLs
  static const String baseUrl = 'https://fw-damage-uat.iassistlabs.in';
  static const String motorBaseUrl = 'https://uat.goclaims.in/motor_iail';
  static const String motorBaseUrlnew = 'https://uat.goclaims.in/motor_claim_api';
  static const String motorClaimApiBase = 'https://uat.goclaims.in/motor_claim_api';
  
  // Motor API Endpoints
  static const String surveyorTaskPagination = '$motorBaseUrl/surveyor_task_pgnt';
  static const String garageSearch = '$motorBaseUrl/garage/search';
  static const String getSurveyorClaims = '$motorBaseUrl/get_surveyor_claims';
  static const String estimateUpdate = '$motorBaseUrl/estimate/update';
  static const String invoiceUpdate = '$motorBaseUrl/invoice/update';
  
  // Motor Claim API Endpoints
  static const String accidentIntimationMotor = '$motorClaimApiBase/accident_intimation_motor';
  
  // Legacy Endpoints (using old baseUrl)
  static const String syncSurveyor = '$motorBaseUrl/sync_surveyor';
  static const String acceptTask = '$motorBaseUrl/accept_task';
  static const String rejectTask = '$motorBaseUrl/reject_task';
  
  // Helper method to get full URL
  static String getMotorUrl(String endpoint) {
    return '$motorBaseUrl/$endpoint';
  }
  
  static String getMotorClaimUrl(String endpoint) {
    return '$motorClaimApiBase/$endpoint';
  }
  
  static String getUrl(String endpoint) {
    return '$baseUrl/$endpoint';
  }
}