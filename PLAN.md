# Ovara: The Man the Tide Brought In — Game Plan

A single-player role-playing game for phones and tablets (iOS and Android), built in Godot, telling the 18-chapter story. The player walks a hero and his party through a pixel-art world seen from above, explores dungeons in first person, and fights turn-based battles on a grid. The model for its structure and its look is Blue Byte's *Albion* (1995). Built agent-first: AI agents do most of the work, and the repository is designed so they cannot lose detail or drift from the world.

Read this with [CLAUDE.md](CLAUDE.md) (the rules every agent follows), [canon/README.md](canon/README.md) (how world facts are stored) and [docs/design/quests.md](docs/design/quests.md) (the main quest and the side quests, place by place).

---

## 1. What "agent-first" means here

Agents forget everything between sessions and cannot hold the whole world in their heads at once. So the project is built on five rules:

1. **The repository is the memory.** Every fact, decision and task lives in a file. Nothing important exists only in a conversation.
2. **Canon is data, not prose.** World facts live as small structured files with stable IDs. Prose documents (the bible, the campaign, the novel) are sources that were ingested once; after that, the data is the truth.
3. **Everything references canon by ID.** A quest cannot mention a place, person or power that has no canon entry. A machine check enforces it.
4. **Everything is checkable without eyes.** Game rules run without graphics. Areas, dungeons and battle maps print as text. A script walks every area, plays every quest to its end and wins every battle. Art is checked against the palette by a script. One command, `./ov check`, says whether the project is sound.
5. **Small tasks, written down.** Each task is a file that states the goal, the canon it touches and how to prove it is done. An agent with no history can pick one up cold.

---

## 2. The game

**Pitch.** You are a man with no memory and a power nobody has had before, in a sea that is being poisoned. You walk the length of a water world, from a poor kelp hold to the neon islands and back, gathering a party from two peoples who do not believe in each other, and finding out what you did.

**Pillars**

| Pillar | What it means in play |
|---|---|
| **A world you walk** | The story is found, not delivered. People tell you history and rumour; places change when you come back to them |
| **The water is the board** | In battle every hex has a water state. Fouled water weakens you, deaf water silences you, and cleaning it is a move |
| **Ask, do not order** | Power is paid for in ebb, which stays with you until you rest. Overreaching is always available and always costs something permanent |
| **Mercy is the hard mode** | Most fights can be avoided, ended early or won without killing. How you act changes how both peoples treat you |
| **Power made of other people** | The hero's ceiling rises through his party and his teachers. The strongest abilities need others to lend strength |

### Three ways of seeing the world

| Mode | What it is | Used for |
|---|---|---|
| **Exploring** | Pixel art seen from above at a slant, on square tiles. The party walks as one figure | Holds, terraces, kelp forest, ports, decks, streets: most of the game |
| **Dungeons** | First person, in 3D, moving and turning freely | Enclosed, dangerous or secret places: wrecks, vaults, towers, the dark |
| **Battles** | Seen from above on a small hex grid, turn by turn | Fights, and a few set pieces that are not fights (holding the pools, taking the wave) |

One game state sits under all three. Leaving a dungeon puts the party back on the exploring map at its door; a battle begins and ends where the party stands.

### Exploring

- **Moving.** Tap a tile and the party walks there by the shortest path. Hold a finger down and the party walks toward it. Tap a person, a door or a thing to walk up and use it. There is no virtual stick.
- **Areas.** The world is a set of areas joined by exits: the terraces of Low Anthem, its dome, the Wet Market, the Sluice. An area is at most 64 by 48 tiles and scrolls with the party.
- **Under water and on land.** Mariner places are swum through, island places are walked, and the view is the same. Who can go where follows canon: mariners weaken on land within a day, and islanders need a hard suit below the kelp. The party you choose decides where you can linger.
- **Finding things.** Things worth examining glint. Hidden things are found with **Listen**, which shows what the water touches for a few seconds.
- **Light.** Dark places need a lamp or a strand of lampweed, which burns down.
- **Encounters.** Hostile creatures and people are seen on the map before they are met. Most can be avoided, calmed or talked to. Touching one starts a battle.

### Dungeons

- **View.** First person, drawn in 3D with pixel textures at the same low resolution as the rest of the game, so it looks like one game and not two.
- **Moving.** The party is one body that walks and turns freely, as in *Albion*. Drag on the left half of the screen to walk and sidestep; drag on the right half to turn. Tapping a door, a person or a thing walks the party up to it and uses it, so a dungeon can also be played with one thumb. The view stays level: there is no looking up or down, no jumping and no falling.
- **Built on a grid all the same.** A level is still written as a text grid of cells, and walls stand on cell edges. That is what lets a level be printed as text and checked by a script, and what the automatic map draws.
- **Contents.** Doors, seams that only a mender can open, switches, things to carry, flooded and dry stretches, lamps to light, people to find, and encounters that can be seen coming.
- **The map.** An automatic map fills in as the party moves. Marks can be added to it.
- **Flooded and dry.** A flooded stretch is swum, and the gift works in it. A dry stretch has only the water the party brought. This is the dungeon version of the water states.
- **Leaving.** Any dungeon can be left by walking out. Progress inside is kept.

Which places are dungeons is fixed in `docs/design/quests.md`. There are about fourteen, from the flooded third of Low Anthem to the vault under Site Nine.

