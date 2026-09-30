# CLAUDE.md — UNIX App project reference

Working notes for this repository. Kept up to date as work lands so any future
session (human or Claude) can pick the project up without re-deriving context.

**Last updated:** 2026-09-30

---

## 1. What this project is

`unix_app` is a Flutter + Firebase campus "super app" for **SLTC Research
University**, built as a **university academic project**. One app bundles
several student services:

| Area | Purpose |
| --- | --- |
| Jobs | Vacancy board, CV upload, AI CV analysis, skill matching, micro-gigs, career passport |
| Recruiter | Separate dashboard for recruiters to post and manage vacancies |
| Marketplace | Buy/sell second-hand student items, plus an AI market assistant |
| Notes | Upload and browse shared study notes |
| Hostels | Browse hostels, pick a room, book and pay |
| Restaurants | Campus canteens, menus, saved places |
| Lost & Found | Report lost/found items, with scheduled follow-up prompts |
| Tickets, Notifications, Profile | Supporting screens |
| **Admin** | Platform stats, user management, content moderation |

### Tech stack

- **Flutter 3.44.8 / Dart 3.12.2** (stable channel)
- **Firebase project:** `my-unix-app-17-d8a63`
  - Auth (email/password + Google Sign-In)
  - Cloud Firestore (with `firestore.rules` in this repo)
  - Cloud Storage (`storage.rules`)
  - Cloud Functions (`functions/`, Node.js)
- **Git remote:** https://github.com/LashanDias/uniX.git

### Access rules

- Students must sign in with an `@sltc.ac.lk` institutional email.
- Recruiters may use any valid email (role is set at signup).
- Admins are a fixed allow-list of five emails, defined in **two places that
  must stay in sync**:
  - `lib/services/app_access_service.dart` → `AppAccessService.adminEmails`
  - `firestore.rules` → `isAdminEmail()`

---

## 2. Repository layout

```
lib/
  core/                 Colours (app_colors.dart) and theme
  models/               Plain data classes (app_models.dart, restaurant.dart)
  screens/<feature>/    One folder per feature area
  services/             All Firestore/Auth/business logic
  widgets/              Small shared widgets
  main.dart             App entry + every named route (onGenerateRoute)
functions/              Cloud Functions (Lost & Found backend)
test/                   Dart tests (*.dart) and rules tests (*.mjs)
firestore.rules         Server-side security — the real enforcement
```

**Convention:** screens hold layout only; anything touching Firestore lives in
`lib/services/`. Follow this when adding features.

---

## 3. Running the app

### Local web build (what we use for testing)

A Flutter **debug** web server (`flutter run -d web-server`) currently fails in
this environment: the injected `dwds` debug client throws
`TypeError: Instance of '_JsonMap': type '_JsonMap' is not a subtype of type
'List<Object?>'` and the page never renders. This is a tooling bug, **not app
code**. Use a **release build served statically** instead:

```bash
flutter build web --release --no-wasm-dry-run
```

```bash
cd build/web && python -m http.server 5123 --bind 127.0.0.1
```

Then open **http://localhost:5123**.

`--no-wasm-dry-run` just silences WebAssembly compatibility warnings coming from
the third-party `image` package; it does not change the output.

`.claude/launch.json` holds a `unix-web` config pointing at port 5123. Port 8080
is reserved by Windows on this machine and cannot be bound.

### Checks

```bash
flutter analyze
```

```bash
flutter test
```

---

## 4. Known environment gotchas

- **Disk space.** Builds failed silently-ish with
  `FileSystemException: ... errno = 112` (disk full). Stale
  `%TEMP%\flutter_tools.*` directories had accumulated ~3.2 GB. If builds or
  tests start failing strangely, check free space first and clear those.
- **A failed web build leaves a partial `build/web`** without `index.html`.
  Delete `build/web` and rebuild rather than trusting an incremental build.
- **`MediaQuery` lies in widget tests.** `tester.binding.setSurfaceSize()`
  changes the render surface but `MediaQuery.sizeOf(context)` still reports
  800×600. For responsive behaviour that tests must see, measure with
  **`LayoutBuilder`** constraints, not `MediaQuery`.
