# DNS Server — PowerDNS + PostgreSQL

DNS server internal berbasis **PowerDNS Authoritative Server** dengan backend **PostgreSQL**, di-deploy menggunakan Docker Compose. Dilengkapi REST API untuk manajemen zone dan record secara programatik.

Project ini dibuat sebagai portofolio SRE/DevOps — mendemonstrasikan kemampuan setup dan otomasi infrastruktur DNS internal tingkat production.

---

## Arsitektur

```
┌─────────────────────────────────────────────────┐
│              Docker Network: pdns_network        │
│                                                  │
│  ┌──────────────────┐    ┌─────────────────────┐ │
│  │  pdns-postgres   │◄───│    pdns-server      │ │
│  │  PostgreSQL 15   │    │  PowerDNS Auth 4.9  │ │
│  │  port 5432       │    │  port 53  (DNS)     │ │
│  │  (internal only) │    │  port 8081 (API)    │ │
│  └──────────────────┘    └─────────────────────┘ │
│                                                  │
└─────────────────────────────────────────────────┘
              ▲
     Laptop / Jaringan Kantor
```

| Komponen | Fungsi |
|---|---|
| **PowerDNS 4.9** | Authoritative DNS server — menjawab query DNS untuk zona internal |
| **PostgreSQL 15** | Backend database — menyimpan semua zone dan DNS record |
| **REST API (port 8081)** | Manajemen zone/record via HTTP — dasar Python CLI di tahap berikutnya |

---



## Struktur Folder

```
dns-server-powerdns/
├── docker-compose.yml          # Orchestrasi container PostgreSQL + PowerDNS
├── config/
│   └── postgres/
│       └── schema.sql          # Schema database PowerDNS (auto-run saat pertama kali)
├── cli/                        # Python CLI tool (Tahap 2 — coming soon)
├── monitoring/                 # Prometheus + Grafana (Tahap 4 — coming soon)
├── tests/                      # Unit test (Tahap 3 — coming soon)
├── .env.example                # Template konfigurasi
├── .gitignore
└── README.md
```

---

## Cara Install & Menjalankan

### 1. Clone repository

```bash
git clone https://github.com/radive15/dns-server-powerdns.git
cd dns-server-powerdns
```

### 2. Buat file konfigurasi

```bash
cp .env.example .env
```

Edit file `.env` sesuai kebutuhan:

```env
POSTGRES_DB=pdns
POSTGRES_USER=pdns
POSTGRES_PASSWORD=ganti-dengan-password-kuat
PDNS_API_KEY=ganti-dengan-api-key-rahasia
```

### 3. Jalankan

```bash
docker compose up -d
```

### 4. Cek status container

```bash
docker compose ps
```

Output yang diharapkan:

```
NAME             STATUS          PORTS
pdns-postgres    Up (healthy)    5432/tcp
pdns-server      Up              0.0.0.0:53->53/udp, 0.0.0.0:8081->8081/tcp
```

---

## Verifikasi Instalasi

### Cek PowerDNS API berjalan

```bash
# Linux/macOS
curl -s -H "X-API-Key: <PDNS_API_KEY>" http://localhost:8081/api/v1/servers | python3 -m json.tool

# Windows PowerShell
Invoke-RestMethod -Uri "http://localhost:8081/api/v1/servers" `
  -Headers @{"X-API-Key" = "<PDNS_API_KEY>"}
```

Respons yang diharapkan:

```json
[
  {
    "type": "Server",
    "id": "localhost",
    "daemon_type": "authoritative",
    "version": "4.9.x"
  }
]
```

### Buat zone dan record pertama (tes manual via API)

```bash
# Buat zone internal.local
curl -s -X POST http://localhost:8081/api/v1/servers/localhost/zones \
  -H "X-API-Key: <PDNS_API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "internal.local.",
    "kind": "Native",
    "nameservers": ["ns1.internal.local."]
  }'

# Tambah A record: dashboard.internal.local → 192.168.1.10
curl -s -X PATCH http://localhost:8081/api/v1/servers/localhost/zones/internal.local. \
  -H "X-API-Key: <PDNS_API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "rrsets": [{
      "name": "dashboard.internal.local.",
      "type": "A",
      "ttl": 300,
      "changetype": "REPLACE",
      "records": [{"content": "192.168.1.10", "disabled": false}]
    }]
  }'
```

### Query DNS record yang baru dibuat

```bash
# Linux/macOS
dig @127.0.0.1 dashboard.internal.local A

# Windows
nslookup dashboard.internal.local 127.0.0.1
```

Output yang diharapkan:

```
Name:    dashboard.internal.local
Address: 192.168.1.10
```

---

## Perintah Berguna

```bash
# Lihat log PowerDNS secara live
docker compose logs -f pdns

# Lihat log PostgreSQL
docker compose logs -f postgres

# Masuk ke shell PostgreSQL untuk inspeksi data
docker exec -it pdns-postgres psql -U pdns -d pdns

# Lihat semua DNS record di database
# (jalankan di dalam psql shell)
SELECT name, type, content, ttl FROM records;

# Stop semua container
docker compose down

# Stop dan hapus semua data (hati-hati!)
docker compose down -v
```

---

## Roadmap Project

| Tahap | Status | Deskripsi |
|---|---|---|
| **Tahap 1** — Setup PowerDNS | ✅ Selesai | Deploy PowerDNS + PostgreSQL via Docker Compose |
| **Tahap 2** — Python CLI | 🔄 Berikutnya | CLI tool untuk manajemen zone dan record via REST API |
| **Tahap 3** — Unit Test | ⬜ Belum | Pytest + mock HTTP untuk test Python CLI |
| **Tahap 4** — Monitoring | ⬜ Belum | Prometheus metrics + Grafana dashboard |
| **Tahap 5** — Health Check | ⬜ Belum | Script otomatis cek kesehatan DNS server |

---

## Lisensi

MIT License — lihat file [LICENSE](LICENSE)
