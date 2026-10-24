import test from 'node:test';
import assert from 'node:assert/strict';
import {validateBooking, BOOKING_SLOTS} from './validation.js';

const valid = {category:'desktop',service_mode:'pickup',issue:'SSD upgrade',service_date:'2026-11-01',service_slot:BOOKING_SLOTS[0],customer_name:'Test Customer',phone:'9876543210',address:'Test street, Bengaluru',notes:''};
const today = new Date(2026, 9, 25);
test('accepts valid desktop booking', () => assert.equal(validateBooking(valid,today),null));
test('rejects missing customer name', () => assert.match(validateBooking({...valid,customer_name:''},today),/required/));
test('rejects invalid category', () => assert.match(validateBooking({...valid,category:'tablet'},today),/device/));
test('rejects invalid service mode', () => assert.match(validateBooking({...valid,service_mode:'unknown'},today),/method/));
test('rejects invalid time slot', () => assert.match(validateBooking({...valid,service_slot:'00:00'},today),/slot/));
test('rejects past dates', () => assert.match(validateBooking({...valid,service_date:'2026-10-24'},today),/future/));
test('rejects impossible dates', () => assert.match(validateBooking({...valid,service_date:'2026-02-30'},today),/date/));
test('rejects short phone numbers', () => assert.match(validateBooking({...valid,phone:'123456789'},today),/phone/));
test('rejects long notes', () => assert.match(validateBooking({...valid,notes:'x'.repeat(1001)},today),/length/));
