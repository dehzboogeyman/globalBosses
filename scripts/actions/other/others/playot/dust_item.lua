local exaltedDust = Action()

function exaltedDust.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local dustAmount = player:getForgeDustLevel() - player:getForgeDusts()

    if dustAmount <= 0 then
        player:sendTextMessage(MESSAGE_LOOK, "You cannot hold any more dusts.")
        return true
    end

    local itemCount = item:getCount()

    if itemCount > dustAmount then
        item:remove(dustAmount)
        player:addForgeDusts(dustAmount)
        player:sendTextMessage(MESSAGE_LOOK, string.format("You have added %d dusts, now you have %d dusts.", dustAmount, player:getForgeDusts()))
    else
        item:remove(itemCount)
        player:addForgeDusts(itemCount)
        player:sendTextMessage(MESSAGE_LOOK, string.format("You have added %d dusts, now you have %d dusts.", itemCount, player:getForgeDusts()))
    end
    
    return true
end

exaltedDust:id(37160)
exaltedDust:register()