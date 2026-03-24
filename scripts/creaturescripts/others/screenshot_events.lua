local SCREENSHOT_TYPE_ACHIEVEMENT = 1
local SCREENSHOT_TYPE_BESTIARY_ENTRY_COMPLETED = 2
local SCREENSHOT_TYPE_BESTIARY_ENTRY_UNLOCKED = 3
local SCREENSHOT_TYPE_BOSS_DEFEATED = 4
local SCREENSHOT_TYPE_DEATH_PVE = 5
local SCREENSHOT_TYPE_DEATH_PVP = 6
local SCREENSHOT_TYPE_PLAYER_KILL_ASSIST = 8
local SCREENSHOT_TYPE_PLAYER_KILL = 9
local SCREENSHOT_TYPE_TREASURE_FOUND = 11
local SCREENSHOT_TYPE_GIFT_OF_LIFE = 13

-- Death events (PvE / PvP)
local deathScreenshot = CreatureEvent("DeathScreenshot")
function deathScreenshot.onDeath(player, corpse, killer, mostDamageKiller, unjustified, mostDamageUnjustified)
	if not player or not player:isPlayer() then
		return true
	end

	if killer and killer:isPlayer() then
		player:sendTakeScreenshot(SCREENSHOT_TYPE_DEATH_PVP)
		killer:sendTakeScreenshot(SCREENSHOT_TYPE_PLAYER_KILL)
	else
		player:sendTakeScreenshot(SCREENSHOT_TYPE_DEATH_PVE)
	end

	return true
end

deathScreenshot:register()

-- Register on login
local deathScreenshotLogin = CreatureEvent("DeathScreenshotLogin")
function deathScreenshotLogin.onLogin(player)
	player:registerEvent("DeathScreenshot")
	return true
end

deathScreenshotLogin:register()
