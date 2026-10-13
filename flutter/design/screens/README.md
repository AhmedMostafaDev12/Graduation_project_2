# Remori screens (exported from the UI board)

Every screen of the app, exported from the UI board so any agent or person can read it as plain files.
**Don't edit these files.** The board is the source; the lead re-exports this folder when the board changes.

| What | Where |
|---|---|
| Screen code: exact layout, colors, fonts, sizes, radii, text | `<ID>.html` (one file per screen, HTML + CSS) |
| How it looks | `png/<ID>.png` (390 × 844, iPhone 14 size) |
| Logo, photos, illustrations | `images/` (`remori-logo.svg` is the app logo) |

## How to build a screen (agents)

1. Read `png/<ID>.png` to see the screen, then `<ID>.html` for the exact values: the `<style>` block in `<head>` has every color, font, size and radius; the `<body>` has the layout and text.
2. Build it in Flutter to match. Endpoints, Patient Mode rules and what never to build: [`../../AGENTS.md`](../../AGENTS.md) §1.
3. The status bar at the top of each screen (9:41, battery) is only a placeholder for the phone's own bar: wrap screens in `SafeArea`, don't draw it.
4. The background curves and wave are part of the design: draw them (for example with `CustomPaint` from the SVG paths in the file).
5. Links between screens (`href="C9_EditReminder.html"`) show the navigation.

## Screens

| Area | Files |
|---|---|
| Onboarding | `A0_Splash` · `A1_ModeSelect` · `A2_Login` · `A3_Signup` · `A4_PatientProfile` · `A5_Pair` · `A6_Permissions` |
| Caregiver Mode | `C1_Home` · `C2_Alerts` · `C3_People` · `C4_AddPerson` · `C5_PersonDetail` · `C6_UnknownFaces` · `C7_UnknownDetail` · `C8_Reminders` · `C9_EditReminder` · `C10_Places` · `C11_EditPlace` · `C12_Journal` · `C13_Media` · `C14_Documents` · `C15_DocumentDetail` · `C16_Device` · `C17_Summary` · `C18_More` · `C19_Caregivers` · `C20_ConnectedAccounts` |
| Patient Mode (Arabic, RTL) | `P1_Today` · `P2_Reminders` · `P3_ReminderAlert` · `P4_MyDay` · `P5_MemoryDetail` · `P6_Ask` · `P7_Games` · `P8_GamePlay` · `P9_GameResult` |
| System states | `D1_Persistent` · `D2_ReminderNotif` · `D3_CaregiverPush` · `D4_Offline` · `D5_Disconnected` · `D6_Empty` · `D7_AccountExists` |

The photos of people are free-license stock photos used as sample data; the real app shows the patient's own photos from the API.
