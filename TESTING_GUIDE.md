# How to test the UNIX app — step by step

Written for someone who has **not** done much software testing before. Nothing
here assumes you know the jargon. Work top to bottom the first time.

---

## Part 0 — The two kinds of testing

There are two completely different things people mean by "testing". You need
both, and they catch different problems.

**1. Automatic tests.** Small programs that check the app's logic by themselves.
You type one command and the computer checks ~57 things in under a minute. They
catch *logic* mistakes ("this function returns the wrong text"). They cannot
tell you whether a button looks right.

**2. Manual testing.** You open the app and click through it like a real
student would. This catches *experience* problems ("this button does nothing",
"the text is cut off", "I got sent to the wrong screen").

Do the automatic tests first, because they are fast. Then do manual testing.

---

## Part 1 — Automatic tests (1 minute)

Open a terminal in the project folder and run:

```bash
flutter test
```

**What you should see** — a lot of scrolling lines, and at the very bottom:

```
All tests passed!
```

That is the only line that matters. If you see it, the logic is healthy.

**If instead you see `Some tests failed:`**, the lines underneath name which
checks broke. Copy that whole block when asking for help — the names tell an
experienced person almost exactly what is wrong.

### The other command worth knowing

```bash
flutter analyze
```

This reads your code without running it and reports mistakes and bad habits.
You want:

```
No issues found!
```

Words to know:
- **`error`** — the app will not build. Must be fixed.
- **`warning`** — probably a bug. Should be fixed.
- **`info`** — a style suggestion. Safe to leave.

---

## Part 2 — Getting the app running so you can click it

Two commands. The first one takes about 2 minutes, the second is instant.

**Step 1 — build the app for the web:**

```bash
flutter build web --release --no-wasm-dry-run
```

Wait for `√ Built build\web`.

**Step 2 — serve it so your browser can open it:**

```bash
cd build/web && python -m http.server 5123 --bind 127.0.0.1
```

This one **keeps running and looks frozen — that is correct.** It is the web
server. Leave that terminal alone. To stop it later, click that terminal and
press `Ctrl+C`.

**Step 3 — open the app:**

👉 **http://localhost:5123**

> **Why not just `flutter run`?** The normal debug command is broken in this
> environment (a Flutter tooling bug called `dwds` stops the page loading). The
> two commands above avoid it. Details in `CLAUDE.md` section 3.

### Important: you must rebuild to see code changes

The served files are a **snapshot**. After any code change, re-run **Step 1**,
then **refresh your browser with `Ctrl+Shift+R`** (a hard refresh, which ignores
the saved copy). The server from Step 2 keeps running — you do not restart it.

---

## Part 3 — How to write down what happened

For every test below, note one of three results:

- ✅ **Pass** — it did exactly what the "Expected" line says.
- ❌ **Fail** — it did something else. **Write down what actually happened.**
- ⚠️ **Blocked** — you could not even try (e.g. you could not log in).

"It didn't work" is not useful. "I clicked Block and nothing happened, and a red
bar said *Could not update this account*" is useful.

---

## Part 4 — Testing the admin panel (the new feature)

### What you need first

An admin account. Only these five emails can open the panel:

- `amashanki191@gmail.com`
- `cit-24-01-0361@sltc.ac.lk`
- `malshikulasekara4816@gmail.com`
- `sandupamabimandhi@gmail.com`
- `jaksikasivakumar@gmail.com`

### ⚠️ Do this before Test A4, or the Users tab will fail

The security rules that let an admin read every account **live in this repo but
are not on Firebase's servers yet**. Deploy them once:

```bash
firebase deploy --only firestore:rules
```

Until you run that, **Test A4 will fail** with "Could not load accounts" — and
that failure is expected, not a bug in the panel.

---

### Test A1 — Non-admins cannot get in

1. Open http://localhost:5123
2. Do **not** log in. Put `/#/admin` on the end of the address so it reads
   `http://localhost:5123/#/admin`, and press Enter.

**Expected:** a padlock icon and **"Admins only"**.

**Why this matters:** it proves a student cannot reach the admin panel just by
guessing the address. *(Already verified ✅.)*

---

### Test A2 — The admin card appears for admins only

1. Log in with a **student** account (`...@sltc.ac.lk`, not on the list above).
2. Look at the dashboard (the first screen after login).

**Expected:** **no** dark "Admin" card.

3. Log out. Log in with an **admin** account.

**Expected:** a dark card with a shield icon **is** now on the dashboard.

---

### Test A3 — Overview tab shows live numbers

1. As an admin, tap the dark admin card.

**Expected:** the **Admin Panel** opens on the **Overview** tab, showing four
number tiles: Registered users, Marketplace items, Shared notes, Open vacancies.

2. Check the numbers are actual numbers, not `...` (still loading) or `--`
   (failed).
3. Underneath, the five admin emails are listed and **yours has a "You" badge**.

**The live test — this is the impressive one for a demo:**

4. Keep the admin panel open. On a **phone, or a second browser window**, log in
   as a student and add a marketplace item.
5. Look back at the admin panel **without refreshing**.

**Expected:** "Marketplace items" goes up by 1 **on its own**.

---

### Test A4 — Users tab

*(Deploy the rules first — see the warning above.)*

1. Tap the **Users** tab.

