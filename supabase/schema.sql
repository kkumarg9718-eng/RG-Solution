-- Run in Supabase SQL editor. Only customers can read their own bookings.
create extension if not exists pgcrypto;
create table if not exists public.bookings (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 category text not null check(category in ('laptop','mobile')),
 issue text not null, service_date date not null, service_slot text not null check(service_slot in ('09:00–11:00','11:00–13:00','14:00–16:00','16:00–18:00')),
 customer_name text not null, phone text not null, address text not null, notes text default '',
 status text not null default 'pending' check(status in ('pending','confirmed','in_progress','completed','cancelled')),
 created_at timestamptz not null default now(), constraint future_date check(service_date >= '2026-01-01')
);
create index if not exists bookings_user_idx on public.bookings(user_id,created_at desc);
alter table public.bookings enable row level security;
create policy "Customers view own bookings" on public.bookings for select to authenticated using ((select auth.uid())=user_id);
create policy "Customers create own bookings" on public.bookings for insert to authenticated with check ((select auth.uid())=user_id and status='pending');
-- Admin status changes are performed securely in Supabase dashboard or trusted server only.
