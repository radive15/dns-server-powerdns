-- Tabel utama: menyimpan daftar DNS zone (misal: internal.perusahaan.com)
CREATE TABLE domains (
  id              SERIAL PRIMARY KEY,
  name            VARCHAR(255) NOT NULL,
  master          VARCHAR(128) DEFAULT NULL,
  last_check      INT DEFAULT NULL,
  type            TEXT NOT NULL,
  notified_serial BIGINT DEFAULT NULL,
  account         VARCHAR(40) DEFAULT NULL
);
CREATE UNIQUE INDEX name_index ON domains(name);

-- Tabel utama: menyimpan semua DNS record (A, CNAME, MX, TXT, dll)
CREATE TABLE records (
  id        BIGSERIAL PRIMARY KEY,
  domain_id INT DEFAULT NULL,
  name      VARCHAR(255) DEFAULT NULL,
  type      VARCHAR(10) DEFAULT NULL,
  content   VARCHAR(65535) DEFAULT NULL,
  ttl       INT DEFAULT NULL,
  prio      INT DEFAULT NULL,
  disabled  BOOL DEFAULT 'f',
  ordername VARCHAR(255),
  auth      BOOL DEFAULT 't'
);
CREATE INDEX rec_name_index ON records(name);
CREATE INDEX nametype_index ON records(name, type);
CREATE INDEX domain_id ON records(domain_id);

-- Tabel untuk komentar/notes per record (opsional tapi berguna di production)
CREATE TABLE comments (
  id          SERIAL PRIMARY KEY,
  domain_id   INT NOT NULL,
  name        VARCHAR(255) NOT NULL,
  type        VARCHAR(10) NOT NULL,
  modified_at INT NOT NULL,
  account     VARCHAR(40) DEFAULT NULL,
  comment     VARCHAR(65535) NOT NULL
);

-- Tabel metadata zone (untuk DNSSEC dan konfigurasi per-zone)
CREATE TABLE domainmetadata (
  id        SERIAL PRIMARY KEY,
  domain_id INT REFERENCES domains(id) ON DELETE CASCADE,
  kind      VARCHAR(32),
  content   TEXT
);

-- Tabel untuk TSIG keys (authentication zone transfer)
CREATE TABLE tsigkeys (
  id        SERIAL PRIMARY KEY,
  name      VARCHAR(255),
  algorithm VARCHAR(50),
  secret    VARCHAR(255),
  CONSTRAINT tsigkeys_unique UNIQUE (name, algorithm)
);