### The party

- **Size.** The hero and up to three companions walk and fight together. Others who have joined wait at the party's base.
- **The base** is the gallery of the Dragon once it runs (chapter 3), and before that the dry hall at Low Anthem. While the Dragon is stolen (chapters 15 to 17) the base is Lashing. Things are stored there, and the Threaded and other travellers bring news.
- **Changing the party** can be done at the base, in any dry hall and aboard any boat. Those not chosen are assumed to follow a day behind.
- **Who can join, and when,** is set by canon and by the chapter state files. Companions leave and return as the story takes them: Sefa cannot heal between chapters 11 and 16 but still walks with the party and still sets bones.
- **Guests.** Some people walk with the party for one place without joining it: Brask, Yeva, Marit, Garran. Guests talk, and act in battle by their own rules.
- **Each companion does something the hero cannot.** See the table under "The character sheet". Each also has their own things to say about every place, and one quest of their own.

### Talking

- **Dialogue** is a framed panel with a portrait, three short lines at a time.
- **Topics.** As the party learns names and facts, they become topics that can be asked about. Asking the right person about the right thing is how most history and most quests are found. Topics are canon IDs.
- **Who knows what** follows the chapter state: nobody tells the hero his name before chapter 7.
- **No asking everyone everything.** A person who has something new to say about a topic the party holds carries the speaking mark. When they have nothing new, the mark is gone, and the topic list shows only what they will answer.
- **The rays never speak.** What they show is a picture panel with no words.

### Things, money and shops

