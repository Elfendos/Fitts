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

## Simülatör testinde bulunan, henüz düzeltilmemiş

- [ ] **Mark as Done, Profile istatistiklerini güncellemiyor.** Bir egzersizi
      tamamlamak `UserProfile.stats` (Workouts/Streak/Calories) veya
      Achievements'ı otomatik artırmıyor — hiçbir yerde bu bağlantı kurulmamış.

## Sıradaki istek turu (kullanıcıdan gelen, uygulandı — teyit bekliyor)

- [x] **Max Weight artık 2.5 kg adımlarla ilerliyor** (0, 2.5, 5, 7.5, 10...)
      — önceden 1 kg adımdı.
- [x] **"Save" butonu kaldırıldı, her değişiklik otomatik kaydediliyor**
      (sets/reps/max weight steplarının her biri artık kendi başına
      `dailyPlan.save()` tetikliyor).
- [x] **"Mark as Done" artık tamamlanmadan önce nötr (gri) görünüyor**,
      sadece gerçekten işaretlenince yeşile dönüyor — önceden her zaman
      hafif yeşildi, kafa karıştırıyordu.
- [x] **Today ekranında "Add More Exercises" butonu artık alt menünün
      altında kalmıyor** (Home, Exercises, Profile, Weekly Plan, Workout
      History, Muscle Map ekranlarına da aynı düzeltme uygulandı).
- [x] **Max Weight artık hatırlanıyor** — bir harekete bugün girdiğiniz
      ağırlık, o hareketi başka bir güne eklediğinizde otomatik geliyor
      (yeni `ExerciseMaxWeightService`, CloudKit'te ayrı bir kayıt).
- [x] **Exercises sayfası artık tek parça kayıyor** — önceden sadece
      "All Exercises" listesinden aşağı sürüklenebiliyordu, Quick Start
      kısmından da tüm sayfa kayıyor artık.
- [ ] **Bu turun testi yarım kaldı** — simülatörde Mark as Done'ı tekrar
      test ederken koordinat hesaplamalarım tutarsız çıktı (muhtemelen
      benim tıklama noktası hesaplamamdan kaynaklı, kodda bulduğum somut
      bir hata yok), ayrıca ekranda 9 egzersizden 7'si daha önceki
      testlerden zaten "tamamlandı" işaretliydi. Kaldığımız yerden devam
      ederken Mark as Done'ı ve otomatik kaydetmeyi bir kez daha, temiz
      bir günlük planla test etmek lazım.

## Karanlık mod / kontrast turu (kullanıcı ekran görüntüsüyle bildirdi)

- [x] **Dark Mode'da yazılar görünmüyordu (Add Exercise, Quick Start önizleme,
      Today's Workout'taki sayılar).** Kök sebep: `AppTheme` tüm renkleri
      sabit (hep açık) hex değerlerle tanımlıyordu, ama `List`, klavye gibi
      sistem bileşenleri cihazın Dark Mode ayarını takip ediyordu — sonuç
      koyu yazı + koyu zemin. Kullanıcının isteği üzerine ekranı açık moda
      zorlamak yerine `AppTheme`'in nötr renkleri (text/background/subtext/
      border/cardBackground) artık UIKit'in `label`/`systemBackground`/
      `secondaryLabel`/`separator` gibi **uyarlanabilir** renklerine taşındı;
      bunlar sistemin açık/koyu ayarını otomatik takip ediyor. Stat kutuları
      (Start weight/Goal/Daily calories) için de açık/koyu ayrı pastel tonlar
      eklendi. Floating tab bar ve onboarding'in koyu "Next" butonları bilerek
      sabit koyu bırakıldı (`AppTheme.tabBarBackground`) çünkü onlar zaten
      beyaz yazıyla eşleşiyor — `AppTheme.text`'e bağlı kalsalardı Dark
      Mode'da beyaz-üstüne-beyaz olurlardı.
- [x] **Exercises listesinde bazı satırlar 2 satıra taşıp hizası bozuluyordu**
      (uzun isimler, ör. "Incline Dumbbell Press") — başlık artık tek satırla
      sınırlı (`.lineLimit(1)`), tüm satırlar aynı yükseklikte/hizada.
- [x] **Klavye açıkken alt menü (floating tab bar) klavyenin üstünde
      görünüyordu.** Artık klavye açıldığında menü tamamen gizleniyor,
      kapanınca geri geliyor.
- [ ] **Not:** Bu turun düzeltmelerini simülatörde son kez görsel olarak
      teyit edemedim — test sırasında simülatörün iCloud hesabı beklenmedik
      şekilde "erişim kısıtlı" durumuna düştü (kod değişikliğiyle ilgisi yok).
      Kaldığımız yerden devam ederken hem açık hem karanlık modda bir kez
      daha göz gezdirmek iyi olur.

## Bu oturumda düzeltilen bug

- [x] **Onboarding "baştan başlıyor" bug'ı** — `UserProfileService.setHealthProfile`
      ve `updateProfile`, CloudKit'te profil kaydı henüz yoksa (`.unknownItem`)
      sessizce başarısız oluyordu; ardından `onFinished()`'ın tetiklediği
      `load()` boş bir profil daha oluşturup kullanıcıyı sıfırdan onboarding'e
      geri gönderiyordu. `DailyPlanService`/`WorkoutPlanService`'teki
      "kayıt yoksa oluştur" deseni artık `UserProfileService`'e de eklendi.
- [x] **Simülatörde bulunan 3 bug (iPhone 17 Pro testi):**
      1. "Egzersiz Ekle" ekranındaki arama kutusu sheet içinde alta düşüp
         liste içeriğine biniyordu — `.searchable` yerleşimi açıkça
         `.navigationBarDrawer(displayMode: .always)` yapıldı.
      2. Home ekranı, Today sekmesinde veya Exercises'te yapılan değişiklikleri
         göstermiyordu — MainTabView tüm sekmeleri canlı tuttuğu için
         `.onAppear` sadece bir kere tetikleniyordu. HomeView ve
         TodayWorkoutView artık `isActive` parametresiyle sekme her seçildiğinde
         yeniden yükleniyor.
      3. Kas Haritası ekranı Home yeniden tasarlanırken hiçbir yerden
         erişilemez hale gelmişti — Quick Actions'a üçüncü kart olarak
         geri eklendi.
