# Quests: the main quest and the side quests

This is the design for what the player does, place by place. It is not canon: every fact in it comes from `canon/` (the world bible, the campaign and the novel), and where it needs something canon does not have, it says **needs a canon proposal**. Content authors turn each stage and quest into data under `game/content/`. Rules for how quests work are in `PLAN.md` section 2.

**How to read a stage**

- **Place:** the areas (walked, seen from above) and dungeons (first person) it uses.
- **Party:** who walks with the hero. *Guest* means present for this place only.
- **Steps:** what the player does. Each step is marked **F** (fetch), **D** (discover) or **P** (puzzle). **B** marks a battle and **S** a set piece in the battle view.
- **Clear when:** the clearing condition.
- **Sets:** the flags the closing scene sets. Flag names are final; use them exactly.
- **Opens:** places, travel, people and skills that become available.

Chapter numbers match the campaign and the chapter state files. The chapter advances at the end of the stage unless a line says otherwise.

---

## Part one: the main quest

### Stage 1. The man the tide brought in (chapter 1)

- **Place:** the kelp terraces of Low Anthem; the dome (dry halls, sea-door, meeting hall).
- **Party:** the hero, called Wrack. Sefa and her hound Bother walk with him as guests.
- **Arrival scene:** he wakes on the seabed breathing water, in boots, with cable-tie marks on his wrists. Sefa names him.
- **Steps**
  1. **D** Follow Sefa in through the terraces to the sea-door. Teaches walking and talking.
  2. **D** Three days in the dry room: ask Sefa about every topic she offers (holds, Makers, the gift, Jef, the Dragon, the Threaded). Each topic learned opens more.
  3. **D** Ione's examination: learn that the memory was taken whole, and the word *undertow*.
  4. **F** Work a row of terrace: cut ten fronds and bring them to the drying racks. Teaches carrying.
  5. **P** The nursery gate. It latches up and across. Davin shows it; the player must do it. Failing lets the silverbacks out and Bother rounds them up.
  6. **D** The night crew's hammock talk: three topics are heard only here, including the Threaded who went up to the islands.
  7. **P** The meeting-hall lamp. On the ninth day, examine it: find the seam, then move three parts into place. First use of the craft.
- **Clear when:** the lamp is lit.
- **Sets:** `low_anthem.accepted`, `low_anthem.lamp_lit`, `hero.craft_mend`.
- **Opens:** the craft, at its first step; the hold's stalls; side quests at Low Anthem.

### Stage 2. The barge (chapter 2)

- **Place:** the terraces by night; the dome's dark side; after the charges, the flooded third of the dome as the first **dungeon**.
- **Party:** Wrack. Hesper and Ione as guests in the battle.
- **Steps**
  1. **P** With Elder Oro, try the eleven dead lamps. One can be lit, one shows a break that needs a tool he does not have, nine will not open. Sets up Jef's tool.
  2. **D** Davin at the net-racks: learn Tenders, Breakers and the barges.
  3. **F** The fall: hold a corner of the net and carry sealed bladders to the carrying crew while the sludge comes down. Timed, cannot be failed outright.
  4. **S** The barge. One action is offered: Raise, far above his mastery. It lifts the barge and scatters: the terrace is wrecked.
  5. **D** Ebbed for three days: Hesper's lesson. The first rule is learned as a topic and as the first step of Listen.
  6. **B** The gunboats. He is still ebbed and cannot call. Get people out: reach six groups on the terraces and lead them to the kelp before the charges land. Hesper turns charges aside by her own rules.
  7. **D** **Dungeon: the flooded third.** Dark, cracked halls, half full of sea. Find the survivors and the dead. Find Elder Oro under the lit lamp. Teaches the first-person view, the automatic map and lampweed.
- **Clear when:** every hall of the flooded third has been entered and the dead are laid at the kelp stems.
- **Closing scene:** Hesper leaves for the Tangle. Okonta arrives on her needle.
- **Sets:** `low_anthem.bombed`, `oro.dead`, `davin.dead`, `hesper.breaker`, `okonta.met`.
- **Opens:** Okonta joins. Needle travel within the Anthem Waters. Low Anthem changes state: a third dark, a hundred and ten people gone to Deep Chorus later.

### Stage 3. The Dragon (chapter 3)

