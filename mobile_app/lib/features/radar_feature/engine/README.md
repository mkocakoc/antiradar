# Location & Notification Engine

Bu motor radar yaklaşım algılama ve bildirim akışını yönetir.

## Bileşenler

- `AdaptiveLocationService`
  - Geolocator stream dinler
  - Hıza göre `distanceFilter` dinamik ayarlar
  - Pil tüketimini düşürür
- `ProximityEvaluator`
  - 1000m trigger
  - Radar bölgesi içi suppress
  - Ters yön (vektörel dot-product) suppress
- `NotificationOrchestrator`
  - `flutter_local_notifications` ile high-importance alarm
- `NotificationCooldownStore`
  - Aynı radar için 1 saat cooldown
- `LocationNotificationEngine`
  - Tüm akışı orkestre eder

## Background / Terminated Notları

Gerçek background/terminated davranışı için platform konfigürasyonu gerekir:

### Android
- Konum izni: `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`
- Foreground service bildirimi ile location stream sürdürme
- `POST_NOTIFICATIONS` (Android 13+)

### iOS
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `UIBackgroundModes` içine `location`
- Kritik bildirim için ilgili capability/entitlement

`background_notification_bootstrap.dart` içindeki `radarBackgroundEntryPoint` bu kurulumlarda entrypoint olarak kullanılabilir.
