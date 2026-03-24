local config = {
    minLevel = 8,
    firstPosition = Position(32953, 32398, 9),
    secondPosition = Position(34070, 31976, 14)
}

local treePass = Action();

function treePass.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if player:getLevel() >= config.minLevel then
        if player:getPosition().y == config.secondPosition.y then
            player:teleportTo(config.firstPosition)
            player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
        else
            player:teleportTo(config.secondPosition)
            player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
        end
		    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Welcome to Rotten Blood")
    else
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You need to be at least level " .. config.minLevel .. " to access this area.")
    end
    return true
end

treePass:aid(50996)
treePass:register()