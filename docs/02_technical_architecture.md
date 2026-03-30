# Teknik Mimari (Flutter)

## Mimari Yaklaşım
Feature-first + Clean Architecture light:

- `lib/core`
  - config (env, constants)
  - network (dio client, interceptors)
  - location (permission + stream)
  - notifications
  - error handling
- `lib/features/route_planning`
  - data (api, dto)
  - domain (entities, usecases)
  - presentation (pages, widgets, providers)
- `lib/features/radar_alerts`
  - data/domain/presentation
- `lib/features/settings`

## Önerilen Paketler
- `flutter_riverpod`
- `dio`
- `google_maps_flutter`
- `geolocator`
- `permission_handler`
- `firebase_core`
- `firebase_messaging`
- `flutter_local_notifications`
- `freezed` + `json_serializable`

## Akış
1. Kullanıcı rota seçer
2. Rota servisi polyline üretir
3. Radar servisi rota corridor'ı için anlık denetim verisini çeker
4. Uygulama marker'ları ve uyarı logic'ini günceller
5. Kullanıcı belirlenen eşik mesafesine girince bildirim alır

## Bildirim Stratejisi
- Foreground: in-app banner + local notification
- Background: push notification (gerekli senaryolarda)
- Debounce: aynı radar kodu için kısa sürede tekrar bildirim verme

## Güvenlik Notları
- API anahtarları source code içinde tutulmaz (`--dart-define` + secure storage)
- Tüm çağrılar HTTPS
- Hassas log maskelenir

## Test Stratejisi
- Unit: usecase ve distance/threshold hesaplamaları
- Widget: rota ekranı ve marker render
- Integration: API mock ile uçtan uca akış

## Sonraki Teknik Adım
API sözleşmesi geldiğinde:
1. `data/models` oluşturulacak
2. `RadarRepository` implement edilecek
3. Harita ekranı + canlı konum + bildirim tetikleme kodlanacak
