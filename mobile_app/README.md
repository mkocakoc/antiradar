# Mobile App - RadarFeature Module

Bu klasör, Clean Architecture yaklaşımıyla yazılmış `RadarFeature` modülünü içerir.

## Katmanlar

- **Domain**
  - `Radar`, `SpeedTunnel`, `GeoPoint`, `RadarBundle` immutable entity'leri
  - Toleranslı `fromJson` parse
  - `RadarRepository` kontratı
- **Infrastructure**
  - `Dio` ile BFF bağlantısı (`RadarRemoteDataSourceDio`)
  - `fpdart Either` dönen `RadarRepositoryImpl`
  - TTL tabanlı in-memory cache
- **Presentation**
  - `RadarBloc` + event/state ile loading/success/failure yönetimi
- **Utility**
  - `PolylineMapper`: `List<GeoPoint>` -> `Polyline`
- **Location & Notification Engine**
  - `AdaptiveLocationService`: hıza göre dinamik `distanceFilter`
  - `ProximityEvaluator`: 1000m tetik + ters yön + zone içi suppress
  - `LocationNotificationEngine`: konum + bildirim orkestrasyonu
  - `NotificationCooldownStore`: radar başına 1 saat cooldown
- **Slick Google Maps Experience**
  - Night/Silver JSON map style (`RadarMapStyle`)
  - `BitmapDescriptor` tabanlı özel radar ikonları (`RadarIconFactory`)
  - Speed tunnel için dashed polyline çizimi
  - 1000m yaklaşımda smooth `animateCamera` odaklama
  - Yaklaşan radar + canlı mesafe gösteren floating bottom card

## Master Integration & Orchestration (Production Skeleton)

- **Dependency Injection (GetIt)**
  - `lib/app/di/service_locator.dart`
  - API, Repository, Bloc, Geofencing, Network monitor, Notification servisleri singleton kayıtlı
- **App Bootstrap**
  - `lib/app/app_bootstrap.dart`
  - `runApp` öncesi async init: DI, permission preflight, network monitor, geofencing initialize
- **Environment Profiles (dev/staging/prod)**
  - `lib/app/config/app_environment.dart`
  - `APP_ENV` + `BFF_BASE_URL` dart-define ile profile-aware baseUrl
- **Reactive Flow**
  - `RadarBloc` veriyi alır -> `RadarHomePage` state dinler
  - Başarılı state'te `GeofencingService.syncTrackedRadars(...)` çağrılır
  - Aynı state `RadarMapPage` UI'ını besler
- **Lifecycle Management**
  - `AppRoot` içinde `WidgetsBindingObserver`
  - `resumed` durumunda geofencing re-check yapılır
  - background'da tracking durdurulmaz (foreground location config)
- **Global Error Handling**
  - `GlobalErrorBus` + `GlobalUiWrapper`
  - API/GPS/Internet sorunları merkezi snackbar hattından gösterilir
- **Retry & Offline Queue**
  - `RadarRepositoryImpl`: exponential retry/backoff
  - `RadarRequestQueue`: ağ yokken istekleri local kuyruğa alır
  - `RadarSyncCoordinator`: internet geri geldiğinde bekleyen istekleri replay eder
- **Clean main.dart**
  - `main.dart` sadece bootstrap + `AppRoot` başlatır

## Rota UX (Yeni)

- `RadarHomePage` artık hardcoded rota yerine form tabanlıdır
- Kullanıcı `fromDistrict` / `toDistrict` girer ve radarları çeker
- Son seçilen rotalar `SharedPreferences` ile saklanır ve chip olarak hızlı seçilebilir

## BFF Beklentisi

`POST /api/route`

Request:

```json
{
  "fromDistrict": "Ankara",
  "toDistrict": "Eskisehir"
}
```

Success response (özet):

```json
{
  "success": true,
  "data": {
    "radars": [
      { "id": "r1", "path": [{ "lat": 39.9, "lng": 32.8 }] }
    ],
    "speedTunnels": [
      { "id": "s1", "path": [{ "lat": 39.8, "lng": 32.7 }] }
    ],
    "controlPoints": [
      { "id": "c1", "path": [{ "lat": 39.85, "lng": 32.75 }] }
    ]
  }
}
```

## Hızlı entegrasyon

`lib/app/radar_feature_bootstrap.dart` içinde:
- `RadarFeatureBootstrap.buildRepository(bffBaseUrl: ...)` kullan
- `RadarBloc(repository: ...)` ile state yönetimini başlat

Location engine bootstrap:
- `lib/app/location_engine_bootstrap.dart`
- `LocationEngineBootstrap.build(zones: radarZones)` ile engine üret
- `await engine.initialize()` ile stream + bildirim akışını başlat

Google Maps UX demo:
- `lib/features/radar_feature/presentation/map/radar_map_page.dart`
- `lib/features/radar_feature/presentation/radar_home_page.dart` state tabanlı map akışını açar

## Platform Gereksinimleri (Background/Terminated)

