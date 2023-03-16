import 'package:flutter/material.dart';
import 'package:ezrider/bloc/cubit/data_bloc_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
  final DataBlocCubit _dataBloc = DataBlocCubit();

  @override
  void initState() {
    super.initState();
    _dataBloc.startRecording();
  }

  @override
  void dispose() {
    _dataBloc.stopRecording();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Page'),
      ),
      body: Center(
        child: BlocBuilder<DataBlocCubit, DataBlocState>(
          bloc: _dataBloc,
          builder: (context, state) {
            if (state is DataUpdated) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Accelerometer Data:',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'X: ${state.accelerometerData?.x.toStringAsFixed(2) ?? 'X'} Y: ${state.accelerometerData?.y.toStringAsFixed(2) ?? 'X'} Z: ${state.accelerometerData?.z.toStringAsFixed(2) ?? 'X'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'GPS Data:',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'Latitude: ${state.gpsData?.latitude?.toStringAsFixed(5) ?? 'X'} Longitude: ${state.gpsData?.longitude?.toStringAsFixed(5) ?? 'X'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(
                    height: 100,
                  ),
                  FloatingActionButton(
                      child: const Icon(Icons.my_location_rounded),
                      onPressed: () {
                        _dataBloc.requestPermission();
                      }),
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
