import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';

typedef HandleDetection = Future<List<Face>> Function(
    FirebaseVisionImage image);

class CameraService {
  // singleton boilerplate
  static final CameraService _cameraServiceService = CameraService._internal();

  factory CameraService() {
    return _cameraServiceService;
  }
  // singleton boilerplate
  CameraService._internal();

  CameraController _cameraController;
  CameraController get cameraController => this._cameraController;

  CameraDescription _cameraDescription;
  ImageRotation _cameraRotation;
  ImageRotation get cameraRotation => this._cameraRotation;
  String _imagePath;
  String get imagePath => this._imagePath;

  Future startService(CameraDescription cameraDescription) async {
    this._cameraDescription = cameraDescription;
    this._cameraController = CameraController(
      this._cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    // sets the rotation of the image
    this._cameraRotation = rotationIntToImageRotation(
      this._cameraDescription.sensorOrientation,
    );

    // Next, initialize the controller. This returns a Future.
    return this._cameraController.initialize();
  }

  Future<CameraDescription> getCamera(CameraLensDirection dir) async {
    return await availableCameras().then(
      (List<CameraDescription> cameras) => cameras.firstWhere(
        (CameraDescription camera) => camera.lensDirection == dir,
      ),
    );
  }

  Uint8List concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    planes.forEach((Plane plane) => allBytes.putUint8List(plane.bytes));
    return allBytes.done().buffer.asUint8List();
  }

  FirebaseVisionImageMetadata buildMetaData(
    CameraImage image,
    ImageRotation rotation,
  ) {
    return FirebaseVisionImageMetadata(
      rawFormat: image.format.raw,
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      planeData: image.planes.map(
        (Plane plane) {
          return FirebaseVisionImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: plane.height,
            width: plane.width,
          );
        },
      ).toList(),
    );
  }

  Future<List<Face>> detect(
    CameraImage image,
    HandleDetection handleDetection,
    ImageRotation rotation,
  ) async {
    return handleDetection(
      FirebaseVisionImage.fromBytes(
        concatenatePlanes(image.planes),
        buildMetaData(image, rotation),
      ),
    );
  }

  ImageRotation rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return ImageRotation.rotation0;
      case 90:
        return ImageRotation.rotation90;
      case 180:
        return ImageRotation.rotation180;
      default:
        assert(rotation == 270);
        return ImageRotation.rotation270;
    }
  }

  /// takes the picture and saves it in the given path 📸

  Future<XFile> takePicture() async {
    XFile file = await _cameraController.takePicture();
    this._imagePath = file.path;
    print("wasssssssimmmmmmm wassimmmm : " + file.path);
    return file;
  }

  /// returns the image size 📏
  Size getImageSize() {
    return Size(
      _cameraController.value.previewSize.height,
      _cameraController.value.previewSize.width,
    );
  }

  dispose() {
    this._cameraController.dispose();
  }
}
