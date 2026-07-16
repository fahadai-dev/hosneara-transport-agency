-- ============================================================
-- Route Ledger (রুট লেজার) — Supabase Schema
-- Multi-tenant fleet management for transport businesses
-- Pattern: shop_id-based tenancy, security-definer helper
-- functions to avoid RLS recursion on the profiles table.
-- ============================================================
 
-- ------------------------------------------------------------
-- 1. TABLES
-- ------------------------------------------------------------
 
create table if not exists shops (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  created_at  timestamptz not null default now()
);
 
create table if not exists profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  shop_id     uuid not null references shops(id) on delete cascade,
  full_name   text not null,
  role        text not null check (role in ('owner', 'staff')),
  created_at  timestamptz not null default now()
);
 
create table if not exists vehicles (
  id                    uuid primary key default gen_random_uuid(),
  shop_id               uuid not null references shops(id) on delete cascade,
  plate                 text not null,
  name                  text,
  driver_name           text,
  driver_phone          text,
  fitness_expiry        date,
  tax_token_expiry      date,
  insurance_expiry      date,
  route_permit_expiry   date,
  is_active             boolean not null default true,
  status                text not null default 'available' check (status in ('available', 'out')),
  current_route         text,
  departed_at           timestamptz,
  created_at            timestamptz not null default now()
);
 
create table if not exists companies (
  id          uuid primary key default gen_random_uuid(),
  shop_id     uuid not null references shops(id) on delete cascade,
  name        text not null,
  phone       text,
  address     text,
  created_at  timestamptz not null default now()
);
 
create table if not exists trips (
  id            uuid primary key default gen_random_uuid(),
  shop_id       uuid not null references shops(id) on delete cascade,
  vehicle_id    uuid not null references vehicles(id) on delete cascade,
  trip_date     date not null default current_date,
  from_location text not null,
  to_location   text not null,
  company_id    uuid references companies(id) on delete set null,
  customer_name text,
  customer_phone text,
  income        numeric(12,2) not null default 0,
  fuel_cost     numeric(12,2) not null default 0,
  khoraki_cost  numeric(12,2) not null default 0,
  other_cost    numeric(12,2) not null default 0,
  commission_percent numeric(5,2) not null default 0,
  commission_cost numeric(12,2) not null default 0,
  payment_status text not null default 'due' check (payment_status in ('due', 'paid')),
  money_holder  text not null check (money_holder in ('office', 'driver')),
  settled       boolean not null default false,
  note          text,
  created_by    uuid references profiles(id),
  created_at    timestamptz not null default now()
);
 
create table if not exists other_bookings (
  id            uuid primary key default gen_random_uuid(),
  shop_id       uuid not null references shops(id) on delete cascade,
  booking_date  date not null default current_date,
  customer_name text not null,
  customer_phone text,
  from_location text not null,
  to_location   text not null,
  income        numeric(12,2) not null default 0,
  fuel_cost     numeric(12,2) not null default 0,
  khoraki_cost  numeric(12,2) not null default 0,
  other_cost    numeric(12,2) not null default 0,
  pay_status    text not null default 'due' check (pay_status in ('due', 'paid')),
  note          text,
  created_by    uuid references profiles(id),
  created_at    timestamptz not null default now()
);
 
create index if not exists idx_profiles_shop_id       on profiles(shop_id);
create index if not exists idx_vehicles_shop_id        on vehicles(shop_id);
create index if not exists idx_companies_shop_id       on companies(shop_id);
create index if not exists idx_trips_shop_id           on trips(shop_id);
create index if not exists idx_trips_vehicle_id        on trips(vehicle_id);
create index if not exists idx_trips_company_id        on trips(company_id);
create index if not exists idx_trips_trip_date         on trips(trip_date);
create index if not exists idx_other_bookings_shop_id  on other_bookings(shop_id);
 
-- ------------------------------------------------------------
-- 2. SECURITY DEFINER HELPER FUNCTIONS
--    (bypass RLS on `profiles` itself -> no recursion)
-- ------------------------------------------------------------
 
create or replace function my_shop_id()
returns uuid
language sql
security definer
set search_path = public
stable
as $$
  select shop_id from profiles where id = auth.uid();
$$;
 
create or replace function is_owner()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select role = 'owner' from profiles where id = auth.uid();
$$;
 
-- ------------------------------------------------------------
-- 3. ENABLE RLS
-- ------------------------------------------------------------
 
alter table shops           enable row level security;
alter table profiles        enable row level security;
alter table vehicles        enable row level security;
alter table companies       enable row level security;
alter table trips           enable row level security;
alter table other_bookings  enable row level security;
 
