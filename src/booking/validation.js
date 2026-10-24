// Client-side booking checks improve UX; the database must enforce all security rules.
export const BOOKING_SLOTS = Object.freeze(['09:00–11:00','11:00–13:00','14:00–16:00','16:00–18:00']);
export function validateBooking(data, today = new Date()) {
  const required = ['category','service_mode','issue','service_date','service_slot','customer_name','phone','address'];
  if (required.some(key => typeof data?.[key] !== 'string' || !data[key].trim())) return 'Please complete all required booking details.';
  if (!['laptop','mobile','desktop'].includes(data.category)) return 'Select a valid device type.';
  if (!['doorstep','pickup','center'].includes(data.service_mode)) return 'Select a valid service method.';
  if (!BOOKING_SLOTS.includes(data.service_slot)) return 'Select a valid time slot.';
  if (!/^\d{4}-\d{2}-\d{2}$/.test(data.service_date)) return 'Select a valid date.';
  const date = new Date(data.service_date + 'T12:00:00');
  if (Number.isNaN(date.getTime()) || date.getFullYear() !== Number(data.service_date.slice(0,4)) || date.getMonth()+1 !== Number(data.service_date.slice(5,7)) || date.getDate() !== Number(data.service_date.slice(8,10))) return 'Select a valid date.';
  const min = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  if (date < min) return 'Please choose today or a future date.';
  if (data.customer_name.trim().length > 100 || data.address.trim().length > 500 || (data.notes || '').length > 1000) return 'Booking details exceed the allowed length.';
  if (!/^[0-9+ ()-]{10,18}$/.test(data.phone.trim()) || data.phone.replace(/\D/g,'').length < 10) return 'Enter a valid phone number.';
  return null;
}
