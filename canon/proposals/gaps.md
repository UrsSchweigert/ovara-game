# Gaps in canon

Things the sources do not say. Each needs the owner before it becomes a fact.

## world.physical

- **Mariners and cold.** The sources say mariners take no harm from the weight of the water (world-bible.md#5) and that the North Well's water is too cold and heavy for most (world-bible.md#11). They do not say whether mariners are adapted to cold. Left out of `world.physical`.
- **Year length.** The Tips see half a year of twilight, but the length of Ovara's year is not given.

## powers

- **Storm and rain.** world-bible.md#6 says the gift is "stronger but wild" in storm and rain but gives no reach figure. `power.storm-water` records no number.
- **Undertow before chapter 7.** The sources say what the undertow takes can be given back only by the rays, and in the campaign this first happens in chapter 7. They do not say whether the rays ever gave anything back before the campaign.

## people

- **Unnamed cast.** The campaign's supporting cast lists people with no name: the Threaded of the gallery (old woman with a clay tube, girl with a harpoon, two brothers from Pearl Stair, the young man from Fallow), the woman of Fallow and her father, the Meridian captain, the senior Lockkeeper and the Halcyon lieutenant. They have no `person.*` entry; naming them is canon.
- **Bother.** The cast table lists Sefa's tide hound among the supporting cast. It is entered as `person.bother` with `kind: animal`; **Resolved by the owner:** Bother stays `person.bother` (`kind: animal`).
- **Home places.** The sources do not say where Tam lives, so `person.tam` has no region. Regions of Ilan, Nerys and Tomas Voss (Saltgate), Rook (Meridian Exchange) and Maelis (the Quiet) are the places the sources tie them to, not stated homes.
- **Ages and looks.** Sefa, Okonta, Hesper, Ione and others have no stated looks or ages beyond those entered.

## chapters

- **Reading of `chapters/chNN.yaml`.** Per the canon README a file is the state when the chapter begins, with two exceptions the campaign forces: `corporations_fallen` lists a company from the chapter in which it falls (Brightwater 8, Kessler-Vane 9, Orrin 13, Halcyon 14, Meridian 18), to match the fall order and each faction's `changes`.
- **`alive` lists only people whose state changes** (Davin, Elder Oro, Jef, Marsh, Rook, Nerys and Tomas Voss). Everyone else in `canon/people/` is alive in every chapter unless a later entry says otherwise.
- **Linnea Marsh.** Rook reports her death in chapter 10 as past ("on Tuesday"); the sources do not say whether she was alive when the chapter began. Entered as dead from chapter 10.
- **Sefa's gift.** Lost at the end of chapter 11, returned in chapter 16. `without_gift: [person.sefa]` is set for chapters 12 to 15; whether she has it at the start of chapter 16 is not stated. Entered as returned.
- **Sefa in chapter 5.** The companion table says she travels with the hero from chapter 6, but chapter 5 needs her ("Sefa's moment"). She is listed from chapter 5 and absent in chapters 3 and 4.
- **Companions.** Hesper is listed only where she is with the hero (chapters 2, 16 to 18), not while she leads the Breakers. Okonta is not listed in chapters 8 and 9 on land, nor Dace after chapter 10; Marit Coyle in chapters 13 and 17. The sources do not say where else they appear.
- **Hero's craft.** There is no `power.*` entry for the craft, so `hero_craft` (`none`, `mend`) records it. The Make stage comes during chapter 18, so it is not yet in the file.
- **Chapter 15.** The hero is ebbed and cannot call (Yeva: a month); abilities are what he knows, not what he can do that day.
- **`known_to_*` and `dragon` values** are labels written for this file; the sources give the events, not the labels. Dragon: running, late (ch3), slow (ch4 to 5), stalled (ch6), heart-taken (ch16 on).
- **Restore and the hero.** In chapter 17 the healers of the Hush and six thousand healers Restore, while the hero sits shut out of the sea; the growth table gives him no Restore. `power.restore` is not in any chapter's `hero_abilities`. **Resolved by the owner:** the hero never learns Restore; the healers restore in chapter 17 while he is shut out. `hero_abilities` is unchanged.

## game needs

- **Prices and scrip.** No source gives the price of anything, a wage, or what scrip is worth against a mariner's goods. Shops, rewards and the Meridian service price (twenty years) need figures. Only the bible's "a bluewood table costs more than a house" is stated.
- **Travel on foot and by water for the player's party.** The bible gives swimmer, hold, needle, Dragon, ship and packet speeds (`world.distances`), but not the speed of a mariner party carrying a hero on land, nor how far an agravar walks a day.
- **Healing and ebb numbers.** How long a given use of the gift leaves a caller ebbed is given only as "hours for small work and days for great work", apart from three days (chapter 2) and a month (chapter 15). No figures for reach 1 to 3.
- **Shops and teachers.** The sources do not say who sells what or where; only Maelis, Okonta, Hesper, Yeva, Jef and Hanne are tied to what they teach.
- **Named holds and speakers.** Only Low Anthem, Fallow, Kelder, Deep Chorus, Rime, Nine Spires, Pearl Stair and Sounding are named. The holds of the Bright Shelves and the "four more holds dark" of chapter 6, and the three holds north that took the refuge, have no names.
- **Enemy kinds.** The fouled are given as slick eels and bloat crabs only. Refuge-ship crews, Halcyon and Meridian soldiers, wreckers and the grey needles have no stated kit or numbers.
- **Maker devices.** No source says what the hand tool does, how a seam is found, what a token looks like, or how the Dragon's token and the Meridian brass tag work in detail.
- **Sizes of places.** Floor areas, tier counts of Deep Chorus (a hundred tiers is implied by "sixtieth" and "forty below") and the layout of dungeons such as the Lantern, the Slick, the Tangle and the drowned city are not given.
- **Chapter 18 afterwards.** The sources do not say what the risen city is called.
