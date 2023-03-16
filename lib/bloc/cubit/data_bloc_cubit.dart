import 'dart:async';
import 'package:location/location.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sensors_plus/sensors_plus.dart';

part 'data_bloc_state.dart';

class DataBlocCubit extends Cubit<DataBlocState> {
  DataBlocCubit() : super(DataBlocInitial());

  StreamSubscription? _accelerometerSubscription;
  StreamSubscription<LocationData>? _locationSubscription;
  PermissionStatus? _permissionSubscription;

  void startRecording() {
    _accelerometerSubscription = Stream.periodic(const Duration(seconds: 1))
        .asyncMap((_) => userAccelerometerEvents.first)
        .listen((UserAccelerometerEvent accelerometerEvent) {
      emit(DataUpdated(
        accelerometerData: accelerometerEvent,
        gpsData: state is DataUpdated ? (state as DataUpdated).gpsData : null,
      ));
    });

    _locationSubscription =
        Location.instance.onLocationChanged.listen((locationData) {
      emit(DataUpdated(
        accelerometerData: state is DataUpdated
            ? (state as DataUpdated).accelerometerData
            : null,
        gpsData: locationData,
      ));
    });
  }

  void stopRecording() {
    _accelerometerSubscription?.cancel();
    _locationSubscription?.cancel();
    emit(DataBlocInitial());
  }

  void requestPermission() async {
    PermissionStatus permissionSubscription =
        await Location.instance.hasPermission();

    if ((permissionSubscription == PermissionStatus.denied) ||
        (permissionSubscription == PermissionStatus.deniedForever)) {
      Location.instance.requestService();
    }
    emit(DataUpdated(
        accelerometerData: state is DataUpdated
            ? (state as DataUpdated).accelerometerData
            : null,
        gpsData: state is DataUpdated ? (state as DataUpdated).gpsData : null,
        permissionStatus: permissionSubscription));
  }

  void setSettings(LocationAccuracy accuracy, double distanceFilter) async {
    Location.instance.changeSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
  }
}
