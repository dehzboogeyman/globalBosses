-- data/scripts/murcion_mechanics.lua
local MUSHROOM_MONSTER_NAME = "Mushroom" -- Nome exato do monstro cogumelo
local MUSHROOM_EXPLOSION_DAMAGE_MIN = 2500
local MUSHROOM_EXPLOSION_DAMAGE_MAX = 3000
local MUSHROOM_EXPLOSION_RADIUS = 3
local MUSHROOM_EXPLOSION_EFFECT = CONST_ME_EXPLOSIONHIT

local MOLD_DAMAGE_PERCENTAGE = 0.2
local MOLD_HEAL_PERCENTAGE = 0.1
local MOLD_TRAIL_ITEM_ID = 3603 -- ID do item de rastro (ex: musgo/mofo)
local MOLD_TRAIL_DURATION = 5000 -- Duração do rastro em milissegundos
local MOLD_HEAL_DELAY = 2 -- Atraso para cura em segundos (Murcion sobre o rastro)

local g_zonesMurcion = {
    {start = Position(33019, 32380, 15), endPos = Position(33030, 32390, 15)} -- Ajuste para a área do seu boss
}

local trailPositionsMurcion = {}
local lastPositionsMurcion = {}
local tileBrokenActiveMurcion = true
local registeredPositionsMurcion = {} -- Para garantir que o MoveEvent seja registrado apenas uma vez por posição

local function getPositionKey(position)
    return position.x .. "," .. position.y .. "," .. position.z
end

local function isInZoneMurcion(position)
    for _, zone in pairs(g_zonesMurcion) do
        local minX, maxX = math.min(zone.start.x, zone.endPos.x), math.max(zone.start.x, zone.endPos.x)
        local minY, maxY = math.min(zone.start.y, zone.endPos.y), math.max(zone.start.y, zone.endPos.y)
        if position.x >= minX and position.x <= maxX and
           position.y >= minY and position.y <= maxY and
           position.z == zone.start.z then
            return true
        end
    end
    return false
end

-- Função para lidar com a explosão do cogumelo
local function handleMushroomExplosion(mushroom)
    local position = mushroom:getPosition()
    position:sendMagicEffect(MUSHROOM_EXPLOSION_EFFECT)
    position:sendDistanceEffect(position, MUSHROOM_EXPLOSION_EFFECT) -- Efeito para alvos próximos

    local spectators = Game.getSpectators(position, false, false, MUSHROOM_EXPLOSION_RADIUS) -- Corrigido para Game.getSpectators
    for i = 1, #spectators do
        local creature = spectators[i]
        if creature:isPlayer() then
            local damage = math.random(MUSHROOM_EXPLOSION_DAMAGE_MIN, MUSHROOM_EXPLOSION_DAMAGE_MAX)
            Combat().doTargetCombatHealth(0, creature, COMBAT_LIFEDRAIN, -damage, -damage, CONST_ME_NONE)
            creature:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Você sofreu " .. damage .. " de dano da explosão do cogumelo!")
        end
    end
    mushroom:remove() -- Remove o cogumelo após explodir
end

-- Evento onDeath do Murcion para parar o rastro temporariamente
local rottenBloodBossDeath = CreatureEvent("RottenBloodBossDeath") -- O nome do evento que está em monster.events do Murcion

function rottenBloodBossDeath.onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
    local monster = creature:getMonster()
    if not monster or monster:getName():lower() ~= "murcion" then
        return true
    end

    tileBrokenActiveMurcion = false
    -- Função para remover rastro
    for key, _ in pairs(trailPositionsMurcion) do
        local x, y, z = key:match("([^,]+),([^,]+),([^,]+)")
        local pos = Position(tonumber(x), tonumber(y), tonumber(z))
        local tile = Tile(pos)
        if tile then
            local item = tile:getItemById(MOLD_TRAIL_ITEM_ID)
            while item do
                item:remove()
                item = tile:getItemById(MOLD_TRAIL_ITEM_ID)
            end
        end
    end
    trailPositionsMurcion = {}

    addEvent(function()
        tileBrokenActiveMurcion = true
    end, 30000) -- Rastro desativado por 30 segundos

    return true
end

rottenBloodBossDeath:register()

-- Evento onThink para o Murcion e os Cogumelos
local murcionThink = CreatureEvent("MurcionThink")