- **`find.text()` skips off-screen widgets.** A widget built inside a
  `ListView`'s cache extent but outside the viewport is *offstage*, so
  `find.text` returns 0 matches. Pass `skipOffstage: false` to inspect, but if a
  test expects something visible, the layout genuinely has to show it.
- **Line endings.** Git reports `LF will be replaced by CRLF` constantly. Noise,
  not an error.

---

## 5. The admin panel

Route `/admin`, screen `lib/screens/admin/admin_dashboard_screen.dart`, logic in
`lib/services/admin_service.dart`.

Entry point: an admin-only card on the student dashboard
(`lib/screens/dashboard/dashboard_screen.dart`). It renders only when
`AuthService.isAdminEmail(...)` passes.

### Tabs

1. **Overview** — live document counts for `users`, `products`, `notes` and
   `jobs`, driven by Firestore `snapshots()` so they update by themselves. Also
   lists the approved admin emails and marks the signed-in one.
2. **Users** — every registered account, searchable by name, email or role.
   Shows role, an `Admin` badge and a `Blocked` badge. Block/unblock per account.
3. **Moderation** — sub-tabs for marketplace items, notes and vacancies. Each
   row can be deleted behind a confirmation dialog.

### Security model

`AdminService` guards every method with `_requireAdmin()`, but that is only a
convenience so the UI can fail fast with a readable message. **The real
enforcement is `firestore.rules`** — a client-side check alone can be bypassed.

Rules relevant to admin:

- `users`: `allow read: if ownsProfile(uid) || isAdmin()` — admins list all
  accounts.
- `users`: the owner may edit their profile but **never their own `blocked`
  flag**; an admin may change **only** `blocked` (+ `updatedAt`), and **not on
  an admin account**, so the panel can never lock every administrator out.
- `jobs`: `allow update, delete` for the owning recruiter or an admin (before,
  nobody could delete a job at all).
- `products` / `notes`: already owner-or-admin.

Blocking is enforced at sign-in too: `AuthService._checkAccount` signs out any
user whose profile has `blocked: true`, so an existing session does not survive
being blocked.

### Scale caveat

The stat tiles use `snapshots()` and count documents client-side. That is fine
at this project's scale but reads every document. If the data ever grows, switch
to Firestore aggregate queries (`query.count().get()`).

---

## 6. Work log

### 2026-09-30

Baseline on arrival: analyzer clean, **2 of 38 tests failing**.

| # | Change | Commit |
| --- | --- | --- |
| 1 | **Career chat leaked developer text.** `CareerAiService.analyze` returned "Connect a hosted AI endpoint to enable full Gemini-style advice." to students. Replaced with a topic-aware local assistant (cv, interview, internship, salary, portfolio, linkedin, skills, network) that gives real advice offline. | `733f10c` |
| 2 | **Hostel detail screen, three defects.** (a) No warden phone or address anywhere, so a student could not ask anything before paying — added a Contact Us card with a tappable `tel:` link, the campus address and a Google Maps link. (b) All four hostels use hardcoded Unsplash URLs; offline, the bare `Image.network` threw and drew a red error box — added `widgets/safe_network_image.dart` (spinner while loading, muted labelled placeholder on failure). (c) A 190px photo ate 85% of a short viewport, pushing the phone number and room list off screen — the hero and the duplicate title now drop below a 420px height breakpoint, measured with `LayoutBuilder`. | `4d97d24` |
| 3 | Lost & Found Cloud Functions backend found uncommitted in the tree, preserved in its own commit. | `f7e94d5` |
| 4 | **Syntax error blocking every web build.** `followup_card.dart` ended a `return` with `,` instead of `;`. One character; no web build could succeed. | `b002bbe` |
| 5 | **Login footer overflowed by 48px.** The "Don't have an account? / Sign UP" `Row` could not reflow once the card's `maxWidth` dropped to 380. Swapped for a `Wrap`. Also protects users with a large system font. | `96d2cdc` |
| 7 | **No auth persistence.** `MaterialApp` hardcoded `initialRoute: '/login'`, so the app opened on the login form even when Firebase held a valid session -- a student who signed in yesterday had to type their password again today. Replaced with an `AuthGate` that waits for the stored session and opens `MainLayout` or `RecruiterDashboardScreen` by role, with a logo splash while the session is read. Treats an unavailable Firebase as signed out so widget tests still see the login screen. | `c26b765` |
| 6 | **Real admin panel.** The old screen was a hardcoded list of five emails, *and it was unreachable* — the dashboard pushes `/admin` but `main.dart` had no such route, so admins landed on the login screen. Added the route and built the three-tab panel described above, plus `AdminService`, the Firestore rule changes, blocked-account sign-out, and `test/admin_service_test.dart`. | `10a1683` |

