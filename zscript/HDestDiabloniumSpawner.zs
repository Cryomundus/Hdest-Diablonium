// Struct for itemspawn information.
class HDDiabloniumSpawnItem play {
	// ID by string for spawner
	string spawnName;
	
	// ID by string for spawnees
	Array<HDDiabloniumSpawnItemEntry> spawnReplaces;
	
	// Whether or not to persistently spawn.
	bool isPersistent;
	
	// Whether or not to replace the original item.
	bool replaceItem;

	string toString() {

		let replacements = "[";

		foreach (spawnReplace : spawnReplaces) replacements = replacements..", "..spawnReplace.toString();

		replacements = replacements.."]";

		return String.format("{ spawnName=%s, spawnReplaces=%s, isPersistent=%b, replaceItem=%b }", spawnName, replacements, isPersistent, replaceItem);
	}
}

class HDDiabloniumSpawnItemEntry play {
	string name;
	int    chance;

	string toString() {
		return String.format("{ name=%s, chance=%s }", name, chance >= 0 ? "1/"..(chance + 1) : "never");
	}
}

// Struct for passing useinformation to ammunition.
class HDDiabloniumSpawnAmmo play {
	// ID by string for the header ammo.
	string ammoName;
	
	// ID by string for weapons using that ammo.
	Array<string> weaponNames;
	
	string toString() {

		let weapons = "[";

		foreach (weaponName : weaponNames) weapons = weapons..", "..weaponName;

		weapons = weapons.."]";

		return String.format("{ ammoName=%s, weaponNames=%s }", ammoName, weapons);
	}
}



// One handler to rule them all.
class HDDiabloniumEnemyHandler : EventHandler {

	// List of persistent classes to completely ignore.
	// This -should- mean this mod has no performance impact.
	static const string blacklist[] = {
        'HDSmoke',
        'BloodTrail',
        'CheckPuff',
        'WallChunk',
        'HDBulletPuff',
        'HDFireballTail',
        'ReverseImpBallTail',
        'HDSmokeChunk',
        'ShieldSpark',
        'HDFlameRed',
        'HDMasterBlood',
        'PlantBit',
        'HDBulletActor',
        'HDLadderSection'
	};

	// List of CVARs for Backpack Spawns
	array<Class <Inventory> > backpackBlacklist;

    // Cache of Ammo Box Loot Table
    private HDAmBoxList ammoBoxList;

	// List of weapon-ammo associations.
	// Used for ammo-use association on ammo spawn (happens very often).
	array<HDDiabloniumSpawnAmmo> ammoSpawnList;

	// List of item-spawn associations.
	// used for item-replacement on mapload.
	array<HDDiabloniumSpawnItem> itemSpawnList;

	bool cvarsAvailable;

	// appends an entry to itemSpawnList;
	void addItem(string name, Array<HDDiabloniumSpawnItemEntry> replacees, bool persists, bool rep=true) {

		if (hd_debug) {

            let msg = "Adding "..(persists ? "Persistent" : "Non-Persistent").." Replacement Entry for "..name..": [";

            foreach (replacee : replacees) msg = msg..", "..replacee.toString();

			console.printf(msg.."]");
		}

		// Creates a new struct;
		HDDiabloniumSpawnItem spawnee = HDDiabloniumSpawnItem(new('HDDiabloniumSpawnItem'));

		// Populates the struct with relevant information,
		spawnee.spawnName = name;
		spawnee.isPersistent = persists;
		spawnee.replaceItem = rep;
        spawnee.spawnReplaces.copy(replacees);

		// Pushes the finished struct to the array.
		itemSpawnList.push(spawnee);
	}

	HDDiabloniumSpawnItemEntry addItemEntry(string name, int chance) {
		// Creates a new struct;
		HDDiabloniumSpawnItemEntry spawnee = HDDiabloniumSpawnItemEntry(new('HDDiabloniumSpawnItemEntry'));
		spawnee.name = name;
		spawnee.chance = chance;
		return spawnee;
	}

	// appends an entry to ammoSpawnList;
	void addAmmo(string name, Array<string> weapons) {

        if (hd_debug) {
            let msg = "Adding Ammo Association Entry for "..name..": [";

            foreach (weapon : weapons) msg = msg..", "..weapon;

            console.printf(msg.."]");
        }

		// Creates a new struct;
		HDDiabloniumSpawnAmmo spawnee = HDDiabloniumSpawnAmmo(new('HDDiabloniumSpawnAmmo'));
		spawnee.ammoName = name;
        spawnee.weaponNames.copy(weapons);

		// Pushes the finished struct to the array.
		ammoSpawnList.push(spawnee);
	}


