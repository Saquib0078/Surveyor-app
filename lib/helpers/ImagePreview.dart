import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:damagedetection1/helpers/getCurrentPosition.dart';

class ImagePreview extends StatefulWidget {
  final String originalPath;
  final Function incrementIndex;
  final Function(String, String, String) updateResult;

  ImagePreview(this.originalPath, this.incrementIndex, this.updateResult, {Key? key})
      : super(key: key);

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Image.file(
                  File(widget.originalPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.close,
                    label: "Retake",
                    color: Colors.red,
                    onPressed: () {
                      Get.back();
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.check,
                    label: "Confirm",
                    color: Colors.green,
                    onPressed: () async {
                      var location = await determinePosition();
                      DateTime currentPhoneDate = DateTime.now();
                      widget.updateResult(
                        widget.originalPath,
                        currentPhoneDate.toIso8601String(),
                        "${location.latitude};${location.longitude}",
                      );
                      widget.incrementIndex();
                      Get.back();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 40),
          color: color,
          onPressed: onPressed,
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 16),
        ),
      ],
    );
  }
}