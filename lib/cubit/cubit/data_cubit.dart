import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

part 'data_state.dart';

class DataCubit extends Cubit<DataState> {
  DataCubit({required this.timeInterval}) : super(DataInitial());

  final int timeInterval;
  late String dateTime;

  late CameraController controller;
  Map<String, Map<String, dynamic>> collectedData = {};
  // Map<DateTime, String> imageData = {};

  StreamSubscription? _locationSubscription;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _cameraSubscription;

  void startRecording() {
    String imagePath;

    Timer.periodic(Duration(milliseconds: timeInterval), (timer) {
      dateTime = DateTime.now().toIso8601String();
    });

    _cameraSubscription = Stream.periodic(Duration(milliseconds: timeInterval))
        .asyncMap((_) => takePicture())
        .listen((File image) async {
      imagePath = image.path;
      collectedData[dateTime] = {"path": imagePath};
      emit(Recording(
          accelerometer:
              state is Recording ? (state as Recording).accelerometer : null,
          location: state is Recording ? (state as Recording).location : null,
          image: image.path));
    });
    _accelerometerSubscription =
        Stream.periodic(Duration(milliseconds: timeInterval))
            .asyncMap((_) => userAccelerometerEvents.first)
            .listen((UserAccelerometerEvent accelerometerEvent) {
      collectedData[dateTime] = {
        "x": accelerometerEvent.x,
        "y": accelerometerEvent.y,
        "z": accelerometerEvent.z,
      };
      emit(Recording(
        accelerometer: accelerometerEvent,
        location: state is Recording ? (state as Recording).location : null,
        image: state is Recording ? (state as Recording).image : null,
      ));
    });

    _locationSubscription =
        Stream.periodic(Duration(milliseconds: timeInterval))
            .asyncMap((_) => Location.instance.getLocation())
            .listen((LocationData locationData) {
      collectedData[dateTime] = {
        "lat": locationData.latitude,
        "long": locationData.longitude,
      };
      emit(Recording(
        accelerometer:
            state is Recording ? (state as Recording).accelerometer : null,
        location: locationData,
        image: state is Recording ? (state as Recording).image : null,
      ));
    });

    appendData(
        dateTime,
        collectedData[dateTime]!['x'],
        collectedData[dateTime]!['y'],
        collectedData[dateTime]!['z'],
        collectedData[dateTime]!['lat'],
        collectedData[dateTime]!['long'],
        collectedData[dateTime]!['path']);
  }

  void stopRecording() {
    _accelerometerSubscription?.cancel();
    _locationSubscription?.cancel();
    _cameraSubscription?.cancel();
    emit(const Recording(
      accelerometer: null,
      location: null,
      image: null,
    ));
  }

  Future<File> takePicture() async {
    final XFile xfile = await controller.takePicture();
    Future<File> image = convertXFileToJpg(xfile);
    return image;
  }

  Future<File> convertXFileToJpg(XFile xFile) async {
    // Read the XFile as bytes
    Uint8List bytes = await xFile.readAsBytes();

    // Decode the bytes to an Image object using the image package
    Image image = decodeImage(bytes)!;

    // Encode the Image object to JPEG format
    List<int> jpgBytes = encodeJpg(image);

    // Create a new File object with the JPEG data
    File jpgFile = File('${xFile.path}.jpg');
    await jpgFile.writeAsBytes(jpgBytes);

    return jpgFile;
  }

  void emitRecording() {
    emit(const Recording(
      accelerometer: null,
      location: null,
      image: null,
    ));
  }

  Future<String> saveImage(File imageFile) async {
    Directory appDir = await getApplicationDocumentsDirectory();
    String imagesDirPath = '${appDir.path}/images';
    Directory(imagesDirPath).createSync(recursive: true);
    String imagePath =
        '$imagesDirPath/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await imageFile.copy(imagePath);
    return imagePath;
  }

  void appendData(String dateTime, double x, double y, double z, double lat,
      double lon, String path) {
    // Append new values to collectedData
    collectedData[dateTime] = {
      'x': x,
      'y': y,
      'z': z,
      'lat': lat,
      'long': lon,
      'path': path,
    };
  }

  void storeData(
      {required Map<String, Map<String, dynamic>> collectedData}) async {
    // Convert the data to JSON format
    final String dataJson = json.encode(collectedData);

    // Get the directory where the application can save files.
    Directory appDocDir = await getApplicationDocumentsDirectory();

    // Get the path to the directory where we will save the data and images.
    String dataPath = "${appDocDir.path}/data/data.json";
    String imagesPath = "${appDocDir.path}/data/images";

    // Create the directories if they don't exist
    Directory(imagesPath).createSync(recursive: true);

    // Store images and update the image paths in collectedData
    print(collectedData.entries);
    await Future.forEach(collectedData.entries, (entry) async {
      print(entry);
      print("------");
      print(entry.value['path']);
      String imagePath = entry.value['path'].toString();
      String imageName = "${entry.key}.jpg";
      File imageFile = File("$imagesPath/$imageName");
      await imageFile.writeAsBytes(await File(imagePath).readAsBytes());
    });

    // Write the data to a file
    final File dataFile = File(dataPath);
    await dataFile.writeAsString(dataJson);
  }