- **Place:** the kelp road; the Tangle; a Charter War wreck (**dungeon**); the ruin of Sounding (seen, entered only in a side quest); the edge of the Slick; Greywatch Stone.
- **Party:** Wrack, Okonta. At the stone, the woman of Fallow, her father and Brask as guests.
- **Steps**
  1. **D** First night's camp: Okonta's story and the rule of the Threaded, as topics. Pale singers heard; learn that she steers by them.
  2. **D** Hunters behind: four sleds. Choose a way through the Tangle. Encounters with wreckers can be avoided by staying in thick kelp.
  3. **P** **Dungeon: the wreck.** Hide the needle and pass through a gunship lying on its side while the sleds search above. Doors are jammed; the way is found by flooding and draining compartments.
  4. **D** Sounding: Okonta tells what it was and whose birthplace. A topic for later.
  5. **B** The Slick: deaf water. The gift does nothing. Hold on, and keep the eels off with what is in the pack, while Okonta flies. Teaches deaf water by losing the gift.
  6. **F** Greywatch Stone: read the names; carry water and food for the old man of Fallow; wait three days. Brask's topics on the Pale and Rime.
  7. **B** The recovery team arrives. Their officer calls him "sir". The battle is to keep the divers off the Fallow camp until the stone sings.
  8. **P** The Dragon stops. Lay a hand on it and mend it enough to run: clear silted channels with Move while seating three parts by hand. First time gift and craft are used in one puzzle.
- **Clear when:** the Dragon runs and all five are aboard.
- **Sets:** `dragon.ridden`, `dragon.mended_once`, `halcyon.knows_face`, `fallow_father.aboard`.
- **Opens:** the Dragon's gallery as the party's base. Dragon travel between Greywatch Stone and the Tips. The empty cradle with the square name can be examined (a topic nobody will answer yet).

### Stage 4. The mechanic (chapter 4)

- **Place:** Kettle House and its shelf; the lip of the North Well; the Lantern (nine halls, walked); the crawlways under the ring (**dungeon**).
- **Party:** Wrack, Okonta. Brask as a guest.
- **Steps**
  1. **D** Eleven days waiting: learn Listen properly at the lip of the Well, a little each day. Rime's people bring food and topics.
  2. **D** Jef and Maelis arrive. Soup; Jef examines his hands.
  3. **P** The workshop: three lessons at the bench, each a machine laid open (warm-stone, lamp heart, a small air-heart). Raises Mend machines.
  4. **D** Afternoons on the step: Jef's history in pieces, as topics. He will not answer the topic *Sounding*.
  5. **S** The Lantern: hold the water of three hundred pools still for six days while Jef works. On the fourth day, go down the crawlways still holding. **Dungeon** with a constraint: every step costs a little, and the pools must not be dropped.
  6. **P** The five forms, one a night, each a small trial at the Well: a ripple, a current, a rope tied in a knot, a bowl held upside down, the sphere with the shoal in it.
  7. **D** Maelis's story and the rays. Learn that they keep what the undertow takes.
  8. **D** The visitor on the step. He offers the hero his name if he will come south. The player may ask him anything. There is no choice to go: when the questions are done, the player carries out the hero's answer by walking him back to the bench where the warm-stone lies open.
  9. **D** The dinner, the tool, the Thread.
  10. **S** The dart. Hold the pools for the nine-hour descent and the eleven hours after. Lend Jef the tool.
- **Clear when:** eight halls relight.
- **Closing scene:** Jef's death. Maelis takes him south. The Dragon's light flickers.
- **Sets:** `jef.dead`, `hero.threaded`, `hero.has_tool`, `lantern.eight_halls`, `rook.seen_unnamed`, `maelis.south`.
- **Opens:** the skill Riding; his own needle. The introduction ends here.

### Stage 5. The lamps go out (chapter 5)

