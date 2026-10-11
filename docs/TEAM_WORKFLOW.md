# Team workflow: branches, pull requests, CI, conflicts

How every change gets from a laptop into `main` without breaking anything or conflicting with someone else's work.

---

## 1. The loop (every change)

```bash
git checkout main
git pull                                   # start from the latest main
git checkout -b <type>/<short-name>        # one branch per change

# ...work only inside your area's folder...
# ...run your area's checks locally (see your AGENTS.md)...

git add <your-folder>/
git commit -m "<area>: <what changed>"
git push -u origin <type>/<short-name>
# → open a Pull Request on GitHub → CI runs → lead reviews → merge → delete branch
```

**Branch names:** `feature/c4-add-person`, `feature/events-batch-endpoint`, `fix/reminder-timezone`, `chore/…`, `docs/…`. Put the screen ID (UI brief) or endpoint in the name when there is one.

**Commit messages:** `<area>: <what changed>`, for example `flutter(C4): photo slots with retake error` or `backend: POST /patients/{id}/events:batch`.

**First time only:** `git clone https://github.com/AhmedMostafaDev12/Graduation_project_2.git` instead of `pull`.

---

## 2. What CI checks on every pull request

Defined in [`.github/workflows/ci.yml`](../.github/workflows/ci.yml). Each area runs **only** when its folder changed.

| Check | Runs when | Fails when | How to fix |
|---|---|---|---|
| **Branch contains latest main** | every PR | `main` has commits your branch doesn't | `git fetch origin && git merge origin/main`, resolve conflicts locally, push |
| **No conflict markers** | every PR | a file contains `<<<<<<<` or `>>>>>>>` | you committed a half-resolved conflict; finish resolving and push |
| **Backend: ruff format** | `backend-ai/**` changed | code isn't formatted | `ruff format .` inside `backend-ai/` |
| **Backend: ruff check** | `backend-ai/**` changed | lint errors | `ruff check . --fix`, then fix the rest by hand |
| **Backend: pytest** | `backend-ai/**` changed | a test fails | run `pytest` locally and fix |
| **Flutter: dart format** | `flutter/**` changed | code isn't formatted | `dart format .` inside `flutter/` |
| **Flutter: analyze** | `flutter/**` changed | analyzer errors or warnings | `flutter analyze` and fix |
| **Flutter: test** | `flutter/**` changed | a test fails | `flutter test` and fix |

Areas that don't exist yet (no `pubspec.yaml`, no `tests/`) are skipped automatically.

**Rule:** a red PR is never merged. GitHub can't block it on this private repo (that needs GitHub Pro), so the team enforces it.

---

## 3. Why these checks prevent conflicts

- **Auto-formatters** (`dart format`, `ruff format`) make everyone's code look identical, so diffs show real changes, not whitespace.
- **`.gitattributes`** stores every text file with LF line endings, so a Windows edit doesn't rewrite every line of a file a Mac user also touched.
- **"Branch contains latest main"** forces conflicts to be resolved **on your branch, by you**, before merging, never on `main`.
- **Areas don't overlap.** Flutter devs change `flutter/`, backend changes `backend-ai/`. Two people rarely edit the same file.

---

## 4. Resolving a conflict (step by step)

```bash
git fetch origin
git merge origin/main            # Git reports "CONFLICT in <file>"
```
1. Open each conflicting file. VS Code shows **Accept Current / Accept Incoming / Accept Both** above each block.
2. Keep the right code, and make sure no `<<<<<<<`, `=======` or `>>>>>>>` lines remain.
3. Run your area's checks again.
4. `git add <files>` → `git commit` → `git push`.

If you're unsure which version is right, **ask the person who wrote the other side** (or the lead) before choosing.

---

## 5. Keeping PRs conflict-free in the first place

- Pull `main` **every morning** and merge it into your branch.
- Keep PRs **small** (one screen, one endpoint) and merge them quickly. Long-lived branches are what conflict.
- Don't reformat or rename files you aren't otherwise changing.
- Shared files (`REMORI_SPEC.md`, `docs/*`, `AGENTS.md`) are edited only by the lead or with the lead's approval.
