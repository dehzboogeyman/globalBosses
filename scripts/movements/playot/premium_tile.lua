local checkPremium = MoveEvent()
function checkPremium.onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then
        return true
    end
    -- Check requirements
    if not player:isVip() then
        player:say("Only VIP players are able to enter this portal.", TALKTYPE_MONSTER_SAY, false, player, fromPosition)
        player:teleportTo(fromPosition)
        fromPosition:sendMagicEffect(CONST_ME_TELEPORT)
        return true
    end
    return true
end
checkPremium:position({x = 32606, y = 32434, z = 7}) -- essa será a posição que você vai colocar uma uniqueId no RME.
checkPremium:register()