- **Place:** Kettle House, empty; the ride south; Deep Chorus (the high hall, the tiers, the lowest galleries); its service ways and heart vaults (**dungeon**).
- **Party:** Wrack, Okonta. Sefa as a guest in the hold.
- **Steps**
  1. **P** Nine days at the bench, with Okonta keeping watch: try to make. It cannot be done; the attempt raises the craft and shows what is missing.
  2. **D** The Dragon stops. Dragon travel is closed. Ride south by needle, learning to ride on the way.
  3. **D** Deep Chorus: Elder Vey denies everything. Find Sefa, and with her the back stairs.
  4. **D** **Dungeon: the service ways.** Go down behind the galleries to the lowest tier and the sealed heart vault. Find how many hearts are silent.
  5. **P** Choose: the hold or the Dragon. Either can be chosen; only the hold can be finished in time, and the game says so before the choice is final.
  6. **S** Hold air in three thousand rooms while mending. The longer it is held, the further the undertow rises. Sefa stops it. The tending song and Bother's name are lost.
  7. **P** Mend the first heart; save the dying one. The other two cannot be mended: the puzzle has no solution, and Jef's voice says what that means.
  8. **D** Sefa in the high hall. Then Vey at the sea-door: the man in grey and his paper.
- **Clear when:** light reaches the sixtieth tier.
- **Sets:** `deep_chorus.five_hearts`, `deep_chorus.lower_sealed`, `hero.lost_tending_song`, `vey.told_truth`, `meridian.refuges_known`.
- **Opens:** the stalled Dragon above the canyon.

### Stage 6. The eldest brother (chapter 6)

- **Place:** the Dragon's gallery; the workings under its floor (**dungeon**); the Slick.
- **Party:** Wrack, Okonta, Sefa.
- **Steps**
  1. **D** Forty-one Threaded: hear the news of the world from them, topic by topic. Corin and Kelder.
  2. **D** Rook arrives in his own cradle and names himself. His offer to the Threaded; his words to Wrack. Fourteen leave.
  3. **B** The night attack: three Threaded in the gallery. The hero's asking is too slow; the battle is lost by design, and he is netted.
  4. **B** Towed into the Slick: nothing can be asked. Okonta's rescue is played as her: draw the eels onto the pursuers.
  5. **P** Okonta's drill: learn to carry a held skin of water. A trial repeated over days until the prow slides off.
  6. **P** **Dungeon: the Dragon's heart.** Three worn wheels. The puzzle is to stop mending and rebuild it to run on two.
- **Clear when:** the Dragon sings again.
- **Sets:** `rook.named`, `dragon.runs_on_two`, `corin.with_rook`, `threaded.nineteen`, `hero.held_skin`, `sefa.joined`.
- **Opens:** Dragon travel again, slower. Sefa joins the party. The spare wheel hangs in the gallery and can be examined.

### Stage 7. The door (chapter 7)

- **Place:** the ride south (seen from the gallery wall: the grey snow under the Girdle, the Bright Shelves); Ember House; the Wheel; the Hush (**dungeon**, without light or speech).
- **Party:** Wrack alone from the black sand onward.
- **Steps**
  1. **D** Ember House: the cairn and the apron.
  2. **S** The Wheel: the rays show the sea as it was and as it is. No controls but looking. It ends on a question that is answered by choosing among what he has seen.
  3. **D** **Dungeon: the Hush.** Find Maelis by touch: the map draws itself only where a hand has been on the wall. Nobody speaks.
  4. **D** Maelis's question. The answer is chosen from what the hero has actually done so far; an answer he has not earned is not offered.
  5. **Cut scene:** his memory, played with the game's own figures: the Sluice, the tray, the dinners, the charts, Site Nine, the rail.
  6. **D** Maelis's two stories: Anselm at fourteen, and Jef at Sounding. The topic *Sounding* is answered at last.
  7. **D** Tell Sefa and Okonta. Sefa leaves for three hours and comes back.
- **Clear when:** Sefa says she is coming to see him pay.
- **Sets:** `hero.named_ilan`, `hero.memory`, `rook.is_patron`, `rays.allied`, `routes.known`, `sounding.told`.
- **Opens:** the islander's manner as a skill; Halcyon codes as a key thing; the Girdle. From here he is Ilan to the game, and Wrack to those who choose.

### Stage 8. Saltgate (chapter 8)

- **Place:** Dace's boat and the Eyes; Saltgate (locks, canals, the Wet Market, the Sluice); the Brightwater tower (**dungeon**, no sea in it).
- **Party:** Ilan, Sefa, Dace. Okonta waits under the keel; Yeva is a guest after the rescue.
- **Steps**
  1. **D** Crossing by the Eyes: Dace reads the gale skates. Sefa's question in the calm.
  2. **D** Saltgate: the Lockkeepers, the neon, the Wet Market. Scrip and island shops for the first time. Sefa must stay wet: a party with a mariner in it cannot leave the canals for long.
  3. **D** The Sluice: his mother's window.
  4. **D** Pell and the Clean Hands: find which floor.
  5. **P** **Dungeon: the tower.** Get to the twenty-second floor on his old authority, by the island manner and his codes. Bring Yeva out when the alarm goes, with only the water in the sprinkler pipes.
  6. **P** Yeva's lesson: learn to intend. The trial fails while he wants anything for himself.
  7. **F** The clinic at the Wet Market: nine days of patients, each a small trial of Mend, Purge or Ease. Garran and Pim.
  8. **D** Dr Marsh on the sixth night.