	// Populates the replacement and association arrays.
	void init() {
		
		cvarsAvailable = true;

		//------------
		// Enemies
		//------------

		// Baby Deviler
		Array<HDDiabloniumSpawnItemEntry> spawns_babydeviler;
		spawns_babydeviler.push(addItemEntry('SpecBabuin', babydeviler_spectre_spawn_bias));
		spawns_babydeviler.push(addItemEntry('Babuin', babydeviler_babuin_spawn_bias));
		addItem('BabyDeviler', spawns_babydeviler, babydeviler_persistent_spawning);

		// Teen Deviler
		Array<HDDiabloniumSpawnItemEntry> spawns_teendeviler;
		spawns_teendeviler.push(addItemEntry('DoomImp', teendeviler_imp_spawn_bias));
		addItem('TeenDeviler', spawns_teendeviler, teendeviler_persistent_spawning);

		// Adult Deviler
		Array<HDDiabloniumSpawnItemEntry> spawns_adultdeviler;
		spawns_adultdeviler.push(addItemEntry('Knave', adultdeviler_hellknight_spawn_bias));
		addItem('AdultDeviler', spawns_adultdeviler, adultdeviler_persistent_spawning);

		// Wretched Ghoul
		Array<HDDiabloniumSpawnItemEntry> spawns_wretchedghoul;
		spawns_wretchedghoul.push(addItemEntry('FlyingSkull', wretchedghoul_lostsoul_spawn_bias));
		spawns_wretchedghoul.push(addItemEntry('SpecBabuin', wretchedghoul_spectre_spawn_bias));
		spawns_wretchedghoul.push(addItemEntry('Babuin', wretchedghoul_babuin_spawn_bias));
		addItem('WretchedGhoul', spawns_wretchedghoul, wretchedghoul_persistent_spawning);
	}

	// Random stuff, stores it and forces negative values just to be 0.
	bool giveRandom(int chance) {
		if (chance > -1) {
			let result = random(0, chance);

			if (hd_debug) console.printf("Rolled a "..(result + 1).." out of "..(chance + 1));

			return result == 0;
		}

		return false;
	}

	// Tries to create the item via random spawning.
	bool tryCreateItem(Actor thing, string spawnName, int chance, bool rep) {
		if (giveRandom(chance)) {
            if (Actor.Spawn(spawnName, thing.pos) && rep) {
                if (hd_debug) console.printf(thing.getClassName().." -> "..spawnName);

                thing.destroy();

				return true;
			}
		}

		return false;
	}

	override void worldLoaded(WorldEvent e) {

		// Populates the main arrays if they haven't been already. 
		if (!cvarsAvailable) init();

        foreach (bl : backpackBlacklist) {
			if (hd_debug) console.printf("Removing "..bl.getClassName().." from Backpack Spawn Pool");
                
			BPSpawnPool.removeItem(bl);
        }
	}

	override void worldThingSpawned(WorldEvent e) {

		// If thing spawned doesn't exist, quit
		if (!e.thing) return;

		// If thing spawned is blacklisted, quit
		foreach (bl : blacklist) if (e.thing is bl) return;

		string candidateName = e.thing.getClassName();

		// Pointers for specific classes.
		let ammo = HDAmmo(e.thing);

		// If the thing spawned is an ammunition, add any and all items that can use this.
		if (ammo) handleAmmoUses(ammo, candidateName);

		// Return if range before replacing things.
        if (level.MapName == 'RANGE') return;

        if (e.thing is 'HDAmBox') {
            handleAmmoBoxLootTable();
        } else {
        handleWeaponReplacements(e.thing, ammo, candidateName);
	}
    }

    private void handleAmmoBoxLootTable() {
        if (!ammoBoxList) {
            ammoBoxList = HDAmBoxList.Get();

            foreach (bl : backpackBlacklist) {
                let index = ammoBoxList.invClasses.find(bl.getClassName());

                if (index != ammoBoxList.invClasses.Size()) {
                    if (hd_debug) console.printf("Removing "..bl.getClassName().." from Ammo Box Loot Table");

                    ammoBoxList.invClasses.Delete(index);
                }
            }
        }
    }

	private void handleAmmoUses(HDAmmo ammo, string candidateName) {
        foreach (ammoSpawn : ammoSpawnList) if (candidateName ~== ammoSpawn.ammoName) {
            if (hd_debug) {
                console.printf("Adding the following to the list of items that use "..ammo.getClassName().."");
                foreach (weapon : ammoSpawn.weaponNames) console.printf("* "..weapon);
            }

            ammo.itemsThatUseThis.append(ammoSpawn.weaponNames);
        }
	}

    private void handleWeaponReplacements(Actor thing, HDAmmo ammo, string candidateName) {

		// Checks if the level has been loaded more than 1 tic.
		bool prespawn = !(level.maptime > 1);

		// Iterates through the list of item candidates for e.thing.
		foreach (itemSpawn : itemSpawnList) {

			// if an item is owned or is an ammo (doesn't retain owner ptr),
			// do not replace it.
            let item = Inventory(thing);
            if ((prespawn || itemSpawn.isPersistent) && (!(item && item.owner) && (!ammo || prespawn))) {
				foreach (spawnReplace : itemSpawn.spawnReplaces) {
                    if (spawnReplace.name ~== candidateName) {
						if (hd_debug) console.printf("Attempting to replace "..candidateName.." with "..itemSpawn.spawnName.."...");

                        if (tryCreateItem(thing, itemSpawn.spawnName, spawnReplace.chance, itemSpawn.replaceItem)) return;
					}
				}
			}
		}
	}
}