  // void storeData(
  //     {required Map<DateTime, Map<String, dynamic>> collectedData,
  //     required Map<DateTime, File> imageData}) async {
  //   Map<DateTime, Map<String, dynamic>> newData =
  //       collectedData.map((dateTime, map) {
  //     Map<String, dynamic> newNestedMap = {
  //       'x': map['x'],
  //       'y': map['y'],
  //       'z': map['z'],
  //       'lat': map['latitude'],
  //       'long': map['longitude'],
  //       'image': map['image'].path,
  //     };
  //     return MapEntry(dateTime, newNestedMap);
  //   }); // Convert the data to JSON format
  //   final String dataJson = json.encode(newData);

  //   // Get the directory where the application can save files.
  //   Directory appDocDir = await getApplicationDocumentsDirectory();
  //   // Get the path to the directory where we will save the image.
  //   String imagesPath = "${appDocDir.path}/data/images";
  //   String dataPath = "${appDocDir.path}/data/data.json";

  //   Directory(imagesPath).createSync(recursive: true);
  //   Directory(dataPath).createSync(recursive: true);

  //   // Store images
  //   imageData.forEach((key, value) async {
  //     String fileName = "$key.jpg";

  //     File file = File("$imagesPath/$fileName");
  //     await file.writeAsBytes(value.readAsBytesSync());
  //   });

  //   // Write the data to a file
  //   final File dataFile = File('data.json');
  //   dataFile.writeAsStringSync(dataJson);
  // }

  void deleteData() async {
    collectedData.clear();
    try {
      // Get the directory where the application can save files.
      Directory appDocDir = await getApplicationDocumentsDirectory();

      // Get the path to the directory where the data and images are stored.
      String imagesPath = "${appDocDir.path}/data/images";
      String dataPath = "${appDocDir.path}/data/data.json";

      // Delete the images
      final imagesDir = Directory(imagesPath);
      if (imagesDir.existsSync()) {
        await imagesDir.delete(recursive: true);
      }

      // Delete the data file
      final dataFile = File(dataPath);
      if (dataFile.existsSync()) {
        await dataFile.delete();
      }
    } catch (e) {
      print('Error deleting data: $e');
    }
  }

  Future<void> uploadToFirebase() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();

    // Get the path to the directory where the data and images are stored.
    String imagesPath = "${appDocDir.path}/data/images";
    String dataPath = "${appDocDir.path}/data/data.json";
    // Initialize Firebase
    final storage = FirebaseStorage.instance;

    // Upload the data file
    final dataRef = storage.ref().child('data.json');
    final dataFile = File(dataPath);
    await dataRef.putFile(dataFile).whenComplete(() => print('Data uploaded'));

    // Upload the images
    final imagesDir = Directory(imagesPath);
    final images = imagesDir.listSync();

    for (var image in images) {
      final imageName = image.path.split('/').last;
      final imageRef = storage.ref().child('images/$imageName');
      Uint8List bytes = await File(image.path).readAsBytes();
      final imageData = bytes;
      await imageRef
          .putData(imageData)
          .whenComplete(() => print('Image $imageName uploaded'));
    }

    print('All files uploaded');
  }

  // Future<void> uploadDataToFirebase({
  //   required Map<DateTime, Map<String, dynamic>> collectedData,
  //   required Map<DateTime, File> imageData,
  // }) async {
  //   try {
  //     // Create a new Firebase Storage instance.
  //     final FirebaseStorage storage = FirebaseStorage.instance;

  //     // Create a new Firestore instance.
  //     final FirebaseFirestore firestore = FirebaseFirestore.instance;

  //     // Create a new batch operation for Firestore.
  //     final WriteBatch batch = firestore.batch();

  //     // Upload images to Firebase Storage.
  //     for (final entry in imageData.entries) {
  //       final String fileName = '${entry.key}.jpg';
  //       final String imagePath = 'images/$fileName';
  //       final Reference imageRef = storage.ref().child(imagePath);

  //       final TaskSnapshot imageSnapshot = await imageRef.putFile(entry.value);
  //       final String imageUrl = await imageSnapshot.ref.getDownloadURL();

  //       // Add the image URL to the batch operation.
  //       batch.set(
  //         firestore.collection('images').doc(entry.key.toString()),
  //         {'url': imageUrl},
  //       );
  //     }

  //     // Add collected data to Firestore.
  //     for (final entry in collectedData.entries) {
  //       final Map<String, dynamic> data = entry.value;

  //       // Add the timestamp to the data map.
  //       data['timestamp'] = entry.key.toIso8601String();

  //       // Add the data to the batch operation.
  //       batch.set(
  //         firestore.collection('data').doc(entry.key.toString()),
  //         data,
  //       );
  //     }

  //     // Commit the batch operation.
  //     await batch.commit();
  //   } catch (e) {
  //     print('Error uploading data to Firebase: $e');
  //   }
  // }
}
