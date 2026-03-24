-- Variáveis globais exclusivas para Bakragore
_G.g_playerCountersBakragore = _G.g_playerCountersBakragore or {}
_G.g_tileBrokenActiveBakragore = _G.g_tileBrokenActiveBakragore or true
_G.g_trailPositionsBakragore = _G.g_trailPositionsBakragore or {}
_G.g_bossDeadBakragore = _G.g_bossDeadBakragore or false  -- Flag para controlar se o boss morreu
_G.g_bossBakragore = _G.g_bossBakragore or nil -- Referência para o boss

-- Zonas onde a mecânica do piso funciona
_G.g_zonesBakragore = {
    {start = Position(33034, 32388, 15), endPos = Position(33052, 32409, 15)},
    {start = Position(33052, 32389, 15), endPos = Position(33034, 32409, 15)}
}

-- Configurações
local DAMAGE_PERCENTAGE_BAKRAGORE = 0.05 -- 5% da vida máxima de dano
local HEAL_PERCENTAGE_BAKRAGORE = 0.02    -- 2% da vida máxima de cura
local TRAIL_ITEM_ID_BAKRAGORE = 43292   -- ID do item que representa o rastro no chão
local TRAIL_DURATION_BAKRAGORE = 5000   -- Duração do rastro em milissegundos (5 segundos)
local DAMAGE_DELAY_BAKRAGORE = 1        -- Atraso para aplicar dano/cura em segundos
local PLAYER_CHAIN_COUNTER_MAX = 5      -- Máximo de cargas de energia sombria

-- Tabela global para o contador do pilar (para a mecânica do Bakragore Beam)
_G.playerChainCountersBakragorePillar = _G.playerChainCountersBakragorePillar or {}

-- Movimento para os tiles do piso
local g_tileBakragore = MoveEvent()
local registeredPositionsBakragore = {}

-- Função auxiliar para obter a chave da posição
local function getPositionKey(position)
    return position.x .. "," .. position.y .. "," .. position.z
end

-- Função para verificar se a posição está dentro da zona do boss
function isInZoneBakragore(position)
    if _G.g_bossDeadBakragore then return false end
    for _, zone in pairs(_G.g_zonesBakragore) do
        local minX = math.min(zone.start.x, zone.endPos.x)
        local maxX = math.max(zone.start.x, zone.endPos.x)
        local minY = math.min(zone.start.y, zone.endPos.y)
        local maxY = math.max(zone.start.y, zone.endPos.y)
        local z = zone.start.z

        if position.x >= minX and position.x <= maxX and
           position.y >= minY and position.y <= maxY and
           position.z == z then
            return true
        end
    end
    return false
end

-- Função para remover o rastro após um atraso
function removeTrailAfterDelayBakragore(position)
    if not _G.g_tileBrokenActiveBakragore then return end

    local key = getPositionKey(position)
    _G.g_trailPositionsBakragore[key] = nil

    local tile = Tile(position)
    if tile then
        local itemsToRemove = {}
        for _, item in ipairs(tile:getItems() or {}) do
            if item:getId() == TRAIL_ITEM_ID_BAKRAGORE then
                table.insert(itemsToRemove, item)
            end
        end
        for _, item in ipairs(itemsToRemove) do
            item:remove()
        end
    end
end

-- Função para criar um rastro entre duas posições
local function createTrailBetweenPositions(startPos, endPos)
    if not _G.g_tileBrokenActiveBakragore then return end
    if not startPos or not endPos or startPos.z ~= endPos.z then return end

    local distanceX = math.abs(startPos.x - endPos.x)
    local distanceY = math.abs(startPos.y - endPos.y)

    local stepX = startPos.x < endPos.x and 1 or (startPos.x > endPos.x and -1 or 0)
    local stepY = startPos.y < endPos.y and 1 or (startPos.y > endPos.y and -1 or 0)

    local currentPos = Position(startPos.x, startPos.y, startPos.z)
    local path = {Position(startPos.x, startPos.y, startPos.z)}

    while currentPos.x ~= endPos.x or currentPos.y ~= endPos.y do
        local nextX = currentPos.x
        local nextY = currentPos.y

        if distanceX > distanceY then
            nextX = currentPos.x + stepX
        else
            nextY = currentPos.y + stepY
        end

        currentPos = Position(nextX, nextY, currentPos.z)
        table.insert(path, currentPos)
    end

    for _, pos in ipairs(path) do
        if isInZoneBakragore(pos) then
            local key = getPositionKey(pos)
            if not _G.g_trailPositionsBakragore[key] then
                local tile = Tile(pos)
                if tile then
                    local item = Game.createItem(TRAIL_ITEM_ID_BAKRAGORE, 1, pos)
                    if item then
                        _G.g_trailPositionsBakragore[key] = {item = item, time = os.time()}
                        addEvent(removeTrailAfterDelayBakragore, TRAIL_DURATION_BAKRAGORE, pos)
                    end
                end
            end
        end
    end
