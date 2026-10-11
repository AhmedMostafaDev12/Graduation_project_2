# Remori — UI Screens Brief (single-board prompt)

> **Instructions for the AI reading this file:** create **ONE image**: a single large design board showing **every screen listed below, and only those screens**. Do not add screens, features, buttons or data fields that are not listed here. Do not drop any. Every screen is backed by a real API and database (see the "Data" column). Anything else would be a feature the system cannot support.
>
> **For the Flutter / UI team:** this is the complete screen inventory for Remori v1 (source of truth: [`REMORI_SPEC.md`](../REMORI_SPEC.md)). If a screen or field isn't here, it isn't in scope. Ask the team lead before adding anything.

---

## 1. Product in one paragraph

Remori is a memory assistant for people living with Alzheimer's. Smart glasses recognize people and announce their names, remember the day's conversations, speak reminders, and answer simple questions by voice. A Flutter companion app (Android + iOS) has two modes:
- **Patient Mode** runs on the patient's own phone. It's very simple: today, reminders, "my day", games.
- **Caregiver Mode** is for family or professional caregivers: managing people, reminders and places, reviewing the journal and media, and monitoring the device.

The glasses do the talking. The app never replaces them.

---

## 2. Board layout (how to draw the image)

- **Canvas:** one wide board, light neutral background, about **16:9**, very high resolution.
- **Frames:** every screen is an **Android phone frame** (portrait, ~9:19.5) of the same size, with a **label above it**: `ID · Screen name` (e.g. `C4 · Add person`).
- **Sections:** four horizontal bands, each with a large title at the top left:
  1. **A · Onboarding & pairing** (6 screens)
  2. **B · Caregiver Mode** (20 screens, in two rows)
  3. **C · Patient Mode** (9 screens)
  4. **D · System notifications & global states** (7 frames)
- **Flow arrows:** thin gray arrows only for the main flows listed in §7.
- **Language:** draw **Patient Mode in Arabic (RTL)** and **Caregiver Mode in English (LTR)**, to show the app supports both. Every screen exists in both languages in the real app.
- **Sample data:** use only the sample data in §6, so screens look consistent across the board.
- **Style:** calm, warm, trustworthy healthcare app. Rounded cards, generous spacing, no clutter, no stock photos of hospitals. One primary color (calm teal/blue) and semantic status colors (§5).

---

## 3. Design rules

### Patient Mode (users with dementia)
- **Huge type:** body ≥ 22sp, titles ≥ 30sp. **Huge buttons:** ≥ 64dp tall, full width.
- **One idea per screen.** At most 4 items visible. No hidden gestures, no swipe-only actions.
- **Bottom navigation with 4 tabs and labeled icons:** اليوم (Today) · التذكيرات (Reminders) · يومي (My Day) · الألعاب (Games). "Ask" (Phase 2) is a large button on Today, not a tab.
- Arabic-first, RTL, high contrast, friendly. Never show error codes, IDs or technical terms.
- **No editing** of people, reminders, places or settings in Patient Mode.

### Caregiver Mode
- Normal density, English shown on the board, LTR.
- **Bottom navigation with 5 tabs:** Home · People · Reminders · Journal · More.
- A **patient switcher** at the top of Home (a caregiver can be linked to several patients).

---

## 4. Screen inventory

### A · Onboarding & pairing (shared entry, first setup on the patient's phone)

| ID | Screen | Must show | Data |
|---|---|---|---|
| A1 | Welcome / mode select | Remori logo + tagline. Two large buttons: **"I'm a caregiver"** and **"This is the patient's phone"** | — |
| A2 | Caregiver login | **Continue with Google** and **Continue with Facebook** buttons (official brand styles) at the top, an "or" divider, then email, password, Log in, "Forgot password?", "Create account" link | `POST /auth/google`, `POST /auth/facebook`, `POST /auth/login` (spec D26) |
| A3 | Caregiver sign-up | **Sign up with Google** / **Sign up with Facebook** buttons, an "or" divider, then full name, email, phone, password, Create account | `POST /auth/google`, `POST /auth/facebook`, `POST /auth/register` |
| A4 | Create patient profile + consent | Patient full name, date of birth (optional), preferred language (Arabic / English), timezone (default Africa/Cairo). **Consent checkboxes:** "Household agrees to conversation memory (audio is deleted after transcription)", "Allow cloud AI processing". Continue | `POST /patients`, `consent_records` |
| A5 | Pair glasses | Step 1: "Scan the QR code on the glasses case" (camera viewfinder). Step 2: progress "Connecting securely…". Step 3: success, "Glasses paired · Serial RMR-0007" | `POST /devices/pair` |
| A6 | Permissions + hand-over | Checklist with grant buttons: Bluetooth, Notifications, Location ("for 'Where am I?'"), Background activity. Final button: **"Give phone to patient → Patient Mode"** | Android permissions |

