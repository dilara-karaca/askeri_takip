# Fizyolojik Takip

Askeri personelin giyilebilir pazuband üzerinden nabız, SpO₂, cilt sıcaklığı ve GSR (stres) verilerini izlemesini; komuta / sağlık irtibatının ise aynı ölçümleri ve konumu takip etmesini sağlayan Flutter uygulaması.

Paket adı (`kronik_hasta_takip`) geçmiş bir kronik hasta takip projesinden gelir. Uygulama adı **Fizyolojik Takip**, odak ise saha personelinin fizyolojik farkındalığıdır.

Bu uygulama teşhis koymaz. Eşikler yalnızca arayüzde NORMAL / DİKKAT / KRİTİK durumunu göstermek içindir; LSTM veya arka uç anomali motoru yoktur.

## Ne işe yarar?

Personel, ESP32 tabanlı pazubandı Bluetooth ile telefona bağlar. Ölçümler ana sayfada kartlar halinde görünür. Değerler eşik dışına çıkınca durum rengi değişir. Acil durumda **ACİL** düğmesi 112 tuş takımını açar ve bağlı komuta hesaplarına bildirim gönderir.

Komuta hesabı, personel kodu ile bağlanır. Komuta ana sayfasında personelin vitalleri ve bildirimleri görünür; harita üzerinden son konum izlenebilir.

## Roller

| Rol | Kayıt ekranı | Ne görür? |
| --- | --- | --- |
| **Personel** | Personel kaydı | Kendi vitalleri, cihaz bağlantısı, acil durum, saha sağlık asistanı |
| **Komuta** | Komuta kaydı | Bağlı personelin vitalleri, bildirimler, harita |

Personel kaydında `HT` ile başlayan 6 karakterlik bir kod üretilir (örnek: `HTA3K9`). Komuta bu kodu girerek ilgili personele bağlanır.

## Özellikler

- E-posta, telefon / SMS ve Google ile giriş
- E-posta doğrulama ve şifre sıfırlama
- BLE ile pazuband bağlantısı (`flutter_blue_plus`)
- Nabız, SpO₂, cilt sıcaklığı, GSR / stres, adım sayısı
- NORMAL / DİKKAT / KRİTİK durum göstergesi
- Periyodik konum güncelleme (yaklaşık 30 saniye)
- Acil durum: 112 tuş takımı + komuta bildirimi
- Komuta tarafında Google Haritalar ile personel konumu
- Saha Sağlık Asistanı: ölçüm aralıkları hakkında bilgi verir, teşhis koymaz
- Profil, güvenlik, hesap silme ve acil durum irtibatları

## Fizyolojik eşikler

Kaynak: SAVTEK 2026 bildirimindeki arayüz eşikleri (`lib/utils/physiological_status.dart`).

| Ölçüm | Normal | Dikkat | Kritik |
| --- | --- | --- | --- |
| Nabız (BPM) | 60–100 | 50–59 veya 101–120 | &lt; 50 veya &gt; 120 |
| SpO₂ | ≥ %95 | %90–94 | &lt; %90 |
| Cilt sıcaklığı | 33–37 °C | 33 °C altı veya 37–38.5 °C | &gt; 38.5 °C |
| GSR | dinlenimde düşük (≤ 20) | yüksek / süren (&gt; 40) | — |

BLE paketi `TEMP:...|BPM:...` biçiminde gelir. Cihaz bağlı değilken arayüz, pazuband OLED’indeki örnek değerlerle doldurulabilir.

## Teknoloji

- Flutter / Dart (SDK `^3.7.0`)
- Firebase Auth, Cloud Firestore, Firebase Core
- `flutter_blue_plus`, `permission_handler`, `pedometer`
- `google_maps_flutter`, `geolocator`
- `fl_chart`, `google_fonts`, `url_launcher`

Arka uç olarak Firebase kullanılır. Koleksiyonlar:

- `patients` — personel profili, konum, personel kodu
- `relatives` — komuta hesabı (`linkedPatient` ile personele bağlı)
- `patientCodes` — kod → personel UID eşlemesi
- `notifications` — acil durum bildirimleri

## Proje yapısı

```
lib/
  main.dart                 # Rotalar, rol yönlendirmesi, alt navigasyon
  firebase_options.dart     # FlutterFire yapılandırması
  screens/                  # Giriş, kayıt, ana sayfa, acil, harita, ayarlar
  services/                 # Personel kodu üretimi ve eşleme
  theme/                    # Renkler ve Material teması
  utils/                    # Fizyolojik eşik değerlendirmesi
  widgets/                  # Ortak kart, buton, alan, navigasyon
```

Personel akışı: Ana Sayfa ↔ Ayarlar, ortada **ACİL**.
Komuta akışı: Ana Sayfa ↔ Ayarlar, ortada konum / harita.

## Kurulum

1. [Flutter](https://docs.flutter.dev/get-started/install) kurulu olsun (`flutter doctor`).
2. Bağımlılıkları alın:

   ```bash
   flutter pub get
   ```

3. Google Maps için `android/local.properties` dosyasına anahtar ekleyin:

   ```
   MAPS_API_KEY=your_maps_api_key
   ```

4. Uygulamayı çalıştırın:

   ```bash
   flutter run
   ```

Firebase (`lib/firebase_options.dart`, `android/app/google-services.json`) projeye zaten bağlıdır. Yeni bir Firebase projesi kullanacaksanız FlutterFire CLI ile yeniden yapılandırın.

Gerekli Android izinleri: Bluetooth tarama / bağlantı, konum, aktivite tanıma (adım sayacı).

## Kullanım özeti

1. Personel hesabı oluşturun; e-postayı doğrulayın.
2. Ana sayfadaki personel kodunu komuta kaydında girin.
3. Ayarlar → Cihaz Bağlantısı ile pazubandı eşleyin.
4. Vitalleri ve durum şeridini izleyin.
5. Kritik durumda **ACİL** ile 112’yi açın; bağlı komuta bildirim alır.
6. Komuta hesabı haritadan personelin son konumunu görür.

## Notlar

- Saha Sağlık Asistanı yalnızca eşik açıklaması yapar; tıbbi tavsiye vermez.
- Konum, personel oturumu açıkken Firestore’a yazılır; komuta bunu haritada okur.
- Paket adı ve bazı koleksiyon adları (`patients`, `relatives`) eski hasta / hasta yakını modelinden kalmıştır; arayüzdeki karşılıkları Personel ve Komuta’dır.
