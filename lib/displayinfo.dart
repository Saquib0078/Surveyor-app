import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:damagedetection1/helpers/glasscontainer.dart';
import 'package:damagedetection1/selfinspection.dart';
import 'package:get/get.dart';

class DetailPage extends StatelessWidget {
  final Map<String, dynamic> selectedEntries;

  final Map<String, String> keyMapping = {
    "rc_number": "RC Number",
    "registration_date": "Registration Date",
    "owner_name": "Owner Name",
    "father_name": "Father's Name",
    "present_address": "Present Address",
    "permanent_address": "Permanent Address",
    "mobile_number": "Mobile Number",
    "vehicle_category": "Vehicle Category",
    "vehicle_chasi_number": "Vehicle Chassis Number",
    "vehicle_engine_number": "Vehicle Engine Number",
    "maker_description": "Maker Description",
    "maker_model": "Maker Model",
    "body_type": "Body Type",
    "fuel_type": "Fuel Type",
    "color": "Color",
    "norms_type": "Norms Type",
    "fit_up_to": "Fit Up To",
    "financer": "Financer",
    "financed": "Financed",
    "insurance_company": "Insurance Company",
    "insurance_policy_number": "Insurance Policy Number",
    "insurance_upto": "Insurance Upto",
    "manufacturing_date": "Manufacturing Date",
    "manufacturing_date_formatted": "Formatted Manufacturing Date",
    "registered_at": "Registered At",
    "latest_by": "Latest By",
    "less_info": "Less Info",
    "tax_upto": "Tax Upto",
    "tax_paid_upto": "Tax Paid Upto",
    "cubic_capacity": "Cubic Capacity",
    "vehicle_gross_weight": "Vehicle Gross Weight",
    "no_cylinders": "Number of Cylinders",
    "seat_capacity": "Seat Capacity",
    "sleeper_capacity": "Sleeper Capacity",
    "standing_capacity": "Standing Capacity",
    "wheelbase": "Wheelbase",
    "unladen_weight": "Unladen Weight",
    "vehicle_category_description": "Vehicle Category Description",
    "pucc_number": "PUCC Number",
    "pucc_upto": "PUCC Upto",
    "permit_number": "Permit Number",
    "permit_issue_date": "Permit Issue Date",
    "permit_valid_from": "Permit Valid From",
    "permit_valid_upto": "Permit Valid Upto",
    "permit_type": "Permit Type",
    "national_permit_number": "National Permit Number",
    "national_permit_upto": "National Permit Upto",
    "national_permit_issued_by": "National Permit Issued By",
    "non_use_status": "Non Use Status",
    "non_use_from": "Non Use From",
    "non_use_to": "Non Use To",
    "blacklist_status": "Blacklist Status",
    "noc_details": "NOC Details",
    "owner_number": "Owner Number",
    "rc_status": "RC Status",
    "masked_name": "Masked Name",
    "challan_details": "Challan Details",
    "variant": "Variant"

  };



  DetailPage({required this.selectedEntries});

  String getDisplayName(String originalKey) {
    return keyMapping[originalKey] ?? toTitleCase(originalKey);
  }

  String toTitleCase(String text) {
    return text.split('_').map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }

  List<Widget> _buildCards(Map<String, dynamic> data) {
    var entries = data['data'] as Map<String, dynamic>;
    var mapEntries = entries.entries.toList();

    // Chunking the data into sets of 4
    List<List<MapEntry<String, dynamic>>> chunks = [];
    for (var i = 0; i < mapEntries.length; i += 4) {
      chunks.add(mapEntries.sublist(i, i + 4 > mapEntries.length ? mapEntries.length : i + 4));
    }

    // For each chunk, create a GlassContainer that displays the key-value pairs
    return chunks.map((chunk) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        child: GlassContainer(
          padding: EdgeInsets.all(10),
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: chunk.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('${getDisplayName(entry.key)}: ${entry.value}',
                    style: TextStyle(color: Colors.blue[900])),
              );
            }).toList(),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(10),
        child: ListView(
          children: [
            Text(
              "Please check your details",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[900]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ..._buildCards(selectedEntries),
            SizedBox(height: 20),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.yellow),
                side: MaterialStateProperty.all(BorderSide(color: Colors.blue[900]!, width: 2)),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0))),
              ),
              onPressed: () {
                // Get.to(() => SelfInspection()); // Pass the data here
              },
              child: Text('Continue to take Car Images', style: TextStyle(color: Colors.blue[900])),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}


