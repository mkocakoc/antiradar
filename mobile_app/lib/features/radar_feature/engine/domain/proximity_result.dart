import 'package:equatable/equatable.dart';

enum ProximityDecision {
  notify,
  tooFar,
  insideZone,
  reverseDirection,
  insufficientMovement,
}

class ProximityResult extends Equatable {
  const ProximityResult({
    required this.decision,
    required this.distanceToStartMeters,
    this.reason,
  });

  final ProximityDecision decision;
  final double distanceToStartMeters;
  final String? reason;

  bool get shouldNotify => decision == ProximityDecision.notify;

  @override
  List<Object?> get props => [decision, distanceToStartMeters, reason];
}
