import 'dart:io';
import 'package:face_camera/face_camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:staras_mobile/core/controllers/api_client.dart';

class CameraView extends StatefulWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  File? _capturedImage;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            if (_capturedImage != null) {
              return Center(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Image.file(
                      _capturedImage!,
                      width: double.maxFinite,
                      fit: BoxFit.fitWidth,
                    ),
                    ElevatedButton(
                        onPressed: () => setState(() => _capturedImage = null),
                        child: const Text(
                          'Capture Again',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ))
                  ],
                ),
              );
            }
            return SmartFaceCamera(
              autoCapture: true,
              defaultCameraLens: CameraLens.front,
              imageResolution: ImageResolution.high,
              indicatorShape: IndicatorShape.square,
              onCapture: (File? image) async {
                setState(() => _capturedImage = image);
                if (_capturedImage != null) {
                  uploadImageToFirebase(_capturedImage!);
                }
              },
              onFaceDetected: (Face? face) {},
              messageBuilder: (context, face) {
                if (face == null) {
                  return _message('Place your face in the camera');
                }
                if (!face.wellPositioned) {
                  return _message('Center your face in the square');
                }

                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }

  void uploadImageToFirebase(File imageFile) async {
    try {
      final String? id = await readAccountId();
      final String? username = await readUsername();
      print('Username: $username');
      print('ID: $id');

      String filePath = 'TempUploadImages/$username/${id}.jpg';
      Reference storageReference = _storage.ref().child(filePath);
      UploadTask uploadTask = storageReference.putFile(imageFile);

      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      String downloadURL = await snapshot.ref.getDownloadURL();

      print('Download URL: $downloadURL');
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Widget _message(String msg) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 15),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, height: 1.5, fontWeight: FontWeight.w400)),
      );
}
