# Xiaomi Redmi Note 14 Pro 4G - Test Runbook

## 1) Geliştirme ortamı

1. Flutter SDK kurulu olmalı
2. Android SDK + platform tools kurulu olmalı
3. Telefonda Geliştirici Seçenekleri + USB hata ayıklama açık olmalı

## 2) BFF başlatma

```bash
cd /Users/admin/Desktop/antiradar/bff
npm install
npm run dev
```

## 3) Mac IP adresini al

```bash
ipconfig getifaddr en0
```

Örnek çıktı: `192.168.1.25`

## 4) Uygulamayı cihaza gönder

```bash
cd /Users/admin/Desktop/antiradar/mobile_app
flutter pub get
flutter run --dart-define=APP_ENV=dev --dart-define=BFF_BASE_URL=http://192.168.1.25:3000
```

> Not: Aynı Wi-Fi ağına bağlı olmalısın.

## 5) Xiaomi/HyperOS ayarları (kritik)

- Ayarlar → Uygulamalar → AntiRadar → İzinler
  - Konum: **Her zaman izin ver**
  - Bildirim: **Açık**
- Ayarlar → Pil → Uygulama pil tasarrufu
  - AntiRadar: **Kısıtlama yok**
- Ayarlar → Uygulamalar → AntiRadar → Diğer izinler
  - Arka planda çalıştırma: **Açık**
- Güvenlik/İzinler bölümünde Auto-start: **Açık**
- Son uygulamalarda kart kilidi: **Açık** (MIUI process kill azaltmak için)

## 6) Kabul kriteri testleri

1. Route formundan ilçe seçip radar verisi çek
2. Haritada radar ikonları + speed tunnel dashed polyline görünmeli
3. Uygulamayı arka plana al
4. Radar başlangıcına yaklaşırken bildirim gelmeli
5. Aynı radar için 1 saat içinde tekrar bildirim gitmemeli (cooldown)

## 7) Hızlı sorun giderme

- Veri gelmiyor:
  - BFF log kontrol et
  - `BFF_BASE_URL` IP/port doğru mu kontrol et
- Bildirim gelmiyor:
  - Android 13+ bildirim izni açık mı?
  - Pil optimizasyonu gerçekten kapalı mı?
- Arka planda kesiliyor:
  - Auto-start ve background izinlerini tekrar kontrol et
