part of 'radar_bloc.dart';

sealed class RadarEvent extends Equatable {
  const RadarEvent();

  @override
  List<Object?> get props => [];
}

final class RadarRequested extends RadarEvent {
  const RadarRequested({
    required this.fromDistrict,
    required this.toDistrict,
    this.forceRefresh = false,
  });

  final String fromDistrict;
  final String toDistrict;
  final bool forceRefresh;

  @override
  List<Object?> get props => [fromDistrict, toDistrict, forceRefresh];
}

final class RadarRefreshed extends RadarEvent {
  const RadarRefreshed({
    required this.fromDistrict,
    required this.toDistrict,
  });

  final String fromDistrict;
  final String toDistrict;

  @override
  List<Object?> get props => [fromDistrict, toDistrict];
}
