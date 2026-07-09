-- ============================================================
-- SUPABASE DATABASE SCHEMA - JasaCepat
-- ============================================================
-- Cara pakai:
-- 1. Buka Supabase Dashboard.
-- 2. Masuk ke menu SQL Editor.
-- 3. Paste seluruh isi file ini.
-- 4. Klik Run.
--
-- Schema ini mengikuti field yang dipakai oleh:
-- lib/core/app_storage_service.dart
--
-- Catatan:
-- Aplikasi saat ini memakai login custom lewat tabel profiles, bukan
-- Supabase Auth. Karena itu policy RLS dibuat terbuka agar cocok dengan
-- kode MVP saat ini. Untuk production sungguhan, sebaiknya pindahkan
-- login ke Supabase Auth dan kunci RLS berdasarkan auth.uid().
-- ============================================================

create extension if not exists "pgcrypto";

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================
-- 1. PROFILES
-- Akun user/admin yang dipakai login oleh aplikasi.
-- ============================================================

create table if not exists public.profiles (
  email text primary key,
  name text not null,
  password text not null,
  role text not null default 'user',
  phone text not null default '',
  avatar_url text not null default '',
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint profiles_role_check check (role in ('admin', 'user', 'technician'))
);

alter table public.profiles add column if not exists phone text not null default '';
alter table public.profiles add column if not exists avatar_url text not null default '';
alter table public.profiles add column if not exists created_at timestamp with time zone not null default now();
alter table public.profiles add column if not exists updated_at timestamp with time zone not null default now();
alter table public.profiles alter column role set default 'user';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_role_check'
  ) then
    alter table public.profiles
      add constraint profiles_role_check
      check (role in ('admin', 'user', 'technician')) not valid;
  end if;
end $$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

-- ============================================================
-- 2. USER_LOCATIONS
-- Lokasi default user. Kode Flutter memakai onConflict: 'user_email',
-- jadi user_email wajib unik.
-- ============================================================

