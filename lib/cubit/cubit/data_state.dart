part of 'data_cubit.dart';

abstract class DataState extends Equatable {
  const DataState();

  @override
  List<Object?> get props => [];
}

class DataInitial extends DataState {}

class Recording extends DataState {
  final UserAccelerometerEvent? accelerometer;
  final LocationData? location;
  final String? image;

  const Recording({
    required this.accelerometer,
    required this.location,
    required this.image,
  });

  @override
  List<Object?> get props => [accelerometer, location, image];
}

class PermissionsGranted extends DataState {}

class PermissionsDenied extends DataState {}
