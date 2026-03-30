# Ürün Kapsamı (MVP)

## 1) Problem Tanımı
Sürücülerin rota sırasında hız limitlerine ve denetim noktalarına dair farkındalığını artırmak.

## 2) Girdi / Çıktı Sözleşmesi (Contract)
- **Girdi:**
  - Başlangıç konumu
  - Varış konumu
  - Kullanıcının bildirim tercihleri
- **Çıktı:**
  - Harita üzerinde rota
  - Rota üzerindeki anlık radar/denetim noktaları
  - Yaklaşma uyarıları (bildirim + in-app)

## 3) Başarı Kriterleri
- Rota oluşturma ve çizme başarılı
- API verisi doğru parse edilip haritada gösteriliyor
- Uyarı koşulu sağlandığında bildirim tetikleniyor
- Android/iOS üzerinde stabil çalışıyor

## 4) Edge Case'ler
1. API geçici olarak erişilemez
2. GPS kapalı / konum izni reddedildi
3. Boş rota veya geçersiz nokta seçimi
4. Çok yoğun veri (yüksek marker sayısı)
5. Arka planda bildirim gecikmesi / OS kısıtları

## 5) Non-Functional Gereksinimler
- Performans: Harita etkileşiminde akıcılık
- Güvenlik: Token saklama ve HTTPS zorunluluğu
- Gizlilik: Konum verisi minimizasyonu
- Dayanıklılık: Retry/backoff ve fallback senaryoları

## 6) Varsayımlar
- İçişleri API'si yasal kullanım için yetkilendirilmiş erişim sunuyor
- Radar/denetim kodları standart bir sözlükle geliyor veya dokümante edilmiş
