# itel S23 (S665L) — Manual Lengkap: Unlock Bootloader · TWRP · Root Magisk

> **Perangkat:** itel S23 (S665L) · Unisoc T606 (UMS9230) · Android 12 · slot aktif `_b` · serial adb `1051364385001435`
> **Status per 6 September 2026:** BOOTLOADER **UNLOCKED** · TWRP **TERPASANG** · ROOT Magisk v30.7 **AKTIF** — semuanya terverifikasi.
> **Folder `~/ubl-s23` ini adalah tiket pemulihan Anda.** Terutama `backup_spl/` — **JANGAN PERNAH DIHAPUS.**

---

## Daftar Isi

1. Informasi Perangkat & Status
2. Struktur Folder
3. Hash Referensi (checksum)
4. Aturan Emas — WAJIB DIBACA
5. Masuk & Keluar TWRP
6. Tutorial Fase 1 — Unlock Bootloader (dari nol)
7. Tutorial Fase 2 — Pasang TWRP
8. Tutorial Fase 3 — Root Magisk
9. Skenario Darurat / Troubleshooting
10. Unroot (Kembali ke Stock)
11. Modifikasi Lanjutan
12. Cheat Sheet Perintah Cepat
13. Catatan, Sumber & Riwayat

---

## 1. Informasi Perangkat & Status

| Item | Nilai |
|---|---|
| Model | itel S23 (S665L) |
| SoC | Unisoc T606 (UMS9230) |
| OS | Android 12, enkripsi FBE (File-Based Encryption), kunci layar PIN |
| Slot aktif | `_b` |
| Serial adb | `1051364385001435` |

Kondisi partisi saat ini:

| Partisi | Isi | Catatan |
|---|---|---|
| `boot_b` | Stock + **Magisk 30.7** | sumber root |
| `vendor_boot_b` | **TWRP** (build 2024-05-17) | masuk recovery = TWRP |
| `boot_a`, `vendor_boot_a` | Stock asli | tidak pernah disentuh |
| `/data` | Terenkripsi FBE, utuh | TWRP tidak bisa membukanya (dekripsi tidak didukung) |

## 2. Struktur Folder

```
~/ubl-s23/                              (±347 MB, 19 file)
├── README.md                           ← file ini
├── backup_spl/                         ← BRANKAS — JANGAN DIHAPUS (168 MB)
│   ├── pgpt.bin                        (32 KB — tabel partisi GPT)
│   ├── splloader.bin                   (256 KB — bootloader)
│   ├── uboot.bin                       (3 MB — bootloader)
│   ├── vendor_boot_b.bin               (100 MB — STOCK, rollback TWRP)
│   └── boot_b.bin                      (64 MB — STOCK, rollback Magisk)
├── recovery/
│   └── TWRP_S665L.img                  (100 MB — image TWRP yang terflash)
├── magisk/
│   ├── Magisk-v30.7.apk                (installer app)
│   └── magisk_patched-30700_28E5C.img  (64 MB — boot_b AKTIF saat ini)
└── tool/                               (2,3 MB — alat BROM & bukti unlock)
    ├── spd_dump                        (binary eksploit BROM)
    ├── fdl1-dl.bin                     (loader tahap 1)
    ├── fdl2-dl.bin                     (loader tahap 2)
    ├── fdl2-cboot.bin                  (loader tahap 2 varian cboot — prosedur unlock)
    ├── spl-unlock.bin                  (SPL patch skip-signcheck — prosedur unlock)
    ├── m3.bin                          (bukti token unlock 64 B dari miscdata)
    └── docs/
        ├── README-prosedur-unlock.md   (prosedur unlock lengkap, otoritatif)
        ├── README-spd_dump.md          (dokumentasi spd_dump)
        ├── README-cve-tool.md          (catatan tool CVE)
        └── ums9230-catatan.txt         (catatan teknis SoC)
```

## 3. Hash Referensi (checksum)

Bandingkan sesekali dengan: `sha256sum backup_spl/*.bin recovery/*.img tool/*`

