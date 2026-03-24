local forgeAction = Action()

function forgeAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if item:getId() == 51963 then -- Substitua pelo ID do item que você deseja que abra a forja
        player:sendTextMessage(MESSAGE_LOOK, "Abrindo a Forja...")
        player:openForge()
    else
        player:sendTextMessage(MESSAGE_LOOK, "Este item nao abre a forja.")
    end
    return true
end

forgeAction:id(51963) -- Substitua pelo ID do item correspondente
forgeAction:register()