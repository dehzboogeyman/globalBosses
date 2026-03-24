local config = {
    minLevel = 8,
    firstPosition = Position(32321, 32217, 7),
    secondPosition = Position(32609, 32434, 7)
}

local treePass = Action()

function treePass.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if not player then
        return false
    end

    -- Verificando se o jogador tem o nível mínimo
    if player:getLevel() < config.minLevel then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You need to be at least level " .. config.minLevel .. " to access this area.")
        return true
    end

    -- Pegando a posição atual do jogador
    local playerPos = player:getPosition()

    -- Comparando se a posição do jogador é igual à segunda posição
    if playerPos.x == config.secondPosition.x and playerPos.y == config.secondPosition.y and playerPos.z == config.secondPosition.z then
        -- Se estiver na segunda posição, teleporta para a primeira
        player:teleportTo(config.firstPosition)
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Welcome to Area VIP")
    else
        -- Se não, teleporta para a segunda posição
        player:teleportTo(config.secondPosition)
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Welcome to Area VIP")
    end
    
    return true
end

treePass:aid(50995)
treePass:register()