-- ------------------------------------------------------------
-- 4. POLICIES
-- ------------------------------------------------------------
 
-- shops: a user can only see their own shop
create policy "shops_select_own" on shops
  for select using (id = my_shop_id());
 
-- profiles: everyone in a shop can see each other's profile;
-- only an owner can insert/update/delete staff profiles
create policy "profiles_select_same_shop" on profiles
  for select using (shop_id = my_shop_id());
 
create policy "profiles_owner_manage" on profiles
  for all using (shop_id = my_shop_id() and is_owner())
  with check (shop_id = my_shop_id() and is_owner());
 
-- vehicles: any shop member can read/write; only owner can delete
create policy "vehicles_select" on vehicles
  for select using (shop_id = my_shop_id());
 
create policy "vehicles_insert" on vehicles
  for insert with check (shop_id = my_shop_id());
 
create policy "vehicles_update" on vehicles
  for update using (shop_id = my_shop_id())
  with check (shop_id = my_shop_id());
 
create policy "vehicles_delete" on vehicles
  for delete using (shop_id = my_shop_id() and is_owner());
 
-- companies: shop member read/write; only owner delete
create policy "companies_select" on companies
  for select using (shop_id = my_shop_id());
 
create policy "companies_insert" on companies
  for insert with check (shop_id = my_shop_id());
 
create policy "companies_update" on companies
  for update using (shop_id = my_shop_id())
  with check (shop_id = my_shop_id());
 
create policy "companies_delete" on companies
  for delete using (shop_id = my_shop_id() and is_owner());
 
-- trips: any shop member can read/write; only owner can delete
create policy "trips_select" on trips
  for select using (shop_id = my_shop_id());
 
create policy "trips_insert" on trips
  for insert with check (shop_id = my_shop_id());
 
create policy "trips_update" on trips
  for update using (shop_id = my_shop_id())
  with check (shop_id = my_shop_id());
 
create policy "trips_delete" on trips
  for delete using (shop_id = my_shop_id() and is_owner());
 
-- other_bookings: same pattern as trips
create policy "other_bookings_select" on other_bookings
  for select using (shop_id = my_shop_id());
 
create policy "other_bookings_insert" on other_bookings
  for insert with check (shop_id = my_shop_id());
 
create policy "other_bookings_update" on other_bookings
  for update using (shop_id = my_shop_id())
  with check (shop_id = my_shop_id());
 
create policy "other_bookings_delete" on other_bookings
  for delete using (shop_id = my_shop_id() and is_owner());
 
-- ============================================================
-- MIGRATION — যদি আগেই এই schema Supabase-এ রান করে ফেলে থাকো,
-- শুধু এই অংশটুকু নতুন করে রান করলেই কমিশন ও ডিসপ্যাচ ফিচার যোগ হয়ে যাবে।
-- (উপরের পুরো ফাইল আবার রান করার দরকার নেই, `if not exists` থাকায় সমস্যা হবে না)
-- ============================================================
 
alter table trips add column if not exists commission_cost numeric(12,2) not null default 0;
 
alter table vehicles add column if not exists status text not null default 'available' check (status in ('available', 'out'));
alter table vehicles add column if not exists current_route text;
alter table vehicles add column if not exists departed_at timestamptz;
 
create table if not exists companies (
  id          uuid primary key default gen_random_uuid(),
  shop_id     uuid not null references shops(id) on delete cascade,
  name        text not null,
  phone       text,
  address     text,
  created_at  timestamptz not null default now()
);
alter table companies enable row level security;
drop policy if exists "companies_select" on companies;
create policy "companies_select" on companies for select using (shop_id = my_shop_id());
drop policy if exists "companies_insert" on companies;
create policy "companies_insert" on companies for insert with check (shop_id = my_shop_id());
drop policy if exists "companies_update" on companies;
create policy "companies_update" on companies for update using (shop_id = my_shop_id()) with check (shop_id = my_shop_id());
drop policy if exists "companies_delete" on companies;
create policy "companies_delete" on companies for delete using (shop_id = my_shop_id() and is_owner());
 
alter table trips add column if not exists company_id uuid references companies(id) on delete set null;
alter table trips add column if not exists customer_name text;
alter table trips add column if not exists customer_phone text;
alter table trips add column if not exists commission_percent numeric(5,2) not null default 0;
alter table trips add column if not exists payment_status text not null default 'due' check (payment_status in ('due', 'paid'));
 
create index if not exists idx_companies_shop_id on companies(shop_id);
create index if not exists idx_trips_company_id on trips(company_id);
 
-- ============================================================
-- End of schema
-- ============================================================
 