create table if not exists public.user_locations (
  id uuid primary key default gen_random_uuid(),
  user_email text not null references public.profiles(email) on update cascade on delete cascade,
  address text not null default 'Lokasi Saya',
  latitude double precision not null default -6.175392,
  longitude double precision not null default 106.827153,
  is_default boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

alter table public.user_locations add column if not exists address text not null default 'Lokasi Saya';
alter table public.user_locations add column if not exists latitude double precision not null default -6.175392;
alter table public.user_locations add column if not exists longitude double precision not null default 106.827153;
alter table public.user_locations add column if not exists is_default boolean not null default true;
alter table public.user_locations add column if not exists created_at timestamp with time zone not null default now();
alter table public.user_locations add column if not exists updated_at timestamp with time zone not null default now();

-- Jika query ini gagal di database lama, berarti ada data lokasi duplikat
-- untuk email yang sama. Hapus duplikatnya dulu lewat Table Editor.
create unique index if not exists user_locations_user_email_key
  on public.user_locations(user_email);

drop trigger if exists user_locations_set_updated_at on public.user_locations;
create trigger user_locations_set_updated_at
before update on public.user_locations
for each row
execute function public.set_updated_at();

-- ============================================================
-- 3. PLACES
-- Tempat/cabang/penyedia jasa yang dibuat dari halaman admin.
-- ============================================================

create table if not exists public.places (
  id text primary key,
  name text not null,
  address text not null default '',
  latitude double precision not null default -6.175392,
  longitude double precision not null default 106.827153,
  description text not null default '',
  image_url text not null default '',
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

alter table public.places add column if not exists address text not null default '';
alter table public.places add column if not exists latitude double precision not null default -6.175392;
alter table public.places add column if not exists longitude double precision not null default 106.827153;
alter table public.places add column if not exists description text not null default '';
alter table public.places add column if not exists image_url text not null default '';
alter table public.places add column if not exists is_active boolean not null default true;
alter table public.places add column if not exists created_at timestamp with time zone not null default now();
alter table public.places add column if not exists updated_at timestamp with time zone not null default now();

create index if not exists places_is_active_idx on public.places(is_active);
create index if not exists places_name_idx on public.places(name);

drop trigger if exists places_set_updated_at on public.places;
create trigger places_set_updated_at
before update on public.places
for each row
execute function public.set_updated_at();

-- ============================================================
-- 4. SERVICES
-- Layanan jasa yang tampil di home, map, detail, dan admin.
-- ============================================================

create table if not exists public.services (
  id text primary key,
  name text not null,
  description text not null default '',
  detail text not null default '',
  price text not null default '0',
  price_unit text not null default 'per panggilan',
  category text not null default 'Umum',
  place_id text references public.places(id) on update cascade on delete set null,
  latitude double precision,
  longitude double precision,
  image_url text not null default '',
  icon_name text not null default 'build',
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

alter table public.services add column if not exists description text not null default '';
alter table public.services add column if not exists detail text not null default '';
alter table public.services add column if not exists price text not null default '0';
alter table public.services add column if not exists price_unit text not null default 'per panggilan';
alter table public.services add column if not exists category text not null default 'Umum';
alter table public.services add column if not exists place_id text;
alter table public.services add column if not exists latitude double precision;
alter table public.services add column if not exists longitude double precision;
alter table public.services add column if not exists image_url text not null default '';
alter table public.services add column if not exists icon_name text not null default 'build';
alter table public.services add column if not exists is_active boolean not null default true;
alter table public.services add column if not exists created_at timestamp with time zone not null default now();
alter table public.services add column if not exists updated_at timestamp with time zone not null default now();

create index if not exists services_is_active_idx on public.services(is_active);
create index if not exists services_category_idx on public.services(category);
create index if not exists services_place_id_idx on public.services(place_id);

drop trigger if exists services_set_updated_at on public.services;
create trigger services_set_updated_at
before update on public.services
for each row
execute function public.set_updated_at();

-- ============================================================
-- 5. ORDERS
-- Pesanan yang dibuat oleh user dan dikelola oleh admin.
-- ============================================================

create table if not exists public.orders (
  id text primary key,
  user_email text not null references public.profiles(email) on update cascade on delete cascade,
  service_id text references public.services(id) on update cascade on delete set null,
  service_name text not null,
  place_id text references public.places(id) on update cascade on delete set null,
  place_name text not null default '',
  technician_name text not null default 'Mencari Teknisi...',
  price text not null default '0',
  notes text not null default '',
  status text not null default 'Menunggu',
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint orders_status_check check (status in ('Menunggu', 'Diterima', 'Diproses', 'Selesai', 'Dibatalkan'))
);

alter table public.orders add column if not exists service_id text;
alter table public.orders add column if not exists service_name text not null default '';
alter table public.orders add column if not exists place_id text;
alter table public.orders add column if not exists place_name text not null default '';
alter table public.orders add column if not exists technician_name text not null default 'Mencari Teknisi...';
alter table public.orders add column if not exists price text not null default '0';
alter table public.orders add column if not exists notes text not null default '';
alter table public.orders add column if not exists status text not null default 'Menunggu';
alter table public.orders add column if not exists created_at timestamp with time zone not null default now();
alter table public.orders add column if not exists updated_at timestamp with time zone not null default now();
alter table public.orders alter column status set default 'Menunggu';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.orders'::regclass
      and conname = 'orders_status_check'
  ) then
    alter table public.orders
      add constraint orders_status_check
      check (status in ('Menunggu', 'Diterima', 'Diproses', 'Selesai', 'Dibatalkan')) not valid;
  end if;
end $$;

create index if not exists orders_user_email_idx on public.orders(user_email);
create index if not exists orders_status_idx on public.orders(status);
create index if not exists orders_created_at_idx on public.orders(created_at desc);

drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at
before update on public.orders
for each row
execute function public.set_updated_at();

-- ============================================================
-- TABLE PRIVILEGES
-- Supabase REST/client butuh GRANT selain RLS policy. Tanpa ini,
-- app bisa terkena error: permission denied for table profiles.
-- ============================================================

grant usage on schema public to anon, authenticated;

grant select, insert, update on public.profiles to anon, authenticated;
grant select, insert, update on public.user_locations to anon, authenticated;
grant select, insert, update, delete on public.places to anon, authenticated;
grant select, insert, update, delete on public.services to anon, authenticated;
grant select, insert, update on public.orders to anon, authenticated;

-- ============================================================
-- ROW LEVEL SECURITY
-- Policy dibuat permisif agar cocok dengan aplikasi saat ini yang memakai
-- anon key dan login custom dari tabel profiles.
-- ============================================================

alter table public.profiles enable row level security;
alter table public.user_locations enable row level security;
alter table public.places enable row level security;
alter table public.services enable row level security;
alter table public.orders enable row level security;

-- Bersihkan nama policy dari versi SQL lama agar tidak tercampur.
drop policy if exists "Semua bisa baca profiles" on public.profiles;
drop policy if exists "Admin insert profiles" on public.profiles;
drop policy if exists "Admin update profiles" on public.profiles;

drop policy if exists "Semua bisa baca user_locations" on public.user_locations;
drop policy if exists "Semua bisa insert user_locations" on public.user_locations;
drop policy if exists "Semua bisa update user_locations" on public.user_locations;

drop policy if exists "Semua bisa baca places" on public.places;
drop policy if exists "Admin insert places" on public.places;
drop policy if exists "Admin update places" on public.places;
drop policy if exists "Admin delete places" on public.places;

drop policy if exists "Semua bisa baca services" on public.services;
drop policy if exists "Admin insert services" on public.services;
drop policy if exists "Admin update services" on public.services;
drop policy if exists "Admin delete services" on public.services;

drop policy if exists "Semua bisa baca orders" on public.orders;
drop policy if exists "Semua bisa insert orders" on public.orders;
drop policy if exists "Semua bisa update orders" on public.orders;

drop policy if exists profiles_select_all on public.profiles;
drop policy if exists profiles_insert_all on public.profiles;
drop policy if exists profiles_update_all on public.profiles;
drop policy if exists profiles_delete_all on public.profiles;

create policy profiles_select_all
  on public.profiles for select
  to anon, authenticated
  using (true);

create policy profiles_insert_all
  on public.profiles for insert
  to anon, authenticated
  with check (true);

create policy profiles_update_all
  on public.profiles for update
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists user_locations_select_all on public.user_locations;
drop policy if exists user_locations_insert_all on public.user_locations;
drop policy if exists user_locations_update_all on public.user_locations;
drop policy if exists user_locations_delete_all on public.user_locations;

create policy user_locations_select_all
  on public.user_locations for select
  to anon, authenticated
  using (true);

create policy user_locations_insert_all
  on public.user_locations for insert
  to anon, authenticated
  with check (true);

create policy user_locations_update_all
  on public.user_locations for update
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists places_select_all on public.places;
drop policy if exists places_insert_all on public.places;
drop policy if exists places_update_all on public.places;
drop policy if exists places_delete_all on public.places;

create policy places_select_all
  on public.places for select
  to anon, authenticated
  using (true);

create policy places_insert_all
  on public.places for insert
  to anon, authenticated
  with check (true);

create policy places_update_all
  on public.places for update
  to anon, authenticated
  using (true)
  with check (true);

create policy places_delete_all
  on public.places for delete
  to anon, authenticated
  using (true);

drop policy if exists services_select_all on public.services;
drop policy if exists services_insert_all on public.services;
drop policy if exists services_update_all on public.services;
drop policy if exists services_delete_all on public.services;

create policy services_select_all
  on public.services for select
  to anon, authenticated
  using (true);

create policy services_insert_all
  on public.services for insert
  to anon, authenticated
  with check (true);

create policy services_update_all
  on public.services for update
  to anon, authenticated
  using (true)
  with check (true);

create policy services_delete_all
  on public.services for delete
  to anon, authenticated
  using (true);

drop policy if exists orders_select_all on public.orders;
drop policy if exists orders_insert_all on public.orders;
drop policy if exists orders_update_all on public.orders;
drop policy if exists orders_delete_all on public.orders;

create policy orders_select_all
  on public.orders for select
  to anon, authenticated
  using (true);

create policy orders_insert_all
  on public.orders for insert
  to anon, authenticated
  with check (true);

create policy orders_update_all
  on public.orders for update
  to anon, authenticated
  using (true)
  with check (true);

-- ============================================================
-- SEED DATA
-- Data awal agar aplikasi langsung bisa login dan menampilkan layanan.
-- ============================================================

insert into public.profiles (email, name, password, role, phone, avatar_url)
values
  ('admin@gmail.com', 'Admin JasaCepat', 'admin123', 'admin', '', ''),
  ('user@gmail.com', 'Pengguna JasaCepat', 'user123', 'user', '', '')
on conflict (email) do nothing;

insert into public.user_locations (user_email, address, latitude, longitude, is_default)
values
  ('user@gmail.com', 'Jl. Urban Raya No. 42, Jakarta', -6.175392, 106.827153, true),
  ('admin@gmail.com', 'Kantor JasaCepat Jakarta', -6.175392, 106.827153, true)
on conflict (user_email) do nothing;

insert into public.places (id, name, address, latitude, longitude, description, image_url, is_active)
values
  (
    'place_001',
    'JasaCepat Hub Jakarta Pusat',
    'Jl. Merdeka No. 1, Jakarta Pusat',
    -6.175392,
    106.827153,
    'Pusat layanan utama JasaCepat',
    '',
    true
  ),
  (
    'place_002',
    'JasaCepat Hub Jakarta Selatan',
    'Jl. Sudirman No. 45, Jakarta Selatan',
    -6.224008,
    106.845261,
    'Cabang layanan Jakarta Selatan',
    '',
    true
  ),
  (
    'place_003',
    'JasaCepat Hub Solo',
    'Jl. Slamet Riyadi No. 25, Surakarta',
    -7.557628,
    110.821781,
    'Cabang layanan area Solo Raya',
    '',
    true
  )
on conflict (id) do nothing;

insert into public.services (
  id,
  name,
  description,
  detail,
  price,
  price_unit,
  category,
  place_id,
  latitude,
  longitude,
  image_url,
  icon_name,
  is_active
)
values
  (
    'svc_001',
    'Servis AC',
    'Cuci, tambah freon, dan perbaikan AC',
    'Layanan meliputi pembersihan filter, cuci evaporator, pengecekan freon, pengisian freon jika habis, dan uji coba AC. Estimasi waktu 1-2 jam.',
    '185000',
    'per unit',
    'AC & Pendingin',
    'place_001',
    -6.176200,
    106.828200,
    '',
    'ac_unit',
    true
  ),
  (
    'svc_002',
    'Potong Rumput',
    'Potong dan rapikan rumput halaman',
    'Layanan meliputi pemotongan rumput menggunakan mesin, pembersihan sisa potongan, dan penataan tepi rumput. Estimasi waktu tergantung luas area.',
    '120000',
    'per sesi',
    'Kebersihan',
    'place_001',
    -6.177100,
    106.826600,
    '',
    'grass',
    true
  ),
  (
    'svc_003',
    'Kuras Toren Air',
    'Bersihkan toren atau tangki air dari lumut dan kotoran',
    'Layanan meliputi pengurasan air, pembersihan dinding toren, desinfeksi, dan pengisian kembali. Cocok untuk toren 500L sampai 2000L.',
    '200000',
    'per toren',
    'Sanitasi',
    'place_002',
    -6.223400,
    106.844700,
    '',
    'water_drop',
    true
  ),
  (
    'svc_004',
    'Pasang Lampu',
    'Instalasi dan penggantian lampu rumah',
    'Layanan meliputi pemasangan lampu baru, penggantian fitting lampu rusak, pengecekan kabel, dan uji coba. Berlaku untuk lampu LED, TL, dan halogen.',
    '75000',
    'per titik',
    'Kelistrikan',
    'place_002',
    -6.225100,
    106.846000,
    '',
    'lightbulb',
    true
  ),
  (
    'svc_005',
    'Perbaikan Keran',
    'Perbaikan keran bocor dan instalasi pipa ringan',
    'Layanan meliputi pengecekan sumber kebocoran, penggantian seal atau keran, dan uji aliran air setelah perbaikan.',
    '95000',
    'per kunjungan',
    'Plumbing',
    'place_003',
    -7.557700,
    110.821800,
    '',
    'plumbing',
    true
  )
on conflict (id) do nothing;

-- Contoh order sengaja tidak dibuat supaya dashboard mulai bersih.