- **Carrying.** Each party member wears a weapon, a garment and two small things, and carries eight more. There is no weight to count. Supplies are held by the party as a whole. Key things (Jef's tool, a Dragon token) take no room and cannot be sold or lost.
- **Weapons and gear** come from canon: harvesting hooks, fishing spears, harpoons, seal-spears, nets, steel knives from the Wet Market, sea-silk and sealskin, hard suits.
- **Supplies** are one number: a day's food for one person. Resting uses them. They are kelp cake and cured sea-pear in the holds, noodles and brack rice on the islands.
- **Light.** A strand of lampweed lights a dark place for a day. Maker lamps the party lights stay lit.
- **Intended water** heals, and fades: a flask is good for three days in the sea and one day on land, and then is only water. It cannot be stockpiled. This is canon and is tested.
- **Other things:** bitterwrack to clean a fouled hex; Maker parts for mending; ray spines and heat-moss for Maelis.
- **Money.** Islanders pay in company scrip, which is only good in that company's ports and at free ports. Holds trade goods for goods. What stands for money among mariners is a canon proposal (`canon/proposals/`), not yet decided.
- **Shops** are people: a stall at the Wet Market, a net-mender, a Driftfolk trader at the tide line. What they stock and what they pay depends on the place, the chapter and the party's standing with that people.
- **Selling** stolen Maker salvage to wreckers is possible and is noticed.

### Time and rest

- **The calendar.** The game counts days, in three watches each. Walking about a place takes no time. Travel between places takes the time in the world bible's table. Resting takes a watch.
- **Rest** is possible only in a dry hall, at the base, aboard a boat, or in a camp the party makes in clean water. It uses one day's supplies for each person. A watch of rest takes away ebb equal to half the person's Standing; a night at the base takes away all of it.
- **No rest in bad water.** There is no camping in fouled, deaf or orphan water, or inside most dungeons. Going in is a decision.
- **The story never waits on the calendar.** No quest fails because days passed, unless the quest shows a count of its own. The calendar exists so that flasks fade, lampweed burns down and rest has a price.

### The character sheet

The sheet follows the shape of GURPS, cut down for a phone: a few attributes, a talent that seldom changes, skills bought with points, and traits that are simply true of a person. Numbers are starting values for balancing.

**Attributes** run from 8 to 14. Ten is an ordinary adult.

| Attribute | What it is | Gives |
|---|---|---|
| **Body** | Strength and staying power | Health; damage with weapons |
| **Hands** | Sureness of movement | Weapon skills; riding; fine work |
| **Mind** | Wit and attention | The craft; ways with people |
| **Standing** | How well the sea knows you. The bible's own word | The nine forms; the ebb limit |

- **Health** equals Body. **Ebb limit** equals Standing. **Quickness** is the average of Hands and Mind and decides who acts first.
- **Reach** is a talent, 0 to 5, set by canon and the story: 0 for every islander, 1 for the Touched, 2 for callers and healers, 3 for the Mighty, 5 for the hero. Points cannot buy it.

**Skills** have five steps of mastery. A skill's **value** is its attribute plus its step, less three: a first step is two under the attribute, a fifth step two over. A skill without a step cannot be used, except weapons, which are used at five under.

| Group | Skills | On |
|---|---|---|
| Calling | Listen, Move, Shape, Hold, Raise | Standing |
| Intending | Mend, Purge, Ease, Restore | Standing |
| The craft | The craft (tend, then mend, then make, as the steps rise) | Mind |
| The Thread | Riding | Hands |
| Weapons | Blades and hooks; spears and harpoons; nets and lines | Hands |
| People | Bargaining; the island manner; reading people | Mind |

**Traits** are true or not, and come from canon: water-breather; built for the deep; dries on land; needs a hard suit; the Thread; Shallowborn; the rule of the Threaded; hunted by Halcyon; taken memory (the hero, chapters 1 to 6); the oath to the Moot (the hero, from chapter 12). A trait can open a topic, close a place, or forbid an act.

**How anything is decided.** Take the skill's value, add what helps and take away what hinders, and compare it with the task's **difficulty** (8 easy, 10 ordinary, 12 hard, 14 very hard). The difference is the **margin**.

- **The gift, the craft and lessons use the margin as it is.** No dice. A margin of zero or more succeeds; a larger margin does it better, further or for less ebb. The same act in the same water always gives the same result.
- **Weapons and dealings with people use three dice,** from the seeded generator: roll the value or under. The roll is made when the act is chosen and is saved, so trying again gives the same answer.

**Points.** Finishing a quest step gives one to three points to everyone in the party; clearing a stage of the main quest gives five. Battles give none. A step of mastery costs 1, 2, 4, 8 and 12 points in turn. An attribute costs 10 a point and may rise at most two above where it began.

**Teachers.** Points are spent with a teacher, who is a canon person in a particular place: Hesper for the first rule, Maelis for the names of the forms, Jef for the craft, Okonta for riding and the held skin, Yeva for intending, Dace for bargaining. A lesson is a short trial, not a purchase. Weapons can be taught by any companion who has the skill a step higher.

**The story gates the top.** No step can pass what the chapter state allows: nobody makes before chapter 18, nobody restores water before chapter 17, and nobody orders the sea before chapter 11.

**What each companion is for**

| Companion | What they bring that the hero lacks |
|---|---|
| Okonta | The Thread: acts twice a turn, hears hidden things far off, carries one person out of danger. No gift |
| Sefa | Steady intending at reach 2 when he is ebbed or wanting too much; reads people |
| Hesper | Calling at reach 3 with all five forms mastered: control, where he has only size |
| Dace | Bargaining, boats, a harpoon, and welcome among the Driftfolk |
| Raske, Hanne | The craft without the gift; at home on the islands and in hard suits below |
| Corin | A second Thread, and the names of Rook's riders |
| Aurel | Hold at mastery five: the best shield in the game |
| Brask, Garran (guests) | Body: they carry, block and stand where others cannot |

### Quests

There are no missions. Everything the player does is a quest: something a person asks for, or something the party decides to find out.

| Kind | What the player does | Example |
|---|---|---|
| **Fetch** | Bring a thing or a person from one place to another | Carry the old man of Fallow's litter to the Dragon |
| **Discover** | Find a place, a fact or a person, often by asking topics | Find out who the square name beside the empty cradle belonged to |
| **Puzzle** | Work out how something opens, runs or fits | Reseat the lamp; rebuild the Dragon's heart on two wheels |

Battles happen inside quests and between them. A few quests end in a set-piece battle; none is only a battle.

- **The main quest** runs through all 18 chapters, one stage per place. It is written out in `docs/design/quests.md`.
- **Side quests** are optional, belong to a place or a companion, and never gate the main quest.
- **The journal** lists the main quest's current stage and every open, finished and closed side quest, each with its next step in one line and the place to go.
- **Nothing closes silently.** When the story is about to change a place, the journal says which open quests will close.

### Travel

- **On foot or swimming** between neighbouring areas.
- **By needle** between places already visited, once Okonta has joined (chapter 2). It is quick within the same waters. A long ride between waters is always possible and costs days.
- **By the Dragon** between any calling stone or landing the party has stood at, once it has been ridden (chapter 3). It is the quickest way across the world.
- **By Dace's boat** between Girdle ports already visited, from chapter 8.
- **Fast travel follows the story.** The Dragon cannot be used while it is stalled (chapters 5 and 6) or stolen (chapters 15 to 17). The needle still can, so no open quest is ever out of reach, only further off.
- **Going back** is always worth something: people have new things to say, shops have new stock, and side quests open in old places.

### How the story moves

- **Stages.** Each place has a stage of the main quest. A stage begins with an arrival scene, has a **clearing condition**, and ends with a closing scene that sets flags and opens the next place.
- **Flags** are plain named facts in the save: `low_anthem.lamp_lit`, `jef.dead`, `dragon.runs_on_two`. People, shops, areas and quests read them. A place is drawn and peopled according to its flags, so Low Anthem before and after the charges is one area with two states.
- **Chapter state.** The chapter number advances when a stage's closing scene says so. Chapter state files in canon say who is alive, who knows what and what the hero can do.
- **Cut scenes** are played with the game's own graphics: figures walk, speak and act on the exploring map or in a battle view, with the camera and the lights directed by a script. They are data, can be skipped, and can be watched again from the journal.
- **Failure is part of it.** Three stages (chapters 5, 11 and 15) end in a loss whatever the player does. The game says so plainly afterwards and never asks the player to replay them.
- **No false choices.** The player is never offered a choice the story will refuse. Where the hero must do one thing (stay at Kettle House, refuse Rook, give the order at Fallow), the player is given the act itself to carry out, not a menu.
- **Standing with each people is shown, not counted.** The two trust tracks are never shown as numbers. They show in how people greet the party, in what shops ask, and in one plain line each in the journal.

Target length is 30 to 40 hours for the main quest. Side quests add to it.

**Out of scope for version 1:** multiplayer, procedural maps, voice acting, looking up and down or jumping in dungeons, a walkable world map between places, in-app purchases, accounts and cloud saves.

### Mobile first

The game is designed for a phone held in landscape, and scales up to tablets. Everything below is a requirement, not a nice-to-have.

| Area | Requirement |
|---|---|
| **Screen** | Landscape only. Must be fully playable on a 5.5-inch phone. Respect notches and rounded corners |
| **Exploring** | Tap or hold to walk; tap a person or thing to use it. 20 by 8 tiles visible above the interface band |
| **Dungeons** | Drag left to walk, drag right to turn; tap a door or thing to walk up and use it. Playable with one thumb by tapping alone. Turn speed can be set, and there is no view bob |
| **Battles** | 9 by 7 hexes visible without scrolling. Tap a unit, tap a hex to preview, tap confirm to commit. Battle maps are at most 12 by 9 |
| **Touch** | Nothing happens on a single tap that cannot be undone. No hover anywhere: long-press shows information |
| **Touch targets** | Every button, hex and usable thing is at least 44 points across |
| **Readability** | Water state and ebb must be readable at arm's length, by pattern as well as colour. Body text no smaller than 14 points |
| **Interruptions** | Save automatically on every step in a dungeon, every change of area and every action in battle. The app can be closed at any moment and resume in place |
| **Offline** | Fully playable with no connection |
| **Performance** | 60 frames per second on a five-year-old mid-range phone, using Godot's Compatibility renderer, in all three modes. Install size under 300 MB |
| **Battery** | Drop to idle frame rate when nothing is animating |
| **Sound** | Playable with sound off; no information carried by audio alone |

### The look

The reference is *Albion* (Blue Byte, 1995). The full brief is `docs/style/art-direction.md`; every agent who touches anything visible reads it. In short:

| We take | How it shows up here |
|---|---|
| A hand-pixelled world seen from above at a slant, with chunky, readable figures | Exploring maps on 32-pixel square tiles; figures 32 by 48 |
| First-person dungeons that belong to the same world | 3D drawn at the game's low resolution with pixel textures from the same palette, no smoothing |
| Battles on a small grid seen from above | A hex grid, hexes 64 by 48, with the same figures as the exploring maps |
| A lush, living, saturated world set against cold company machinery | Mariner places are curved, grown, green-gold and lit from within. Agravar places are straight, riveted, rust and neon |
| Painted portraits beside the words | Every speaking character has a 96 by 96 portrait; dialogue is a framed panel |
| An interface that looks made, not drawn | Frames of shell and pale glass for mariner screens, riveted steel and dim screens for agravar ones |
| A small palette, dithering, hue-shifted shadows | One master palette of 64 colours, checked by script |
| A world that never stands still | Kelp sways, lamps pulse, fish pass. Deaf water is the one thing that does not move |

We take the structure and the principles. Nothing is copied or traced from *Albion*: no sprite, tile, texture, portrait, interface graphic, map, character, creature or name.

**Base resolution** is 640 by 360, scaled up whole to the device.

---

## 3. Battles

Battles are one of the three modes. They start when the party touches an encounter on a map or in a dungeon, or when a quest calls for one. The party fights where it stands: the battle map is built from the ground around it, with its water states.

All terms below are canon terms from the world bible's sections on the gift and the craft. Numbers are starting values for balancing, not canon.

### Board

- Hex grid, pointy-top, axial coordinates. Maps of 9 by 7 up to 12 by 9 hexes (see "Mobile first").
- Squads are small: the hero plus up to three companions, against six to ten enemies.
- Each hex has a **terrain** and a **water state**.

| Terrain | Effect |
|---|---|
| Open water | Normal movement |
| Kelp | Blocks sight beyond 1 hex; +1 move cost; hides units |
| Wreck, rock, coral | Impassable; glass coral damages units pushed into it |
| Maker structure | Impassable; may hold a machine to tend or mend |
| Deck or land | Agravars move freely; mariners take **drying** each turn |
| Surface | Ships sit here; units below cannot be shot from above without depth weapons |

| Water state | Effect on the gift |
|---|---|
| Clean | Full strength |
| Fouled | Abilities act one reach lower |
| Deaf | No gift abilities can be used from or into this hex |
| Orphan | One reach lower; created effects last one turn only |
| Storm | One reach higher; each use scatters to a random adjacent target |
| Well | One reach higher |

Water states change during play: enemies dump and foul, bloat crabs burst, healers Purge.

### Units

Every unit has the sheet described in section 2. In battle these matter:

| Stat | Meaning |
|---|---|
| Health | Equal to Body. Reaching zero means **out of the fight**, not dead, unless the battle says otherwise |
| Move | Four hexes for a swimmer, three for an islander in a suit, eight for a needle |
| Quickness | Decides the order of turns |
| Reach | 0 to 5: the largest gift effect the unit could ever use |
| Ebb | Rises by the size of each gift effect used. The limit equals Standing |
| Actions | Two per turn: move, attack, a form, tend, or use a thing |

**The order of turns.** Units act one at a time, quickest first, in an order fixed when the battle starts and shown on screen. A unit on a needle takes two turns in each round. A caller cannot answer anything that happens before their turn, unless they prepared a **held skin** on their last one.

**Attacks.** The attacker rolls three dice against their weapon skill, with the distance and the cover taken off. A hit does the weapon's damage plus one for each two points of Body over ten, less what the target wears. A target who has not yet acted this round may spend their coming move to dodge, rolling against Quickness. Nets and lines pin; they do no damage.

**Using the gift.** Each effect has a **size** from 1 to 5: a room's worth, a boat's, a ship's, a city's, a sea's.

- **Safe reach** is the lower of the unit's Reach and its step in that form, with the water state applied. Up to safe reach, the effect does what was asked.
- **Shouting.** Above safe reach but within Reach, the effect happens at full size and scatters: it lands a hex off, or spreads to the hexes around, by the seeded generator. It costs double ebb. This is the barge in chapter 2, and it is how the hero plays until he has learned control.
- **Overreach.** Above Reach in that water, or when the ebb would pass the limit, the effect still happens and the **undertow** comes.

**The undertow** takes one thing, which the player chooses from three the game offers: a step of a skill, a point of an attribute, or a topic the party has learned. The offer is made before the act is confirmed, with a second confirmation.

- **What it takes is kept.** The rays keep whatever the undertow takes. From chapter 7, each thing can be asked back through Maelis: bring her a ray spine and heat-moss, and have finished a quest since the loss, so that her question has an answer. One thing for each bottle.
- **What the story takes stays taken** until the story returns it: the hero's memory, the tending song, Sefa's gift.

**Giving up.** Every enemy group has a nerve. It breaks when their leader is out of the fight, when half of them are, or when they are shown something far beyond them, such as a ship lifted. A broken group flees or yields, and the battle ends. A group that yields can be spoken to.

### Abilities (canon forms, as mechanics)

| Form | Type | Mechanic |
|---|---|---|
| Listen | Calling | Reveal hidden units and water states in a radius |
| Move | Calling | Push or pull a unit; lay a current that changes move costs for 2 turns |
| Shape | Calling | Create a wall hex, an air pocket for agravar allies, or a blade attack |
| Hold | Calling | Pin a unit or ship; make a hex impassable; stop a falling charge |
| Raise | Calling | Lift and reposition a unit or ship; wave attack along a line |
| Mend | Intending | Restore health |
| Purge | Intending | Remove poison from a unit, or raise a hex's water state one step toward clean |
| Ease | Intending | Reduce an ally's ebb; remove fear and stun |
| Restore | Intending | Only on Well hexes: return a unit that is out of the fight. From chapter 17, three or more adjacent healers can also turn one deaf hex clean over several turns, faster when clean hexes are behind them |
| Tend / Mend machine | Craft | Activate or repair a Maker machine on the map (lamp: light and sight; air-heart: safe hexes for agravars) |
| The Thread | Craft | Vehicle units: very high move, must keep moving, ram attack |
| Chorus | Group | Adjacent callers add reach, but if any one is interrupted the effect fails and all take ebb |
| Shared calling | Group | From chapter 12: allies anywhere on the map lend ebb capacity to the hero; no failure cascade |
| Held skin | Calling | From chapter 6: a Hold prepared on the hero's own turn absorbs the first hit of the enemy turn. Without it, fast units act before he can answer |
| Ordering | Hero only | Known from chapter 10. Any calling effect, at any range through non-deaf water, for no ebb. Every hex it touches becomes deaf for the rest of the campaign, and an adjacent ally loses their gift. Scripted in chapter 11. After chapter 12 using it loses the battle and breaks his oath to the Moot |

### Enemies

| Faction | Units | Signature |
|---|---|---|
| Halcyon | Divers, sleds, gunboats, waste barges | Depth charges telegraphed one turn ahead; dumping that fouls hexes |
| Kessler-Vane, Meridian | Armoured security, cutters, mercenaries | Disciplined focus fire; capture, not kill |
| Wreckers | Fast salvagers | Flanking, nets that pin |
| The fouled | Slick eels, bloat crabs | Eels are invisible in fouled and deaf water; crabs burst and foul six hexes |
| Rook's Threaded | Grey needles, and one dart | Move twice a turn, ram and withdraw; nets that carry a unit off the map; some can be turned by Corin from chapter 17 |
| Meridian patrols | Gunboats, trawl transports, spoil tenders | Lay fouled and deaf hexes on purpose; net civilians rather than kill them |
| Breakers | Tidecallers, reach 2 to 3 | The player's own toolset turned on them; cannot be killed without a trust penalty |
| Neutral | Well-wardens, belt sharks, anchor crabs | Hazards with simple rules |

### Winning, losing and what follows

- **Each battle has its own end:** drive them off, hold for N turns, protect someone, purge N hexes, disable a machine, set ships down, get away. Killing is seldom the only way and often the worst.
- **Ending early.** Many enemies give up, flee or can be talked down once the odds turn: wreckers who are paid, sailors who are frightened, Threaded who know your companions by name.
- **Losing** a common battle puts the party back at the last place it rested, ebbed. Losing a story battle that the story says is lost moves the story on.
- **Ebb is carried out of the battle.** It goes down only with rest, which costs supplies and a watch and cannot be had in bad water (section 2, "Time and rest"). A party that fights three times without resting has little gift left for the fourth.
- **Two tracks, standing with the mariners and standing with the islanders,** move with how the party acts in battles and in quests: who was protected, who was harmed, whether overreach was used in front of others. They open and close topics, shops, companions' quests and help in the last chapters. They do not change the story's facts, only who stands with the hero.
- **No randomness in battle,** apart from Storm scatter and the scatter of an unmastered form, both from a seeded generator. Every battle can be replayed exactly by a script.
- **Set pieces.** A few story moments use the battle view without being fights: holding three hundred pools while Jef works, taking the twelve wills of the wave one at a time, being the way through at Site Nine. Each gives the player something to do with their hands. Being a way through is played as steering: strength arrives from the rings around the hero, and the player turns it toward where it is needed without ever stopping it or keeping it. Holding it back raises his ebb; letting it pool ends the piece.

Where each battle and set piece falls is in `docs/design/quests.md`.

---

## 4. Technology

Chosen for how well agents can build and check it. Everything is a text file and runs from the command line. The exact versions are recorded in `docs/decisions/0001-stack.md`.

| Part | Choice | Why |
|---|---|---|
| Engine | Godot 4 (4.7 or newer), Compatibility renderer | Exports to iOS and Android itself; 2D pixel art is its home ground; scenes and scripts are plain text; runs headless for checks |
| Language | GDScript with static types everywhere. Untyped declarations are a parse error in this project | Type errors catch agent mistakes early, with no build step |
| Game rules | `game/rules/`: scripts that extend `RefCounted` only, with no nodes, scenes, input, clock or global randomness. A test enforces it | Runs in tests and scripts without a window |
| Client | `game/scenes/` and `game/ui/`: Godot scenes that draw the state the rules return | Keeps logic out of the scene tree |
| Exploring maps | `TileMapLayer` with 32-pixel square tiles; areas stored as rows of text plus a list of people, things and exits | The engine draws; the rules decide what can be walked and used |
| Dungeons | Godot 3D in the Compatibility renderer: a grid of cells built into walls, floors and doors by script, unlit or lit by a few lamps, drawn into a 320 by 180 viewport and scaled up. The party moves freely and collides with the walls; the rules are told each time it enters a new cell | Looks like the pixel art beside it; a dungeon is still a text grid a script can check |
| Battle maps | `TileMapLayer` with a hexagonal tile set; axial coordinates in the rules | Same division |
| Content | JSON files under `game/content/`, loaded by the rules and shipped with the game. Maps are stored as rows of text inside the JSON so they can be read by eye | Godot reads JSON natively; agents edit it safely |
| Canon | YAML under `canon/`, outside the Godot project, never shipped | Readable prose facts; only tools read it |
| Tests | A small test runner in the repository (`game/tests/run_tests.gd`), run headless | No add-on to download or keep in step with the engine |
| Data checks | Python 3 scripts under `tools/` (canon schema, references, glossary, chapters, art palette), in a local virtual environment | YAML, JSON Schema and image checks are simplest there |
| Saves | JSON under `user://`, with a version number, written after every action | Survives the app being closed; simple to inspect |
| Commands | One script, `./ov`: `check`, `test`, `map`, `play`, `shot`, `index`, `run`, `edit`, `harness`. `map` takes an area, dungeon or battle ID; `play` takes a quest or battle ID; `harness` passes everything after it to the harness | Agents never need to remember engine flags |

**What is already in the kit and tested.** The Godot project, the test runner, the structure tests, a seeded random generator, the `./ov` script and a screenshot tool were built and run with Godot 4.7.2 on macOS before this kit was packed. `./ov check` passed, and deliberately broken files (a `randi()` call in `rules/`, an untyped function, a failing assertion) each made it fail.

**How agents see their work.** Three ways, in order of cost:

1. `./ov map <id>` prints an area, a dungeon level or a battle map as text, with people, things, doors and exits marked. Use it for every one.
2. `./ov shot <scene> <file.png>` runs a scene for a moment and saves a picture at the base resolution. It opens a window briefly, so it needs a desktop session. Look at the picture.
3. `./ov run` starts the game in a desktop window with touch emulated from the mouse.

**Phones.** From milestone 2 the client engineer exports Android and iOS builds. Godot's own documentation has said that export to the iOS Simulator is not supported, and that an exported iOS project can instead be run on an Apple Silicon Mac from Xcode. Read the current "Exporting for iOS" page before relying on either. The owner tests on real phones at each gate.

**What the owner must provide.** These cannot be done by agents:

- Godot 4.7 or newer, with its export templates installed.
- An Apple Developer account and a Google Play developer account, both paid.
- A Mac with Xcode for iOS builds; a JDK and the Android SDK for Android builds.
- Store listings, age rating answers, a privacy policy, and the final submission.
- At least one real iPhone and one real Android phone for gate testing.
- A decision, before milestone 9, on who makes the final art (see section 8).

---

## 5. Repository layout

```
CLAUDE.md               rules every agent follows
PLAN.md                 this file
ov                      the one command script
canon/                  the world, as data (single source of truth); not part of the Godot project
  README.md             entry format, ID rules, change process
  glossary.yaml         canon terms and banned synonyms
  index.md              generated: one line per entry
  source/               the original prose (bible, campaign, novel): read-only
  proposals/            requested canon changes awaiting approval
  places/ people/ factions/ powers/ machines/ creatures/ flora/ events/ chapters/
game/                   the Godot project (project.godot lives here)
  rules/                pure game logic: world state and flags, walking and reach, dungeon grid, hex battles, abilities, AI, skills, items and trade, quests, cut-scene steps
  content/              the game, as data: areas/ dungeons/ battles/ units/ abilities/ skills/ traits/ teachers/ items/ shops/ people/ dialogue/ quests/ cutscenes/
  scenes/               Godot scenes and their scripts: explore, dungeon, battle, dialogue, journal, shop, cut scene, title
  ui/                   theme, frames, controls
  assets/               tiles/ sprites/ portraits/ ui/ audio/ palettes/ briefs/ and manifest.json
  tests/                run_tests.gd, test_case.gd and every test_*.gd
  tools/                headless scripts: print_map.gd, autoplay.gd, shot.gd
tools/                  Python data checks and generators; requirements.txt
  harness/              the development harness: plans, approval, scheduler, sandboxed workers
requirements/           one file per milestone: the harness's input
.github/workflows/      check.yml, the required status check
docs/
  decisions/            one short file per design decision
  style/                art-direction.md (the brief), then art.md and writing.md
tasks/                  backlog/  doing/  done/   (one file per task)
.claude/agents/         role definitions for subagents
```

**Layering, strictly one way:** `canon` → `game/content` → `game/rules` → `game/scenes` and `game/ui`. Nothing lower may depend on anything higher. A script in `rules/` never extends a node, never touches input, and never loads anything from `scenes/`, `ui/` or `assets/`.

**Godot files agents must respect**

- `*.uid` and `*.import` files are created by the engine beside scripts and assets. Commit them. Never write one by hand; run `./ov check`, whose first step imports the project.
- `game/.godot/` is a cache. It is ignored and never committed.
- Scene files (`.tscn`) are text. Keep them small: build anything repetitive in the scene's script, and never hand-edit a scene you have not just read.
- Do not add an add-on from the Asset Library without a decision record.

---

## 6. How consistency is kept

| Mechanism | What it prevents |
|---|---|
| **Canon entries with IDs** (`place.low-anthem`, `power.purge`) | Agents inventing or misremembering facts |
| **Reference check**: every `canon` reference in content must exist | Quests set in places that do not exist |
| **Glossary check**: banned synonyms fail the check ("water-bending" must be "tidecalling") | Terminology drift |
| **Canon rules as tests** (deaf water blocks the gift; agravars never have reach) | Mechanics contradicting the world |
| **Chapter state files**: who is alive, who knows what, which corporations have fallen, as of each chapter | Dead characters reappearing; secrets known too early |
| **One canon keeper**: only that role edits `canon/`; everyone else files a proposal | Silent, conflicting edits |
| **Decision records** in `docs/decisions/` | Re-arguing or reversing settled choices |
| **Auto-player**: a script wins every battle and plays the main quest from the first stage to the last, and every side quest in every chapter it is open | Unwinnable battles; quests that cannot be finished; a main quest that needs a side quest |
| **Walker**: a script checks that every person, thing, door and exit in every area and dungeon can be reached, in every state the flags allow | People behind walls; a dungeon with no way out; a place that breaks when it changes |
| **Flag and quest rules as tests**: every flag that is read is set somewhere; no reward or teacher grants a skill early; no shop sells a key thing; a quest cannot be open after its place is lost | Side content quietly breaking the story; dead ends in the save |
| **Text map printer** for areas, dungeon levels and battle maps | Agents designing places they cannot see |
| **Structure tests**: `rules/` stays pure; every script loads; every declaration is typed | Logic leaking into scenes; code that only fails on a phone |
| **Art check**: every image uses only palette colours, has the right size for its kind, and is listed in the manifest | A look that drifts a little with every asset |
| **Screenshots in task results** | Visual work nobody looked at |
| **Generated `canon/index.md`** | Agents loading the whole canon; they read the index, then only what they need |

---

## 7. Agent roles

Defined in `.claude/agents/`. One agent session takes one role and one task.

| Role | Owns | May edit |
|---|---|---|
| **Canon keeper** | The world's facts and their consistency | `canon/` only |
| **Rules engineer** | Game logic, its tests, and the checking tools | `game/rules/`, `game/tests/`, `game/tools/`, `tools/`, `ov` |
| **Content author** | Areas, dungeons, battles, people, dialogue, quests, items, shops, skills, cut scenes | `game/content/`, `docs/style/writing.md` |
| **Client engineer** | The three modes on screen, input, interface, cut-scene player, exports | `game/scenes/`, `game/ui/`, `game/project.godot`, export presets |
| **Art director** | The look: palette, tiles, figures, portraits, dungeon textures, interface art | `game/assets/`, `docs/style/art.md` |
| **Verifier** | Independent checking of finished tasks | Nothing; reads, runs, reports |
| **Overseer** | Looks at a stuck issue before the owner is asked: retry, extend a budget, or refine | Nothing |
| **Steward** | Answers the harness's process questions in the owner's place (`tools/steward.py`); refers core plot and anything only a person can do | Nothing |

The human owner approves canon proposals, design decisions and each milestone gate.

**The harness** (`tools/harness/`, manual in `docs/harness/README.md`) is how these roles are run. It takes one requirements file per milestone from `requirements/`, has an investigator draft phases and issues, waits for the owner to approve the plan once, and then runs workers in a sandbox: for each issue a refiner, an implementer, the checks, an independent reviewer, a pull request and a merge. Trusted code, not an agent, decides what is allowed and what counts as done. A worker's lane comes from the paths its issue may change (`CLAUDE.md`, "Working under the harness"). The harness asks the owner for anything it cannot decide: canon proposals, design choices, and every judgement by eye or on a phone.

**Task loop without the harness** (a single session working by hand)

1. Pick the top file in `tasks/backlog/` for your role; move it to `tasks/doing/`.
2. Read `CLAUDE.md`, the task, and only the canon entries it lists.
3. Do the work in one branch. Keep the change small.
4. Run `./ov check`. Fix until it passes.
5. Fill in the task file's "Result" section; move it to `tasks/done/`.
6. A verifier session re-runs the checks and reviews against the acceptance list.

---

## 8. Milestones

Each milestone ends at a gate the owner signs off. Do not start the next before the gate passes.

| # | Milestone | Delivers | Gate |
|---|---|---|---|
| 0 | **Canon and foundations** | All prose ingested into `canon/` entries; glossary; validators; the writing guide; the art guide with the master palette, the art check and placeholder tiles, figures and dungeon textures | `./ov check` passes; owner spot-checks 20 entries against the bible and approves the palette from a screenshot |
| 1 | **World core** | In the rules only: world state and flags, areas and walking, people and topics, the quest engine, the journal, saves; text printer; walker; auto-player | Chapter 1 of the main quest is played to its end by the script, in the terminal |
| 2 | **Slice A: a place you can walk** | Low Anthem on screen: exploring, talking, the journal, one fetch, one discover and one puzzle quest, a shop, a cut scene, saves; desktop at phone size, then Android and iOS builds | Owner plays chapter 1 start to finish on a real phone, and says the look is right |
| 3 | **Slice B: a battle** | The hex battle mode with water states, ebb carried out of battle, two party members and one guest: the fouled thing in the terraces, and the barge as a set piece | Owner plays chapter 2 through the barge on a phone |
| 4 | **Slice C: a dungeon** | The first-person mode: free movement by touch, doors, seams, flooded and dry stretches, the automatic map, encounters: the flooded third of Low Anthem, then a wreck in the Tangle | Owner walks both dungeons on a phone and can always tell where they are |
| 5 | **The systems, complete** | the character sheet, points and teachers; things, supplies, the calendar and rest; shops and both kinds of money; the full party, base and guests; all four kinds of travel; all forms, overreach and undertow; trust tracks | Every canon rule has a passing test; the walker and auto-player pass on chapters 1 to 4 |
| 6 | **Main quest, chapters 1 to 9** | Every stage, area, dungeon, battle, person and cut scene on the main path | Auto-player finishes it; owner plays it through before any side quest is written |
| 7 | **Main quest, chapters 10 to 18** | The same, with ordering, shared calling, restoring and the finale | Same |
| 8 | **Side quests and going back** | Every side quest and companion quest; new things to hear and buy in old places | Walker and auto-player pass with every side quest open in every chapter it allows |
| 9 | **Art and sound** | Final tiles, figures, portraits, dungeon textures, interface and music per region, replacing every placeholder | Art check passes with no placeholder left in the manifest; owner approves each region from screenshots |
| 10 | **Balance and release** | Difficulty and economy pass, tutorial polish, performance and battery pass on old phones in all three modes, signed builds, test releases (TestFlight and Play internal testing) | Three outside players reach chapter 4 on their own phones without help; owner submits to both stores |

**Size.** This is a larger game than the tactics game first planned: three modes on screen where there were one and a half, and a world to fill. The slices come first so that each mode is proved on a phone before content is written for it. If the scope has to shrink, cut side quests first, then dungeons from the optional list in `docs/design/quests.md`. Do not cut a mode.

**Who makes the final art.** Agents can make palette-correct placeholders and write exact briefs, and they can check any image against the rules. Whether agents can also produce final pixel art good enough to ship is not known, and the plan does not depend on it. Before milestone 9 the owner chooses: a human pixel artist working from the briefs, image tools with every result cleaned to the palette, or both. Because the placeholders already use the final sizes, view and palette, final art drops in file for file.

**Region look**

| Region | Palette | In the oblique view | Sound |
|---|---|---|---|
| The Pale | Black water, cyan and white glow | Dark tiles; everything alive carries its own light | Near silence, distant whale song |
| Anthem Waters | Green and gold | Tall kelp stems as cover, raked sand, pale Maker ribs | A constant low chord |
| The Girdle | Murky teal with neon magenta and orange | Stilts, hull plates, signs reflected in wet planking | Rain, engines, sirens |
| Bright Shelves | White sand, turquoise, clear light | Open floor, sharp shadows, glass coral that glints | Glass chimes |
| The Quiet | Black with ember red | Red tube-gardens, black sand, no lamps | Nothing, then heartbeat-slow pulses |

---

## 9. First steps

1. Create a new repository and install this kit with `BOOTSTRAP-PROMPT.md`. It proves the skeleton and sets up the harness.
2. Do the owner's steps the bootstrap reports: a GitHub repository with a protected base branch, the two tokens, the sandbox.
3. Run milestone 0: `./ov harness start --requirements requirements/M0-canon-and-foundations.md`. Read the investigator's report before you approve.
4. Review the ingested canon. This is the most valuable hour you will spend: every later agent trusts it.
5. Sign off the gate, then run the next file in `requirements/`.
