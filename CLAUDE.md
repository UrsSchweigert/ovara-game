# Ovara — instructions for every agent

You are working on a role-playing game for phones and tablets, built in Godot 4 with typed GDScript, set in the world of Ovara. The player walks a party through a pixel-art world seen from above, explores dungeons in first person and fights turn-based battles on a hex grid. It looks and is built like a role-playing game of the mid-1990s. You have no memory of earlier sessions. This repository is the memory. Follow these rules exactly; they exist so that many agents, over many sessions, build one consistent game.

## Start of every session

1. Read this file.
2. Read your task: `/work/task.json` if the harness started you (see "Working under the harness"), otherwise your task file in `tasks/doing/` (or take the top one for your role from `tasks/backlog/` and move it).
3. Read `canon/index.md`, then open only the canon entries your task lists or that you need. Do not load all of canon.
4. If your task touches design, skim `PLAN.md` sections 2 and 3, the stage or quest it belongs to in `docs/design/quests.md`, and any files in `docs/decisions/` named in the task.
5. If your task touches anything a player will see, read `docs/style/art-direction.md`.

## Working under the harness

Most work on this repository is done by workers that the harness starts (`tools/harness/`, manual in `docs/harness/README.md`). You are one of them if `/work/task.json` exists. Then:

- **Your task is `/work/task.json`,** not a file under `tasks/`. Do not move task files. Do what the harness's own instructions say about results, commits and limits; they come first.
- **Your lane is decided by the paths your task may change.** Read the matching role file before you start, and follow it as well as this file.

| Paths your task allows | Lane | Read |
|---|---|---|
| `canon/` (never `canon/source/`) | Canon keeper | `.claude/agents/canon-keeper.md` |
| `game/rules/`, `game/tests/`, `game/tools/`, `tools/` (not `tools/harness/`) | Rules engineer | `.claude/agents/rules-engineer.md` |
| `game/content/`, `docs/style/writing.md` | Content author | `.claude/agents/content-author.md` |
| `game/scenes/`, `game/ui/` | Client engineer | `.claude/agents/client-engineer.md` |
| `game/assets/`, `docs/style/art.md` | Art director | `.claude/agents/art-director.md` |
| Nothing: you are reviewing | Verifier | `.claude/agents/verifier.md` |
| Nothing: an issue is stuck | Overseer | `.claude/agents/overseer.md` |

- **You cannot open a window.** `./ov shot` and `./ov run` do not work in the sandbox. Do not claim to have looked at anything. Say in your result exactly what a person must look at; the harness turns that into a manual test for the owner.
- **You cannot reach the network,** install anything, or push. If the task needs that, report it as blocked.
- **Protected paths** need the owner: `canon/source/`, `CLAUDE.md`, `PLAN.md`, `docs/design/quests.md`, `docs/decisions/`, `.claude/agents/`, `requirements/`, `ov`, `game/project.godot`, the test runner and structure tests, and `tools/harness/`. If your task cannot be done without changing one, stop and say so.
- **The check is `bash ov check`.** Run it before you report. The harness runs it again on its own copy, and its result is the one that counts.

**If you are the investigator** drafting a plan from a file in `requirements/`:

- Make phases follow lanes: one lane's paths per phase where you can, so that a phase's allowlist matches one role file.
- Use `bash ov check` as the validation command. Add a narrower command only if it exists in the repository today.
- Keep issues small: one content kind, one rule, one screen.
- Anything that must be seen, heard or felt on a phone is a human task, never an acceptance criterion for a worker.
- Anything that needs a new world fact is a canon proposal first, and the owner's answer is a human task.
- Order by dependency: canon before content, rules before scenes, placeholders before anything that draws.

## The rules

### Canon

- **`canon/` is the single source of truth about the world.** If canon and anything else disagree, canon wins and the other thing is a bug.
- **Never state a world fact from memory.** Look it up. If it is not in canon, it is not true yet.
- **Never invent canon in passing.** If your work needs a new fact (a name, a place, a number, a rule), write a proposal in `canon/proposals/` and either wait or use a clearly marked placeholder (`TODO-CANON: ...`). The check fails while any placeholder remains.
- **Only the canon keeper role edits `canon/`.** Files under `canon/source/` are read-only for everyone.
- **Reference canon by ID.** In content files use `"canon": "place.low-anthem"`, not the name typed out.
- **Use canon terms.** `canon/glossary.yaml` lists the correct word and the banned alternatives. The check fails on a banned term.
- **Respect chapter state.** Before writing anything set in chapter N, read `canon/chapters/chNN.yaml`: who is alive, who knows what, what has fallen. Jef dies at the end of chapter 4. The hero is called Wrack until chapter 7 and does not know his past. Sefa has no gift from the end of chapter 11 until chapter 16. Anselm Rook is alive until chapter 17.

### World rules that mechanics must never break

These are canon. Each has a test under `game/tests/`. Do not weaken a test to make content pass.

1. The gift needs contact with water joined to the sea.
2. Deaf water gives no answer at all. Fouled and orphan water weaken by one reach. Water that has been ordered is deaf.
3. Agravars never have the gift. Any willing body can carry the Thread.
4. Intended water fades; it cannot be stored or traded.
5. Using the gift builds ebb. Overreach invites the undertow, which takes something and keeps it. Only the rays can return it, and not before chapter 7.
6. A chorus fails if one member drops. Shared calling does not exist before chapter 12.
7. Only Jef can make Maker things until the hero learns in chapter 18. Nobody can make new Threaded after chapter 4.
8. Mariners weaken on land within a day.
9. Nobody orders the sea before chapter 11. The hero learns how in chapter 10; Hesper's Breakers use it from chapter 12. Ordered hexes stay deaf for the rest of the campaign. Deaf water made by filth can be purged; deaf water made by an order can only be restored, by several healers, from chapter 17.
10. Rook has no gift and cannot mend. Nothing he does may require either.

