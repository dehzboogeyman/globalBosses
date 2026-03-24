local preyCardAction = Action()

function preyCardAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if not player then
        return false
    end

    local itemCount = player:getItemCount(item:getId()) -- Conta a quantidade total do item no inventário
    if itemCount <= 0 then
        player:sendTextMessage(MESSAGE_LOOK, "Voce nao tem Prey Wildcards suficientes.")
        return true
    end

    -- Adiciona a quantidade total de Prey Cards
    if player:addPreyCards(itemCount) then
        player:sendTextMessage(MESSAGE_LOOK, "Voce ativou " .. itemCount .. " Prey Wildcard(s)!")
        player:removeItem(item:getId(), itemCount) -- Remove todo o montante do item usado
    else
        player:sendTextMessage(MESSAGE_LOOK, "Nao foi possivel adicionar os Prey Wildcards.")
    end

    return true
end

preyCardAction:id(51981) -- Substitua pelo ID do item
preyCardAction:register()
