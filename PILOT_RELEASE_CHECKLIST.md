# RG Solution — Pilot Launch Gate

**Scope:** Customer email-link sign-in, laptop/mobile/desktop repair requests, three service modes, customer booking history/cancellation, admin assignment, technician progress updates, and basic notifications. Payments, paid AI inference and advanced automation are **out of scope** for the initial pilot.

## Deployment safety

- Development branch: `development/initial-hardening`. Do not merge into `main` or deploy without separate owner approval.
- GitHub CI (`npm test` and `npm run build`) verifies JavaScript tests/build only; it does **not** execute PostgreSQL migrations or simulate Supabase RLS.
- Run migrations in order on a disposable **staging** Supabase project before applying to any live project.
- Never place service-role keys, SMTP credentials or AI API secrets in `VITE_*` variables or source control.
- A `SECURITY DEFINER` capacity trigger must be owned by a privileged database role that bypasses bookings RLS; otherwise customers can see only their own bookings and overbook a shared slot.

## Staging acceptance checklist (requires connected staging database)

- [ ] Run all migrations in filename order without errors.
- [ ] Verify customer A can insert/select only their own bookings; customer B cannot select A's details.
- [ ] Verify anonymous visitors cannot insert or read bookings.
- [ ] Verify a customer cannot directly update status, assign a technician, or promote their own profile role.
- [ ] Verify three **different** customers can reserve the same future date/slot and a fourth is rejected, including simultaneous requests.
- [ ] Verify duplicate requests from one customer are rejected, while cancelled requests do not occupy capacity.
- [ ] Verify a customer can cancel only their pending/confirmed booking via `manage_booking`.
- [ ] Verify a technician sees only assigned bookings and cannot change other customers' bookings.
- [ ] Verify an admin can assign only profiles with technician role.
- [ ] Verify invalid/oversized fields and past booking dates are rejected by the database.
- [ ] Verify email-link redirects, booking success, dashboard refresh, and sign-out using staging accounts.
- [ ] Configure and test booking notifications through a verified email provider; do not claim notifications work until a real message arrives.

## Release blockers

Staging project access, business contact/service area, first admin identity, email sender verification, and explicit production deployment approval. All are still unverified.

## Notes

The current SQL capacity check uses a transaction-level advisory lock plus a privileged trigger. The UI's remaining-slot number is advisory only; the database must reject racing fourth bookings. Existing database rows may require cleanup before validating the `NOT VALID` field constraints. Avoid changing production data during staging tests.
