class_name ComplaintsData
extends RefCounted

## Bank data keluhan warga KotaBareng (Phase 1 Langkah 5 & persiapan masa depan)

# 3 Keluhan aktif di Phase 1:
const COMPLAINT_TRAFFIC: String = "macet"
const COMPLAINT_TRASH: String = "sampah"
const COMPLAINT_TRAFFIC_LIGHT: String = "lampu_merah"
const COMPLAINT_NO_SCHOOL: String = "tidak_ada_sekolah"
const COMPLAINT_NO_HEALTH: String = "tidak_ada_berobat"
const COMPLAINT_INSECURE: String = "tidak_aman"
const COMPLAINT_NO_FIRE: String = "takut_kebakaran"
const COMPLAINT_FIRE: String = "kebakaran"
const COMPLAINT_ANGKOT_NGETEM: String = "angkot_ngetem"
const COMPLAINT_PUNGLI: String = "pungli"
const COMPLAINT_POLLUTION: String = "polusi"
const COMPLAINT_FLOOD: String = "banjir"
const COMPLAINT_BLACKOUT: String = "mati_listrik"
const COMPLAINT_DIRTY_WATER: String = "air_kotor"
const COMPLAINT_BAD_ROAD: String = "jalan_rusak"
const COMPLAINT_INFLATION: String = "harga_naik"
const COMPLAINT_UNEMPLOYMENT: String = "pengangguran"
const COMPLAINT_NO_TRANSIT: String = "tidak_ada_transportasi"
const COMPLAINT_AIRPORT_NOISE: String = "kebisingan_bandara"
const COMPLAINT_EVENT_BANJIR: String = "event_banjir"
const COMPLAINT_EVENT_DEMO: String = "event_demo"

# Variasi kalimat bubble chat untuk 3 keluhan utama
const COMPLAINT_QUOTES = {
	COMPLAINT_TRAFFIC: [
		"duh ini macet banget sih, katanya cuma 15 menit doang di maps",
		"antrean mobil nggak gerak-gerak, ada yang parkir sembarangan ya di depan?",
		"aduh telat absen kantor ini mah kalau jalanannya macet begini",
		"mobil pada parkir makan badan jalan, tolong ditertibkan dong Pak Wali!"
	],
	COMPLAINT_TRASH: [
		"sampah di depan rumah udah seminggu nggak diangkut, baunya sampai ke dalam",
		"tong sampah perumahan udah meluber ke selokan, takutnya jadi sarang nyamuk",
		"lingkungan kita butuh taman atau bak sampah terpadu biar nggak jorok begini",
		"baunya menusuk hidung tiap lewat sini, tolong armada kebersihan segera datang"
	],
	COMPLAINT_TRAFFIC_LIGHT: [
		"lampu merahnya lama banget, udah 3x hijau di seberang, kita masih merah",
		"persimpangan ini ruwet banget, harusnya ada petugas atau durasi lampu disesuaikan",
		"antre lampu merah sampai 4 kali siklus baru bisa nyeberang, capek betul",
		"durasi hijaunya cuma 10 detik tapi merahnya 120 detik, nggak seimbang!"
	],
	COMPLAINT_NO_SCHOOL: [
		"tidak ada sekolah di kota ini, anak-anak harus sekolah ke kota sebelah",
		"warga butuh Sekolah biar anak-anak bisa belajar dekat rumah, Pak Wali"
	],
	COMPLAINT_NO_HEALTH: [
		"tidak ada tempat berobat, kalau sakit bingung mau periksa ke mana",
		"tolong bangun Puskesmas atau Rumah Sakit, warga butuh layanan kesehatan"
	],
	COMPLAINT_INSECURE: [
		"tidak aman, sering ada pencurian di lingkungan perumahan malam hari",
		"warga resah karena tidak aman dan sering ada pencurian, butuh Kantor Polisi"
	],
	COMPLAINT_NO_FIRE: [
		"takut kebakaran, tidak ada damkar kalau sewaktu-waktu ada api",
		"kota makin ramai tapi belum ada Damkar, warga takut kebakaran besar"
	],
	COMPLAINT_FIRE: [
		"Kebakaran! Tolong! Ada bangunan terbakar, segera padamkan!"
	],
	COMPLAINT_ANGKOT_NGETEM: [
		"angkotnya ngetem terus di tengah jalan, bikin macet panjang!",
		"butuh Halte Angkot biar angkot nggak ngetem sembarangan"
	],
	COMPLAINT_PUNGLI: [
		"ada pungutan liar di persimpangan, tolong ditertibkan Pak Wali!"
	],
	COMPLAINT_POLLUTION: [
		"asap pabrik bikin sesak napas anak-anak, tolong dikendalikan"
	],
	COMPLAINT_FLOOD: [
		"hujan sebentar air selokan langsung meluap ke jalan, butuh normalisasi"
	],
	COMPLAINT_BLACKOUT: [
		"listrik sering padam mendadak, warga & toko terganggu"
	],
	COMPLAINT_DIRTY_WATER: [
		"air keran keruh dan berbau, tolong cek jaringan pipa air"
	],
	COMPLAINT_BAD_ROAD: [
		"banyak jalan berlubang, rawan pengendara motor jatuh"
	],
	COMPLAINT_INFLATION: [
		"harga kebutuhan pokok naik, tolong adakan operasi pasar"
	],
	COMPLAINT_UNEMPLOYMENT: [
		"banyak warga belum dapat kerja, butuh zona komersial atau industri baru"
	],
	COMPLAINT_NO_TRANSIT: [
		"tidak ada transportasi umum yang layak, warga susah bepergian"
	],
	COMPLAINT_AIRPORT_NOISE: [
		"berisik, pesawat lewat terus dekat rumah warga!"
	],
	COMPLAINT_EVENT_BANJIR: [
		"hujan deras bikin jalan tergenang banjir kecil, mobil susah lewat!"
	],
	COMPLAINT_EVENT_DEMO: [
		"kami mau perubahan! warga berkumpul menyampaikan aspirasi di Balai Kota!"
	]
}

