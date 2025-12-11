final List<Map<String, List<dynamic>>> formSections = [
  {
    'Insured Details': [
      'Policy / Cover Note No',
      'Name',
      'Permanent Address',
      'City',
      'State',
      {'field': 'Pin Code', 'type': 'number'},
      {'field': 'Mobile No', 'type': 'number'},
      {'field': 'Email ID', 'type': 'email'},
      {'field': 'Date of Birth', 'type': 'date'},
      'Gender',
      'Communication Address (if different)',
    ]
  },
  {
    'Vehicle Details': [
      'Make of Vehicle',
      'Model',
      'Registration Number',
      'Engine Number',
      'Chassis Number',
      {'field': 'Date of Registration', 'type': 'date'},
      // {'field': 'Odometer Reading', 'type': 'number'},
    ]
  },
  {
    'Driver Details': [
      'Driver Name',
      'Driving License Number',
      'License Issuing Authority',
      {'field': 'License Date of Expiry', 'type': 'date'},
      'License for Type of Vehicle',
      {'field': 'Was the license temporary?', 'type': 'boolean'},
      'Relation with Insured',
      {'field': 'If paid driver, how long has he been in your employment?', 'type': 'number'},
      {'field': 'Was he under the influence of intoxicating liquor or drugs?', 'type': 'boolean'},
    ]
  },
  {
    'Garage Details': [
      'Garage Name',
      'Garage Contact Person and Address',
      {'field': 'Garage Phone Number', 'type': 'number'},
    ]
  },
  {
    'Accident Details': [
      {'field': 'Date of Accident', 'type': 'date'},
      {'field': 'Time of Accident', 'type': 'time'},
      {'field': 'Exact Location of Accident','type': 'location'}    ,
      {'field': 'Speed of Vehicle (Kmph)', 'type': 'number'},
      {'field': 'No. of Occupants / Pillion rider', 'type': 'number'},
      'Brief description of the accident',
      {'field': 'Was accident reported to Police?', 'type': 'boolean'},
      'If yes, Name of the Police station',
      'FIR No. / CR Dairy Number',
    ]
  },
  {
    'Bank Details': [
      'Bank Name',
      {'field': 'Account Number', 'type': 'number'},
      'IFSC / MICR Code',
      'Account Holder Name',
    ]
  },
];