local outfitChestId = 61702

-- {female, male, name}
local category1 = {
	{ 136, 128, "Citizen" },
	{ 137, 129, "Hunter" },
	{ 139, 131, "Knight" },
	{ 1825, 1824, "Monk" },
	{ 147, 143, "Barbarian" },
	{ 148, 144, "Druid" },
	{ 140, 132, "Nobleman" },
	{ 150, 146, "Oriental" },
	{ 149, 145, "Wizard" },
	{ 431, 430, "Afflicted" },
	{ 1598, 1597, "Ancient Aucar" },
	{ 157, 153, "Beggar" },
	{ 279, 278, "Brotherhood of Bones" },
	{ 1387, 1386, "Citizen of Issavi" },
	{ 578, 577, "Dream Warden" },
	{ 1147, 1146, "Dream Warrior" },
	{ 929, 931, "Festive" },
	{ 1808, 1809, "Fiend Slayer" },
	{ 1461, 1460, "Formal Dress" },
	{ 270, 273, "Jester" },
	{ 1043, 1042, "Makeshift Warrior" },
	{ 252, 251, "Norseman" },
	{ 155, 151, "Pirate" },
	{ 1271, 1270, "Poltergeist" },
	{ 1372, 1371, "Rascoohan" },
	{ 1323, 1322, "Revenant" },
	{ 845, 846, "Rift Warrior" },
	{ 158, 154, "Shaman" },
	{ 336, 335, "Warmaster" },
	{ 366, 367, "Wayfarer" },
	{ 324, 325, "Yalaharian" },
}

local category2 = {
	{ 142, 134, "Warrior" },
	{ 156, 152, "Assassin" },
	{ 1070, 1069, "Battle Mage" },
	{ 575, 574, "Cave Explorer" },
	{ 513, 512, "Crystal Warlord" },
	{ 1663, 1662, "Decaying Defender" },
	{ 464, 463, "Deepling" },
	{ 288, 289, "Demon Hunter" },
	{ 542, 541, "Demon" },
	{ 1723, 1722, "Draccoon Herald" },
	{ 433, 432, "Elementalist" },
	{ 618, 610, "Glooth Engineer" },
	{ 1244, 1243, "Hand of the Inquisition" },
	{ 1861, 1860, "Illuminator" },
	{ 466, 465, "Insectoid" },
	{ 1252, 1251, "Orcsoberfest Garb" },
	{ 1162, 1161, "Percht Raider" },
	{ 1775, 1774, "Rootwalker" },
	{ 1437, 1436, "Royal Bounacean Advisor" },
	{ 514, 516, "Soil Guardian" },
}

local category3 = { 
	{ 138, 130, "Mage" },
	{ 141, 133, "Summoner" },
	{ 1095, 1094, "Discoverer" },
	{ 1289, 1288, "Dragon Slayer" },
	{ 1211, 1210, "Golden" },
	{ 1456, 1457, "Royal Costume" },
}

local categoryNames = {
	[1] = "Comun",
	[2] = "Raro",
	[3] = "Impossivel",
}

local categoryEffects = {
	[1] = CONST_ME_GIFT_WRAPS,
	[2] = CONST_ME_FIREWORK_BLUE,
	[3] = CONST_ME_FIREWORK_RED,
}

local randOutfit = Action("OutfitChest")

function randOutfit.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- Roll category: 1-79 = cat1, 80-99 = cat2, 100 = cat3
	local roll = math.random(1, 100)
	local categoryIndex
	local outfitList

	if roll <= 79 then
		categoryIndex = 1
		outfitList = category1
	elseif roll <= 99 then
		categoryIndex = 2
		outfitList = category2
	else
		categoryIndex = 3
		outfitList = category3
	end

	local outfit = outfitList[math.random(1, #outfitList)]
	local addon = math.random(1, 2)

	-- Check if player already has both (female+male) with this addon
	if player:hasOutfit(outfit[1], addon) and player:hasOutfit(outfit[2], addon) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You already have the " .. outfit[3] .. " outfit with addon " .. addon .. ". Try again!")
		return true
	end

	-- Grant the outfit addon (male + female)
	player:addOutfitAddon(outfit[1], addon)
	player:addOutfitAddon(outfit[2], addon)

	-- Effects
	player:getPosition():sendMagicEffect(categoryEffects[categoryIndex])

	-- Message
	local msg = string.format("[%s] You received the %s outfit with addon %d!", categoryNames[categoryIndex], outfit[3], addon)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, msg)

	item:remove(1)
	return true
end

randOutfit:id(outfitChestId)
randOutfit:register()