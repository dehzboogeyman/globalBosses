-- Adicionar uma função para verificar se a guilda está em guerra
function isInWar(player, target)
    local playerGuild = player:getGuild()
    local targetGuild = target:getGuild()
    if not playerGuild or not targetGuild then
        return false
    end

    local resultId = db.storeQuery("SELECT `id` FROM `guild_wars` WHERE `status` = 1 AND ((`guild1` = " .. playerGuild:getId() .. " AND `guild2` = " .. targetGuild:getId() .. ") OR (`guild1` = " .. targetGuild:getId() .. " AND `guild2` = " .. playerGuild:getId() .. "))")
    
    if resultId then
        Result.free(resultId)
        return true
    end

    return false
end

-- Função para registrar frags de guerra em servidores non-PvP
function onKill(player, target)
    if isInWar(player, target) then
        -- Contabiliza o frag de guerra aqui
        local playerGuild = player:getGuild()
        local targetGuild = target:getGuild()
		if getWorldType() == WORLDTYPE_PVP then
    -- Lógica adicional para ajustar danos ou comportamento em servidores PVP
end
        -- Exemplo de contagem de frag:
        db.query("UPDATE `guild_wars` SET `frags1` = `frags1` + 1 WHERE `guild1` = " .. playerGuild:getId() .. " AND `guild2` = " .. targetGuild:getId() .. " AND `status` = 1")
        db.query("UPDATE `guild_wars` SET `frags2` = `frags2` + 1 WHERE `guild1` = " .. targetGuild:getId() .. " AND `guild2` = " .. playerGuild:getId() .. " AND `status` = 1")

        -- Enviar mensagem de frag:
        Game.broadcastMessage("[WAR] " .. player:getName() .. " from " .. playerGuild:getName() .. " killed " .. target:getName() .. " from " .. targetGuild:getName() .. ".")
    end
end