| 8 | **Girls hostel had almost no rooms.** The screen showed 4 hardcoded "reference rooms" on the 2nd floor and said every other floor was "pending". Modelled the real building: 23 rooms on each of 3 floors (69, "60+"), 3 six-sharing and 20 four-sharing per floor, room numbers encoding floor+room (0207). New `services/girls_hostel_inventory.dart` holds structure, published rates and free-bed counts, derived from the room number so availability does not reshuffle while scrolling. |
| 9 | **Add Restaurant was under the fold.** The button sat inline below the search box and filter chips, so adding a place meant scrolling first. Moved to a pinned `FloatingActionButton.extended`. |
| 10 | **Marketplace showed error icons for missing photos.** A listing with no `imageUrl` rendered a bare grey icon, and a failed URL rendered a broken-image icon. Both now draw `MarketplacePreviewArt`, picked from the title and category by the new `kindFor()`. Added calculator, audio, laptop, bag and textbook artwork. |
| 11 | **Two AI screens had no artwork.** The CV & job matching banner was text on a blue rectangle; the AI Market Assistant had no hero at all. Both now show the AI robot beside the copy, dropped below 420px. |
| 12 | **Nine overflows clipped content on phones.** A sweep at 320/360/430px found Text widgets sitting directly in Rows with no flex across tickets, micro gigs, career passport and signup, plus a vertical clip in the marketplace grid (tiles pinned to 210px needed 224 once a title wrapped). Fixed with Expanded/Flexible/Wrap and a taller tile. |

Suite after this work: **120 passing, 0 failing**; `flutter analyze` clean.
All commits pushed to `origin/master`.

**Responsive testing.** `test/responsive_sweep_test.dart` pumps every screen
that builds without Firebase at 320, 360 and 430px and fails on any overflow.
Add new screens to its `_screens` map. Screens that touch FirebaseAuth or
Firestore during build (Jobs home, Dashboard, Profile, recruiter) cannot be
covered without Firebase mocks and are deliberately absent.

---

## 7. Open items / next steps

- **The admin panel's authenticated screens have not been exercised against
  live Firebase.** The route and the "Admins only" guard are verified; signing
  in requires real credentials. See `TESTING_GUIDE.md`.
- **`firestore.rules` changes are not deployed.** They only take effect after
  `firebase deploy --only firestore:rules`. Until then the admin Users tab will
  show a load error, because the deployed rules still block admins from reading
  other profiles.
- **Admin list is hardcoded in two files.** Promoting someone to admin means a
  code change *and* a rules deploy. A `role: 'Admin'` field would be better.
- Several `curly_braces_in_flow_control_structures` lints remain in the
  in-progress Lost & Found files.

---

## 8. Conventions for future work

- Commit **after every change**, with a message that says what was wrong and why
  the fix is right — not just what changed.
- Stage **explicit paths**, never `git add -A`: this working tree often has
  unrelated in-progress edits, and a broad add silently commits someone else's
  work under your message.
- Run `flutter analyze` and `flutter test` before every commit.
- Add a manual test script to `TESTING_GUIDE.md` for every user-facing feature.
- Update the work log in section 6 as changes land.
