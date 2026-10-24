-- Apply after schema.sql and production.sql
alter table public.bookings add column if not exists service_mode text not null default 'doorstep' check (service_mode in ('doorstep','pickup','center'));
create table if not exists public.agent_audit (id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id), agent text not null, action text not null, result text not null, created_at timestamptz default now());
alter table public.agent_audit enable row level security;
create policy "Agent audit owner read" on public.agent_audit for select to authenticated using (user_id=auth.uid() or public.current_role()='admin');
-- No client insert policy: write agent audit records only through trusted server-side functions.