### Code and content

- **Layering is one-way:** `canon` → `game/content` → `game/rules` → `game/scenes` and `game/ui`. A script in `game/rules/` extends `RefCounted` and nothing else: no nodes, no scene tree, no input, no clock, no files from `scenes/`, `ui/` or `assets/`. A test enforces this. If you need to break it, the design is wrong; stop and say so.
- **The scene shows state; it does not decide it.** Scenes send the player's intent to the rules and draw what comes back. No damage, range or legality is worked out in a scene script. The one exception is walking in a dungeon: the scene moves the party freely and keeps it out of the walls, and tells the rules each time it enters a new cell. Doors, encounters, triggers, light and everything else are still decided by the rules, per cell.
- **Content is data.** Areas, dungeons, battles, people, dialogue, quests, items, shops, skills and cut scenes are JSON under `game/content/`, validated by schema. Do not hard-code them in GDScript.
- **One state, three modes.** Exploring, dungeons and battles all read and change the same world state in `game/rules/`. A mode never keeps its own copy of the party, the pack or the flags.
- **Flags are the story's memory.** Use the flag names in `docs/design/quests.md` exactly. Every flag that is read must be set somewhere; the check fails otherwise. Never invent a flag to get past a problem: write a task for the content author.
- **Follow the quest outline.** `docs/design/quests.md` fixes the main quest's stages, their clearing conditions and which places are dungeons. Changing it needs the owner.
- **Side content never rewrites the story.** A side quest, a shop or a teacher may not grant a skill step or an ability before the chapter state allows it, may not be needed for the main path, may not use a person who is dead or absent in that chapter, and may not add a fact about the world without a canon proposal. An unnamed person of a place is fine; a name or a history is canon.
- **Rules are deterministic.** No `randi`, `randf`, `shuffle`, `pick_random` or `RandomNumberGenerator`. Use `rules/seeded_rng.gd`, and only where `PLAN.md` allows randomness.
- **Type everything.** Every variable, parameter and return value has a static type. An untyped declaration is a parse error in this project; do not change that setting.
- **Leave the engine's files to the engine.** Never write a `.uid` or `.import` file by hand, and never commit `game/.godot/`. Create new scripts and assets, then run `./ov check`; its first step imports the project and creates those files. Commit them.
- **Scenes are text, and fragile.** Keep `.tscn` files small and build repetitive structure in the scene's script. Read a scene file in full before editing it. If the editor is the safer way to make a change, say so in the task result and ask the owner.
- **No add-ons** without a decision record.
- **Stay in your lane.** Edit only the folders your role owns (`PLAN.md` section 7). If the task needs a change elsewhere, write a follow-up task for the owning role.
- **Small changes.** One task, one branch, one purpose. If a task grows past about 400 changed lines, split it and write the rest as new task files.
- **Do not refactor what you were not asked to touch.**

### Checking your work

- Run `./ov check` before you say anything is done. It runs: project import, unit and structure tests, canon validation, glossary check, reference and chapter check, art check, the walker over every area and dungeon, and the auto-player over every battle, the main quest and every side quest. Use `./ov`, not `godot`, so that errors in the engine's output are not missed.
- When you make or change an area, a dungeon or a battle map, run `./ov map <id>` and look at the text output. Confirm that people, things, doors and exits are reachable and water states are what you intended.
- When you change anything visible, run `./ov shot <scene> <file.png>` and look at the picture, then `./ov run` and play the affected place with the mouse as a finger. Report what you saw and attach the picture's path. This is a mobile game: if it needs a keyboard, a hover or a right click, it does not work.
- When you add or change an image, the art check must pass: palette colours only, the right size for its kind, listed in `game/assets/manifest.json`.
- Maps must fit the mobile limits in `PLAN.md` section 2: areas at most 64 by 48 tiles; battle maps at most 12 by 9 hexes, playable with 9 by 7 visible; dungeon levels at most 32 by 32 cells.
- **Report honestly.** If a check fails, say so and paste the output. Never mark a task done with a failing or skipped check. Never delete or loosen a test to get a pass; if you believe a test is wrong, write that in the task result and stop.

### Decisions

- Before making a design choice, look in `docs/decisions/`. If it has been decided, follow it.
- If you make a choice that others will need to follow, record it as `docs/decisions/NNNN-short-title.md`: context, decision, consequences, in under 200 words.
- Do not reopen a recorded decision. If you think it is wrong, write a task for the owner explaining why.

### Finishing

1. Fill in the task file's **Result** section: what changed, what you verified and how, what you could not verify, follow-up tasks you created.
2. Move the task file to `tasks/done/`.
3. Commit with a message that begins with the task ID.

## Writing style for in-game text

- Plain, concrete, short sentences. No narrator commentary. A dialogue panel holds three short lines, so write for that.
- Mariners speak slowly and in images of water and tending. Agravars speak fast, in ownership, numbers and brand names.
- The hero never jokes about what he did.
- Tone guide and sample lines: `docs/style/writing.md`. For voice, the novel in `canon/source/` is the reference.

## When you are stuck

Stop and write down, in the task file, exactly what blocks you and what you tried. A clear question for the owner is a good result. A guess that enters the repository as fact is the worst result.
