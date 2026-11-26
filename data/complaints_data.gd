class_name ComplaintsData
extends RefCounted

## Bank data keluhan warga KotaBareng (Phase 1 Langkah 5 & persiapan masa depan)

# 3 Keluhan aktif di Phase 1:
const COMPLAINT_TRAFFIC: String = "macet"
const COMPLAINT_TRASH: String = "sampah"
const COMPLAINT_TRAFFIC_LIGHT: String = "lampu_merah"

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
