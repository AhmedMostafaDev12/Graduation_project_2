# Seed data: fixed IDs and test accounts

`scripts/seed.py` loads the UI board's sample data with **fixed IDs**, so the Flutter app, tests and teammates can refer to the same records. All times are around **today** in Africa/Cairo when the seed runs.

```bash
cd backend-ai
python -m scripts.seed            # local; running it again changes nothing
python -m scripts.seed --reset    # local only: wipe all data and seed again (moves "today")
```

ID format: `0000000K-0000-4000-8000-00000000000N`, where **K** is the kind and **N** the number.

## Accounts

| Who | ID | Login |
|---|---|---|
| Fatma Mahmoud (patient) | `00000001-0000-4000-8000-000000000001` | device token (below) |
| Ahmed Mostafa (caregiver, son, primary, **manager**) | `00000001-0000-4000-8000-000000000002` | `ahmed@example.com` |
| Mona Ali (caregiver, nurse, **viewer**) | `00000001-0000-4000-8000-000000000003` | `mona@example.com` |

**Passwords:** local seed = `remori-local`. On Supabase the seed refuses known defaults: the password comes from `SEED_PASSWORD` and is shared privately, never committed.
**Device RMR-0007** `00000003-0000-4000-8000-000000000001`. Local device token = `local-device-token-RMR-0007` (stored as a SHA-256 hash). On Supabase it comes from `SEED_DEVICE_TOKEN`.

## Records

| Kind (K) | Records |
|---|---|
| 2 enrolled people | 1 Ahmed (son) · 2 Sara (daughter) · 3 Dr. Hany (doctor) · 4 Mona (nurse) |
| 4 places | 1 Home · البيت · 2 بيت أحمد · Ahmed's house · 3 Clinic |
| 5 reminders | 1 Blood pressure pill (daily 09:00) · 2 Doctor appointment (Fridays 17:00) · 3 Drink water (daily 12:00, 16:00) |
| 6 reminder logs | 1 pill today: completed by voice · 2 water 12:00: snoozed to 12:15 · 3 water 16:00: pending · 4 pill yesterday: missed |
| 7 events | 1 pill · 2 encounter Ahmed 09:15–09:40 · 3 conversation 09:20 · 4 question "مين ده؟" 10:02 · 5 recording 11:30 · 6 receipt 11:45 · 7 garden moment 11:50 · 8 memory paused 12:05 · 9 medication label (3 days ago) · 10 card game (yesterday) |
| 8 media | 1 encounter photo (expires in 23 days) · 2 recorded video 12 s · 3 receipt photo · 4 garden photo · 5 label photo. **Placeholder storage keys, no real files yet** |
| 9 documents | 1 pharmacy receipt 120 EGP · 2 medication label Concor 5 mg |
| 10 encounters | 1 Ahmed |
| 11 unknown face clusters | 1 seen 5 times on 3 days, awaiting the caregiver |
| 12 consent records | 1 household conversation memory · 2 cloud processing · 11–14 face enrollment for people 1–4 |
| 13 alerts (for Ahmed) | 1 new face (unread) · 2 low battery (unread) · 3 missed pill (read) · 4 device offline (read) · 5 daily summary ready |
| 14 daily summaries | 1 yesterday |
| 15 game sessions | 1 card match 8 · 2 picture naming 6 · 3 word recall 5 (yesterday) |
| 16 caregiver links | 1 Ahmed → Fatma · 2 Mona → Fatma |

Not seeded: face embeddings (Phase 8), audio segments (transient), tokens, audit log.
