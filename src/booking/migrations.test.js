import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
const dir = new URL('../../supabase/migrations/', import.meta.url);
const files = readdirSync(dir).filter(name => name.endsWith('.sql')).sort();
const migrations = files.map(name => ({name,sql:readFileSync(new URL(name,dir),'utf8')}));
test('pilot migrations include the booking schema and security controls', () => {
  assert.ok(migrations.length >= 4,'Expected base, operations, agent support, hardening');
  const sql = migrations.map(x=>x.sql).join('\n').toLowerCase();
  assert.match(sql,/create table if not exists public\.bookings/);
  assert.match(sql,/alter table public\.bookings enable row level security/);
  assert.match(sql,/customers create own bookings/);
  assert.match(sql,/create or replace function public\.manage_booking/);
  assert.match(sql,/pg_advisory_xact_lock/);
});
test('slot capacity trigger runs as security definer for cross-customer counting', () => {
  const hardening = migrations.find(x=>x.name.includes('booking_hardening'));
  assert.ok(hardening,'Missing booking hardening migration');
  assert.match(hardening.sql,/create or replace function public\.enforce_slot_capacity\(\)[\s\S]*?security definer/i);
  assert.match(hardening.sql,/revoke all on function public\.enforce_slot_capacity\(\) from public, anon, authenticated/i);
});
test('no migration includes a hardcoded Supabase secret or service role token', () => {
  for (const {name,sql} of migrations) {
    assert.doesNotMatch(sql,/sb_secret_[A-Za-z0-9]+|service_role\s*[:=]\s*['"][A-Za-z0-9._-]+/i,name);
  }
});
