# Townverse — KotaBareng (Phase 1: Mode Walikota)

Game simulasi pembangunan kota 3D low-poly (*city-builder* + *citizen life* sederhana) untuk **Laptop (Windows)** dan **Android (Landscape)** menggunakan **Godot 4.7.2-stable (GDScript, GL Compatibility)**.

- **Judul Game:** Townverse (*"your city, your rule"*)
- **Kota Pertama:** KotaBareng (Season 2 — Mode Walikota, *single-player offline*)

---

## 1. Cara Menjalankan (F5 di Godot)

1. Buka **Godot 4.7.2-stable (Standard)** dan muat project ini (`project.godot`).
2. Main Scene sudah diarahkan ke `res://scenes/main_menu.tscn`.
3. Tekan **F5** untuk menjalankan game:
   - **Permainan Baru:** memulai kota baru dari Bulan 1, Tahun 1 (modal awal Rp 150.000).
   - **Lanjutkan:** aktif jika sudah ada file save (`user://save_season2.cfg` atau migrasi `user://save.cfg`).
   - **Pengaturan:** mengatur Volume Utama, Musik, SFX, dan toggle Mute (`user://settings.cfg`).

---

## 2. Kontrol (Mouse/Keyboard & Sentuh Android)

### Laptop (Mouse & Keyboard)
- **Klik Kiri (< 5 px):** pakai tool aktif pada tile (pasang jalan, zona, utilitas, farm, panen, bulldoze) atau klik warga / Pak Slamet / Balai Kota.
- **Drag Kiri (> 5 px) atau WASD / Panah:** pan (geser) kamera.
- **Drag Kanan / Tengah:** orbit & ubah sudut kamera.
- **Scroll Wheel:** zoom in / out.
- **Esc:** buka/tutup Pause Menu (atau tutup modal aktif).

### Android (Sentuh — Landscape, tanpa joystick)
- **Tap Tile:** pakai tool aktif / panen / klik warga / Pak Slamet / Balai Kota.
- **Tap Tahan (Long-press ~0.55 detik):** tampilkan info singkat tile/bangunan (tipe, level, status listrik/air, tahap farm).
- **1 Jari Drag di Tanah:** pan (geser) kamera.
- **1 Jari Drag di Tool Palette Bawah:** pilih tool dengan cepat.
- **Pinch 2 Jari:** zoom in / out (tetap berfungsi walau 1 jari sedang menahan tombol tool).
- **Tombol `⟲` / `⟳` di Kanan Bawah:** putar sudut kamera ke kiri/kanan.

---

## 3. Struktur Folder

```text
kota-barengin/
├── data/
│   └── complaints_data.gd          # Data kategori pengaduan warga & opsi solusi
├── scenes/
│   ├── main_menu.tscn              # Main Menu (TOWNVERSE + kota 3D contoh)
│   ├── main.tscn                   # Scene utama kota 3D
│   └── hud.tscn                    # Antarmuka HUD, modal Pak Slamet, Balai Kota, Profil Warga
├── scripts/
│   ├── audio_manager.gd            # Generator SFX prosedural (AudioStreamWAV)
│   ├── building_builder.gd         # Generator mesh 3D low-poly prosedural
│   ├── camera_controller.gd        # Kontrol kamera mouse/keyboard + multitouch
│   ├── car_controller.gd           # Simulasi mobil lalu lintas di jalan
│   ├── city_data.gd                # State kota, grid 16x16, utilitas, ekonomi, warga
│   ├── city_manager.gd             # Loop bulanan, zoning growth, farm, misi, save trigger
│   ├── grid_drawer.gd              # Grid visual 16x16
│   ├── hud.gd                      # Kontrol HUD, bubble 2D, misi, pause & settings
│   ├── main_menu.gd                # Logika Main Menu & kamera orbit showcase
│   ├── save_manager.gd             # Save/Load ConfigFile per Season (save_season2.cfg)
│   ├── citizens/
│   │   └── citizen_manager.gd      # Pejalan kaki, bubble chat, pemicu keluhan warga
│   └── government/
│       └── pak_slamet_manager.gd   # NPC Pak Slamet, parkir liar, 3 opsi kebijakan
├── export_presets.cfg              # Preset export Android (com.andika.kotabarengin, arm64-v8a)
├── project.godot                   # Konfigurasi project Godot 4.7
└── README_PHASE1.md                # Dokumentasi Phase 1 ini
```

---

## 4. Daftar Harga Tool

| Tool | Biaya Bangun | Keterangan |
| :--- | :--- | :--- |
| **Jalan** | Rp 5.000 / tile | Penghubung zona, farm, lalu lintas mobil & warga |
| **Zona R (Perumahan)** | Rp 2.000 / tile | Tumbuh otomatis Lv 1–3 bila dekat jalan + ada listrik & air |
| **Zona C (Komersial)** | Rp 2.000 / tile | Tumbuh otomatis Lv 1–3 (toko/kantor), bayar pajak |
| **Zona I (Industri)** | Rp 2.000 / tile | Tumbuh otomatis Lv 1–3 (pabrik), serap tenaga kerja |
| **Pembangkit Listrik** | Rp 50.000 | Supply 100 unit listrik, upkeep Rp 2.000/bulan |
| **Menara Air** | Rp 30.000 | Supply 100 unit air, upkeep Rp 1.500/bulan |
| **Taman** | Rp 10.000 | +Kebahagiaan sekitar, upkeep Rp 500/bulan |
| **Farm (Gandum)** | Rp 15.000 / tile | Harus dekat jalan; panen tiap 3 bulan (+10 gandum) |
| **Bulldozer** | Gratis | Menghapus tile menjadi kosong |

---

## 5. Daftar 6 Misi Kota

1. **Capai 50 penduduk** — Hadiah `+Rp 50.000`
2. **Capai 100 penduduk** — Hadiah `+Rp 100.000`
3. **Bangun 10 rumah** — Hadiah `+Rp 75.000`
4. **Bangun 1 Pembangkit + 1 Menara Air** — Hadiah `+Rp 50.000`
5. **Panen gandum pertama** — Hadiah `+Rp 25.000`
6. **Capai level Kota Kecil** — Hadiah `+Rp 150.000`

*Hadiah hanya masuk saat tombol **Klaim** ditekan (sekali klaim tiap misi).*

---

## 6. Cara Menambah Bangunan / Tanaman Baru

1. **Tambah tipe tile/tanaman** di `enum TileType` pada `scripts/city_data.gd` beserta konstanta biayanya.
2. **Buat generator mesh 3D prosedural** di `scripts/building_builder.gd` (misalnya `static func _create_nama_mesh() -> Node3D:`), lalu hubungkan di `create_tile_node()`.
3. **Tambahkan `ToolMode`** di `scripts/city_manager.gd` (`_on_tile_clicked`) dan tombolnya di `scenes/hud.tscn` + `scripts/hud.gd`.

---

## 7. Sistem Save / Load

- **Save Season 2 (Mode Walikota):** `user://save_season2.cfg` (format `ConfigFile`, terpisah dari `save_season1.cfg`).
- **Migrasi Save Lama:** Jika ditemukan `user://save.cfg`, otomatis dimuat sekali lalu disimpan ke `user://save_season2.cfg`.
- **Settings Audio:** `user://settings.cfg` (Master, Music, SFX, Mute).
- **Autosave:** berjalan otomatis setiap pergantian bulan dan saat memilih **Keluar ke Menu Utama** di Pause Menu.
- **Manual Save:** melalui tombol **Simpan** di Pause Menu (`Esc` / `☰ Menu`).