function murcionThink.onThink(creature)
    if not creature or not creature:isMonster() then
        return true
    end

    local creatureId = creature:getId()
    local position = creature:getPosition()

    -- Lógica para o Murcion criar o rastro
    if creature:getName():lower() == "murcion" then
        local oldPos = lastPositionsMurcion[creatureId]
        local dx = position.x - (oldPos and oldPos.x or position.x)
        local dy = position.y - (oldPos and oldPos.y or position.y)
        local steps = math.max(math.abs(dx), math.abs(dy))

        for i = 0, steps do
            local intermediatePos = Position(
                (oldPos and oldPos.x or position.x) + math.floor((dx / steps) * i),
                (oldPos and oldPos.y or position.y) + math.floor((dy / steps) * i),
                position.z
            )
            if tileBrokenActiveMurcion and isInZoneMurcion(intermediatePos) then
                local key = getPositionKey(intermediatePos)
                if not trailPositionsMurcion[key] then
                    Game.createItem(MOLD_TRAIL_ITEM_ID, 1, intermediatePos)
                    trailPositionsMurcion[key] = {position = intermediatePos, time = os.time()}
                    addEvent(function(posToRemove)
                        local tile = Tile(posToRemove)
                        if tile then
                            local item = tile:getItemById(MOLD_TRAIL_ITEM_ID)
                            while item do
                                item:remove()
                                item = tile:getItemById(MOLD_TRAIL_ITEM_ID)
                            end
                        end
                        trailPositionsMurcion[getPositionKey(posToRemove)] = nil
                    end, MOLD_TRAIL_DURATION, intermediatePos)
                end
            end
        end
        lastPositionsMurcion[creatureId] = {x = position.x, y = position.y, z = position.z}

        -- Lógica de cura para o Murcion no rastro
        local key = getPositionKey(position)
        local trailData = trailPositionsMurcion[key]
        if trailData and (os.time() - trailData.time) >= MOLD_HEAL_DELAY then
            local maxHealth = creature:getMaxHealth()
            local healAmount = math.floor(maxHealth * MOLD_HEAL_PERCENTAGE)
            creature:addHealth(healAmount)
            position:sendMagicEffect(CONST_ME_MAGIC_GREEN)
        end
    end

    -- Lógica para a explosão do cogumelo
    if creature:getName():lower() == MUSHROOM_MONSTER_NAME:lower() then
        -- Verifica se há jogadores próximos para explodir
        local playersNear = Game.getSpectators(position, false, true, MUSHROOM_EXPLOSION_RADIUS) -- Corrigido
        if #playersNear > 0 then
            handleMushroomExplosion(creature)
        else
            -- Lógica para explodir se ninguém estiver perto após um tempo (ex: 15 segundos)
            if not creature:hasStorageValue(10001) then -- Usar uma storage para o tempo de spawn
                creature:setStorageValue(10001, os.time())
            end
            if os.time() - creature:getStorageValue(10001) >= 15 then -- Explode após 15 segundos
                handleMushroomExplosion(creature)
            end
        end
    end

    return true
end

murcionThink:register()

-- Evento onStepIn para o dano nos jogadores no rastro
local tileMurcion = MoveEvent()

function tileMurcion.onStepIn(creature, item, position, fromPosition)
    if not creature then return true end
    local player = creature:getPlayer()
    if not player then return true end

    if not isInZoneMurcion(position) then return true end

    local key = getPositionKey(position)
    if trailPositionsMurcion[key] then
        local maxHealth = player:getMaxHealth()
        local damage = math.floor(maxHealth * MOLD_DAMAGE_PERCENTAGE)
        player:addHealth(-damage)
        player:getPosition():sendMagicEffect(CONST_ME_HITBYFIRE)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Você sofreu " .. damage .. " de dano ao pisar no rastro de Murcion!")
    end

    return true
end

-- REGISTRA APENAS UMA VEZ POR TILE
for _, zone in pairs(g_zonesMurcion) do
    local minX, maxX = math.min(zone.start.x, zone.endPos.x), math.max(zone.start.x, zone.endPos.x)
    local minY, maxY = math.min(zone.start.y, zone.endPos.y), math.max(zone.start.y, zone.endPos.y)
    local z = zone.start.z

    for x = minX, maxX do
        for y = minY, maxY do
            local key = string.format("%d|%d|%d", x, y, z)
            if not registeredPositionsMurcion[key] then
                tileMurcion:position(Position(x, y, z))
                registeredPositionsMurcion[key] = true
            end
        end
    end
end

tileMurcion:type("stepin")
tileMurcion:aid(1280) -- Certifique-se que este AID não conflita com outros no seu servidor
tileMurcion:register()