| File | Hash |
|---|---|
| backup_spl/vendor_boot_b.bin | sha256 `e59437a68458283d7b9a20bff9ec3476d51b2590282d9fb978214da2c3e3cc4a` |
| backup_spl/boot_b.bin | sha256 `5958acd5c2a3339772f5a4b0f677c38cd5445058b7186f67c8e01ca20216c4e9` |
| recovery/TWRP_S665L.img | sha256 `a5328be80027a8d595a45a49e232d72849e2aa6000ce13f5ccf4a41ab629b568` |
| magisk/magisk_patched-30700_28E5C.img | md5 `b1a2e19ccf0bf9439c50184034b349b8` — aktif di boot_b |
| tool/spd_dump | sha256 `f52a69d6b23dd80a835942e52295443d7798e3c52f26e7a08a4c8e70890854f9` |
| tool/fdl1-dl.bin | sha256 `ca58692b3f239d454907e2113ae54b3eec1ad021253ac88b38bfc98fbe4b5c4a` |
| tool/fdl2-dl.bin | sha256 `51c65d79e7f8e004998cb9d63842dd77acbcc8f070d88aa1ae3bdde5c6e29804` |
| tool/fdl2-cboot.bin | sha256 `3fa327c24ed657a79a1cab33971fe9c40b8bc7a2bbdc05cbef8a418d803a0801` |
| tool/spl-unlock.bin | sha256 `6295690f1287174b892c1238d9f24981ad2fbcde8da5d43a2b4fbb2214d3d211` |
| tool/m3.bin | sha256 `8bca08ad22137087e06c4f9bd5d05a7b2da3075db30d5b70ee33f4c8df1561fb` |

## 4. Aturan Emas — WAJIB DIBACA

1. **JANGAN PERNAH sentuh Wipe / Format Data di TWRP.** `/data` terenkripsi FBE — format = semua
   data pribadi hilang + HP tidak bisa boot normal.
2. **Saat halaman PIN TWRP muncul → langsung CANCEL.** Dekripsi FBE tidak didukung build TWRP ini;
   operasi Decrypt bisa menggantung dan mengunci layar sentuh. Cancel = TWRP tetap usable
   (flash boot tetap bisa, /data tetap terkunci — tidak masalah).
3. **Menu Reboot di TWRP sering tidak berfungsi.** Selalu reboot dari PC: `adb reboot` (Android)
   atau `adb reboot recovery` (TWRP).
4. **JANGAN re-lock bootloader** selama `vendor_boot_b` masih TWRP / `boot_b` masih patched —
   HP tidak akan boot. Lihat bagian 10.4.
5. **Hindari OTA otomatis** — update bisa menimpa `boot_b`/`vendor_boot_b` (root & TWRP hilang).
   Lihat bagian 11.4.
6. **Sebelum menulis apa pun ke partisi: verifikasi hash.** Aturan tetap: `dd` lalu `md5sum`
   file vs partisi — wajib identik sebelum reboot.
7. `pam-sindu.zip` di `/sdcard/Download/` HP adalah **file pribadi — jangan disentuh**.

## 5. Masuk & Keluar TWRP

**Masuk TWRP:**
- Cara terbaik (terbukti): `adb reboot recovery`
- Cara manual: matikan HP → tahan **Vol(+) + Power** → lepas saat logo muncul

