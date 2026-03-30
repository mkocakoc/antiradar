# Sprint 1 Execution Plan — AntiRadar

## Sprint Objective

Sprint 1’in amacı, uygulamayı "demo" seviyesinden "güvenilir MVP" seviyesine taşımaktır:

1. **Veri güvenilirliği:** rota sonuçları tutarlı ve anlaşılır olmalı.
2. **Ürün dili / UX netliği:** kullanıcı radar ve EDS/hız koridoru farkını net görmeli.
3. **Temel telemetri:** canlı kullanımda nerede sorun yaşandığını ölçebilir olmalıyız.

## Scope (In)

- BFF tarafında rota isteği dayanıklılığı (timeout/retry/standard error body)
- BFF response’unda tutarlı summary alanları
- Mobil tarafta sonuç metinlerinin netleştirilmesi (radar vs EDS)
- Mobilde temel event loglama (request start/success/fail + count bilgileri)
- Boş veri durumunda (EMPTY_DATA) kullanıcı dostu mesaj

## Out of Scope (Sprint 1 dışı)

- CarPlay/Android Auto entegrasyonu
- Çoklu rota alternatifi
- Abonelik/ödeme sistemi
- Gelişmiş hız limiti karşılaştırma motoru

---

## Work Breakdown Structure (WBS)

## 1) Data Reliability (Backend + Contract)

### 1.1 Standard response contract hardening
- [ ] `bff/src/routes/route.js`
  - success/failure response shape’lerinin tek formatta olduğundan emin ol
  - `summary` alanını her durumda güvenilir şekilde dön

**Acceptance Criteria**
- [ ] `POST /api/route` başarılı çağrıda: `data.speedTunnels`, `data.radars`, `data.summary`
- [ ] EMPTY_DATA çağrıda: `success=false`, `error.code=EMPTY_DATA`, `data.summary` 0 değerlerle var
- [ ] Hata body’si mobilin parse edeceği sabit formatta

### 1.2 Retry + timeout policy (upstream)
- [ ] `bff/src/services/icisleri.service.js`
  - kısa timeout + sınırlı retry (idempotent read akışları için)
  - upstream unreachable durumunda belirgin hata kodu

**Acceptance Criteria**
- [ ] Geçici ağ sorunlarında en az 1 retry denenir
- [ ] Toplam bekleme süresi mobilde kötü UX yaratmayacak sınırda kalır
- [ ] Log’ta retry nedeni görülebilir

### 1.3 Backend unit tests
- [ ] `bff/test/route-transformer.test.js` genişlet
- [ ] mümkünse route response shape testleri ekle

**Acceptance Criteria**
- [ ] Radar-only, Tunnel-only, Mixed, Empty fixture’ları geçer
- [ ] `summary` sayıları fixture ile tutarlıdır

---

## 2) Product Language & UX Clarity (Mobile)

### 2.1 Terminology update
- [ ] `mobile_app/lib/features/radar_feature/presentation/radar_home_page.dart`
  - CTA metni: "Radarı Getir" yerine daha kapsayıcı metin
  - Sonuç metni: radar + hız koridoru/EDS ayrı ve net

**Acceptance Criteria**
- [ ] Kullanıcı tek bakışta "radar var/yok" ve "koridor var/yok" ayrımını anlar
- [ ] EMPTY_DATA mesajı teknik değil, kullanıcı diliyle görünür

### 2.2 Empty/partial data UX
- [ ] Radar=0, Koridor>0 senaryosunda info banner/chip
- [ ] Radar>0, Koridor=0 senaryosunda info banner/chip

**Acceptance Criteria**
- [ ] Kısmi veri durumlarında kullanıcı "sistem bozuk" algısına girmez

---

## 3) Telemetry Baseline (Mobile + BFF)

### 3.1 Mobile event logging (phase-1 local/console)
- [ ] `RadarRequested` başlarken event
- [ ] success/failure event + süre + count

Örnek event alanları:
- `eventName`
- `fromDistrict`, `toDistrict`
- `durationMs`
- `radarCount`, `speedTunnelCount`
- `resultType` (success/empty/error)

### 3.2 BFF request log enrichment
- [ ] request-id/correlation-id yaklaşımı
- [ ] route endpoint için status + duration logları

**Acceptance Criteria**
- [ ] Aynı isteğin mobil ve backend tarafı temel seviyede eşleştirilebilir

---

## Execution Order (Step-by-step)

### Step 1 — Contract & Reliability (Backend first)
1. Response shape stabilize et
2. Retry/timeout politikası ekle
3. Backend testlerini güncelle

**DoD:** `POST /api/route` çıktısı her senaryoda deterministic.

### Step 2 — UX & Product Language (Mobile)
1. Metinleri güncelle (Radar/EDS netliği)
2. Kısmi veri banner/chip durumlarını ekle
3. Widget testlerinde temel metin doğrulaması

**DoD:** Kullanıcı radar=0/koridor>0 durumunu doğru anlıyor.

### Step 3 — Telemetry Baseline
1. Mobil event logları
2. BFF süre + durum logları
3. 1-2 uçtan uca smoke run ile log doğrulama

**DoD:** Bir rota denemesinde neden başarı/boş/hata olduğunu logdan okuyabiliyoruz.

---

## Sprint 1 Definition of Done

- [ ] Backend: contract stabil + testler yeşil
- [ ] Mobile: sonuç dili net, partial-data UX hazır
- [ ] Telemetry: temel eventler ve süre ölçümü hazır
- [ ] Dokümantasyon: değişen API ve UI davranışı `README`/docs’da güncel

---

## Riskler ve Önlemler

1. **Upstream API ani değişiklik**
   - Önlem: transformer fallback + guard + test fixture

2. **Yanlış alarm / yanlış beklenti (radar yokken hata sanılması)**
   - Önlem: UI’da data-source açıklaması ve partial-data mesajı

3. **Log gürültüsü**
   - Önlem: sprint 1’de sadece kritik eventler

---

## Suggested Timeline (1 week)

- **Day 1-2:** Backend contract + retry/timeout + tests
- **Day 3-4:** Mobile UX metin + partial-data states + widget tests
- **Day 5:** Telemetry baseline + smoke verification + docs polish
