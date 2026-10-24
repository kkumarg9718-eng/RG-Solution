# RG Solution — Professional Multi-Agent Repair Platform

Urban-inspired independent repair marketplace for laptop and mobile repairs; not affiliated with Urban Company.

## Included
- Premium responsive React/Vite storefront; laptop and mobile repair services
- Doorstep, Pickup & Drop, Service Center booking modes
- Supabase email authentication, bookings, slot limits, customer order history
- Role-based admin and technician consoles with secure database RPC
- Server-side optional AI repair chat and modular deterministic triage, booking recommendation, dispatch recommendation and notification planning agents
- Supabase RLS, GitHub Actions build/test, Vercel config

## Local installation
1. `npm install` then `cp .env.example .env` (Windows: `copy .env.example .env`).
2. Create Supabase project; add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` to `.env`. Never use service-role key in browser.
3. In Supabase SQL Editor execute in this order: `supabase/schema.sql`, `supabase/production.sql`, `supabase/multi_agent_upgrade.sql`.
4. Set Supabase Auth URL Configuration site URL to `http://localhost:5173` and redirect URL `http://localhost:5173/**`.
5. `npm run dev` to run, `npm test` to test agent rules, `npm run build` to verify bundle.
6. Promote admin manually via SQL after registering: `update public.profiles set role='admin' where id='YOUR-AUTH-USER-UUID';`. Never allow customer-controlled role assignment.

## AI repair assistant
Deploy `supabase/functions/repair-assistant` via Supabase CLI. Configure server-side `OPENAI_API_KEY` and `ALLOWED_ORIGINS` secrets, and set frontend `VITE_AI_FUNCTION_URL` to your function endpoint. Without it, chat uses safe booking guidance. Add authentication, rate limits and abuse monitoring before exposing the endpoint publicly.

## Deploy
Push repo to GitHub. Import into Vercel (Vite; build `npm run build`; output `dist`). Set the VITE_ environment variables in Vercel. Add production domain to Supabase Auth Site URL and Redirect URLs. Deploy Edge Function separately.

## Important boundaries
This is a deployable project source package, **not** a fully integrated commercial launch. Live payment checkout, payment webhooks, actual service-center locations, WhatsApp/SMS delivery, live technician shift calendars, autonomous AI booking writes, multi-agent LLM orchestration, and production monitoring are NOT implemented. The modular agents provide deterministic recommendations; booking and status updates remain human-authorized. Slots are capped at three per date/time across all service modes; adjust after defining capacity. Test production security, accessibility and business rules before real customer launch.
