import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:image/image.dart';
import 'package:location/location.dart';
import 'package:sensors_plus/sensors_plus.dart';

part 'data_state.dart';

class DataCubit extends Cubit<DataState> {
  DataCubit({required this.timeInterval}) : super(DataInitial());

  final int timeInterval;
  late List<CameraDescription> cameras;
  late CameraController controller;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _cameraSubscription;
  PermissionStatus? _permissionSubscription;

  void startRecording() {
    _accelerometerSubscription =
        Stream.periodic(Duration(milliseconds: timeInterval))
            .asyncMap((_) => userAccelerometerEvents.first)
            .listen((UserAccelerometerEvent accelerometerEvent) {
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
      emit(Recording(
        accelerometer:
            state is Recording ? (state as Recording).accelerometer : null,
        location: locationData,
        image: state is Recording ? (state as Recording).image : null,
      ));
    });

    _cameraSubscription = Stream.periodic(Duration(milliseconds: timeInterval))
        .asyncMap((_) => takePicture())
        .listen((File image) {
      emit(Recording(
          accelerometer:
              state is Recording ? (state as Recording).accelerometer : null,
          location: state is Recording ? (state as Recording).location : null,
          image: image));
    });
  }

  void stopRecording() {
    _accelerometerSubscription?.cancel();
    _locationSubscription?.cancel();
    _cameraSubscription?.cancel();
    controller.dispose();
    emit(PermissionsGranted());
  }

  void getAvailableCameras() async {
    cameras = await availableCameras();
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

  void requestPermission() async {
    _permissionSubscription = await Location.instance.hasPermission();

    if ((_permissionSubscription == PermissionStatus.denied) ||
        (_permissionSubscription == PermissionStatus.deniedForever)) {
      Location.instance.requestService();
      print("Location Persmissions Granted");
    }
    emit(PermissionsGranted());
    controller = CameraController(cameras[0], ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.bgra8888);

    controller.initialize().then((_) {
      if (!controller.value.isInitialized) {
        emit(PermissionsDenied());
        print("Camera Permissions Denied");
      } else {
        emit(PermissionsGranted());
        print("Camera Permissions Granted");
      }
    });
  }
}
