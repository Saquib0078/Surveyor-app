import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class DLExtractionService {
  /// Extract DL details from image using Google ML Kit OCR
  static Future<Map<String, dynamic>> extractDLDetails(File dlImage) async {
    try {
      print('🔍 Starting DL OCR extraction...');
      
      // Initialize text recognizer
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final inputImage = InputImage.fromFile(dlImage);
      
      print('📄 Processing image with ML Kit...');
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      // Close the recognizer
      await textRecognizer.close();
      
      print('✅ Text recognition complete');
      print('📝 Full extracted text:\n${recognizedText.text}');
      
      // DEBUG: Print all lines with indices
      print('\n🔍 DEBUG: All extracted lines:');
      int lineIndex = 0;
      for (var block in recognizedText.blocks) {
        for (var line in block.lines) {
          print('Line $lineIndex: "${line.text}"');
          lineIndex++;
        }
      }
      
      // Extract DL details from recognized text
      Map<String, dynamic> extractedData = _parseDLText(recognizedText);
      
      print('✅ DL extraction completed');
      print('📋 Extracted data: $extractedData');
      
      return {
        'success': true,
        'data': extractedData,
        'rawText': recognizedText.text,
      };
    } catch (e, stackTrace) {
      print('❌ DL extraction error: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Parse extracted text to find DL number, name, and expiry date
  static Map<String, dynamic> _parseDLText(RecognizedText recognizedText) {
    String fullText = recognizedText.text;
    Map<String, dynamic> result = {};

    // Extract DL Number
    RegExp dlNumberPattern = RegExp(
      r'[A-Z]{2}[-\s]*\d{2}[-\s]*\d{4}[-\s]*\d{7}',
      caseSensitive: false,
    );
    
    Match? dlMatch = dlNumberPattern.firstMatch(fullText);
    if (dlMatch != null) {
      String dlNumber = dlMatch.group(0)!.replaceAll(RegExp(r'[\s-]'), '');
      result['dl_number'] = dlNumber;
      print('✅ Found DL Number: $dlNumber');
    } else {
      // Fallback: Look for any sequence starting with 2 letters followed by 13+ digits
      RegExp fallbackPattern = RegExp(r'[A-Z]{2}[0-9\s-]{13,}', caseSensitive: false);
      Match? fallbackMatch = fallbackPattern.firstMatch(fullText);
      if (fallbackMatch != null) {
        String possibleDL = fallbackMatch.group(0)!.replaceAll(RegExp(r'[\s-]'), '');
        if (possibleDL.length >= 15) {
          result['dl_number'] = possibleDL;
          print('✅ Found DL Number (Fallback): $possibleDL');
        }
      } else {
        print('⚠️ DL Number not found');
      }
    }

    // Extract Name - IMPROVED VERSION
    result['name'] = _extractNameImproved(recognizedText);

    // Extract Date of Birth
    result['dob'] = _extractDate(fullText, ['DOB', 'Date of Birth', 'Birth']);

    // Extract Validity/Expiry Date
    result['validity'] = _extractValidityDates(fullText);

    return result;
  }

  /// IMPROVED name extraction with better logic and debugging
  static String? _extractNameImproved(RecognizedText recognizedText) {
    print('\n🔍 Starting IMPROVED name extraction...');
    
    List<String> allLines = [];
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        allLines.add(line.text.trim());
      }
    }

    // Strategy 1: Find "Name" keyword and extract value
    for (int i = 0; i < allLines.length; i++) {
      String line = allLines[i];
      String lower = line.toLowerCase();
      
      if (lower.contains('name')) {
        print('📍 Found "name" keyword at line $i: "$line"');
        
        // Check if name value is on the same line (after colon or space)
        String afterKeyword = line
            .replaceFirst(RegExp(r'.*name\s*:?\s*', caseSensitive: false), '')
            .trim();
        
        if (afterKeyword.isNotEmpty && _isValidName(afterKeyword)) {
          String cleaned = _cleanNameValue(afterKeyword);
          if (cleaned.isNotEmpty) {
            print('✅ Extracted name from same line: "$cleaned"');
            return cleaned;
          }
        }
        
        // Check next line
        if (i + 1 < allLines.length) {
          String nextLine = allLines[i + 1].trim();
          print('📍 Checking next line: "$nextLine"');
          
          if (_isValidName(nextLine)) {
            String cleaned = _cleanNameValue(nextLine);
            if (cleaned.isNotEmpty) {
              print('✅ Extracted name from next line: "$cleaned"');
              return cleaned;
            }
          }
        }
      }
    }

    // Strategy 2: Find name before S/O, W/O, D/O
    for (int i = 0; i < allLines.length; i++) {
      String line = allLines[i];
      String lower = line.toLowerCase();
      
      if (lower.contains('s/o') || lower.contains('w/o') || 
          lower.contains('d/o') || lower.contains('s/d/w')) {
        print('📍 Found relation keyword at line $i: "$line"');
        
        if (i > 0) {
          String prevLine = allLines[i - 1].trim();
          print('📍 Checking previous line: "$prevLine"');
          
          if (_isValidName(prevLine)) {
            String cleaned = _cleanNameValue(prevLine);
            if (cleaned.isNotEmpty) {
              print('✅ Extracted name before relation: "$cleaned"');
              return cleaned;
            }
          }
        }
      }
    }

    // Strategy 3: Find first valid name-like line (skip headers)
    print('📍 Using fallback: scanning for name-like text...');
    
    Set<String> skipWords = {
      'govt', 'government', 'india', 'state', 'union', 'transport', 
      'department', 'licence', 'license', 'driver', 'driving', 'drive',
      'issue', 'issued', 'valid', 'authority', 'date', 'dob', 'address',
      'signature', 'holder', 'blood', 'class', 'vehicle', 'form', 'rule',
      'mcwg', 'lmv', 'republic', 'ministry', 'motor', 'auth', 'pin', 'dist'
    };
    
    for (int i = 0; i < allLines.length; i++) {
      String line = allLines[i].trim();
      String lower = line.toLowerCase();
      
      // Skip if too short
      if (line.length < 3) continue;
      
      // Skip if contains numbers
      if (RegExp(r'\d').hasMatch(line)) continue;
      
      // Skip if contains skip words
      bool hasSkipWord = false;
      for (String skipWord in skipWords) {
        if (lower.contains(skipWord)) {
          hasSkipWord = true;
          break;
        }
      }
      if (hasSkipWord) continue;
      
      // Must be mostly alphabetic
      if (_isValidName(line)) {
        String cleaned = _cleanNameValue(line);
        if (cleaned.isNotEmpty && cleaned.length >= 3) {
          print('✅ Found name using fallback at line $i: "$cleaned"');
          return cleaned;
        }
      }
    }

    print('❌ Could not extract name from DL');
    return null;
  }

  /// Check if text looks like a valid name
  static bool _isValidName(String text) {
    // Must have at least some alphabetic characters
    if (!RegExp(r'[a-zA-Z]').hasMatch(text)) return false;
    
    // Calculate ratio of alphabetic characters
    int alphaCount = RegExp(r'[a-zA-Z]').allMatches(text).length;
    double alphaRatio = alphaCount / text.length;
    
    // Should be at least 70% alphabetic characters
    return alphaRatio >= 0.7;
  }

  /// Clean name value - remove unwanted characters but keep spaces
  static String _cleanNameValue(String raw) {
    // Remove everything except letters and spaces
    String cleaned = raw
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toUpperCase();
    
    // Remove standalone single letters (except valid initials)
    List<String> words = cleaned.split(' ');
    words = words.where((word) => word.length > 1 || words.length <= 3).toList();
    
    return words.join(' ');
  }

  /// Extract date based on keywords
  static String? _extractDate(String text, List<String> keywords) {
    RegExp datePattern = RegExp(
      r'\b(\d{2})[-/.](\d{2})[-/.](\d{4})\b',
    );
    
    List<String> lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      
      for (String keyword in keywords) {
        if (line.toLowerCase().contains(keyword.toLowerCase())) {
          // Look for date in current line
          Match? match = datePattern.firstMatch(line);
          if (match != null) {
            String date = match.group(0)!;
            print('✅ Found ${keywords[0]}: $date');
            return date;
          }
          
          // Look for date in next line
          if (i + 1 < lines.length) {
            match = datePattern.firstMatch(lines[i + 1]);
            if (match != null) {
              String date = match.group(0)!;
              print('✅ Found ${keywords[0]}: $date');
              return date;
            }
          }
        }
      }
    }
    
    print('⚠️ ${keywords[0]} not found');
    return null;
  }

  /// Extract validity dates (issue and expiry)
  static Map<String, dynamic>? _extractValidityDates(String text) {
    Map<String, dynamic> validity = {};
    
    String? expiryNT = _extractDate(text, ['Valid Till', 'Valid Upto', 'NT', 'Non-Transport']);
    String? expiryT = _extractDate(text, ['Transport', 'COV']);
    
    if (expiryNT != null || expiryT != null) {
      validity['non-transport'] = {
        'to': expiryNT,
      };
      
      if (expiryT != null) {
        validity['transport'] = {
          'to': expiryT,
        };
      }
      
      print('✅ Found Validity: $validity');
      return validity;
    }
    
    print('⚠️ Validity dates not found');
    return null;
  }
}