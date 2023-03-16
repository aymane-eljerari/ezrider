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

  Future<PermissionStatus> isPermission() async {
    PermissionStatus persmission = await Location.instance.hasPermission();

    if ((persmission == PermissionStatus.denied) ||
        (persmission == PermissionStatus.deniedForever)) {
      Location.instance.requestService();
      return persmission;
    }
    return persmission;
  }

  void setSettings(LocationAccuracy accuracy, double distanceFilter) async {
    Location.instance.changeSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
  }
}
