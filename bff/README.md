# AntiRadar BFF (Node.js + Express)

Flutter uygulaması ile İçişleri Bakanlığı `CreateRoute` servisi arasında çalışan BFF katmanıdır.

## Özellikler
- `POST /api/route` endpoint'i
- `FromDistrict` / `ToDistrict` ile upstream çağrı
- `SpeedTunnels` ve `Radars` parse + sadeleştirme
- Koordinatları `double`'a çevirme ve harita dostu `path` (`[{lat,lng}]`) üretimi
- Anlamlı hata çıktısı + boş state dönüşü
- Helmet ve CORS güvenlik katmanı

## Kurulum
```bash
npm install
```

## Çalıştırma
```bash
npm run dev
```

## Test
```bash
npm test
```

## İstek Örneği
`POST /api/route`

Body:
```json
{
  "fromDistrict": "Ankara",
  "toDistrict": "Eskişehir"
}
```

## Başarılı Yanıt Şeması
```json
{
  "success": true,
  "message": "Güzergah verisi başarıyla alındı.",
  "data": {
    "speedTunnels": [
      {
        "id": "123",
        "type": "speed_tunnel",
        "label": "Tünel 1",
        "district": "Ankara",
        "road": "D200",
        "path": [{ "lat": 39.92, "lng": 32.85 }],
        "pathPointCount": 1
      }
    ],
    "radars": [],
    "summary": {
      "speedTunnelCount": 1,
      "radarCount": 0
    }
  }
}
```
