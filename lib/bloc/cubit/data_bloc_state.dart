part of 'data_bloc_cubit.dart';

abstract class DataBlocState extends Equatable {
  const DataBlocState();

  @override
  List<Object?> get props => [];
}

class DataBlocInitial extends DataBlocState {}

class DataUpdated extends DataBlocState {
  final UserAccelerometerEvent? accelerometerData;
  final LocationData? gpsData;

  const DataUpdated({
    this.accelerometerData,
    this.gpsData,
  });

  @override
  List<Object?> get props => [accelerometerData, gpsData];
}
