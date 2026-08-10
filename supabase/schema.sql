-- Ledger schema for Supabase (Auth + Postgres + RLS)
-- Run in Supabase Dashboard → SQL Editor

create extension if not exists "pgcrypto";

-- categories
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  color text,
  created_at timestamptz not null default now()
);

create index if not exists categories_user_id_idx on public.categories (user_id);

-- items (purchases)
create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  category_id uuid not null references public.categories (id) on delete restrict,
  price double precision not null,
  currency_code text not null,
  purchased_at timestamptz not null,
  expected_finish_at timestamptz not null,
  expires_at timestamptz,
  finished_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists items_user_id_idx on public.items (user_id);
create index if not exists items_category_id_idx on public.items (category_id);
create index if not exists items_expected_finish_at_idx on public.items (expected_finish_at);
create index if not exists items_expires_at_idx on public.items (expires_at);
create index if not exists items_finished_at_idx on public.items (finished_at);

-- profiles
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  currency_code text not null,
  created_at timestamptz not null default now(),
  unique (user_id)
);

-- envelopes
create table if not exists public.envelopes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  year integer not null,
  month integer not null,
  name text not null,
  type text not null,
  budgeted double precision not null,
  actual double precision not null default 0,
  currency_code text not null,
  category_id uuid references public.categories (id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists envelopes_user_id_idx on public.envelopes (user_id);
create index if not exists envelopes_year_idx on public.envelopes (year);
create index if not exists envelopes_month_idx on public.envelopes (month);
create index if not exists envelopes_type_idx on public.envelopes (type);

alter table public.categories enable row level security;
alter table public.items enable row level security;
alter table public.profiles enable row level security;
alter table public.envelopes enable row level security;

drop policy if exists "categories_own" on public.categories;
drop policy if exists "items_own" on public.items;
drop policy if exists "profiles_own" on public.profiles;
drop policy if exists "envelopes_own" on public.envelopes;

create policy "categories_own"
  on public.categories for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "items_own"
  on public.items for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "profiles_own"
  on public.profiles for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "envelopes_own"
  on public.envelopes for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
