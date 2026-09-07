# FitApp — Yapılacaklar

Bilinçli olarak ertelenen / basitleştirilen konular. Sırayla ele alınacak.

## Bilinen basitleştirmeler

- [ ] **WorkoutPlan ↔ DailyPlan senkronizasyonu yok.** Weekly Plan (tekrarlayan
      şablon: "Pazartesi = Bench Press...") ile Home/Today's Workout'un
      okuduğu somut günlük kayıtlar (belirli bir tarihe ait) şu an tamamen
      ayrı veri modelleri. Aktif planın günleri otomatik olarak o günün
      DailyPlan'ına işlenmiyor.
- [ ] **Egzersiz detayında gerçek video oynatma yok.** Ekran görüntülerindeki
      "tap to play" video oynatıcı eklenmedi — uygulamada video asset/altyapısı
      olmadığı için.
- [ ] **PRO paywall / abonelik sistemi yok.** Ekran görüntülerindeki kilitli
      "Max Weight PRO" gibi öğeler için hiçbir ödeme altyapısı kurulmadı.
- [ ] **"Ready to train?" antrenman kronometresi yok.** Today's Workout
      ekranındaki canlı süre sayacı henüz eklenmedi.
- [ ] **Floating tab bar, alt ekranlarda da görünüyor.** Today's Workout,
      Workout History, Exercise Detail gibi push edilen ekranlarda da alt
      navigasyon çubuğu görünür durumda kalıyor — normalde bu tür detay
      ekranlarında gizlenmesi beklenir.
- [ ] **Onboarding'deki kilo/boy girişleri düz bir SwiftUI Slider.**
      Ekran görüntülerindeki özel "ruler" (cetvel) sürükleme kontrolü
      pikselinde birebir uygulanmadı.
- [ ] **Weekly Plan'da drag-reorder, plan kopyalama, AI import yok.**
      Orijinal RN ekranındaki bu özellikler kapsam dışı bırakıldı.

## Bu oturumda düzeltilen bug

- [x] **Onboarding "baştan başlıyor" bug'ı** — `UserProfileService.setHealthProfile`
      ve `updateProfile`, CloudKit'te profil kaydı henüz yoksa (`.unknownItem`)
      sessizce başarısız oluyordu; ardından `onFinished()`'ın tetiklediği
      `load()` boş bir profil daha oluşturup kullanıcıyı sıfırdan onboarding'e
      geri gönderiyordu. `DailyPlanService`/`WorkoutPlanService`'teki
      "kayıt yoksa oluştur" deseni artık `UserProfileService`'e de eklendi.