end

-- Função para aplicar o contador de energia sombria do pilar (para o Bakragore Beam)
local function applyChainCounterBakragore(player)
    local playerId = player:getId()
    local counterData = _G.playerChainCountersBakragorePillar[playerId]

    if not counterData then
        -- Inicia um novo contador
        counterData = {count = 1, eventId = nil}
        _G.playerChainCountersBakragorePillar[playerId] = counterData

        local function tickChainDamage()
            local currentCounterData = _G.playerChainCountersBakragorePillar[playerId]
            if not currentCounterData then return end

            if currentCounterData.count > 0 then
                local damage = currentCounterData.count * 150 -- Dano por tick baseado no contador
                if player and player:isPlayer() and player:getHealth() > 0 then
                    player:doCombat(player, COMBAT_DEATHDAMAGE, -damage, -damage, nil)
                    player:getPosition():sendMagicEffect(CONST_ME_MORTAREA)
                    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Cargas de energia sombria te corroem! (" .. currentCounterData.count .. "x)")
                    currentCounterData.count = math.max(0, currentCounterData.count - 1) -- Diminui o contador
                    player:setIcon(CreatureIconCategory_Quests, CreatureIconQuests_ArrowDown, currentCounterData.count) -- Atualiza ícone
                    _G.playerChainCountersBakragorePillar[playerId].eventId = addEvent(tickChainDamage, 1000) -- Reagenda
                else
                    -- Remove o ícone e limpa o contador se o player não existe ou morreu
                    player:setIcon(CreatureIconCategory_None) -- Remove o ícone
                    _G.playerChainCountersBakragorePillar[playerId] = nil
                end
            else
                -- Remove o ícone e limpa o contador se chegou a 0
                player:setIcon(CreatureIconCategory_None) -- Remove o ícone
                _G.playerChainCountersBakragorePillar[playerId] = nil
            end
        end
        _G.playerChainCountersBakragorePillar[playerId].eventId = addEvent(tickChainDamage, 1000)

    else
        -- Apenas aumenta o contador, sem iniciar um novo tick
        counterData.count = math.min(counterData.count + 1, PLAYER_CHAIN_COUNTER_MAX)
        player:setIcon(CreatureIconCategory_Quests, CreatureIconQuests_ArrowDown, counterData.count) -- Atualiza ícone
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "O contador de energia sombria aumentou!")
    end
end

-- Função para parar o contador e remover rastros quando o boss morre ou o jogador sai
function stopCounterAndRemoveTrailsBakragore(playerId)
    if _G.playerChainCountersBakragorePillar[playerId] and _G.playerChainCountersBakragorePillar[playerId].eventId then
        stopEvent(_G.playerChainCountersBakragorePillar[playerId].eventId)
    end
    _G.playerChainCountersBakragorePillar[playerId] = nil
    local player = Player(playerId)
    if player then
        player:setIcon(CreatureIconCategory_None)
    end
end

