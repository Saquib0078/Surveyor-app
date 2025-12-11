import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:damagedetection1/helpers/routeobserver.dart';
import 'dart:io';

import 'helpers/ImagePreview.dart';
import 'helpers/getCurrentPosition.dart';

class CameraImageUpload extends StatefulWidget {
  final Function(List<Map<String, String>>) updateImageData;
  final bool showTopBanner;
  final String appBarTitle;
  final Function updateSingleImageData;
  final int singleImageIndex;

  CameraImageUpload({
    required this.updateImageData,
    required this.showTopBanner,
    required this.appBarTitle,
    required this.updateSingleImageData,
    required this.singleImageIndex,
    Key? key,
  }) : super(key: key);

  @override
  State<CameraImageUpload> createState() => _CameraImageUploadState();
}

class _CameraImageUploadState extends State<CameraImageUpload> with RouteAware {
  int _currentIndex = 0;
  CarouselController imageCarouselController = CarouselController();
  late CameraController _cameraController;
  bool _isCameraInitialized = false;

  List<String> imageNameList = [
    "FrontSide",
    "FrontRightHandSide",
    "DriverSide",
    "RearRightHandSide",
    "RearSide",
    "RearLeftHandSide",
    "PassengerSide",
    "FrontLeftHandSide",
    "EngineCompart",
    "ChassisNo",
    "OdometerCar"
  ];

  List<Map<String, String>> returnListofMap = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      print('No cameras found');
      return;
    }

    final backCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.max,
      enableAudio: false,
    );

    try {
      await _cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void incrementCurrentIndex() {
    if (widget.showTopBanner) {
      Get.back();
    } else {
      if (_currentIndex == 10) {
        widget.updateImageData(returnListofMap);
        Get.back();
      }
      setState(() {
        _currentIndex = _currentIndex + 1;
      });

      imageCarouselController.animateToPage(
        _currentIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void addToReturnList(String path, String time, String location) {
    if (widget.showTopBanner) {
      widget.updateSingleImageData(
        widget.singleImageIndex,
        path,
        time,
        location,
      );
    } else {
      setState(() {
        returnListofMap = [
          ...returnListofMap,
          {"imgPath": path, "timestamp": time, "location": location}
        ];
      });
    }
  }

  Widget imageRowChild(int idx, int imgIdx) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Text(
            imageNameList[imgIdx],
            style: TextStyle(
              color: Colors.white,
              fontSize: imgIdx == idx ? 20 : 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 20),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _cameraController.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _isCameraInitialized
            ? Stack(
          children: [
            CameraPreview(_cameraController),
            widget.showTopBanner
                ? Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.appBarTitle,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
                : CarouselSlider(
              carouselController: imageCarouselController,
              options: CarouselOptions(
                height: 50,
                viewportFraction: 0.4,
                initialPage: 0,
                enableInfiniteScroll: false,
                reverse: false,
                autoPlay: false,
                enlargeCenterPage: true,
                scrollDirection: Axis.horizontal,
              ),
              items: imageNameList.map((i) {
                return imageRowChild(
                  _currentIndex,
                  imageNameList.indexOf(i),
                );
              }).toList(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: FloatingActionButton(
                  onPressed: () async {
                    try {
                      final XFile file = await _cameraController.takePicture();
                      final currentTime = DateTime.now().toIso8601String();
                      final location = await determinePosition();
                      Get.to(
                            () => ImagePreview(
                          file.path,
                          incrementCurrentIndex,
                          addToReturnList,
                        ),
                      );
                    } catch (e) {
                      print('Error taking picture: $e');
                    }
                  },
                  child: Icon(Icons.camera),
                ),
              ),
            ),
          ],
        )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }
}