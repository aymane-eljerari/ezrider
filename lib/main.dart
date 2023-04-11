import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ezrider/cubit/cubit/data_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';



String generateRandomString(int length) {
  var rng = Random();
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(rng.nextInt(chars.length))));
}

late List<CameraDescription> _cameras;
var uuid = generateRandomString(30);
late Directory appDocDir;

void _showManual(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Welcome to EZRider!'),
        content: SingleChildScrollView(
          child: ListBody(
            children: const <Widget>[
              Text('HOW TO USE:'),
              Text('1. Place your phone in a rigid dashboard mount with the camera facing the road in front of you.\n'),
              Text('2. Press "Record" to start collecting accelerometer, GPS, and image data.\n'),
              Text('3. Press "Stop Recording" to turn off data collection.  If the data is good, store it locally.  If not, delete it.\n'),
              Text('4. Once the data is stored locally, you can then press "Upload" to send it to our database.\n'),
              Text('***IF THE DATA IS NOT STORED LOCALLY, IT WILL NOT UPLOAD TO DATABASE***\n'),
              Text('5. Press "Delete" to clear all data stored after upload.\n'),
              Text('Note: Please scroll down while in landscape orientation to view buttons.\n'),
              Text("Let's find some rough roads!")
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


// entry point of app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  appDocDir = await getApplicationDocumentsDirectory();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EZ Rider',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const DataPage(title: 'EZ Rider Home Page'),
    );
  }
}



class DataPage extends StatefulWidget {
  final String title;

  const DataPage({super.key, required this.title});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> with WidgetsBindingObserver {
  
  final DataCubit _dataCubit =
      DataCubit(timeInterval: 1000, uuid: uuid, directory: appDocDir);
  late CameraController controller;
  

  @override
  void initState() {
    super.initState();
    _dataCubit.emitRecording();
    controller = CameraController(_cameras[0], ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.bgra8888);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
    controller.setFlashMode(FlashMode.off);
    controller.setExposurePoint(null);
    _dataCubit.controller = controller;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (!cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    await controller.dispose();
    controller = CameraController(cameraDescription, ResolutionPreset.medium,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.bgra8888);

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        print('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      print(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('EZRider'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showManual(context);
            },
          ),
        ],
      ),
      body: Center(
        child: BlocBuilder<DataCubit, DataState>(
          bloc: _dataCubit,
          builder: (context, state) {
            if (state is Recording) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Padding(
                      padding: EdgeInsets.all(screenSize.width * 0.025),
                      child: OrientationBuilder(
                        builder: (context, orientation) {
                          double width, height;
                          if (orientation == Orientation.portrait) {
                            width = screenSize.width * 0.9;
                            height = screenSize.width * 0.9;
                          } else {
                            width = screenSize.height * 0.0001;
                            height = screenSize.height * 0.0001;
                          }
                          return SizedBox(
                            width: width,
                            height: height,
                            child: ClipRect(
                              child: OverflowBox(
                                minWidth: width,
                                minHeight: height,
                                child: CameraPreview(controller),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const Text(
                    'Accelerometer Data:',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'X: ${state.accelerometer?.x.toStringAsFixed(2) ?? '?'} Y: ${state.accelerometer?.y.toStringAsFixed(2) ?? '?'} Z: ${state.accelerometer?.z.toStringAsFixed(2) ?? '?'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'GPS Data:',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'Latitude: ${state.location?.latitude?.toStringAsFixed(5) ?? '?'} Longitude: ${state.location?.longitude?.toStringAsFixed(5) ?? '?'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        child: const Text("Record"),
                        onPressed: () {
                          _dataCubit.startRecording();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Started Recording'),
                              duration: Duration(milliseconds: 1000),
                            ),
                          );
                        },
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            child: const Text("Stop Recording"),
                            onPressed: () {
                              _dataCubit.stopRecording();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Stopped Recording'),
                                  duration: Duration(milliseconds: 1000),
                                ),
                              );
                            },
                          ),
                        ],
                      ),Row(
                        children: [
                          ElevatedButton(
                            child: const Text("Display Map"),
                            onPressed: () {
                              Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SecondPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        child: const Text("Delete"),
                        onPressed: () {
                          _dataCubit.deleteData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Deleted Data'),
                              duration: Duration(milliseconds: 1000),
                            ),
                          );
                        },
                      ),
                      ElevatedButton(
                        child: const Text("Store Locally"),
                        onPressed: () {
                          _dataCubit.storeData(
                            collectedData: _dataCubit.collectedData,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stored Data Locally'),
                              duration: Duration(milliseconds: 1000),
                            ),
                          );
                        },
                      ),
                      ElevatedButton(
                        child: const Text("Upload"),
                        onPressed: () {
                          _dataCubit.uploadToFirebase();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Upload Data'),
                              duration: Duration(milliseconds: 1000),
                            ),
                          );
                        },
                      )
                    ],
                  )
                ],
              )
              );
            } else {
              return const Text(
                'Unexpected State: Please Contact aymanelj@bu.edu',
                style: TextStyle(fontSize: 20),
              );
            }
          },
        ),
      ),
    );
  }
}

class SecondPage extends StatefulWidget {
  const SecondPage({Key? key}) : super(key: key);

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  final Set<Marker> _markers = {};

  Future<void> _loadMarkersFromAsset() async {
  final jsonString = await rootBundle.loadString('assets/locations.json');
  final data = json.decode(jsonString);
  final latitudes = Map<String, dynamic>.from(data['Latitude']);
  final longitudes = Map<String, dynamic>.from(data['Longitude']);

  final markers = <Marker>[];
  for (var i = 0; i < latitudes.length; i++) {
    final latitude = latitudes[i.toString()] as double?;
    final longitude = longitudes[i.toString()] as double?;

    if (latitude != null && longitude != null) {
      markers.add(
        Marker(
          markerId: MarkerId('marker$i'),
          position: LatLng(latitude, longitude),
          infoWindow: InfoWindow(
            title: 'Rough Road',
            snippet: 'This road has potholes.',
          ),
        ),
      );
    }
  }

  setState(() {
    _markers.addAll(markers);
  });
}

  @override
  void initState() {
    super.initState();
    _loadMarkersFromAsset();
  }

  @override
  Widget build(BuildContext context) {
    // build the widget tree using the _markers set
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rough Road Locations'),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(42.3505, -71.1054),
          zoom: 15,
        ),
        mapType: MapType.normal,
        myLocationEnabled: true,
        markers: _markers,
      ),
    );
  }
}