-- Evento onStepIn do piso
function g_tileBakragore.onStepIn(creature, item, position, fromPosition)
    if not creature or not creature:isPlayer() or _G.g_bossDeadBakragore then
        return true
    end

    if not isInZoneBakragore(position) then
        return true
    end

    local playerId = creature:getId()
    local lastPlayerPosition = _G.g_playerCountersBakragore[playerId] and _G.g_playerCountersBakragore[playerId].lastPosition

    -- Cria rastro se o jogador se move
    if lastPlayerPosition and (lastPlayerPosition.x ~= position.x or lastPlayerPosition.y ~= position.y or lastPlayerPosition.z ~= position.z) then
        createTrailBetweenPositions(lastPlayerPosition, position)
    end

    _G.g_playerCountersBakragore[playerId] = _G.g_playerCountersBakragore[playerId] or {}
    _G.g_playerCountersBakragore[playerId].lastPosition = position

    local key = getPositionKey(position)
    local trailData = _G.g_trailPositionsBakragore[key]

    -- Lógica de dano/cura ao pisar no rastro
    if trailData and (os.time() - trailData.time) >= DAMAGE_DELAY_BAKRAGORE then
        if _G.g_bossBakragore and _G.g_bossBakragore:isValid() then
            -- Aplica dano ao jogador
            local damageAmount = math.floor(creature:getMaxHealth() * DAMAGE_PERCENTAGE_BAKRAGORE)
            creature:doCombat(_G.g_bossBakragore, COMBAT_FIREDAMAGE, -damageAmount, -damageAmount, nil)
            creature:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Você pisou em um rastro de energia escura e sofreu dano!")

            -- Cura o boss
            local healAmount = math.floor(_G.g_bossBakragore:getMaxHealth() * HEAL_PERCENTAGE_BAKRAGORE)
            _G.g_bossBakragore:addHealth(healAmount)
            _G.g_bossBakragore:getPosition():sendMagicEffect(CONST_ME_HOLYDAMAGE) -- Efeito visual de cura no boss
        end
        removeTrailAfterDelayBakragore(position) -- Remove o rastro após a interação
    end

    return true
end

-- Lógica para registrar todas as posições na zona do boss no MoveEvent
local function registerBossArenaTiles()
    local registeredPositions = {}
    for _, zone in pairs(_G.g_zonesBakragore) do
        local minX, maxX = math.min(zone.start.x, zone.endPos.x), math.max(zone.start.x, zone.endPos.x)
        local minY, maxY = math.min(zone.start.y, zone.endPos.y), math.max(zone.start.y, zone.endPos.y)
        local z = zone.start.z

        for x = minX, maxX do
            for y = minY, maxY do
                local posKey = string.format("%d|%d|%d", x, y, z)
                if not registeredPositions[posKey] then
                    g_tileBakragore:position(Position(x, y, z))
                    registeredPositions[posKey] = true
                end
            end
        end
    end
end

g_tileBakragore:type("stepin")
registerBossArenaTiles() -- Chama a função para registrar os tiles da arena
g_tileBakragore:register()

-- Evento onDeath do boss para limpar os efeitos do piso
_G.g_tileBrokenOnMonsterDeathBakragore = CreatureEvent("TileBrokenOnMonsterDeath_Bakragore")

function _G.g_tileBrokenOnMonsterDeathBakragore.onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
    local monster = creature:getMonster()
    if not monster or monster:getName():lower() ~= "bakragore" then
        return true
    end

    _G.g_bossDeadBakragore = true
    _G.g_tileBrokenActiveBakragore = false

    -- Limpa contadores de cargas e remove rastros dos jogadores
    for playerId in pairs(_G.g_playerCountersBakragorePillar) do
        stopCounterAndRemoveTrailsBakragore(playerId)
    end
    _G.g_playerChainCountersBakragorePillar = {} -- Limpa a tabela global de contadores do pilar

    -- Limpa rastros remanescentes no chão
    for key, data in pairs(_G.g_trailPositionsBakragore) do
        local tile = Tile(Position(tonumber(string.match(key, "(%d+),%d+,%d+")), tonumber(string.match(key, "%d+,(%d+),%d+")), tonumber(string.match(key, "%d+,%d+,(%d+)"))))
        if tile then
            for _, item in ipairs(tile:getItems() or {}) do
                if item:getId() == TRAIL_ITEM_ID_BAKRAGORE then
                    item:remove()
                end
            end
        end
    end
    _G.g_trailPositionsBakragore = {}

    -- Limpa a referência ao boss
    _G.g_bossBakragore = nil

    return true
end

_G.g_tileBrokenOnMonsterDeathBakragore:register()