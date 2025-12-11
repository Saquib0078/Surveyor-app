import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadPreview extends StatefulWidget {
  final Function(List<String>) onImagesSelected;

  const ImageUploadPreview({Key? key, required this.onImagesSelected}) : super(key: key);

  @override
  _ImageUploadPreviewState createState() => _ImageUploadPreviewState();
}

class _ImageUploadPreviewState extends State<ImageUploadPreview> {
  final ImagePicker _picker = ImagePicker();
  List<File> _images = []; // List to store multiple images

  // Function to pick multiple images from the gallery
  Future<void> _pickImagesFromGallery() async {
    List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
      _updateImagePaths();
    }
  }

  // Function to capture a single image from the camera
  Future<void> _pickImageFromCamera() async {
    XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
      _updateImagePaths();
    }
  }

  // Function to update the selected image paths
  void _updateImagePaths() {
    List<String> paths = _images.map((file) => file.path).toList();
    widget.onImagesSelected(paths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Image Upload & Preview'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Grid to display selected images
          Expanded(
            child: _images.isEmpty
                ? Center(child: Text("No images uploaded", style: TextStyle(color: Colors.grey[600])))
                : GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    // Remove button on each image
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _images.removeAt(index);
                          });
                          _updateImagePaths();
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Buttons to upload images from gallery or camera
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImagesFromGallery,
                  icon: Icon(Icons.photo_library),
                  label: Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickImageFromCamera,
                  icon: Icon(Icons.camera_alt),
                  label: Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Usage example:
// class ClaimStepperForm extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: ImageUploadPreview(
//         onImagesSelected: (List<String> paths) {
//           // Handle the selected image paths here
//           print('Paths received in ClaimStepperForm: $paths');
//           // You can now use these paths in your form or pass them to other widgets
//         },
//       ),
//     );
//   }
// }
