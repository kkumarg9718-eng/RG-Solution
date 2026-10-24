// Client-safe deterministic agents. Privileged booking/payment operations must be server-authorized.
export const AGENTS = Object.freeze({triage:'repair-triage',booking:'booking-assistant',dispatch:'technician-dispatch',support:'customer-support',notifications:'notification-planner'});

export function triageIssue(message = '') {
  const t = typeof message === 'string' ? message.toLowerCase() : '';
  const urgent = /smoke|swollen|bulging|burning|sparks|fire|battery leak|overheat/.test(t);
  const category = /laptop|notebook|macbook|keyboard|trackpad/.test(t) ? 'laptop'
    : /mobile|phone|android|iphone|smartphone/.test(t) ? 'mobile'
    : /desktop|tower|motherboard|ram upgrade|ssd upgrade/.test(t) ? 'desktop'
    : null;
  return {
    category,
    urgent,
    advice: urgent
      ? 'Stop using or charging the device; do not open or puncture the battery. Seek qualified assistance.'
      : 'A technician should confirm the diagnosis before any price is finalized.'
  };
}

export function bookingRecommendation({mode = 'doorstep', category = 'laptop'} = {}) {
  return {mode, category, requiresCustomerConfirmation:true, canWriteBookings:false};
}

export function dispatchRecommendation(booking, technicians = []) {
  if (!booking || !Array.isArray(technicians)) return [];
  return technicians
    .filter(t => t.available && Array.isArray(t.skills) && t.skills.includes(booking.category))
    .map(t => ({technicianId:t.id, reason:'Available and qualified'}));
}

export function notificationPlan(booking) {
  return [{event:'booking_requested', channel:'email', bookingId:booking.id, requiresProvider:true}];
}
