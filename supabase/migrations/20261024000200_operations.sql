-- RG Solution production extension. Run AFTER schema.sql in Supabase SQL Editor.
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default '',
 role text not null default 'customer' check(role in ('customer','technician','admin')),
 created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
create or replace function public.current_role() returns text language sql stable security definer set search_path=public as $$select coalesce((select role from public.profiles where id=auth.uid()),'customer')$$;
revoke all on function public.current_role() from public;
grant execute on function public.current_role() to authenticated;
create policy "Profiles own read" on public.profiles for select to authenticated using (id=auth.uid() or public.current_role()='admin');
create or replace function public.create_profile() returns trigger language plpgsql security definer set search_path=public as $$begin insert into public.profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name','')) on conflict(id) do nothing;return new;end$$;
drop trigger if exists on_auth_user_created_rg on auth.users;
create trigger on_auth_user_created_rg after insert on auth.users for each row execute procedure public.create_profile();
insert into public.profiles(id) select id from auth.users on conflict do nothing;
alter table public.bookings add column if not exists technician_id uuid references public.profiles(id);
alter table public.bookings add column if not exists updated_at timestamptz not null default now();
create index if not exists rg_booking_date_slot on public.bookings(service_date,service_slot,status);
create index if not exists rg_booking_technician on public.bookings(technician_id,service_date);
create policy "Staff view permitted bookings" on public.bookings for select to authenticated using(public.current_role()='admin' or (public.current_role()='technician' and technician_id=auth.uid()));
-- Customers never directly edit booking status, and technicians only update assigned work through this RPC.
create or replace function public.manage_booking(p_booking_id uuid,p_status text default null,p_technician_id uuid default null)
returns void language plpgsql security definer set search_path=public as $$
declare v public.bookings%rowtype; r text;
begin
 select * into v from public.bookings where id=p_booking_id for update;
 if not found then raise exception 'Booking not found';end if;
 r:=public.current_role();
 if r='admin' then
  if p_status is not null and p_status not in ('pending','confirmed','in_progress','completed','cancelled') then raise exception 'Invalid status';end if;
  if p_technician_id is not null and not exists(select 1 from public.profiles where id=p_technician_id and role='technician') then raise exception 'Invalid technician';end if;
  update public.bookings set status=coalesce(p_status,status),technician_id=coalesce(p_technician_id,technician_id),updated_at=now() where id=p_booking_id;
 elsif r='technician' and v.technician_id=auth.uid() then
  if p_status not in ('in_progress','completed') then raise exception 'Not allowed';end if;
  update public.bookings set status=p_status,updated_at=now() where id=p_booking_id;
 elsif v.user_id=auth.uid() then
  if p_status<>'cancelled' or v.status not in ('pending','confirmed') then raise exception 'Cancellation unavailable';end if;
  update public.bookings set status='cancelled',updated_at=now() where id=p_booking_id;
 else raise exception 'Permission denied';end if;
end$$;
revoke all on function public.manage_booking(uuid,text,uuid) from public;
grant execute on function public.manage_booking(uuid,text,uuid) to authenticated;
-- Booking capacity is 3 per slot across all technicians; adjust for actual staffing.
create or replace function public.get_slot_counts(p_date date) returns table(slot text,booked bigint)
language sql stable security definer set search_path=public as $$
select service_slot,count(*) from public.bookings where service_date=p_date and status not in ('cancelled') group by service_slot$$;
revoke all on function public.get_slot_counts(date) from public;
grant execute on function public.get_slot_counts(date) to authenticated,anon;
create or replace function public.enforce_slot_capacity() returns trigger language plpgsql set search_path=public as $$
declare n int;
begin
 if new.service_date<current_date then raise exception 'Cannot book a past date';end if;
 perform pg_advisory_xact_lock(hashtext(new.service_date::text||new.service_slot));
 select count(*) into n from public.bookings where service_date=new.service_date and service_slot=new.service_slot and status<>'cancelled' and id<>new.id;
 if n>=3 and new.status<>'cancelled' then raise exception 'Time slot is full. Choose another slot.';end if;
 return new;
end$$;
drop trigger if exists rg_capacity on public.bookings;
create trigger rg_capacity before insert or update of service_date,service_slot,status on public.bookings for each row execute procedure public.enforce_slot_capacity();
-- Promote a known user manually, using their auth UUID, never from client-side code:
-- update public.profiles set role='admin' where id='YOUR-USER-UUID';
-- update public.profiles set role='technician',display_name='Technician Name' where id='TECHNICIAN-UUID';

-- Explicitly restrict helper RPC execution. Trigger functions are not client RPCs.
revoke all on function public.create_profile() from public, anon, authenticated;
revoke all on function public.enforce_slot_capacity() from public, anon, authenticated;
