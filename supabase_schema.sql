-- ============================================================
-- SCHEMA DATABASE SUPABASE — JasaCepat v2.0
-- Jalankan semua perintah ini di Supabase SQL Editor
-- ============================================================

-- 1. TABEL PROFILES (Pengguna & Admin)
create table if not exists profiles (
  email text primary key,
  name text not null,
  password text not null,
  role text not null default 'user',
  phone text default '',
  avatar_url text default '',
  created_at timestamp with time zone default now()
);

-- 2. TABEL USER_LOCATIONS (Lokasi Tersimpan per Pengguna)
create table if not exists user_locations (
  id uuid primary key default gen_random_uuid(),
  user_email text not null references profiles(email) on delete cascade,
  address text not null default 'Lokasi Saya',
  latitude double precision not null default -6.175392,
  longitude double precision not null default 106.827153,
  is_default boolean default true,
  updated_at timestamp with time zone default now()
);

-- 3. TABEL PLACES (Tempat/Lokasi Penyedia Jasa — diisi oleh Admin)
create table if not exists places (
  id text primary key,
  name text not null,
  address text not null default '',
  latitude double precision not null default -6.175392,
  longitude double precision not null default 106.827153,
  description text default '',
  image_url text default '',
  is_active boolean default true,
  created_at timestamp with time zone default now()
);

-- 4. TABEL SERVICES (Jasa — diisi oleh Admin)
create table if not exists services (
  id text primary key,
  name text not null,
  description text not null default '',
  detail text not null default '',           -- Detail lengkap jasa
  price text not null default '0',
  price_unit text default 'per panggilan',   -- Satuan harga (per jam, per meter, dll)
  category text not null default 'Umum',
  place_id text references places(id) on delete set null,
  image_url text default '',
  icon_name text default 'build',            -- Nama icon Material untuk Flutter
  is_active boolean default true,
  created_at timestamp with time zone default now()
);

-- 5. TABEL ORDERS (Pesanan)
create table if not exists orders (
  id text primary key,
  user_email text not null,
  service_id text references services(id) on delete set null,
  service_name text not null,
  place_id text references places(id) on delete set null,
  place_name text default '',
  technician_name text default 'Mencari Teknisi...',
  price text not null,
  notes text default '',
  status text not null default 'Menunggu',
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS) — Opsional tapi direkomendasikan
-- ============================================================

-- Enable RLS
alter table profiles enable row level security;
alter table user_locations enable row level security;
alter table places enable row level security;
alter table services enable row level security;
alter table orders enable row level security;

-- Policy: Semua user bisa baca data places dan services (untuk tampil di beranda)
create policy "Semua bisa baca places"
  on places for select using (true);

create policy "Semua bisa baca services"
  on services for select using (true);

-- Policy: Hanya admin yang bisa insert/update/delete
create policy "Admin insert places"
  on places for insert with check (true);

create policy "Admin update places"
  on places for update using (true);

create policy "Admin delete places"
  on places for delete using (true);

create policy "Admin insert services"
  on services for insert with check (true);

create policy "Admin update services"
  on services for update using (true);

create policy "Admin delete services"
  on services for delete using (true);

-- Policy: Profiles
create policy "Semua bisa baca profiles"
  on profiles for select using (true);

create policy "Admin insert profiles"
  on profiles for insert with check (true);

create policy "Admin update profiles"
  on profiles for update using (true);

-- Policy: User locations (hanya user sendiri)
create policy "Semua bisa baca user_locations"
  on user_locations for select using (true);

create policy "Semua bisa insert user_locations"
  on user_locations for insert with check (true);

create policy "Semua bisa update user_locations"
  on user_locations for update using (true);

-- Policy: Orders
create policy "Semua bisa baca orders"
  on orders for select using (true);

create policy "Semua bisa insert orders"
  on orders for insert with check (true);

create policy "Semua bisa update orders"
  on orders for update using (true);

-- ============================================================
-- DATA AWAL (SEED DATA) — Contoh data untuk testing
-- ============================================================

-- Akun default
insert into profiles (email, name, password, role) values
  ('admin@gmail.com', 'Admin JasaCepat', 'admin123', 'admin'),
  ('user@gmail.com', 'Pengguna JasaCepat', 'user123', 'user')
on conflict (email) do nothing;

-- Contoh tempat
insert into places (id, name, address, latitude, longitude, description) values
  ('place_001', 'JasaCepat Hub Jakarta Pusat', 'Jl. Merdeka No. 1, Jakarta Pusat', -6.175392, 106.827153, 'Pusat layanan utama JasaCepat'),
  ('place_002', 'JasaCepat Hub Jakarta Selatan', 'Jl. Sudirman No. 45, Jakarta Selatan', -6.224008, 106.845261, 'Cabang layanan Jakarta Selatan')
on conflict (id) do nothing;

-- Contoh layanan
insert into services (id, name, description, detail, price, price_unit, category, place_id, icon_name) values
  ('svc_001', 'Servis AC', 'Cuci, tambah freon, dan perbaikan AC', 'Layanan meliputi: pembersihan filter, cuci evaporator, pengecekan freon, pengisian freon jika habis, dan uji coba AC. Estimasi waktu 1-2 jam.', '185000', 'per unit', 'AC & Pendingin', 'place_001', 'ac_unit'),
  ('svc_002', 'Potong Rumput', 'Potong dan rapikan rumput halaman', 'Layanan meliputi: pemotongan rumput menggunakan mesin, pembersihan sisa potongan, penataan tepi rumput (edging). Estimasi waktu tergantung luas area.', '120000', 'per sesi', 'Kebersihan', 'place_001', 'grass'),
  ('svc_003', 'Kuras Toren Air', 'Bersihkan toren/tangki air dari lumut dan kotoran', 'Layanan meliputi: pengurasan air, pembersihan dinding toren, desinfeksi, dan pengisian kembali. Cocok untuk toren 500L - 2000L.', '200000', 'per toren', 'Sanitasi', 'place_002', 'water_drop'),
  ('svc_004', 'Pasang Lampu', 'Instalasi dan penggantian lampu rumah', 'Layanan meliputi: pemasangan lampu baru, penggantian fitting lampu rusak, pengecekan kabel, dan uji coba. Berlaku untuk semua jenis lampu LED, TL, dan halogen.', '75000', 'per titik', 'Kelistrikan', 'place_002', 'lightbulb')
on conflict (id) do nothing;
