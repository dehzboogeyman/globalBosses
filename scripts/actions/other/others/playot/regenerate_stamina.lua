local smallstaminarefill = Action()

function smallstaminarefill.onUse(player, item, ...)
    local maxStamina = 2520 -- 42 horas em minutos
    local stamina = player:getStamina()

    if stamina >= maxStamina then
        player:sendCancelMessage("You already have full stamina.")
        return true
    end

    -- Recupera o máximo permitido sem exceder 42 horas
    local staminaToAdd = maxStamina - stamina
    player:setStamina(maxStamina)

    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
    player:sendCancelMessage("Your stamina has been fully regenerated.")
    item:remove(1) -- Remove o item usado
    return true
end

smallstaminarefill:id(44179)
smallstaminarefill:register()