# Solusi Balai Kota untuk pengaduan
const COMPLAINT_SOLUTIONS = {
	COMPLAINT_TRAFFIC: [
		{
			"title": "Buka Opsi Penertiban Pak Slamet",
			"cost": 0,
			"pop_gain": 0,
			"desc": "Tinjau langsung penataan parkir liar di lokasi kejadian."
		}
	],
	COMPLAINT_TRASH: [
		{
			"title": "Kirim Armada Angkut Darurat",
			"cost": 15000,
			"pop_gain": 6,
			"desc": "Bersihkan tumpukan sampah segera. Popularitas +6."
		},
		{
			"title": "Himbau Warga Mandiri",
			"cost": 0,
			"pop_gain": -2,
			"desc": "Minta warga kelola sampah sendiri. Popularitas -2."
		}
	],
	COMPLAINT_TRAFFIC_LIGHT: [
		{
			"title": "Atur Ulang Durasi Lampu & Rambu",
			"cost": 10000,
			"pop_gain": 5,
			"desc": "Optimasi timer lampu lalu lintas. Popularitas +5."
		},
		{
			"title": "Tunda Dulu (Evaluasi Pekan Depan)",
			"cost": 0,
			"pop_gain": -3,
			"desc": "Biarkan sementara waktu. Popularitas -3."
		}
	],
	COMPLAINT_NO_SCHOOL: [
		{
			"title": "Subsidi Transportasi Sekolah Sementara",
			"cost": 10000,
			"pop_gain": 5,
			"desc": "Bantu anak sekolah sementara sambil menyiapkan Sekolah. Popularitas +5."
		},
		{
			"title": "Abaikan Keluhan",
			"cost": 0,
			"pop_gain": -5,
			"desc": "Tunda pembangunan fasilitas pendidikan. Popularitas -5."
		}
	],
	COMPLAINT_NO_HEALTH: [
		{
			"title": "Kirim Layanan Klinik Keliling",
			"cost": 10000,
			"pop_gain": 5,
			"desc": "Layani warga sementara sambil menyiapkan Puskesmas. Popularitas +5."
		},
		{
			"title": "Abaikan Keluhan",
			"cost": 0,
			"pop_gain": -5,
			"desc": "Biarkan tanpa layanan kesehatan. Popularitas -5."
		}
	],
	COMPLAINT_INSECURE: [
		{
			"title": "Tingkatkan Patroli Siskamling",
			"cost": 8000,
			"pop_gain": 5,
			"desc": "Amankan lingkungan sementara dan naikkan Keamanan. Popularitas +5."
		},
		{
			"title": "Abaikan Keluhan",
			"cost": 0,
			"pop_gain": -5,
			"desc": "Keamanan terus menurun. Popularitas -5."
		}
	],
	COMPLAINT_NO_FIRE: [
		{
			"title": "Bagikan Alat Pemadam Ringan",
			"cost": 8000,
			"pop_gain": 5,
			"desc": "Langkah darurat pencegahan kebakaran. Popularitas +5."
		},
		{
			"title": "Abaikan Keluhan",
			"cost": 0,
			"pop_gain": -5,
			"desc": "Warga tetap cemas risiko kebakaran. Popularitas -5."
		}
	],
	COMPLAINT_FIRE: [
		{
			"title": "Kerahkan Bantuan Darurat Pemadam",
			"cost": 5000,
			"pop_gain": 5,
			"desc": "Bantu evakuasi & percepat penanganan kebakaran. Popularitas +5."
		},
		{
			"title": "Abaikan Laporan",
			"cost": 0,
			"pop_gain": -5,
			"desc": "Warga kecewa lambatnya respons darurat. Popularitas -5."
		}
	],
	COMPLAINT_ANGKOT_NGETEM: [
		{
			"title": "Penertiban Angkot Ngetem",
			"cost": 25000,
			"pop_gain": 5,
			"desc": "Tertibkan angkot yang ngetem sembarangan. Popularitas +5."
		},
		{
			"title": "Abaikan Keluhan",
			"cost": 0,
			"pop_gain": -5,
			"desc": "Kemacetan berlanjut. Popularitas -5."
		}
	],
	COMPLAINT_PUNGLI: [
		{
			"title": "Razia Pungli",
			"cost": 50000,
			"pop_gain": 5,
			"integ_gain": 5,
			"desc": "Berantas pungli di lapangan. Popularitas +5, Integritas +5."
		},
		{
			"title": "Abaikan Laporan",
			"cost": 0,
			"pop_gain": -5,
			"desc": "Pungli dibiarkan (3 bulan -> -10 Popularitas)."
		}
	],
	COMPLAINT_POLLUTION: [
		{ "title": "Pasang Filter Cerobong", "cost": 20000, "pop_gain": 5, "desc": "Kurangi asap industri. Popularitas +5." },
		{ "title": "Abaikan Keluhan", "cost": 0, "pop_gain": -5, "desc": "Udara tetap tercemar. Popularitas -5." }
	],
	COMPLAINT_FLOOD: [
		{ "title": "Normalisasi Selokan", "cost": 25000, "pop_gain": 5, "desc": "Lancarkan drainase kota. Popularitas +5." },
		{ "title": "Abaikan Keluhan", "cost": 0, "pop_gain": -5, "desc": "Genangan berulang. Popularitas -5." }
	],
	COMPLAINT_BLACKOUT: [
		{ "title": "Stabilkan Gardu Listrik", "cost": 15000, "pop_gain": 5, "desc": "Perbaiki distribusi daya. Popularitas +5." },
		{ "title": "Abaikan Keluhan", "cost": 0, "pop_gain": -5, "desc": "Warga terganggu. Popularitas -5." }
	],
	COMPLAINT_DIRTY_WATER: [
		{ "title": "Kuras Pipa & Filter Air", "cost": 15000, "pop_gain": 5, "desc": "Bersihkan saluran air bersih. Popularitas +5." },
		{ "title": "Abaikan Keluhan", "cost": 0, "pop_gain": -5, "desc": "Air tetap keruh. Popularitas -5." }
	],
	COMPLAINT_BAD_ROAD: [
		{ "title": "Tambal Aspal Jalan", "cost": 12000, "pop_gain": 5, "desc": "Perbaiki jalan berlubang. Popularitas +5." },
		{ "title": "Abaikan Keluhan", "cost": 0, "pop_gain": -5, "desc": "Jalan tetap rusak. Popularitas -5." }
	],
	COMPLAINT_INFLATION: [
		{ "title": "Operasi Pasar Murah", "cost": 20000, "pop_gain": 5, "desc": "Stabilkan harga pangan warga. Popularitas +5." },
		{ "title": "Abaikan Keluhan", "cost": 0, "pop_gain": -5, "desc": "Harga tetap tinggi. Popularitas -5." }
	],
	COMPLAINT_UNEMPLOYMENT: [
		{ "title": "Pelatihan Kerja Warga", "cost": 15000, "pop_gain": 5, "desc": "Bantu pencari kerja. Popularitas +5." },
		{ "title": "Abaikan Keluhan", "cost": 0, "pop_gain": -5, "desc": "Pengangguran meningkat. Popularitas -5." }
	],
	COMPLAINT_NO_TRANSIT: [
		{ "title": "Subsidi Angkutan Sementara", "cost": 15000, "pop_gain": 5, "desc": "Bantu mobilitas warga. Popularitas +5." },
		{ "title": "Abaikan Keluhan", "cost": 0, "pop_gain": -5, "desc": "Warga kesulitan transportasi. Popularitas -5." }
	],
	COMPLAINT_AIRPORT_NOISE: [
		{ "title": "Pasang Peredam Suara Warga", "cost": 30000, "pop_gain": 3, "desc": "Redam kebisingan pesawat. Popularitas +3." },
		{ "title": "Abaikan Keluhan", "cost": 0, "pop_gain": -5, "desc": "Kebisingan berlanjut. Popularitas -5." }
	],
	COMPLAINT_EVENT_BANJIR: [
		{ "title": "Sedot Banjir & Bersihkan Drainase", "cost": 50000, "pop_gain": 5, "desc": "Banjir surut cepat. Popularitas +5." },
		{ "title": "Abaikan Keluhan", "cost": 0, "pop_gain": -5, "desc": "Banjir surut alami 1 bulan. Popularitas -5." }
	],
	COMPLAINT_EVENT_DEMO: [
		{ "title": "Dialog & Penuhi Aspirasi Warga", "cost": 30000, "pop_gain": 5, "desc": "Massa bubar tertib. Popularitas +5." },
		{ "title": "Abaikan Aspirasi", "cost": 0, "pop_gain": -5, "desc": "Popularitas turun -5." }
	]
}

# Bank keluhan masa depan (Phase 2+) dicatat sebagai blueprint data
const FUTURE_COMPLAINTS = {
	"polusi": "Asap pabrik bikin sesak napas anak-anak sekolah.",
	"pungli_wisata": "Ada oknum minta karcis masuk ganda di gerbang taman.",
	"banjir": "Hujan deras 1 jam air selokan langsung meluap ke teras.",
	"mati_listrik": "Listrik padam mendadak pas jam operasional toko.",
	"air_kotor": "Air keran warnanya agak keruh dan berbau tanah.",
	"jalan_rusak": "Banyak lubang aspal dalam di jalan raya, rawan pemotor jatuh."
}

static func get_random_quote(complaint_type: String, citizen_name: String) -> String:
	var quotes: Array = COMPLAINT_QUOTES.get(complaint_type, ["Lingkungan kota butuh perhatian lebih."])
	var q: String = quotes[randi() % quotes.size()]
	return "%s: %s" % [citizen_name, q]
