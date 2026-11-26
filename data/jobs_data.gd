class_name JobsData
extends RefCounted

## Data pekerjaan bebas untuk Season 1 (warga biasa, tanpa syarat & tanpa penguncian)

const NAME_POOL: Array[String] = [
	"Dimas", "Sari", "Budi", "Rina", "Agus", "Dewi",
	"Joko", "Maya", "Rizky", "Putri", "Andi", "Lestari"
]

const JOBS: Array[Dictionary] = [
	{
		"id": "pedagang_warung",
		"title": "Pedagang Warung",
		"salary": 2500000,
		"variable_salary": false,
		"effects_text": "Kebahagiaan +2, Kesehatan -1",
		"kesehatan": -1,
		"kebahagiaan": 2,
		"popularitas": 0,
		"integritas": 0
	},
	{
		"id": "ojek_online",
		"title": "Ojek Online",
		"salary": 3000000,
		"variable_salary": false,
		"effects_text": "Kesehatan -3, Kebahagiaan -1",
		"kesehatan": -3,
		"kebahagiaan": -1,
		"popularitas": 0,
		"integritas": 0
	},
	{
		"id": "guru_honorer",
		"title": "Guru Honorer",
		"salary": 1500000,
		"variable_salary": false,
		"effects_text": "Popularitas +3, Kebahagiaan +2",
		"kesehatan": 0,
		"kebahagiaan": 2,
		"popularitas": 3,
		"integritas": 0
	},
	{
		"id": "karyawan_pabrik",
		"title": "Karyawan Pabrik",
		"salary": 3500000,
		"variable_salary": false,
		"effects_text": "Kesehatan -2, Kebahagiaan -2",
		"kesehatan": -2,
		"kebahagiaan": -2,
		"popularitas": 0,
		"integritas": 0
	},
	{
		"id": "barista",
		"title": "Barista",
		"salary": 2800000,
		"variable_salary": false,
		"effects_text": "Kebahagiaan +3, Popularitas +1",
		"kesehatan": 0,
		"kebahagiaan": 3,
		"popularitas": 1,
		"integritas": 0
	},
	{
		"id": "petani",
		"title": "Petani",
		"salary": 2000000,
		"variable_salary": false,
		"effects_text": "Kesehatan +2, Kebahagiaan +1",
		"kesehatan": 2,
		"kebahagiaan": 1,
		"popularitas": 0,
		"integritas": 0
	},
	{
		"id": "penjaga_toko",
		"title": "Penjaga Toko",
		"salary": 2200000,
		"variable_salary": false,
		"effects_text": "Kebahagiaan +1",
		"kesehatan": 0,
		"kebahagiaan": 1,
		"popularitas": 0,
		"integritas": 0
	},
	{
		"id": "kurir_paket",
		"title": "Kurir Paket",
		"salary": 2700000,
		"variable_salary": false,
		"effects_text": "Kesehatan -2, Popularitas +1",
		"kesehatan": -2,
		"kebahagiaan": 0,
		"popularitas": 1,
		"integritas": 0
	},
	{
		"id": "freelance_desain",
		"title": "Freelance Desain",
		"salary": 3200000,
		"variable_salary": true,
		"salary_min": 2000000,
		"salary_max": 4500000,
		"effects_text": "Gaji acak Rp2jt-4,5jt, Kebahagiaan +2",
		"kesehatan": 0,
		"kebahagiaan": 2,
		"popularitas": 0,
		"integritas": 0
	},
	{
		"id": "tukang_bengkel",
		"title": "Tukang Bengkel",
		"salary": 2900000,
		"variable_salary": false,
		"effects_text": "Kesehatan -1, Popularitas +1",
		"kesehatan": -1,
		"kebahagiaan": 0,
		"popularitas": 1,
		"integritas": 0
	}
]

const MONTHLY_EVENTS: Array[Dictionary] = [
	{
		"text": "Tetangga mengajakmu kerja bakti membersihkan selokan.",
		"kebahagiaan": 0,
		"popularitas": 2
	},
	{
		"text": "Warung sebelah bagi-bagi gorengan gratis sore ini.",
		"kebahagiaan": 2,
		"popularitas": 0
	},
	{
		"text": "Hujan deras semalam, jalan depan rumah becek.",
		"kebahagiaan": -2,
		"popularitas": 0
	},
	{
		"text": "Anak tetangga minta diajari PR matematika.",
		"kebahagiaan": 0,
		"popularitas": 2
	},
	{
		"text": "Ada pasar malam di lapangan, ramai sampai tengah malam.",
		"kebahagiaan": 2,
		"popularitas": 0
	}
]

static func get_job_by_title(job_title: String) -> Dictionary:
	for j in JOBS:
		if j["title"] == job_title:
			return j
	return {}
