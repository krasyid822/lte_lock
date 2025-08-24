# LTE Lock - Radio Info Viewer

Aplikasi Flutter untuk mengakses informasi radio/telephony yang sebelumnya tersedia melalui kode dial *#*#4636#*#* pada Android API level 36 dan device yang lebih baru.

## Fitur

- ✅ **Informasi Radio Lengkap**: Menampilkan detail network type, signal strength, dan cell info
- ✅ **Kompatibel API 36**: Dirancang khusus untuk Android API level 36 dan yang lebih baru
- ✅ **Buka Testing Menu**: Tombol untuk membuka menu testing/phone info/radio info langsung
- ✅ **Real-time Info**: Refresh informasi radio secara real-time
- ✅ **Permission Management**: Menangani permission secara otomatis

## Informasi yang Ditampilkan

### Network Information
- **Network Type**: LTE, 5G NR, WCDMA, GSM, dll.
- **Radio Technology**: Teknologi radio yang sedang digunakan
- **Network Class**: 2G, 3G, 4G, 5G
- **Operator**: Nama operator jaringan
- **MCC/MNC**: Mobile Country Code dan Mobile Network Code
- **Roaming Status**: Status roaming

### Signal Information
- **Signal Strength**: Kekuatan sinyal dalam dBm
- **Data State**: Status koneksi data (Connected, Disconnected, dll.)
- **Data Activity**: Aktivitas data (In, Out, In/Out, dll.)

### Cell Information
- **Cell ID**: Identitas cell tower
- **LAC/TAC**: Location Area Code atau Tracking Area Code
- **Cell Signal Strength**: Kekuatan sinyal spesifik cell

## Cara Penggunaan

1. **Install dan Jalankan Aplikasi**
2. **Berikan Permission**: Aplikasi akan meminta permission yang diperlukan
3. **Lihat Info Radio**: Informasi akan ditampilkan secara otomatis
4. **Buka Testing Menu**: Tekan tombol "Buka Testing Menu" untuk mengakses menu testing native Android
5. **Refresh Info**: Tekan tombol "Refresh Info" untuk memperbarui data

## Persyaratan

- **Android API Level**: 21+ (dioptimalkan untuk API 36)
- **Flutter SDK**: 3.0.0+
- **Permissions**: READ_PHONE_STATE, ACCESS_NETWORK_STATE, ACCESS_FINE_LOCATION

## Limitasi untuk API 36

Pada Android API level 36, beberapa fitur yang sebelumnya tersedia melalui *#*#4636#*#* sudah tidak dapat diakses lagi oleh aplikasi pihak ketiga:

- ❌ **Mengubah Network Mode**: Tidak bisa lagi mengubah LTE only, 3G only, dll.
- ❌ **Mengubah Preferred Network Type**: Memerlukan system-level permissions
- ✅ **Membaca Informasi**: Masih bisa membaca semua informasi radio
- ✅ **Membuka Testing Menu**: Bisa membuka menu testing native Android

## Instalasi

### From Source
```bash
git clone [repository-url]
cd lte_lock
flutter pub get
flutter run
```

### Build APK
```bash
flutter build apk --release
```

## Permissions

Aplikasi menggunakan permissions berikut:
- `READ_PHONE_STATE`: Untuk membaca informasi telephony
- `ACCESS_NETWORK_STATE`: Untuk membaca status jaringan
- `ACCESS_COARSE_LOCATION`: Untuk informasi cell tower
- `ACCESS_FINE_LOCATION`: Untuk informasi cell tower yang lebih detail

## Troubleshooting

### Testing Menu Tidak Terbuka
Aplikasi akan mencoba beberapa intent alternatif:
1. `com.android.settings.RadioInfo`
2. `com.android.phone.settings.RadioInfo`
3. `com.samsung.android.app.telephonyui` (untuk Samsung)
4. `com.android.settings.TestingSettings`

### Permission Ditolak
- Pastikan permission diberikan melalui Settings > Apps > LTE Lock > Permissions
- Restart aplikasi setelah memberikan permission

### Informasi Tidak Lengkap
- Beberapa informasi mungkin tidak tersedia tergantung device dan operator
- Coba refresh informasi atau restart aplikasi

## Changelog

### v2.0.0 - Read-Only Mode
- **CHANGED**: Menghapus fungsi mengubah network mode karena API 36 restrictions
- **ADDED**: Tombol untuk membuka testing menu native Android
- **IMPROVED**: Fokus pada menampilkan informasi radio saja
- **FIXED**: Error permission pada API level tinggi

### v1.0.0 - Initial Release
- Fitur lengkap dengan network mode switching (tidak kompatibel dengan API 36)

## Kontribusi

Kontribusi sangat diterima! Silakan buat issue atau pull request untuk perbaikan atau fitur baru.

## Lisensi

MIT License - lihat file LICENSE untuk detail lengkap.
