local mType = Game.createMonsterType("The Pale Count2")
local monster = {}

monster.description = "The Pale Count"
monster.experience = 28000
monster.outfit = {
	lookType = 557,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.bosstiary = {
	bossRaceId = 972,
	bossRace = RARITY_NEMESIS,
}

monster.health = 65000
monster.maxHealth = 65000
monster.race = "blood"
monster.corpse = 18953
monster.speed = 280
monster.manaCost = 0

monster.changeTarget = {
	interval = 4000,
	chance = 10,
}

monster.strategiesTarget = {
	nearest = 70,
	health = 10,
	damage = 10,
	random = 10,
}

monster.flags = {
	summonable = false,
	attackable = true,
	hostile = true,
	convinceable = false,
	pushable = false,
	rewardBoss = true,
	illusionable = false,
	canPushItems = true,
	canPushCreatures = true,
	staticAttackChance = 90,
	targetDistance = 1,
	runHealth = 0,
	healthHidden = false,
	isBlockable = false,
	canWalkOnEnergy = true,
	canWalkOnFire = true,
	canWalkOnPoison = true,
}

monster.light = {
	level = 0,
	color = 0,
}

monster.summon = {
	maxSummons = 6,
	summons = {
		{ name = "Nightfiend", chance = 15, interval = 2000, count = 6 },
	},
}

monster.voices = {
	interval = 5000,
	chance = 10,
	{ text = "You followed me to your doom!", yell = false },
	{ text = "This is MY sanctuary!", yell = false },
	{ text = "Now you will NEVER leave!", yell = false },
	{ text = "Your blood will feed me for centuries!", yell = true },
}

monster.loot = {
	{ id = 8192, chance = 100000 },
	{ id = 18927, chance = 100000 },
	{ id = 18936, chance = 8000 },
	{ id = 18935, chance = 8000 },
	{ id = 11449, chance = 60000 },
	{ id = 9685, chance = 60000 },
	{ id = 19083, chance = 8000 },
	{ id = 3031, chance = 1000000, maxCount = 100 },
	{ id = 3035, chance = 100000, maxCount = 8 },
	{ id = 237, chance = 60000, maxCount = 5 },
	{ id = 236, chance = 60000, maxCount = 5 },
	{ id = 3049, chance = 15000 },
	{ id = 3098, chance = 15000 },
	{ id = 5909, chance = 12000 },
	{ id = 5911, chance = 12000 },
	{ id = 5912, chance = 12000 },
	{ id = 7427, chance = 8000 },
	{ id = 3326, chance = 12000 },
	{ id = 7419, chance = 8000 },
	{ id = 8075, chance = 8000 },
	{ id = 19373, chance = 8000 },
	{ id = 3434, chance = 8000 },
	{ id = 19374, chance = 8000 },
	{ id = 3028, chance = 60000, maxCount = 5 },
	{ id = 3027, chance = 60000, maxCount = 5 },
	{ id = 3029, chance = 60000, maxCount = 5 },
	{ id = 3032, chance = 60000, maxCount = 5 },
	{ id = 3036, chance = 15000 },
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, skill = 100, attack = 150 },
	{ name = "speed", interval = 1000, chance = 20, speedChange = -700, range = 7, radius = 4, effect = CONST_ME_MAGIC_RED, target = true, duration = 2000 },
	{ name = "combat", interval = 2000, chance = 25, type = COMBAT_ICEDAMAGE, minDamage = -200, maxDamage = -500, range = 6, radius = 3, shootEffect = CONST_ANI_SMALLICE, effect = CONST_ME_GIANTICE, target = true },
	{ name = "combat", interval = 2000, chance = 18, type = COMBAT_LIFEDRAIN, minDamage = -300, maxDamage = -600, range = 7, effect = CONST_ME_MAGIC_RED, target = true },
	{ name = "the pale count bomb", interval = 2000, chance = 15, minDamage = -200, maxDamage = -400, target = false },
	{ name = "combat", interval = 2000, chance = 18, type = COMBAT_MANADRAIN, minDamage = -100, maxDamage = -200, range = 7, shootEffect = CONST_ANI_EARTH, effect = CONST_ME_CARNIPHILA, target = false },
}

monster.defenses = {
	defense = 85,
	armor = 85,
	{ name = "combat", interval = 4000, chance = 25, type = COMBAT_HEALING, minDamage = 500, maxDamage = 1000, effect = CONST_ME_MAGIC_BLUE, target = false },
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 10 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 40 },
	{ type = COMBAT_EARTHDAMAGE, percent = 10 },
	{ type = COMBAT_FIREDAMAGE, percent = 25 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = 40 },
	{ type = COMBAT_HOLYDAMAGE, percent = -15 },
	{ type = COMBAT_DEATHDAMAGE, percent = 100 },
}

monster.immunities = {
	{ type = "paralyze", condition = true },
	{ type = "outfit", condition = false },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = false },
}

mType:register(monster)