### B · Caregiver Mode

| ID | Screen | Must show | Data |
|---|---|---|---|
| C1 | Home dashboard | Patient switcher (avatar + name ▾). **Device card:** glasses connected / last seen 5 min ago, battery 76%, memory **Capturing** / **Paused** chip. **Today card:** people met (3), reminders 1/3 done, 1 snoozed. **Alerts preview** (latest 3) → C2. **AI summary card** labeled "Phase 2" → C17 | `/sync`, `/caregivers/me/alerts`, `devices` |
| C2 | Alerts | List grouped by day. Each alert: icon + type + message + time + unread dot. Types only: **Missed medication · Someone new visited (unknown face) · Low battery · Device offline · Daily summary ready**. Tap marks it read and opens the related screen | `GET /caregivers/me/alerts`, `POST /alerts/{id}/read` |
| C3 | People list | Banner: **"2 new faces to review"** → C6. Grid/list of enrolled people: photo, name, relationship. Filter: Active / Archived. FAB **+ Add person** | `GET /patients/{id}/people` |
| C4 | Add person | 1–5 photo slots (camera / gallery) with tip "clear face, good light, one person". Name, relationship (e.g. son, daughter, nurse). **Consent checkbox:** "This person agreed to be recognized". Save. **Show one error state:** photo 3 outlined red, "No face found — retake" | `POST /patients/{id}/people` |
| C5 | Person detail | Large photo, name, relationship, all enrolled photos + **Add photos**. Edit, **Archive** (confirm) | `PATCH/DELETE /people/{id}`, `POST /people/{id}/photos` |
| C6 | Unknown faces | Cards: sample face photo, "Seen 5 times on 3 different days", first seen / last seen. Tap → C7 | `GET /patients/{id}/unknown-faces` |
| C7 | Unknown face detail | Sample photos. Two actions: **"I know them"** (form: name, relationship, consent checkbox → Save) and **"Stranger — dismiss"** (note: "photos will be deleted") | `POST /unknown-faces/{id}/promote` · `/dismiss` |
| C8 | Reminders | **Today** section: each occurrence with time + title + status chip (Pending / Completed via voice / Snoozed until 09:15 / Missed). **All reminders** section: title, type icon (medication / appointment / task), schedule summary ("Every day at 09:00"), active toggle. FAB + Add | `GET /patients/{id}/reminders`, `reminder_logs` |
| C9 | Add / edit reminder | Title, **"What the glasses will say"** (spoken text, Arabic), type (medication / appointment / task), repeat (once / daily / weekly with weekday chips), time(s), start date, timezone (default patient's). Save, Delete (edit only) | `POST/PATCH/DELETE /patients/{id}/reminders` |
| C10 | Saved places | List: place name, address hint, radius. Explanation: "Used when the patient asks 'Where am I?'". FAB + Add | `GET /patients/{id}/places` |
| C11 | Add / edit place | Map with draggable pin, place name (e.g. "Home", "بيت أحمد"), radius slider (50–500 m), Save | `POST/PATCH /patients/{id}/places` |
| C12 | Journal (day timeline) | Date selector (‹ Thu 1 Oct ›). Type filter chips. Vertical timeline; item types **only:** **Encounter** (person photo, "Ahmed (son) · 09:15–09:40", keyframe thumbnail) · **Conversation** (time range, present people avatars, transcript excerpt) · **Question asked** (question + answer) · **Reminder** (title + final status) · **Recording** (video thumbnail + duration) · **Document** (type icon + key field) · **Notable moment** (photo + AI tag) · **Memory paused / resumed** (small gray marker) | `GET /patients/{id}/journal?date=` |
| C13 | Media viewer | Full photo/video, time, linked event, AI tags. Retention badge: **"Auto-deletes in 23 days"** or **"Kept"**. Actions: **Pin to keep**, **Delete** (confirm dialog) | `GET /patients/{id}/media/{id}`, `POST /media/{id}/pin`, `DELETE /media/{id}` |
| C14 | Documents | Tabs: All / Receipts / Bills / Medication labels. Cards: thumbnail, type, date, key extracted field ("120 EGP", "Concor 5 mg") | `GET /patients/{id}/documents` |
| C15 | Document detail | Photo, extracted fields as a key-value list, full OCR text (collapsible), date | `captured_documents` |
| C16 | Device | Glasses card: serial, firmware, battery, last seen, connection status. **Memory capture master switch** (`memory_capture_enabled`) with an explanation. Re-pair, Unpair (confirm) | `devices`, `patient_profiles` |
| C17 | Daily summary *(Phase 2)* | Date selector, AI summary paragraph, pattern tiles: **Medication adherence 92%**, **Visits 3**, **Talk time 2 h 20 m**, "Routine change" note if any. Label "Generated nightly" | `GET /patients/{id}/daily-summary?date=` |
| C18 | More / settings | Sections: Patient profile (name, language, timezone) · Caregivers → C19 · Consent records (list with date, revoke) · Saved places → C10 · Documents → C14 · Device → C16 · My account · **Connected accounts → C20** · Log out | various |
| C19 | Caregivers & invite | Linked caregivers: name, relationship, **Primary** badge, permission (**Viewer** / **Manager**). Invite form: email + relationship + permission → Send invite | `POST /patients/{id}/caregivers` |
| C20 | Connected accounts | One row per sign-in method: **Google** (connected: email shown, **Disconnect**), **Facebook** (not connected: **Connect**), **Email + password** (set / change password). Note: "Keep at least one way to sign in": the last remaining method has no Disconnect button | `GET /auth/identities`, `POST`/`DELETE /auth/link/{provider}` (spec D26) |

### C · Patient Mode (Arabic, RTL on the board)

| ID | Screen | Must show | Data |
|---|---|---|---|
| P1 | Today (اليوم) | Very large time + date ("الخميس ١ أكتوبر · ١٠:٠٥ ص"). Small status line: glasses connected ● and "الذاكرة شغالة" (memory on) or "متوقفة" (paused). **Next reminder card** with **خدته (Taken)** / **بعدين (Later)**. "قابلت النهارده" (people you met today): up to 3 faces with names. Large button **"اسأل" (Ask)**, labeled Phase 2 | local drift data |
| P2 | Reminders (التذكيرات) | Today's reminders only, as large cards: time, title, status. Pending ones have big **خدته** / **بعدين** buttons | `reminder_logs` (local) |
| P3 | Reminder full screen | Opened from the notification: icon, "ميعاد دواء الضغط", time, two giant buttons **خدته** / **بعدين** | local |
| P4 | My Day (يومي) | Simple timeline in plain sentences with photos: "قابلت أحمد (ابنك) الساعة ٩:١٥", "اتكلمت مع أحمد عن ميعاد الدكتور", "سجلت فيديو", "خدت دوا الضغط". Day switcher (today / yesterday) | `GET /journal` (cached) |
| P5 | Memory detail | One item: big photo or video, the sentence, time. Button **امسح (Delete)** with a confirm dialog | journal item, `DELETE /media/{id}` |
| P6 | Ask (اسأل) *(Phase 2)* | Giant mic button "اضغط واتكلم" + optional text field. **Answer card:** "أحمد قالك إن ميعاد الدكتور بكره الساعة ٥" with small source chips (time + type) | `POST /patients/{id}/assist` |
| P7 | Games (الألعاب) | 3–4 large game tiles (e.g. memory card match, picture naming, word recall), each with last score | `mind_game_sessions` |
| P8 | Game play | Example: **memory card match**, 6 large cards (some flipped), timer, simple encouragement, no fail state shown harshly | — |
| P9 | Game result | Friendly "أحسنت!" (Well done!), score, duration, buttons: play again / back | `POST /patients/{id}/mind-game-sessions` |

### D · System notifications & global states

| ID | Frame | Must show |
|---|---|---|
| D1 | Persistent notification (Android) | Pull-down shade: "Remori is connected to your glasses" (ongoing, low priority) |
| D2 | Reminder notification | Heads-up notification "ميعاد دواء الضغط" with action buttons **خدته** / **بعدين** |
| D3 | Caregiver push | Lock screen: "Missed medication: blood pressure pill (09:00)" |
| D4 | Offline / syncing banner | Caregiver Journal with top banner "Offline · 12 items waiting to sync" |
| D5 | Glasses disconnected | Patient Today with a gentle banner "النضارة مش متوصلة" (glasses not connected) + "Try again" |
| D6 | Empty state | Caregiver People list empty: illustration + "Add the first person your patient should recognize" + button |
| D7 | Account already exists | A2 after "Continue with Facebook" with an email that already has an account: message "An account with this email already exists. Sign in with Google or your email, then connect Facebook in Connected accounts." + buttons: Continue with Google / Log in with email | `409 ACCOUNT_EXISTS` (spec D26) |

---

## 5. Status colors (use consistently)

| Meaning | Color |
|---|---|
| Completed / connected / capturing | Green |
| Pending / scheduled | Neutral gray-blue |
| Snoozed / paused / low battery | Amber |
| Missed / offline / error | Red (soft, never alarming in Patient Mode) |
| Phase 2 features | Small "Phase 2" outline badge |

---

## 6. Sample data (use only this)

- **Patient:** فاطمة محمود (Fatma Mahmoud), 72, Arabic, Africa/Cairo.
- **Caregiver:** Ahmed Mostafa (son, primary, manager). Second caregiver: Mona Ali (nurse, viewer).
- **Enrolled people:** Ahmed (son) · Sara (daughter) · Dr. Hany (doctor) · Mona (nurse).
- **Reminders:** دواء الضغط (blood pressure pill), daily 09:00, medication · ميعاد الدكتور (doctor appointment), Fri 17:00, appointment · اشرب مية (drink water), daily 12:00 / 16:00, task.
- **Places:** Home (البيت) · بيت أحمد (Ahmed's house) · Clinic.
- **Device:** serial RMR-0007, firmware 0.3.1, battery 76%.
- **Document:** pharmacy receipt 120 EGP · medication label "Concor 5 mg".

---

## 7. Flows to draw as arrows

1. A1 → A2 → C1 (caregiver login: Google, Facebook or email)
8. C18 → C20 (connected accounts) and A2 → D7 (Facebook email already used)
2. A1 → A2 → A4 → A5 → A6 → P1 (first setup on the patient's phone)
3. C3 → C4, and C3 → C6 → C7 (enroll / review unknown face)
4. C8 → C9 (create reminder) and D2 → P3 (reminder notification → full screen)
5. C12 → C13 (journal → media) and P4 → P5
6. C1 → C2 → C17 (alert → daily summary)
7. P7 → P8 → P9 (game)

---

## 8. Do NOT design (out of scope: it would break or contradict the system)

- ❌ **Live camera view or video stream** from the glasses. The glasses never stream.
- ❌ **Audio playback** of conversations. Raw audio is deleted after transcription; only transcripts exist.
- ❌ **Live GPS tracking / patient location map** for caregivers. Location is used only for the patient's "Where am I?" question. Places are just saved pins.
- ❌ **Chat, messaging, video or voice calls** between caregiver and patient.
- ❌ Patient-side **editing** of people, reminders, places, consent or settings.
- ❌ **Password login for the patient.** Patient Mode signs in automatically with the paired device.
- ❌ Face-recognition **threshold / AI model settings**, wake-word setup, **AR display settings**.
- ❌ An **iOS-specific glasses-relay setup** (the relay runs on Android in v1).
- ❌ Social features, sharing to other apps, likes, comments, feeds.
- ❌ Payments, subscriptions, ads, admin panels, analytics dashboards beyond C17.
- ❌ Any data field not listed in §4.

---

## 9. Feature → screen coverage (checklist)

| Feature (spec §2) | Screens |
|---|---|
| Face enrollment | C3, C4, C5 |
| Unknown recurring faces | C6, C7, C2 |
| Real-time recognition (encounters) | C12, P1, P4 |
| Ambient memory (conversations) | C12, P4, C16 (master switch), A4 (consent) |
| Voice assistant questions | C12 (question + answer), P6 |
| Reminders | C8, C9, P1, P2, P3, D2 |
| Where am I (saved places) | C10, C11 |
| Daily journal | C12, P4, P5 |
| Intelligent capture + media | C12, C13 |
| Document capture | C14, C15 |
| User-requested recording | C12, C13, P4, P5 |
| Privacy controls + retention | A4, C13 (expiry, pin, delete), C16, C18 (consent), P5 |
| Device pairing + status | A5, A6, C1, C16, D1, D5 |
| Caregiver sign-in: Google, Facebook, email (D26) | A2, A3, C20, D7 |
| Alerts | C1, C2, D3 |
| Mind games | P7, P8, P9 |
| Daily summary / insights (Phase 2) | C1, C17 |
| Multiple caregivers | C1 (switcher), C19 |
| Offline-first | D4, D5 |

**Total: 6 + 20 + 9 + 7 = 42 frames.**

---

### Note to the human using this file
Most image models can't render 40 legible phone screens in one image. If the result is unreadable:
1. Generate **one image per section** (A, B, C, D) with the same prompt and style.
2. Or give this file to a **UI-design AI** (e.g. Figma Make, Google Stitch, v0), which can produce real, editable screens.

Either way, this file stays the checklist: every screen and field above, nothing more.
