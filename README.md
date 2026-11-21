# Ovara

A role-playing game for phones and tablets, set in the water world of Ovara and telling the story *The Man the Tide Brought In*. The player walks a party through a pixel-art world seen from above, explores dungeons in first person and fights turn-based battles on a hex grid. Built in Godot 4 with typed GDScript, mostly by AI agents run by a harness.

Nothing playable exists yet: this repository holds the world, the plan, the rules for agents, a small Godot skeleton and the harness.

## Where things are

| What | Where |
|---|---|
| The plan: design, rules of play, technology, milestones | [PLAN.md](PLAN.md) |
| The main quest and side quests | [docs/design/quests.md](docs/design/quests.md) |
| The rules every agent follows | [CLAUDE.md](CLAUDE.md) |
| The world: bible, campaign, novel | [canon/source/](canon/source/) |
| The look | [docs/style/art-direction.md](docs/style/art-direction.md) |
| Decisions already made | [docs/decisions/](docs/decisions/) |
| The harness that builds the game | [docs/harness/README.md](docs/harness/README.md) |
| What each milestone must deliver | [requirements/](requirements/) |

## Commands

Everything goes through one script.

```sh
./ov check                    # import, tests, canon and art checks, auto-player: must end with CHECK PASSED
./ov test                     # unit and structure tests only
./ov map <id>                 # print an area, dungeon or battle map as text
./ov play <id>                # auto-play a battle or a quest
./ov shot <scene> <file.png>  # save a picture of a scene (opens a window for a moment)
./ov run                      # start the game in a window
./ov edit                     # open the Godot editor
./ov harness <command>        # the development harness
```

You need Godot 4.7 or newer (as `godot`, or set `GODOT` to the binary) and Python 3.9 or newer. Create the Python environment once:

```sh
python3 -m venv .venv
.venv/bin/pip install -r tools/requirements.txt
```

## Building the game

```sh
./ov harness isolation verify
./ov harness start --requirements requirements/M0-canon-and-foundations.md
```

See [docs/harness/README.md](docs/harness/README.md) for what the harness needs first and what it will ask you.

## Licence

All rights reserved. This repository is public so that it can be read; it is not open source, and nothing in it may be copied, changed, reused or built on without written permission. See [LICENSE](LICENSE). The harness in `tools/harness/` has its own licence there.
