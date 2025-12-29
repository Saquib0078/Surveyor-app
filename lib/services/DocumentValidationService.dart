import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class DocumentValidationService {
  static const String apiUrl = 'https://iassistlabs.com/kyc-vision/predict';
  static const double confidenceThreshold = 0.70;

  /// Validate document using KYC Vision API
  /// Returns a map with validation result
  static Future<Map<String, dynamic>> validateDocument(
    File documentImage,
    String expectedDocType,
  ) async {
    try {
      print('========== DOCUMENT VALIDATION START ==========');
      print('Expected Document Type: $expectedDocType');
      print('Image Path: ${documentImage.path}');

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add the document image
      request.files.add(
        await http.MultipartFile.fromPath(
          'document',
          documentImage.path,
        ),
      );

      // Add cookies (if needed)
      request.headers['Cookie'] =
          'AWSALB=r7giP0TPbQMY+0TQ5cwsNHROkuf5JIazHcT2kCJf4RJKZzcINSh8JXqyQpUrjgh92YowaL+m4aT2Xwi4GSjWtAX4iF7KoL84pDvFH+5n6/YX5jt+oVfF7dWmvw5w; AWSALBCORS=r7giP0TPbQMY+0TQ5cwsNHROkuf5JIazHcT2kCJf4RJKZzcINSh8JXqyQpUrjgh92YowaL+m4aT2Xwi4GSjWtAX4iF7KoL84pDvFH+5n6/YX5jt+oVfF7dWmvw5w';

      print('Sending request to API...');
      var response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('API request timeout');
        },
      );

      print('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('Response Body: $responseBody');

        final jsonResponse = json.decode(responseBody);

        if (jsonResponse['results'] != null &&
            jsonResponse['results'].isNotEmpty) {
          final firstResult = jsonResponse['results'][0];
          final resultKey = firstResult.keys.first;
          final prediction = firstResult[resultKey]['prediction'];
          final confidence = firstResult[resultKey]['confidence'];

          print('Prediction: $prediction');
          print('Confidence: $confidence');

          // Check if confidence is good
          if (confidence >= confidenceThreshold) {
            // Check if prediction matches expected document type
            bool isMatch = _checkDocumentMatch(expectedDocType, prediction);

            print('Document Match: $isMatch');
            print('========== VALIDATION SUCCESS ==========');

            return {
              'success': true,
              'validated': isMatch,
              'prediction': prediction,
              'confidence': confidence,
              'message': isMatch
                  ? 'Document validated successfully'
                  : 'Document type mismatch. Expected: ${_formatDocType(expectedDocType)}, Got: ${_formatDocType(prediction)}',
            };
          } else {
            print('Low confidence: $confidence');
            print('========== VALIDATION LOW CONFIDENCE ==========');

            return {
              'success': true,
              'validated': false,
              'prediction': prediction,
              'confidence': confidence,
              'message':
                  'Document quality is low (${(confidence * 100).toStringAsFixed(1)}% confidence). Please capture a clearer image.',
              'askUser': true,
            };
          }
        } else {
          print('No results in API response');
          print('========== VALIDATION NO RESULTS ==========');

          return {
            'success': false,
            'validated': false,
            'message': 'Unable to identify document type',
            'askUser': true,
            'useFallback': true,
          };
        }
      } else {
        print('API Error: ${response.statusCode}');
        print('========== VALIDATION API ERROR ==========');

        return {
          'success': false,
          'validated': false,
          'message': 'API validation failed',
          'useFallback': true,
        };
      }
    } catch (e) {
      print('Exception during validation: $e');
      print('========== VALIDATION EXCEPTION ==========');

      return {
        'success': false,
        'validated': false,
        'message': 'Validation error: $e',
        'useFallback': true,
      };
    }
  }

  /// Fallback validation using ML Kit Image Labeling
  static Future<Map<String, dynamic>> validateDocumentLocally(
    File documentImage,
    String expectedDocType,
  ) async {
    try {
      print('========== LOCAL VALIDATION START ==========');
      print('Using ML Kit Image Labeling as fallback');

      final inputImage = InputImage.fromFile(documentImage);
      final imageLabeler = ImageLabeler(options: ImageLabelerOptions());

      final labels = await imageLabeler.processImage(inputImage);
      await imageLabeler.close();

      print('Labels found: ${labels.length}');
      for (var label in labels) {
        print('Label: ${label.label}, Confidence: ${label.confidence}');
      }

      // Check if any label suggests it's a document
      bool isDocument = labels.any((label) =>
          label.label.toLowerCase().contains('document') ||
          label.label.toLowerCase().contains('card') ||
          label.label.toLowerCase().contains('paper') ||
          label.label.toLowerCase().contains('text') ||
          label.confidence > 0.7);

      print('Is Document: $isDocument');
      print('========== LOCAL VALIDATION END ==========');

      return {
        'success': true,
        'validated': isDocument,
        'message': isDocument
            ? 'Document detected locally'
            : 'Unable to verify document locally',
        'labels': labels.map((l) => l.label).toList(),
      };
    } catch (e) {
      print('Local validation error: $e');
      return {
        'success': false,
        'validated': false,
        'message': 'Local validation failed: $e',
      };
    }
  }

  /// Check if predicted document type matches expected type
  static bool _checkDocumentMatch(String expectedType, String predictedType) {
    // Normalize both strings
    String expected = expectedType.toLowerCase().replaceAll('_', '');
    String predicted = predictedType.toLowerCase().replaceAll('_', '');

    // Direct match
    if (expected == predicted) return true;

    // Check for common variations
    Map<String, List<String>> documentVariations = {
      'aadharcard': ['aadhar', 'aadhaar', 'aadharfront', 'aadharback'],
      'pancard': ['pan', 'pancard'],
      'drivinglicense': ['dl', 'license', 'drivinglicence', 'drivinglicense'],
      'rcbook': ['rc', 'rcbook', 'registration'],
      'insurancepolicy': ['insurance', 'policy', 'insurancepolicy'],
      'fircopy': ['fir', 'fircopy'],
      'policereport': ['police', 'policereport'],
    };

    // Check if predicted type is in the variations of expected type
    for (var entry in documentVariations.entries) {
      if (expected.contains(entry.key) || entry.value.any((v) => expected.contains(v))) {
        if (predicted.contains(entry.key) || entry.value.any((v) => predicted.contains(v))) {
          return true;
        }
      }
    }

    return false;
  }

  /// Format document type for display
  static String _formatDocType(String docType) {
    return docType.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