### Android
- `ACCESS_FINE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `POST_NOTIFICATIONS` (Android 13+)
- Foreground location service bildirimi (geolocator `foregroundNotificationConfig`)

### iOS
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `UIBackgroundModes` içine `location`
- Kritik bildirimler için uygun capability/entitlement

## Not

Bu ortamda Flutter/Dart SDK kurulu olmadığı için komutlar burada çalıştırılamadı. SDK kurulduktan sonra aşağıdaki adımları kullanabilirsin:

```bash
flutter pub get
flutter test
flutter analyze
```

## Telefonda deneme (Android/iOS)

> Fiziksel cihazda `localhost` çalışmaz; BFF için bilgisayarının yerel IP'sini kullan.

Kurulum yardımcıları:
- Flutter kurulum scripti: `scripts/setup_flutter_macos.sh`
- Xiaomi saha test runbook: `docs/XIAOMI_REDMI_NOTE_14_PRO_4G_TEST_RUNBOOK.md`

### 1) BFF'i başlat

```bash
cd /Users/admin/Desktop/antiradar/bff
npm install
npm run dev
```

### 2) Bilgisayar IP'sini öğren

```bash
ipconfig getifaddr en0
```

### 3) Flutter app'i profile + base URL ile çalıştır

```bash
cd /Users/admin/Desktop/antiradar/mobile_app
flutter pub get
flutter run --dart-define=APP_ENV=dev --dart-define=BFF_BASE_URL=http://<LOCAL_IP>:3000
```

> Önemli: APK'yı manuel kurarken (`flutter build apk` + `adb install`) `--dart-define=BFF_BASE_URL=...` verilmezse uygulama dev fallback olarak `http://localhost:3000` kullanır. Fiziksel telefonda bu adres backend'e gitmez ve "Ağ bağlantısı yok, istek kuyruğa alındı" hatası görülür.

Manuel APK için doğru örnek:

```bash
cd /Users/admin/Desktop/antiradar/mobile_app
flutter build apk --debug --dart-define=APP_ENV=dev --dart-define=BFF_BASE_URL=http://<LOCAL_IP>:3000
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Web için Google Maps key (lokal, repoya girmez)

`web/maps_api_key.local.js` dosyası oluştur:

```js
window.GMAPS_WEB_API_KEY = 'YOUR_BROWSER_RESTRICTED_KEY';
```

Örnek dosya: `web/maps_api_key.local.js.example`

### Android için Google Maps key (web key'den farklı olmalı)

Mobilde beyaz harita görüyorsan en yaygın neden Android key kısıtlarıdır.

- Google Cloud'da **Maps SDK for Android** aktif olmalı.
- Key, **Application restrictions = Android apps** olacak şekilde kısıtlanmalı.
- Android paket adı: `com.example.antiradar_mobile_app`
- Debug SHA1 (bu projede yerel debug keystore):
  - `7D:EC:A3:36:F0:03:07:5E:84:31:EE:4F:27:CF:5E:15:65:6E:14:0B`

`android/local.properties` içine:

```properties
MAPS_API_KEY=YOUR_ANDROID_RESTRICTED_KEY
```

> Not: `web/maps_api_key.local.js` içindeki browser key ile Android key aynı olmak zorunda değil; çoğu kurulumda ayrı tutulur.

### 4) Örnek profile komutları

```bash
flutter run --dart-define=APP_ENV=staging --dart-define=BFF_BASE_URL=https://staging.example.com
flutter run --dart-define=APP_ENV=prod --dart-define=BFF_BASE_URL=https://api.example.com
```

## Platform izin dosyaları (eklendi)

- Android: `android/app/src/main/AndroidManifest.xml`
  - Konum: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`
  - Bildirim: `POST_NOTIFICATIONS`
  - Arka plan izleme: `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`
  - Harita anahtarı: `com.google.android.geo.API_KEY = ${MAPS_API_KEY}`
- iOS: `ios/Runner/Info.plist`
  - Konum açıklamaları: `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`
  - Background modes: `location`, `fetch`, `remote-notification`
  - Harita anahtarı: `GMSApiKey = $(MAPS_API_KEY)`

> Not: Bu proje Flutter CLI olmadan elde oluşturulduğu için platform klasörleri de manuel eklendi.
> Flutter kurduktan sonra eksik native iskelet dosyaları için gerekirse `flutter create .` çalıştırıp bu izin ayarlarını koruyarak merge et.

## Xiaomi Redmi Note 14 Pro 4G (MIUI) test checklist

1. **Uygulama izinleri**
  - Ayarlar → Uygulamalar → AntiRadar → İzinler
  - Konum: **Her zaman izin ver**
  - Bildirim: **İzin ver**

2. **Pil optimizasyonu kapat**
  - Ayarlar → Pil → Uygulama pil tasarrufu
  - AntiRadar için: **Kısıtlama yok / No restrictions**

3. **Arka planda çalışma izni**
  - Ayarlar → Uygulamalar → AntiRadar → Diğer izinler
  - **Arka planda başlatma** ve benzeri MIUI kısıtlarını aç

4. **Otomatik başlatma**
  - Güvenlik / Uygulamalar bölümünden AntiRadar için **Autostart** açık olsun

5. **Son uygulamalar kilidi (önerilen)**
  - Son uygulamalarda AntiRadar kartını aşağı çekip/uzun basıp kilitle
  - MIUI uygulamayı agresif kapatmasın

6. **Saha testi senaryosu**
  - Uygulamayı aç, rota seç, radarlar gelsin
  - Ekranı kapat / arka plana al
  - 1000m yaklaşıma girerken bildirim geldiğini doğrula