- **Clear when:** Garran asks who he is, and he gives his name.
- **Sets:** `yeva.free`, `hero.intends`, `brightwater.falling`, `marsh.asked_leave`, `garran.met`, `hero.named_in_public`.
- **Opens:** skills Mend, Purge, Ease. Boat travel between Girdle ports.

### Stage 9. The engineers (chapter 9)

- **Place:** Keelhaven (coal wharf, design loft, net loft, ferry stage); Slip Nine (**dungeon**: the unfinished hull, optional here, needed for a side quest); the storms; Lashing.
- **Party:** Ilan, Okonta, Dace. Sefa stays in the tub aboard.
- **Steps**
  1. **D** See Slip Nine from the wharf. Okonta's advice to sink it can be heard and refused.
  2. **P** Raske's office: mend her warm-stone on her desk.
  3. **P** The net loft: talk Hanne through opening her own lamp without touching it. The player gives the instructions; she does the work.
  4. **F** The ferry stage: get three hundred and eleven people and their families onto eleven tugs before the trucks arrive.
  5. **S** The storm: asking a storm gives twenty times too much. Ask for one small road.
  6. **D** Lashing and its law.
  7. **P** The first class: teach the seam. The trial is to explain, not to do.
  8. **D** The purple paper. The Moot is called.
- **Clear when:** forty lamps burn on the barge rail.
- **Sets:** `kessler.emptied`, `engineers.311`, `raske.joined`, `hanne.opened_lamp`, `paper.out`, `moot.called`.
- **Opens:** Lashing as a second base. Raske and Hanne can join on the surface.

### Stage 10. The table (chapter 10)

- **Place:** the afterdeck of the frigate at Lashing.
- **Party:** Ilan alone at the table. Sefa under the grating.
- **Steps**
  1. **D** Dinner with Rook. Every question may be asked. He answers all of them truthfully.
  2. **P** The bowl: fetch the sea, watch the governor, then try to ask the water for anything. Nothing answers.
  3. **D** The offer. There is no choice to accept. The hero is shown wanting to, and the player gives his refusal by choosing what he says no with, from what he has learned.
