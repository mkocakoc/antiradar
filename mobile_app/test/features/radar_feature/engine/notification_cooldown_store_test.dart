import 'package:flutter_test/flutter_test.dart';
import 'package:antiradar_mobile_app/features/radar_feature/radar_feature.dart';

void main() {
  test('InMemoryNotificationCooldownStore blocks duplicate notifications within 1 hour', () async {
    final store = InMemoryNotificationCooldownStore();
    final base = DateTime(2026, 3, 29, 12, 0, 0);

    final firstCheck = await store.canNotify(radarId: 'r1', now: base);
    expect(firstCheck, isTrue);

    await store.markNotified(radarId: 'r1', now: base);

    final secondCheck = await store.canNotify(
      radarId: 'r1',
      now: base.add(const Duration(minutes: 30)),
    );
    expect(secondCheck, isFalse);

    final thirdCheck = await store.canNotify(
      radarId: 'r1',
      now: base.add(const Duration(hours: 1, minutes: 1)),
    );
    expect(thirdCheck, isTrue);
  });
}
