import 'package:faceTest/services/camera.service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui show Image;

typedef HandleDetection = Future<List<Face>> Function(
    FirebaseVisionImage image);

class MLKitService {
  // singleton boilerplate
  static final MLKitService _cameraServiceService = MLKitService._internal();

  factory MLKitService() {
    return _cameraServiceService;
  }
  // singleton boilerplate
  MLKitService._internal();

  // service injection
  CameraService _cameraService = CameraService();

  bool _isDetecting = false;
  CameraLensDirection _direction = CameraLensDirection.back;
  CameraController _camera;

  List<Face> faces;
  FaceDetector _faceDetector;
  FaceDetector get faceDetector => this._faceDetector;

  void initialize() {
    this._faceDetector = FirebaseVision.instance.faceDetector(
      FaceDetectorOptions(
        mode: FaceDetectorMode.accurate,
      ),
    );
  }

  Future<List<Face>> getFacesFromImage(
      CameraImage image, HandleDetection handleDetection) async {
    FirebaseVisionImageMetadata _firebaseImageMetadata =
        FirebaseVisionImageMetadata(
      rawFormat: image.format.raw,
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: _cameraService.cameraRotation,
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

    /// Transform the image input for the _faceDetector 🎯

    return handleDetection(
      FirebaseVisionImage.fromBytes(
          concatenatePlanes(image.planes), _firebaseImageMetadata),
    );
  }

  Uint8List concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    planes.forEach((Plane plane) => allBytes.putUint8List(plane.bytes));
    return allBytes.done().buffer.asUint8List();
  }
}
