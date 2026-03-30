# Anti Radar (Trafik Güvenliği Asistanı)

Bu proje, sürücünün **hız limitine uyumunu** ve yol güvenliğini artırmak için geliştirilen Flutter tabanlı mobil uygulamadır.

> Not: Uygulama tasarımı, yasalara uygun sürüş ve güvenlik amacıyla ele alınır. Amaç radar/denetimden kaçınmak değil, kullanıcıyı güvenli sürüş konusunda bilinçlendirmektir.

## Hedef Platformlar
- iOS
- Android

## Ana Özellikler (MVP)
1. Başlangıç ve varış noktası seçimi
2. Rota üzerinde harita gösterimi (Google Maps)
3. Resmi API'den anlık radar/denetim verisi çekimi
4. Rota üzerinde ilgili uyarı noktalarının gösterimi
5. Konuma göre yaklaşma bildirimleri (push/local notification)
6. Basit ayarlar (bildirim açık/kapalı, uyarı mesafesi)

## Önerilen Teknoloji
- **Flutter** (cross-platform)
- **Google Maps Flutter**
- **State Management:** Riverpod
- **Networking:** Dio
- **Local Storage:** SharedPreferences / Hive
- **Notifications:** Firebase Cloud Messaging + Local Notifications

## Dokümanlar
- `docs/01_product_scope.md`
- `docs/02_technical_architecture.md`

## Lisans ve Telif

Bu repository açık kaynak olarak lisanslanmamıştır.

- Lisans: `LICENSE`
- Telif notu: `COPYRIGHT.md`

Özetle: kodun tüm hakları saklıdır (All Rights Reserved). Ürünleştirme,
ticari kullanım, dağıtım veya gelir elde etmeye yönelik kullanım için yazılı
ticari lisans gerekir.