**Di dalam TWRP:**
- Halaman PIN muncul → **CANCEL** (lihat Aturan Emas #2)
- `/data` akan tampil terkunci — itu normal dan tidak menghalangi flash boot

**Keluar dari TWRP:**
- Ke Android: `adb reboot`
- Reboot ulang TWRP: `adb reboot recovery`

## 6. Tutorial Fase 1 — Unlock Bootloader (dari nol)

> **Catatan: fase ini SUDAH SELESAI dan tidak perlu diulang**, kecuali HP pernah kembali ke
> kondisi locked (misal setelah perbaikan servis) atau mencoba prosedur yang sama di HP sejenis.
> **Prosedur ini menghapus semua data** (factory reset adalah langkah resminya). Panduan
> langkah-demi-langkah lengkap tersimpan di `tool/docs/README-prosedur-unlock.md` — ikuti itu
> sebagai referensi otoritatif.

Ringkasan alur yang dilakukan:

1. **Siapkan BROM tool** — `spd_dump` + `fdl1-dl.bin` + `fdl2-dl.bin` (sudah ada di `tool/`).
   Sesiko BROM Unisoc: `exec_addr 0x65015f08`, fdl1 `0x65000800`, fdl2 `0x9efffe00`.
2. **Sesi BROM** — template umum (ganti `<perintah>` sesuai kebutuhan):
   ```bash
   cd ~/ubl-s23/tool
   sudo ./spd_dump --wait 60 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 \
     fdl fdl2-dl.bin 0x9efffe00 exec blk_size 65535 verbose 2 \
     <perintah> reset
   ```
3. **Tulis cboot modifikasi + bersihkan SPL** (`w uboot` dengan payload cboot mod,
   `e splloader` + `e splloader_bak`) → HP mati dan boot berikutnya jatuh ke **BROM fallback**.
4. **Kirim SPL patch** — `spl-unlock.bin` (skip signcheck) + fdl2-cboot → cboot modifikasi
   menjalankan `set_lock_status()` yang **menulis flag unlock ke miscdata**.
5. **Bukti & pulihkan** — baca `miscdata` (menghasilkan `m3.bin`, 64 B token+hash; inilah bukti
   flag tertulis), lalu **restore splloader + splloader_bak + uboot** dari backup, reset.
6. **Factory reset** via menu recovery (perilaku terdokumentasi setelah proses ini) → setup ulang.
7. **Verifikasi**: `adb shell getprop ro.boot.vbmeta.device_state` → `unlocked`;
   `ro.boot.flash.locked` → `0`.

## 7. Tutorial Fase 2 — Pasang TWRP

> S665L **tidak punya partisi recovery** — TWRP ditempatkan di `vendor_boot_b` (vendor_boot v4).
> TWRP hanya dimuat saat boot recovery; boot normal 100% tidak terpengaruh. **Fase ini juga
> sudah selesai** — diulang hanya jika TWRP tertimpa (misal oleh OTA).

Sesi BROM tunggal (backup dulu bila backup lama tidak ada, lalu tulis):

```bash
cd ~/ubl-s23/tool
sudo ./spd_dump --wait 60 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 \
  fdl fdl2-dl.bin 0x9efffe00 exec blk_size 65535 verbose 2 \
  r vendor_boot_b \
  w vendor_boot_b ~/ubl-s23/recovery/TWRP_S665L.img reset
```

Verifikasi keberhasilan:
- Log: `Write Part Done: vendor_boot_b, target: 0x6400000, written: 0x6400000` (penuh 100 MB)
- AVB footer image: `vbmeta_offset 0x3C63000, vbmeta_size 0x8C0` (stock = `0x1386000`)
- Uji: `adb reboot recovery` → TWRP muncul → **Cancel** di halaman PIN

## 8. Tutorial Fase 3 — Root Magisk

> Metode: **Select and Patch a File**. Target: partisi `boot_b` (Android 12 GKI — **BUKAN**
> init_boot). Fase ini juga sudah selesai; diulang hanya saat re-patch (bagian 9.6 / 11.4).

| Langkah | Perintah / Aksi |
|---|---|
| M0 Backup boot (dari TWRP) | `adb shell dd if=/dev/block/by-name/boot_b of=/tmp/boot_b.bin` → `adb pull /tmp/boot_b.bin backup_spl/boot_b.bin` → `sha256sum` = `5958acd5...` |
| M1 Boot normal | `adb reboot` → `adb devices` = `device` |
| M2 Install Magisk | `wget` `Magisk-v30.7.apk` dari `github.com/topjohnwu/Magisk/releases/latest` (ambil URL persis dari API, nama file memuat versi) → `adb install` |
| M3 Kirim boot ke HP | `adb push backup_spl/boot_b.bin /sdcard/Download/boot.img` |
| M4 Patch di HP | Aplikasi Magisk → **Install** → **Select and Patch a File** → `boot.img` → menghasilkan `magisk_patched-30700_XXXXX.img` |
| M5 Tarik ke PC | `adb pull /storage/emulated/0/Download/magisk_patched-*.img ~/ubl-s23/magisk/` |
| M6 Flash ke boot_b (dari TWRP) | `adb reboot recovery` → `adb push magisk/magisk_patched-*.img /tmp/` → `adb shell dd if=/tmp/magisk_patched-*.img of=/dev/block/by-name/boot_b` → **`adb shell md5sum /tmp/*.img /dev/block/by-name/boot_b` — WAJIB identik** → `adb reboot` |
| M7 Verifikasi root | Aplikasi Magisk: *Installed 30.7* · `adb shell su -c id` → `uid=0(root) ... context=u:r:magisk:s0` |

## 9. Skenario Darurat / Troubleshooting

| # | Gejala | Sebab umum | Penanganan |
|---|---|---|---|
| 1 | Bootloop setelah install modul Magisk | modul bermasalah | → 9.1 |
| 2 | Bootloop setelah flash boot | boot_b rusak | → 9.2 |
| 3 | Tidak bisa boot sistem, TWRP pun bermasalah | boot/vendor_boot rusak | → 9.3 |
| 4 | TWRP macet "decrypt FBE", layar tak bisa disentuh | TEE Unisoc tidak menjawab | → 9.4 |
| 5 | Menu Reboot TWRP tidak bereaksi | bug build TWRP | → 9.5 |
| 6 | Root/Magisk hilang setelah update sistem | OTA menimpa boot_b | → 9.6 |
| 7 | TWRP hilang setelah update sistem | OTA menimpa vendor_boot_b | → 9.7 |
| 8 | Layar hitam total, tidak ada logo, tidak terdeteksi PC | brick boot chain | → 9.8 |

**9.1 Safe Mode Magisk (modul bermasalah — coba paling dulu)**
Tahan **Vol(+)** sejak HP dinyalakan sampai selesai boot → Magisk masuk *Safe Mode* (semua
modul nonaktif, HP boot normal) → buka aplikasi Magisk → hapus modul bermasalah → reboot.

**9.2 Restore boot_b stock via TWRP** (HP masih bisa masuk TWRP)
```bash
cd ~/ubl-s23
adb push backup_spl/boot_b.bin /tmp/
adb shell dd if=/tmp/boot_b.bin of=/dev/block/by-name/boot_b
adb shell md5sum /tmp/boot_b.bin /dev/block/by-name/boot_b   # wajib IDENTIK
adb reboot
```
Hasil: root & Magisk hilang (bisa di-root ulang lewat bagian 8), TWRP tetap ada.

**9.3 Restore via BROM** (bootloop berat / TWRP tidak bisa diandalkan)
Masuk mode BROM: HP mati total → tahan **Vol(−)** sambil colok USB → `--wait 60` menunggu
deteksi (kalau lewat 60 detik, cabut-pasang kabel dan ulangi).
```bash
cd ~/ubl-s23/tool
# pulihkan TWRP / vendor_boot:
sudo ./spd_dump --wait 60 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 \
  fdl fdl2-dl.bin 0x9efffe00 exec blk_size 65535 verbose 2 \
  w vendor_boot_b ~/ubl-s23/recovery/TWRP_S665L.img reset
# pulihkan boot stock (ganti baris w):
#   w boot_b ~/ubl-s23/backup_spl/boot_b.bin reset
```

**9.4 TWRP macet saat dekripsi FBE** — percobaan Decrypt menunggu jawaban secdis/TEE yang tidak
datang dan **mengunci layar sentuh**. Solusi terbukti: `adb reboot recovery` dari PC → saat
halaman PIN muncul → **langsung Cancel**. Jangan isi PIN.

**9.5 Menu Reboot TWRP mati** — selalu gunakan `adb reboot` / `adb reboot recovery` dari PC
(adbd TWRP hampir selalu hidup).

**9.6 Root hilang setelah OTA** — boot_b dikembalikan stock oleh update. Backup dulu boot baru:
`dd if=/dev/block/by-name/boot_b` (dari TWRP) → simpan → ulangi langkah **M2–M6** di bagian 8
dengan boot.img yang baru.

**9.7 TWRP hilang setelah OTA** — vendor_boot_b tertimpa stock. Flash ulang TWRP via BROM:
lihat 9.3 (baris `w vendor_boot_b ...TWRP_S665L.img`).

**9.8 Brick berat** (bootloader rusak) — penulisan ulang `pgpt`, `splloader`, `uboot` dari
`backup_spl/` via BROM (`w pgpt ...`, `w splloader ...`, `w uboot ...`). **Lakukan hanya dengan
panduan** — urutan dan ukurannya kritis. Semua file tersedia di brankas.

## 10. Unroot (Kembali ke Stock)

**10.1 Lewat aplikasi (HP boot normal — cara termudah)**
Aplikasi Magisk → **Uninstall** → **Complete Uninstall** → HP reboot sendiri → verifikasi:
`adb shell su -c id` harus **ditolak / not found**.

**10.2 Manual (terjamin)** — restore `boot_b` stock via TWRP: lihat **9.2**.

**10.3 Full stock 100%** (unroot + TWRP ikut dihilangkan) — restore `vendor_boot_b` stock via
BROM:
```bash
cd ~/ubl-s23/tool
sudo ./spd_dump --wait 60 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 \
  fdl fdl2-dl.bin 0x9efffe00 exec blk_size 65535 verbose 2 \
  w vendor_boot_b ~/ubl-s23/backup_spl/vendor_boot_b.bin reset
```

**10.4 JANGAN re-lock bootloader.** Re-lock (`fastboot flashing lock` atau setara) selama ada
partisi non-stock = verified boot gagal = **brick**. Bahkan setelah full stock, re-lock tetap
tidak disarankan pada perangkat ini.

## 11. Modifikasi Lanjutan

**11.1 Update Magisk** — aplikasi Magisk → *Install* → **Direct Install** (tanpa TWRP, tanpa
PC) → reboot → cek `adb shell su -c id`.

**11.2 Zygisk & modul** — aktifkan Zygisk di Magisk → Settings → reboot. Install modul dari
aplikasi. Aturan aman: satu modul per waktu, sumber terpercaya, catat modul yang aktif. Kalau
bootloop → **9.1** (Safe Mode) → 9.2 bila perlu.

**11.3 App bank / Play Integrity** — umumnya butuh Zygisk + modul *Play Integrity Fix* dan
penyembunyi root. Hasilnya tidak dijamin (kebijakan Google berubah); risiko: akun ketat
mendeteksi root.

**11.4 OTA update** — nonaktifkan update otomatis di Setelan. Jika OTA terlanjur jalan:
biasanya root/TWRP hilang tapi HP selamat → pulihkan lewat **9.6** dan **9.7**. Kalau OTA
memicu bootloop → **9.2 / 9.3**.

**11.5 GSI / custom ROM** — dimungkinkan karena bootloader unlocked, tapi kombinasi vendor
Unisoc + FBE berisiko tinggi. Riset khusus S665L dulu; brankas + bagian 9 selalu jaring
pengaman terakhir.

## 12. Cheat Sheet Perintah Cepat

```bash
# Cek root
adb shell su -c id

# Masuk TWRP / kembali ke Android
adb reboot recovery
adb reboot

# Integritas brankas (bandingkan dengan tabel hash bagian 3)
cd ~/ubl-s23 && sha256sum backup_spl/*.bin recovery/*.img

# Sesi BROM umum (ganti <perintah>)
cd ~/ubl-s23/tool
sudo ./spd_dump --wait 60 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 \
  fdl fdl2-dl.bin 0x9efffe00 exec blk_size 65535 verbose 2 \
  <perintah> reset

# Contoh <perintah> yang terbukti:
#   r vendor_boot_b                          (backup)
#   w vendor_boot_b <file.img>               (tulis TWRP / stock)
#   w boot_b <file.img>                      (tulis boot)
#   r miscdata 8192 64                       (baca flag unlock)
```

## 13. Catatan, Sumber & Riwayat

**Sumber alat:**
- `spd_dump` — github.com/TomKing062/CVE-2022-38694_unlock_tool (CVE-2022-38694)
- TWRP_S665L.img — release "For_s23", Massatriof16/recovery-collections (build 2024-05-17)
- Magisk — github.com/topjohnwu/Magisk (v30.7 stable)
- Prosedur unlock lengkap: `tool/docs/README-prosedur-unlock.md` (otoritatif)

**Catatan teknis:**
- Pre-init storage Magisk: `cache` (normal untuk perangkat ini)
- `fdl2-cboot.bin` & `spl-unlock.bin` disimpan sebagai **artefak prosedur unlock** — tidak
  dibutuhkan untuk rollback harian, tapi penting bila proses unlock harus diulang
- Slot `boot_a` / `vendor_boot_a` tetap stock — cadangan tambahan bila suatu saat dibutuhkan

**Riwayat:**
- 5–6 September 2026: unlock bootloader (CVE-2022-38694) → TWRP di vendor_boot_b → root
  Magisk 30.7 — semua terverifikasi (`uid=0(root) ... context=u:r:magisk:s0`)
- 6 September 2026: folder kerja dirapikan (1.729 file / 432 MB → 19 file / ±347 MB) —
  venv, repo source, dan sisa percobaan dihapus; artefak terbukti diselamatkan ke `tool/`