- **Clear when:** Rook's launch leaves the Eye.
- **Sets:** `hero.knows_ordering`, `marsh.dead`, `rook.wants_dragon`, `engine.is_ring_known_wrong` (Rook's account, which is mistaken).
- **Opens:** the topic *the heart*.

### Stage 11. Deaf water (chapter 11)

- **Place:** the valley in the kelp south of Fallow.
- **Party:** Ilan, Okonta, Sefa.
- **Steps**
  1. **D** The young Threaded from Fallow brings word. Choose to go.
  2. **B** The patrol. Spoil is laid; the gift comes faint. One net can be torn and eleven people freed. Purge fails while he wants the ships dead. The battle cannot be won by asking.
  3. **S** The order. When asking has failed for the set number of turns, every form on the hero's sheet goes dark but one, which has no name. The player must give it. It is not a choice, and the game does not dress it as one.
  4. **F** Bring the living out of the wrecks with the people of Fallow.
  5. **D** Sefa's hands. Corin's message. Hesper at dusk. The dead, one by one.
- **Clear when:** the column goes over the ridge.
- **Sets:** `fallow_road.deaf`, `hero.ordered`, `dead.161`, `sefa.no_gift`, `hesper.learned_ordering`, `hero.promised`.
- **Opens:** nothing. Fallow stands empty, and the road to it is deaf.

### Stage 12. The Great Moot (chapter 12)

- **Place:** the tug; Nine Spires and its aprons; Tidehall.
- **Party:** Ilan. The forty engineers and Sefa as guests.
- **Steps**
  1. **D** Nine Spires: lodged apart. What others say can be heard from the window and through Sefa.
  2. **D** The Moot: answer both charges. The answers offered are only true ones.
  3. **D** Who speaks: Vey, Brask, Ione, Sefa. Which of them speak, and how warmly, depends on the trust tracks and on side quests done.
  4. **S** The shared calling: do nothing, and be a way through. Reaching for the strength ends it.
- **Clear when:** the coral rings.
- **Sets:** `hero.bound_to_mending`, `hero.forbidden_order`, `hero.shared_calling`, `engineers.guests`, `hesper.gone_to_crown`.
- **Opens:** every hold as a place where engineers may be sent (side quests).

### Stage 13. The signal (chapter 13)

- **Place:** Old Tolla; Concord; the Orrin Spire (**dungeon**: studio floors up to the backup transmitter).
- **Party:** Ilan, Raske, Dace. Marit as a guest. Sefa waits aboard Dace's boat at the Concord seawall.
- **Steps**
  1. **D** The shrine at Old Tolla.
  2. **D** Marit's plan, and Venn's card.
  3. **F** Bring the eleven charts and the photograph into the Spire in Raske's document case, through the front door on Venn's card.
  4. **P** **Dungeon: the Spire.** While Ilan is in the chair, the player is Marit's three: bring up the backup transmitter on the hundred and ninetieth floor before the censor finishes cutting.
  5. **D** The confession: what is said is chosen from what has been done, and must include Fallow.
- **Clear when:** the captain stands aside.
- **Sets:** `orrin.fallen`, `islands.know`, `rook.named_in_public`, `wave.rising`, `fleet.sailed`.

### Stage 14. The wave (chapter 14)

- **Place:** the Girdle from the Dragon's brow; the harbour mouth of Port Halcyon.
- **Party:** Ilan, Okonta, Sefa.
- **Steps**
  1. **P** Call the Dragon off its course and drive it.
  2. **D** Corin at the wave: Okonta shows him the tin roofs.
  3. **S** The wave: take twelve wills, one at a time, in the right order, without holding any.
  4. **P** The harbour: Purge deaf water. It works only when he wants nothing.
  5. **S** The lance and the fleet: a shield, three small things moved at a distance, forty ships set down.
- **Clear when:** the last ship is in its berth.
- **Sets:** `halcyon.fallen`, `harbour.clean`, `lance.dead`, `hesper.spent`, `hero.ebbed_month`.

### Stage 15. The heart (chapter 15)

- **Place:** the harbour mouth; the refinery school on the Waterline.
- **Party:** Ilan, Sefa. Yeva, Garran and Crane as guests.
- **Steps**
  1. **S** Hold the Dragon against Rook. It cannot be held.
  2. **D** Three days later: learn, one visitor at a time, what has happened: the wall, the dead water, the deeds, the queues.
  3. **D** Garran's question. There is no answer to choose.
  4. **D** Crane's report: the ring and the lance.
  5. **P** The drawings on the schoolroom wall: put together what the city was built for from topics already held.
- **Clear when:** he says the city was built to come up.
- **Sets:** `dragon.stolen`, `rook.runs_ring`, `wall.standing`, `crane.surrendered`, `hero.knows_city_rises`.
- **Opens:** nothing by the Dragon. Travel is by needle and boat until stage 17 ends.

### Stage 16. The long way round (chapter 16)

Four askings, done in any order, then the gathering. The hero cannot call; he can ride, talk and carry.

- **The tanks, Port Halcyon** (**dungeon**: the tank-sheds). **D** Find the speaker of Kelder among eleven thousand. **F** Carry word between the troughs while Kelder holds its Moot. Corin says the rule again.
- **Saltgate.** **D** Climb to the senior Lockkeeper. **P** Ask for the one thing she can give without taking a side.
- **Deep Chorus.** **D** Speak in the high hall with nothing to offer.
- **The other holds and ports** the party has helped: each side quest finished earlier adds boats or callers here.
- **Lashing, at the edge of the dead water.** **D** Maelis and Sefa: the bottle. **D** What the rays want. **D** Hesper.
- **Clear when:** all three askings are done and Sefa's gift is returned.
- **Sets:** `kelder.out_of_tanks`, `corin.returned`, `lockkeepers.horns`, `deep_chorus.yes`, `sefa.gift_returned`, `hesper.returned`, `gathering.count` (a number, from the askings and side quests).

### Stage 17. Site Nine (chapter 17)

- **Place:** the road through the dead water; the wall; the pit; the drowned city (walked); the vault behind three doors (**dungeon**).
- **Party:** Ilan, and any three of those who came. Maelis, Raske, Hanne and Crane as guests.
- **Steps**
  1. **S** The road: the healers restore a road of living water. The player places barges and rowers to carry them forward.
  2. **B** Rook's Threaded: Corin calls them by name. Each name known from earlier topics turns one without a blow.
  3. **D** The gunboat: Garran with the trumpet.
  4. **D** Over the wall; the city; the lamps lighting ahead.
  5. **D** **Dungeon: the vault.** Three doors, already open. Rook at the bench.
  6. **D** The talk at the ring: offer the tool. He will not take it. The wall behind him answers.
  7. **P** Seat the engine: eleven hours, in stages, with Hanne on the lamp, Raske calling sections and Crane fetching.
  8. **S** The square at dawn: be the way through. The count from stage 16 decides how much each ring must give, not whether it succeeds.
- **Clear when:** half the city stands dry.
- **Sets:** `engine.seated`, `rook.gone`, `city.risen`, `walls.lit`, `peoples.met`.

### Stage 18. Meet (chapter 18)

- **Place:** Meet; the Dragon; Low Anthem; the sealed workshop under the eastern quarter (**dungeon**).
- **Party:** free choice.
- **Steps**
  1. **P** Seat the two wheels in the Dragon again.
  2. **P** Low Anthem: close the crack in the dome with ten engineers and ten mariners; light the ten dead lamps with Jef's tool.
  3. **D** Hesper teaches the tending song again.
  4. **D** **Dungeon: the workshop.** Find the walls that still read.
  5. **P** Finish the housing of the first air-heart.
- **Clear when:** Maelis asks her question again.
- **Sets:** `dragon.whole`, `low_anthem.mended`, `hero.makes`, `game.complete`.
- **Opens:** everything. The world stays open after the end: ten domes, a hundred dark holds, the Slick.

---

## Part two: side quests

Rules: optional; never needed for the main quest; open only in the chapters given; close when their place is lost. Each gives points (one to three a step, as every quest does) and one of: standing with a people, a companion's scene, a topic, something to read, boats or callers at the gathering in stage 16. None lets a skill pass the step the chapter allows.

### Places

| # | Name | Kind | Place | Open | What it is |
|---|---|---|---|---|---|
| S1 | The slipped herd | F | Low Anthem | 1 to 2 | Silverbacks have gone into the wild kelp. Bring them back with Bother. |
| S2 | Names on the stems | D | Low Anthem | 1 to 2, and 18 | Read the oldest names, which have climbed out of reach. An old woman of the night crew wants one found. |
| S3 | Something out of the Slick | B, D | Low Anthem | 1 to 2 | A fouled thing is in the terraces at night. Find what it is, and drive it off or purge it. (From the bible's adventure seeds.) |
| S4 | The broken lamp | P | Low Anthem | 4 to 18 | The lamp that needed a tool. Come back with Jef's tool. |
| S5 | Sounding | D | The Tangle (**dungeon**: the broken dome) | 3 to 18 | Walk the ruin. What is found there gives a second answer to Maelis's stories in stage 7. |
| S6 | The Breakers' lights | D | The Tangle | 3 to 10 | Find Hesper's camp. She will not speak; others will. |
| S7 | Sabel's patrol | D | The edge of the Slick | 3 to 18 | Okonta's old partner went into the Slick. Find what is left of her needle. Okonta's own quest. |
| S8 | The four dark halls | D | The Lantern (**dungeon**) | 4 only | Before they relight: what was left in the halls that went dark centuries ago. |
| S9 | Nobody starves on his doorstep | F | Rime | 4 to 18 | Carry the season's cod to the Lantern with Brask's cousins, under the ice. |
| S10 | The lowest tiers | D | Deep Chorus (**dungeon**: the sealed galleries) | 6 to 18 | Go back into the forty tiers that were sealed. Things were left behind. |
| S11 | A dark hold | D | Kelder (**dungeon**: an empty hold) | 6 to 15 | Kelder after its people went up in nets. Find the speaker's copy of the paper. Feeds stage 16. |
| S12 | The square name | D | The Dragon | 3 to 6 | Ask about the scratched-out name beside the empty cradle. Three old Threaded each know a piece. |
| S13 | A fortune for an hour | P | Saltgate | 8 to 13 | A Kessler-Vane engineer wants one hour with a needle. Okonta's answer, and what he does with it. (From the bible's adventure seeds.) |
| S14 | Broth, no noodles | D | The Sluice, Saltgate | 8, and 16 to 18 | The noodle-seller remembers a woman who came for broth. |
| S15 | The tank with the lid off | D | The Brightwater tower | 8 to 9, and 18 | Sefa wants to see it empty. |
| S16 | Missing tonnage | D | Saltgate, Concord | 8 to 13 | Follow a Clean Hands manifest to a barge that has not sailed yet, and stop it without sinking it. |
| S17 | The tanker | P, D | A kelp farm on the Shoulder | 8 to 13 | A Brightwater tanker has sunk with its crew alive inside and its cargo leaking. The hold is arguing. (From the bible's adventure seeds.) |
| S18 | Slip Nine | D | Keelhaven (**dungeon**: the unfinished hull) | 9 to 13 | Go aboard and find what the well amidships is braced for. |
| S19 | Hold your breath | F | Lashing | 9 to 12 | Two apprentices want to see a hold. Get them hard suits, and somewhere that will have them. |
| S20 | The first fish | D | Old Tolla | 13 to 18 | Who carved the neighbour in the shrine, and when. |
| S21 | The refinery school | F | Port Halcyon | 15 to 18 | The children's drawings. One child's father is in the tank-sheds. |
| S22 | Eleven routes | P | Ten holds on the routes | 12 to 18, and after the end | Mend one dome on each of the routes he drew. Each is a short place with its own people. The Moot's sentence, as play. |
| S23 | Under the Exchange | D | Concord (**dungeon**: the flooded dock) | 18 | The dock only the chairman used, and an empty cradle. |

### Companions

| # | Companion | Open | What it is |
|---|---|---|---|
| C1 | Sefa | 8 to 18 | To become a Wellwalker: three patients in three places who cannot be reached by anyone else. |
| C2 | Okonta | 3 to 18 | Sabel's patrol (S7), then who keeps the Anthem Waters when she cannot. |
| C3 | Hesper | 18 | The valley by Fallow: sit with the Hush's healers for a day. |
| C4 | Dace | 8 to 18 | Her aunt's soup barge is owed a debt nobody will name. |
| C5 | Raske | 9 to 18 | Her father's lungs, and the riveters' sheds she came from. |
| C6 | Hanne | 9 to 18 | Tell her husband what the drainpipe behind the stove was. |
| C7 | Corin | 16 to 18 | Find where each of Rook's Threaded had family put. |
| C8 | Crane | 15 to 18 | The memorial service he read at. He wants to give the reading back. |

---

## Dungeons at a glance

| Dungeon | Stage or quest | Needed for the main quest |
|---|---|---|
| The flooded third of Low Anthem | 2 | Yes |
| A Charter War wreck in the Tangle | 3 | Yes |
| The crawlways under the Lantern | 4 | Yes |
| Deep Chorus: service ways and heart vaults | 5 | Yes |
| The Dragon's heart | 6 | Yes |
| The Hush | 7 | Yes |
| The Brightwater tower | 8 | Yes |
| The Orrin Spire | 13 | Yes |
| The tank-sheds | 16 | Yes |
| The vault under Site Nine | 17 | Yes |
| The sealed workshop | 18 | Yes |
| Sounding | S5 | No |
| The four dark halls | S8 | No |
| Deep Chorus: the sealed galleries | S10 | No |
| Kelder | S11 | No |
| Slip Nine | S18 | No |
| Under the Exchange | S23 | No |

If the scope must shrink, cut from the bottom of this table upward, and never above the line between "No" and "Yes".

---

## What needs a canon proposal before it can be built

- What stands for money among mariners (see `PLAN.md`, "Things, money and shops").
- Names for unnamed people who now have lines: the speaker of Kelder, the officer of the recovery team, the old woman of the night crew, the two apprentices, Dace's aunt.
- The layout of each dungeon. Canon gives what each place is; it does not give floor plans. A floor plan is not a world fact, but any object, inscription or person placed in one is.
- The ten other holds on the eleven routes (S22): canon names only Low Anthem.
- What is found in Sounding (S5), the four dark halls (S8) and under the Exchange (S23).
