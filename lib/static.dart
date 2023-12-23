import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';

class StaticObjectDetection extends StatefulWidget {
  const StaticObjectDetection({super.key});

  @override
  State<StaticObjectDetection> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<StaticObjectDetection> {
  late ImagePicker imagePicker;
  File? _image;
  dynamic image;
  dynamic objectDetector;

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
    const mode = DetectionMode.single;
    final options = ObjectDetectorOptions(
      classifyObjects: true,
      multipleObjects: true,
      mode: mode,
    );
    objectDetector = ObjectDetector(options: options);
  }

  @override
  void dispose() {
    super.dispose();
    objectDetector.close();
  }

  //capture image using camera
  imgFromCamera() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      doObjectDetection();
    }
  }

  //choose image using gallery
  imgFromGallery() async {
    XFile? pickedFile =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      doObjectDetection();
    }
  }

  //face detection code here
  late List<DetectedObject> objects;
  doObjectDetection() async {
    InputImage inputImage = InputImage.fromFile(_image!);
    objects = await objectDetector.processImage(inputImage);
    for (DetectedObject detectedObject in objects) {
      // final rect = detectedObject.boundingBox;
      // final trackingId = detectedObject.trackingId;
      for (Label label in detectedObject.labels) {
        print('${label.text} ${label.confidence}');
      }
    }
    setState(() {
      objects;
      _image;
    });
    drawRectanglesAroundObjects();
  }

  var result = '';
  //draw rectangles
  drawRectanglesAroundObjects() async {
    image = await _image?.readAsBytes();
    image = await decodeImageFromList(image);
    setState(() {
      image;
      objects;
      result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 100),
            child: Stack(children: <Widget>[
              Center(
                child: ElevatedButton(
                  onPressed: imgFromGallery,
                  onLongPress: imgFromCamera,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent),
                  child: Container(
                    width: 350,
                    height: 350,
                    margin: const EdgeInsets.only(
                      top: 45,
                    ),
                    child: image != null
                        ? Center(
                            child: FittedBox(
                              child: SizedBox(
                                width: image.width.toDouble(),
                                height: image.width.toDouble(),
                                child: CustomPaint(
                                  painter: ObjectPainter(
                                      objectList: objects, imageFile: image),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.black,
                            width: 350,
                            height: 350,
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 53,
                            ),
                          ),
                  ),
                ),
              ),
            ]),
          ),
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: Text(
              result,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ObjectPainter extends CustomPainter {
  List<DetectedObject> objectList;
  dynamic imageFile;
  ObjectPainter({required this.objectList, @required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }
    Paint p = Paint();
    p.color = Colors.yellow;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 10;

    for (DetectedObject rectangle in objectList) {
      canvas.drawRect(rectangle.boundingBox, p);
      var list = rectangle.labels;
      for (Label label in list) {
        print("${label.text}   ${label.confidence.toStringAsFixed(2)}");
        TextSpan span = TextSpan(
            text: label.text,
            style: const TextStyle(fontSize: 25, color: Colors.yellow));
        TextPainter tp = TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas,
            Offset(rectangle.boundingBox.left, rectangle.boundingBox.top));
        break;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
