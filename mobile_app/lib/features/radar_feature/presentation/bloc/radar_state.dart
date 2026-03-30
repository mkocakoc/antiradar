part of 'radar_bloc.dart';

enum RadarLoadStatus { initial, loading, success, failure }

class RadarState extends Equatable {
  const RadarState({
    this.status = RadarLoadStatus.initial,
    this.data = const RadarBundle(radars: [], speedTunnels: [], controlPoints: []),
    this.failure,
  });

  final RadarLoadStatus status;
  final RadarBundle data;
  final RadarFailure? failure;

  RadarState copyWith({
    RadarLoadStatus? status,
    RadarBundle? data,
    RadarFailure? failure,
    bool clearFailure = false,
  }) {
    return RadarState(
      status: status ?? this.status,
      data: data ?? this.data,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, data, failure?.type, failure?.message, failure?.code];
}
