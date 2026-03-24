local autobankItemAction = Action()

autobankItemAction.onUse = function(player, item, fromPosition, target, toPosition, isHotkey)
    if item:getId() == 51965 then  -- ID do item "Autobank Token"
        local totalMoney = player:getMoney() -- Obtém o dinheiro carregado pelo jogador

        if totalMoney > 0 then
            -- Remove o dinheiro da posse do jogador
            local removed = player:removeMoney(totalMoney)

            if removed then
                -- Atualiza manualmente o saldo bancário do jogador
                local currentBalance = player:getBankBalance() -- Obtém saldo atual
                player:setBankBalance(currentBalance + totalMoney) -- Define o novo saldo

                -- Mensagem de confirmação para o jogador
                player:sendTextMessage(MESSAGE_LOOK, "Autobank ativado! " .. totalMoney .. " moedas foram depositadas no seu banco.")
            else
                player:sendTextMessage(MESSAGE_LOOK, "Erro ao remover o dinheiro do inventario.")
            end
        else
            -- Caso o jogador não tenha dinheiro
            player:sendTextMessage(MESSAGE_LOOK, "Voce nao tem dinheiro suficiente para depositar.")
        end
    else
        -- Caso o item usado não seja o "Autobank Token"
        player:sendTextMessage(MESSAGE_LOOK, "Este item nao ativa o autobanking.")
    end
    return true
end

autobankItemAction:id(51965)  -- ID do item "Autobank Token"
autobankItemAction:register()
