-- Booking hardening: review and test in staging before applying to a live Supabase project.
-- NOT VALID avoids blocking deployment because of pre-existing bad rows;
-- PostgreSQL still enforces these constraints for new and updated rows.
alter table public.bookings
  add constraint rg_booking_issue_length check (length(btrim(issue)) between 1 and 500) not valid;
alter table public.bookings
  add constraint rg_booking_name_length check (length(btrim(customer_name)) between 1 and 100) not valid;
alter table public.bookings
  add constraint rg_booking_address_length check (length(btrim(address)) between 1 and 500) not valid;
alter table public.bookings
  add constraint rg_booking_notes_length check (notes is null or length(notes) <= 1000) not valid;
alter table public.bookings
  add constraint rg_booking_phone_format check (
    phone ~ '^[0-9+ ()-]{10,18}$'
    and length(regexp_replace(phone, '[^0-9]', '', 'g')) >= 10
  ) not valid;

-- SECURITY DEFINER is required so capacity counts include bookings owned by OTHER customers.
-- Migration must run as the privileged schema owner; never grant direct RPC access.
-- Keep the existing capacity trigger name; replacing its function changes behavior
-- without requiring trigger recreation. Advisory lock serializes competing inserts.
create or replace function public.enforce_slot_capacity()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_count integer;
begin
  if new.service_date < current_date then
    raise exception 'Cannot book a past date';
  end if;

  -- A cancelled booking does not consume a slot.
  if new.status = 'cancelled' then
    return new;
  end if;

  perform pg_advisory_xact_lock(hashtext(new.service_date::text || ':' || new.service_slot));

  -- Reject accidental duplicate active requests from the same customer.
  if exists (
    select 1 from public.bookings b
    where b.id <> new.id
      and b.user_id = new.user_id
      and b.category = new.category
      and b.issue = new.issue
      and b.service_date = new.service_date
      and b.service_slot = new.service_slot
      and b.status <> 'cancelled'
  ) then
    raise exception 'A matching booking already exists for this time slot';
  end if;

  select count(*) into v_count
  from public.bookings b
  where b.id <> new.id
    and b.service_date = new.service_date
    and b.service_slot = new.service_slot
    and b.status <> 'cancelled';

  if v_count >= 3 then
    raise exception 'Time slot is full. Choose another slot.';
  end if;

  return new;
end;
$$;

revoke all on function public.enforce_slot_capacity() from public, anon, authenticated;
