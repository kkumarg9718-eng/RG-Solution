# RG Solution Signature Premium Edition

The homepage is redesigned with a dark cinematic hero, three service categories, popular repairs, service modes, responsive cards and AI assistant access. This is a functional React UI, not an exact reproduction of the approved visual concept. Existing Supabase booking/auth/technician flows are retained.

## Important limitations

- Pricing is intentionally not invented; repair quotes are provided after inspection.
- Desktop booking and RAM/SSD options are present in the UI, but the database category constraint and any technician skill mappings must be migrated before accepting live desktop bookings. Check `supabase/production.sql` and existing production data before modifying constraints.
- AI assistant requires an external function endpoint and credentials.
- Payments, WhatsApp notifications, shift scheduling, and monitoring remain unimplemented.
- This is not production-certified. Run `npm install`, `npm test`, and `npm run build`, then perform end-to-end testing before deploying.
