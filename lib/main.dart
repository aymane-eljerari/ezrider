import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ezrider/cubit/cubit/data_cubit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const DataPage(title: 'Flutter Demo Home Page'),
    );
  }
}

class DataPage extends StatefulWidget {
  final String title;

  const DataPage({super.key, required this.title});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final DataCubit _dataCubit = DataCubit(timeInterval: 1000);

  @override
  void initState() {
    super.initState();
    _dataCubit.getAvailableCameras();
  }

  @override
  void dispose() {
    _dataCubit.stopRecording();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EZRider'),
      ),
      body: Center(
        child: BlocBuilder<DataCubit, DataState>(
          bloc: _dataCubit,
          builder: (context, state) {
            if (state is DataInitial) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Press the button to enable persmissions',
                    style: TextStyle(fontSize: 20),
                  ),
                  FloatingActionButton(
                      child: const Icon(Icons.my_location_rounded),
                      onPressed: () {
                        _dataCubit.requestPermission();
                      }),
                ],
              );
            }
            if (state is PermissionsGranted) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Press the button to start recording',
                    style: TextStyle(fontSize: 20),
                  ),
                  FloatingActionButton(
                      child: const Icon(Icons.play_arrow_rounded),
                      onPressed: () {
                        _dataCubit.startRecording();
                      }),
                ],
              );
            }
            if (state is PermissionsDenied) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'App Permissions have not been granted',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              );
            }
            if (state is Recording) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: CameraPreview(_dataCubit.controller),
                  ),
                  const Text(
                    'Accelerometer Data:',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'X: ${state.accelerometer?.x.toStringAsFixed(2) ?? 'X'} Y: ${state.accelerometer?.y.toStringAsFixed(2) ?? 'X'} Z: ${state.accelerometer?.z.toStringAsFixed(2) ?? 'X'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'GPS Data:',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'Latitude: ${state.location?.latitude?.toStringAsFixed(5) ?? 'X'} Longitude: ${state.location?.longitude?.toStringAsFixed(5) ?? 'X'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  FloatingActionButton(
                    child: const Icon(Icons.cancel_outlined),
                    onPressed: () {
                      _dataCubit.stopRecording();
                    },
                  )
                ],
              );
            } else {
              return const Text(
                'Enable GPS Permissions',
                style: TextStyle(fontSize: 20),
              );
            }
          },
        ),
      ),
    );
  }
}