**Expected:** a list of every registered account, each showing a name, an email,
and a grey role badge (`Student` or `Recruiter`). Admin accounts also carry a
blue **Admin** badge.

2. Type part of a name into the search box.

**Expected:** the list narrows as you type. Try searching an email fragment
(`sltc`) and a role (`student`) too — all three should work.

3. Clear the search box.

**Expected:** everyone comes back.

---

### Test A5 — Blocking a student

**Use a throwaway student account you do not mind losing access to.**

1. On the **Users** tab, find that student and tap the 🚫 icon on the right.

**Expected:** a grey bar at the bottom reads
*"&lt;name&gt; is blocked from signing in."* and a red **Blocked** badge appears
on their row.

2. Log out. Try to log in as that blocked student.

**Expected:** login is **refused**, with a message saying the account has been
blocked by an administrator.

3. Log back in as admin, find them, tap the 🔓 icon.

**Expected:** *"&lt;name&gt; can sign in again."*, the red badge disappears, and
that student can log in normally again.

---

### Test A6 — Admins cannot be blocked (safety check)

1. On the **Users** tab, look at a row for one of the five admin emails.

**Expected:** there is **no** block button on that row at all.

**Why this matters:** if admins could block each other, one mistake could lock
every administrator out of the app permanently.

---

### Test A7 — Moderation: deleting content

1. Tap the **Moderation** tab, then the **Items** sub-tab.

**Expected:** the marketplace listings, newest first.

2. Tap the 🗑 icon on any row.

**Expected:** a dialog: *"Delete this permanently?"*

3. Tap **Cancel**.

**Expected:** dialog closes, **the item is still there**. (Cancel must not
delete — check this properly.)

4. Tap 🗑 again, then **Delete**.

**Expected:** the row disappears immediately and a bar confirms *Deleted "…"*.

5. Repeat on the **Notes** and **Jobs** sub-tabs.

6. Open the app as a normal student and check the deleted item is gone for them
   too.

---

## Part 5 — Testing the other fixes from this session

### Test B1 — Hostel contact details

1. Log in as a student → **Hostels** → pick **Girls** → pick a hostel.
2. Scroll a little.

**Expected:** a **Contact Us** box showing **0112 100 5000**, the SLTC address on
Ingiriya Road, and a **View on Google Maps** button.

3. Tap the phone number.

**Expected:** your phone offers to dial it. *(On a desktop browser nothing may
happen — that is normal. Test this one on a phone.)*

4. Tap **View on Google Maps**.

**Expected:** Google Maps opens at the campus.

---

### Test B2 — Hostel screen with no internet

1. On the hostel detail screen, turn your Wi-Fi **off** and hard-refresh
   (`Ctrl+Shift+R`).

**Expected:** where the photo was, a **neat grey box with an icon and the hostel
name**.

**Must NOT happen:** a red or black error box, or the page breaking.

3. Turn Wi-Fi back on.

---

### Test B3 — Hostel screen on a short window

1. On the hostel detail screen, drag the **bottom edge** of your browser window
   up until the window is very short.

**Expected:** the large photo **disappears**, and the room list and Contact Us
box stay usable. Nothing is cut off or unreachable.

**Why:** a decorative photo should never hide the warden's phone number.

---

### Test B4 — Career AI chat gives real advice

1. Go to **Jobs** → the career chat.
2. Send: `How do I improve my CV?`

**Expected:** friendly advice starting *"I reviewed your message"*, then
numbered suggestions.

**Must NOT appear:** the words *"Connect a hosted AI endpoint"* or *"Gemini"*.
That was developer text leaking to students; it is the bug that was fixed.

3. Try `interview`, `internship`, `salary` — each should give different advice.

---

### Test B5 — Login screen on a narrow window

1. Log out. Drag the browser window **narrow**, like a phone.
2. Look at the bottom: *"Don't have an account? Sign UP"*.

**Expected:** if it does not fit on one line, **"Sign UP" moves to a second
line**, centred.

**Must NOT happen:** yellow-and-black striped bars, or text running off the
edge. That striped pattern is Flutter's "content doesn't fit" warning.

---

## Part 6 — Quick reference

| I want to… | Command |
| --- | --- |
| Check the logic | `flutter test` |
| Check the code quality | `flutter analyze` |
| Rebuild after a change | `flutter build web --release --no-wasm-dry-run` |
| Start the web server | `cd build/web && python -m http.server 5123 --bind 127.0.0.1` |
| Open the app | http://localhost:5123 |
| Publish the security rules | `firebase deploy --only firestore:rules` |
| Stop the web server | `Ctrl+C` in its terminal |
| Force browser to load new code | `Ctrl+Shift+R` |

### If something breaks

1. **Page is blank / white.** You probably forgot to rebuild, or the build
   failed. Re-run the build and watch for `√ Built build\web`.
2. **Build fails with a weird disk error.** Your C: drive is full. Delete the
   `build` folder and clear `%TEMP%\flutter_tools.*`. This has happened before —
   see `CLAUDE.md` section 4.
3. **"Could not load accounts" on the Users tab.** The security rules are not
   deployed. Run `firebase deploy --only firestore:rules`.
4. **Changes don't show up.** Hard refresh with `Ctrl+Shift+R`.
