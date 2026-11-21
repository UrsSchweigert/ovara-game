# Milestones: where you are and what comes next

The harness runs one milestone at a time and does not know about the next one. This page is the owner's checklist. Tick things off here as you go, through a pull request.

**The loop, every time**

1. Do "Before you start".
2. Reread the milestone's file in `requirements/` against `PLAN.md`, and edit it if the plan has moved.
3. `./ov harness isolation verify` (the sandbox attestation lasts 24 hours).
4. Start it with the command given. Read the investigator's report before you approve.
5. While it runs: `./ov harness status`, and `./ov harness tasks` for what is waiting for you.
6. When the plan is finished, check that its run branch is merged into `main`.
7. Do "The gate". Only then move on.

If `tools/steward.py` is running, it does steps 3 to 6 for you and drafts the next plan. What stays yours is each plan's approval (`./ov harness approve <plan-id>`) and the parts of each gate that need a person, which you record with `python3 tools/steward.py --sign-off <plan-id>`.

Workers cannot open a window. Everything that must be seen, heard or tried on a phone comes to you as a manual test.

---

## 0. Canon and foundations

`./ov harness start --requirements requirements/M0-canon-and-foundations.md --model-source claude`

- [ ] **Before you start:** the two GitHub rulesets, the Claude token and the broker token (see `docs/harness/README.md`).
- [ ] **During:** answer canon proposal P-001 (what mariners trade with).
- [ ] **The gate:** `./ov check` passes with the real validators.
- [ ] **The gate:** spot-check 20 canon entries against the world bible.
- [ ] **The gate:** approve the palette from a picture.

## 1. World core

`./ov harness start --requirements requirements/M1-world-core.md --model-source claude`

- [ ] **Before you start:** nothing beyond the loop.
- [ ] **During:** answer canon proposals for unnamed people who now have lines.
- [ ] **The gate:** the script plays chapter 1 of the main quest to its end in the terminal (`./ov play`), and `./ov check` passes.

## 2. Slice A: a place you can walk

`./ov harness start --requirements requirements/M2-slice-a-a-place-you-can-walk.md --model-source claude`

- [ ] **Before you start:** install Godot's export templates, the Android SDK with a JDK, and Xcode.
- [ ] **Before you start:** choose the app's real name and its identifiers for both stores.
- [ ] **During:** a manual test for every scene.
- [ ] **The gate:** build for Android and iOS and play chapter 1 start to finish on a real phone.
- [ ] **The gate:** say whether the look is right. If it is not, change `docs/style/art-direction.md` before going on.

## 3. Slice B: a battle

`./ov harness start --requirements requirements/M3-slice-b-a-battle.md --model-source claude`

- [ ] **During:** manual tests of the battle scene.
- [ ] **The gate:** play chapter 2 through the barge on a phone.

## 4. Slice C: a dungeon

`./ov harness start --requirements requirements/M4-slice-c-a-dungeon.md --model-source claude`

- [ ] **During:** manual tests of touch control and comfort. Expect several rounds; this is the riskiest mode.
- [ ] **The gate:** walk both dungeons on a phone and always know where you are.
- [ ] **The gate:** decide whether free movement stays. If it does not work on a phone, record a new decision before milestone 5.

## 5. The systems, complete

`./ov harness start --requirements requirements/M5-the-systems-complete.md --model-source claude`

- [ ] **The gate:** every world rule in `CLAUDE.md` has a passing test.
- [ ] **The gate:** the walker and the auto-player pass on chapters 1 to 4.

## 6. Main quest, chapters 1 to 9

`./ov harness start --requirements requirements/M6-main-quest-chapters-1-to-9.md --model-source claude`

- [ ] **During:** canon proposals for what dungeons contain and for unnamed people.
- [ ] **The gate:** the auto-player finishes stages 1 to 9.
- [ ] **The gate:** play stages 1 to 9 yourself. No side quest is written before you have.

## 7. Main quest, chapters 10 to 18

`./ov harness start --requirements requirements/M7-main-quest-chapters-10-to-18.md --model-source claude`

- [ ] **The gate:** the auto-player finishes the main quest from stage 1 to stage 18.
- [ ] **The gate:** play it through.

## 8. Side quests and going back

`./ov harness start --requirements requirements/M8-side-quests-and-going-back.md --model-source claude`

- [ ] **During:** canon proposals for the ten other holds on the routes, for Sounding and for what lies under the Exchange.
- [ ] **The gate:** the walker and the auto-player pass with every side quest open in every chapter it allows.

## 9. Art and sound

`./ov harness start --requirements requirements/M9-art-and-sound.md --model-source claude`

- [ ] **Before you start:** decide who makes the final art: a pixel artist working from the briefs, image tools with every result cleaned to the palette, or both. Record it in `docs/decisions/`.
- [ ] **The gate:** the art check passes with no placeholder left in the manifest.
- [ ] **The gate:** approve each region from pictures.

## 10. Balance and release

`./ov harness start --requirements requirements/M10-balance-and-release.md --model-source claude`

- [ ] **Before you start:** Apple and Google developer accounts.
- [ ] **During:** signing, store listings, age ratings and a privacy policy. None of this is done by workers.
- [ ] **The gate:** three outside players reach chapter 4 on their own phones without help.
- [ ] **The gate:** submit to both stores.

---

## If the scope has to shrink

Cut side quests first (milestone 8), then the optional dungeons at the bottom of the table in `docs/design/quests.md`. Do not cut one of the three modes.
