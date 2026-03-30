import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/radar_bundle.dart';
import '../../domain/failures/radar_failure.dart';
import '../../domain/repositories/radar_repository.dart';

part 'radar_event.dart';
part 'radar_state.dart';

class RadarBloc extends Bloc<RadarEvent, RadarState> {
  RadarBloc({required RadarRepository repository})
      : _repository = repository,
        super(const RadarState()) {
    on<RadarRequested>(_onRequested);
    on<RadarRefreshed>(_onRefreshed);
  }

  final RadarRepository _repository;

  Future<void> _onRequested(
    RadarRequested event,
    Emitter<RadarState> emit,
  ) async {
    emit(state.copyWith(status: RadarLoadStatus.loading, clearFailure: true));

    final result = await _repository.fetchByDistrictRoute(
      fromDistrict: event.fromDistrict,
      toDistrict: event.toDistrict,
      forceRefresh: event.forceRefresh,
    );

    result.match(
      (failure) => emit(
        state.copyWith(
          status: RadarLoadStatus.failure,
          failure: failure,
          data: const RadarBundle(radars: [], speedTunnels: []),
        ),
      ),
      (data) => emit(
        state.copyWith(
          status: RadarLoadStatus.success,
          data: data,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<void> _onRefreshed(
    RadarRefreshed event,
    Emitter<RadarState> emit,
  ) {
    add(
      RadarRequested(
        fromDistrict: event.fromDistrict,
        toDistrict: event.toDistrict,
        forceRefresh: true,
      ),
    );
    return Future.value();
  }
}
