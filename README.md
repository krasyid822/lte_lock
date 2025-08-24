# LTE Lock - Radio Info App

Aplikasi Flutter untuk mengakses informasi radio/telephony yang menggantikan menu *#*#4636#*#* yang sudah tidak dapat diakses pada Android API level 36.

## Fitur

- **Informasi Radio Lengkap**: Menampilkan informasi jaringan, signal strength, cell ID, LAC/TAC, MCC, MNC, dan lainnya
- **LTE Lock**: Memaksa perangkat untuk menggunakan jaringan LTE/4G saja
- **Auto Mode**: Mengembalikan ke mode otomatis pemilihan jaringan
- **Real-time Monitoring**: Refresh informasi secara real-time
- **UI Modern**: Interface yang mudah digunakan dengan indikator visual

## Informasi yang Ditampilkan

1. **Network Type**: Jenis jaringan (2G/3G/4G/5G) dengan deskripsi teknologi
2. **Signal Strength**: Kekuatan sinyal dalam dBm dengan indikator kualitas
3. **Cell ID**: Identitas cell tower
4. **LAC/TAC**: Location Area Code atau Tracking Area Code
5. **MCC/MNC**: Mobile Country Code dan Mobile Network Code
6. **Operator**: Nama operator jaringan
7. **Data State**: Status koneksi data
8. **Data Activity**: Aktivitas data (In/Out/None)
9. **Roaming**: Status roaming
10. **Network Class**: Kelas jaringan (2G/3G/4G/5G)
11. **Radio Technology**: Teknologi radio yang digunakan

## Persyaratan

- Flutter SDK 3.9.0 atau lebih baru
- Android API 21+ (Android 5.0+)
- Permissions:
  - `READ_PHONE_STATE`
  - `ACCESS_NETWORK_STATE`
  - `ACCESS_COARSE_LOCATION`
  - `ACCESS_FINE_LOCATION`

## Instalasi dan Build

1. Clone repository ini
2. Jalankan `flutter pub get` untuk menginstall dependencies
3. Build aplikasi:
   ```bash
   flutter build apk --release
   ```

## Penggunaan

1. Buka aplikasi
2. Berikan izin akses yang diperlukan
3. Aplikasi akan otomatis menampilkan informasi radio
4. Gunakan tombol "LTE Only" untuk memaksa jaringan 4G
5. Gunakan tombol "Auto Mode" untuk kembali ke mode otomatis
6. Gunakan tombol refresh untuk memperbarui informasi

## Catatan Penting

### Android API Level 36 Compatibility

Pada Android API level 36, beberapa fitur memerlukan permission sistem yang lebih tinggi:

1. **Membaca Informasi Radio**: Sebagian besar informasi dapat diakses dengan permission normal
2. **Mengubah Mode Jaringan**: Memerlukan permission sistem (`MODIFY_PHONE_STATE`)
3. **Informasi Privileged**: Beberapa informasi memerlukan `READ_PRIVILEGED_PHONE_STATE`

### Limitasi

- Fitur LTE Lock mungkin tidak berfungsi pada semua perangkat tanpa root
- Beberapa informasi mungkin tidak tersedia tergantung pada versi Android dan kebijakan OEM
- Permission sistem memerlukan aplikasi untuk menjadi aplikasi sistem

## Dependensi

- `flutter`: Framework utama
- `permission_handler`: Untuk menangani permission
- `android_intent_plus`: Untuk intent Android (optional)

## Kontribusi

Aplikasi ini dibuat sebagai alternatif untuk menu engineering mode (*#*#4636#*#*) yang sudah tidak dapat diakses pada Android versi terbaru. Kontribusi dan saran perbaikan sangat diterima.

## Lisensi

Proyek ini dibuat untuk tujuan edukasi dan penggunaan pribadi.
