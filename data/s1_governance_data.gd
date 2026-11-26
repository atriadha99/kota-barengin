class_name S1GovernanceData
extends RefCounted

## Data pengaduan warga dan tindakan kas untuk Season 1 (S1-2: Ketua RT & Ketua RW)

const RT_COMPLAINTS: Array[Dictionary] = [
	{ "type": "sampah", "title": "Sampah numpuk di gang", "cost": 25000 },
	{ "type": "jalan", "title": "Jalan kampung berlubang", "cost": 50000 },
	{ "type": "lampu", "title": "Lampu jalan mati", "cost": 20000 },
	{ "type": "ribut", "title": "Perselisihan antar tetangga", "cost": 10000 },
	{ "type": "pencurian", "title": "Laporan pencurian malam", "cost": 30000 }
]

const LURAH_COMPLAINTS: Array[Dictionary] = [
	{ "type": "sampah", "title": "Sampah menumpuk di TPS", "cost": 120000 },
	{ "type": "banjir", "title": "Banjir genangan di permukiman", "cost": 250000 },
	{ "type": "listrik", "title": "Mati listrik di beberapa RT", "cost": 150000 },
	{ "type": "air", "title": "Air bersih warga keruh/kotor", "cost": 180000 },
	{ "type": "jalan_parah", "title": "Jalan utama rusak parah", "cost": 300000 },
	{ "type": "harga", "title": "Harga bahan pokok naik", "cost": 200000 }
]

const RT_DUES_MONTHLY: int = 100000 # 10 rumah x Rp 10.000
const RW_DUES_MONTHLY: int = 300000 # 30 rumah x Rp 10.000
const LURAH_BUDGET_MONTHLY: int = 1000000
const CAMAT_BUDGET_MONTHLY: int = 3000000
const LURAH_SALARY: int = 3000000
const CAMAT_SALARY: int = 5000000

const RT_ACTIONS: Array[Dictionary] = [
	{
		"id": "kerja_bakti",
		"title": "Kerja Bakti RT",
		"cost": 50000,
		"happy": 3,
		"pop": 2,
		"integ": 2,
		"ronda": false,
		"desc": "Rp 50.000 | Senang +3, Populer +2, Integritas +2"
	},
	{
		"id": "perbaiki_jalan",
		"title": "Perbaiki Jalan RT",
		"cost": 100000,
		"happy": 5,
		"pop": 3,
		"integ": 0,
		"ronda": false,
		"desc": "Rp 100.000 | Senang +5, Populer +3"
	},
	{
		"id": "ronda_malam",
		"title": "Ronda Malam",
		"cost": 30000,
		"happy": 1,
		"pop": 2,
		"integ": 0,
		"ronda": true,
		"desc": "Rp 30.000 | Keamanan naik, pencurian turun"
	}
]

const RW_ACTIONS: Array[Dictionary] = [
	{
		"id": "kerja_bakti_rw",
		"title": "Kerja Bakti RW",
		"cost": 150000,
		"happy": 9,
		"pop": 6,
		"integ": 3,
		"ronda": false,
		"desc": "Rp 150.000 | Senang +9, Populer +6, Integritas +3"
	},
	{
		"id": "perbaiki_jalan_rw",
		"title": "Perbaiki Jalan RW",
		"cost": 300000,
		"happy": 15,
		"pop": 9,
		"integ": 0,
		"ronda": false,
		"desc": "Rp 300.000 | Senang +15, Populer +9"
	},
	{
		"id": "pos_keamanan_rw",
		"title": "Pos Keamanan RW",
		"cost": 100000,
		"happy": 3,
		"pop": 6,
		"integ": 0,
		"ronda": true,
		"desc": "Rp 100.000 | Keamanan 3 RT naik"
	}
]

const LURAH_ACTIONS: Array[Dictionary] = [
	{
		"id": "jalan_kel",
		"title": "Perbaiki Jalan Kel.",
		"cost": 400000,
		"happy": 5,
		"pop": 3,
		"health": 0,
		"integ": 2,
		"clean": false,
		"desc": "Rp 400.000 | Senang +5, Populer +3, Integritas +2"
	},
	{
		"id": "posyandu",
		"title": "Posyandu",
		"cost": 200000,
		"happy": 0,
		"pop": 2,
		"health": 3,
		"integ": 1,
		"clean": false,
		"desc": "Rp 200.000 | Sehat +3, Populer +2, Integritas +1"
	},
	{
		"id": "bantuan_miskin",
		"title": "Bantuan Warga",
		"cost": 300000,
		"happy": 4,
		"pop": 4,
		"health": 0,
		"integ": 2,
		"clean": false,
		"desc": "Rp 300.000 | Senang +4, Populer +4, Integritas +2"
	},
	{
		"id": "kebersihan_kel",
		"title": "Kebersihan Kel.",
		"cost": 150000,
		"happy": 3,
		"pop": 1,
		"health": 0,
		"integ": 1,
		"clean": true,
		"desc": "Rp 150.000 | Senang +3, keluhan sampah turun"
	}
]

const CAMAT_ACTIONS: Array[Dictionary] = [
	{
		"id": "jalan_kec",
		"title": "Perbaiki Jalan Kec.",
		"cost": 1200000,
		"happy": 15,
		"pop": 9,
		"health": 0,
		"integ": 3,
		"clean": false,
		"desc": "Rp 1.200.000 | Senang +15, Populer +9, Integritas +3"
	},
	{
		"id": "puskesmas",
		"title": "Puskesmas",
		"cost": 600000,
		"happy": 0,
		"pop": 6,
		"health": 3,
		"integ": 2,
		"clean": false,
		"desc": "Rp 600.000 | Sehat +3, Populer +6, Integritas +2"
	},
	{
		"id": "bansos_kec",
		"title": "Bantuan Sosial",
		"cost": 900000,
		"happy": 12,
		"pop": 12,
		"health": 0,
		"integ": 3,
		"clean": false,
		"desc": "Rp 900.000 | Senang +12, Populer +12, Integritas +3"
	},
	{
		"id": "kebersihan_kec",
		"title": "Kebersihan Kec.",
		"cost": 450000,
		"happy": 9,
		"pop": 3,
		"health": 0,
		"integ": 2,
		"clean": true,
		"desc": "Rp 450.000 | Senang +9, keluhan sampah turun"
	}
]
