-- Variáveis globais exclusivas para Chagorz
g_playerCountersChagorz = {}
g_tileBrokenActiveChagorz = true
g_trailPositionsChagorz = {}
g_bossDeadChagorz = false  -- Flag para controlar se o boss morreu
g_bossChagorz = nil -- Referência para o boss

g_zonesChagorz = {
    {start = Position(33034, 32357, 15), endPos = Position(33052, 32375, 15)},
    {start = Position(33052, 32357, 15), endPos = Position(33034, 32375, 15)}
}

function isInZoneChagorz(position)
    if g_bossDeadChagorz then return false end
    for _, zone in pairs(g_zonesChagorz) do
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

function removeTrailAfterDelayChagorz(position)
    addEvent(function()
        local tile = Tile(position)
        if tile then
            local item = tile:getItemById(43929)
            if item then
                item:remove()
            end
        end
    end, 5000)
end

function saveTrailChagorz(player)
    local position = player:getPosition()
    if isInZoneChagorz(position) then
        local tile = Tile(position)
        if tile then
            Game.createItem(43929, 1, position)
            table.insert(g_trailPositionsChagorz, position)
            removeTrailAfterDelayChagorz(position)
        end
    end
end

function stopCounterAndRemoveTrailsChagorz(playerId)
    if g_playerCountersChagorz[playerId] and g_playerCountersChagorz[playerId].eventId then
        stopEvent(g_playerCountersChagorz[playerId].eventId)
    end

    local player = Player(playerId)
    if player then
        local position = player:getPosition()
        local tile = Tile(position)
        if tile then
            local item = tile:getItemById(43929)
            if item then
                item:remove()
            end
        end

        player:setIcon("step-counter", CreatureIconCategory_None)
        player:setIcon("waiting-arrow", CreatureIconCategory_None)
    end

    g_playerCountersChagorz[playerId] = nil
end

function startStepCounterChagorz(playerId)
    local player = Player(playerId)
    if not player or not isInZoneChagorz(player:getPosition()) then
        stopCounterAndRemoveTrailsChagorz(playerId)
        return
    end

    if g_playerCountersChagorz[playerId] and g_playerCountersChagorz[playerId].eventId then
        stopEvent(g_playerCountersChagorz[playerId].eventId)
    end

    g_playerCountersChagorz[playerId] = { count = 0, eventId = nil, damageMultiplier = 1 }
    player:setIcon("step-counter", CreatureIconCategory_Quests, CreatureIconQuests_ArrowUp)

    local function updateStepCounter()
        local counterData = g_playerCountersChagorz[playerId]
        if not counterData or not isInZoneChagorz(player:getPosition()) then
            stopCounterAndRemoveTrailsChagorz(playerId)
            return
        end

        if counterData.count < 5 then
            counterData.count = counterData.count + 1
        else
            local damage = math.random(100, 200) * counterData.damageMultiplier
            player:addHealth(-damage)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Você está sangrando! Dano: %d HP!", damage))
            player:getPosition():sendMagicEffect(249)

            counterData.count = 0
            counterData.damageMultiplier = math.min(counterData.damageMultiplier * 2, 5)
        end

        player:setIcon("step-counter", CreatureIconCategory_Quests, CreatureIconQuests_ArrowUp, counterData.count)
        saveTrailChagorz(player)

        counterData.eventId = addEvent(updateStepCounter, 1000)
    end

    updateStepCounter()
end

g_tileChagorz = MoveEvent()

function g_tileChagorz.onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player or player:isInGhostMode() then
        return true
    end

    local playerId = player:getId()

    if not isInZoneChagorz(position) then
        stopCounterAndRemoveTrailsChagorz(playerId)
        return true
    end

    local damage = math.random(100, 200)
    player:addHealth(-damage)
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Você tomou %d de dano ao pisar no piso!", damage))
    position:sendMagicEffect(249)

    local countdown = 1
    local function countdownUpdate()
        if countdown >= 0 then
            player:setIcon("waiting-arrow", CreatureIconCategory_Quests, CreatureIconQuests_ArrowDown, countdown)
            countdown = countdown - 1
            addEvent(countdownUpdate, 1000)
        else
            player:setIcon("step-counter", CreatureIconCategory_Quests, CreatureIconQuests_ArrowUp)
            startStepCounterChagorz(playerId)
        end
    end
    countdownUpdate()

    saveTrailChagorz(player)

    return true
end

-- REGISTRANDO O EVENTO NOS TILES DAS ZONAS, evitando duplicados
local registeredPositions = {}

for _, zone in pairs(g_zonesChagorz) do
    local minX = math.min(zone.start.x, zone.endPos.x)
    local maxX = math.max(zone.start.x, zone.endPos.x)
    local minY = math.min(zone.start.y, zone.endPos.y)
    local maxY = math.max(zone.start.y, zone.endPos.y)
    local z = zone.start.z

    for x = minX, maxX do
        for y = minY, maxY do
            local posKey = string.format("%d|%d|%d", x, y, z)
            if not registeredPositions[posKey] then
                g_tileChagorz:position(Position(x, y, z))
                registeredPositions[posKey] = true
            end
        end
    end
end

g_tileChagorz:type("stepin")
g_tileChagorz:register()

g_tileBrokenOnMonsterDeathChagorz = CreatureEvent("TileBrokenOnMonsterDeath_Chagorz")

function g_tileBrokenOnMonsterDeathChagorz.onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
    local monster = creature:getMonster()
    if not monster or monster:getName():lower() ~= "chagorz" then
        return true
    end

    g_bossDeadChagorz = true
    g_tileBrokenActiveChagorz = false

    for playerId in pairs(g_playerCountersChagorz) do
        stopCounterAndRemoveTrailsChagorz(playerId)
    end
    g_playerCountersChagorz = {}

    for _, position in ipairs(g_trailPositionsChagorz) do
        local tile = Tile(position)
        if tile then
            for _, item in ipairs(tile:getItems() or {}) do
                if item:getId() == 43929 then
                    item:remove()
                end
            end
        end
    end
    g_trailPositionsChagorz = {}

    return true
end

g_tileBrokenOnMonsterDeathChagorz:register()

function g_bossVerificationChagorz(monster)
    if not monster then return end
    g_bossDeadChagorz = false
    g_tileBrokenActiveChagorz = true
end
