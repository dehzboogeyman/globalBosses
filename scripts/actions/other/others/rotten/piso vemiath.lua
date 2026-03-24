-- data/scripts/vemiath_mechanics.lua

-- Definição de variáveis globais exclusivas para Vemiath
_G.registeredPositionsVemiath = _G.registeredPositionsVemiath or {}
local registeredPositionsVemiath = _G.registeredPositionsVemiath

_G.g_playerCountersVemiath = _G.g_playerCountersVemiath or {}
_G.g_tileBrokenActiveVemiath = _G.g_tileBrokenActiveVemiath or true
_G.g_trailPositionsVemiath = _G.g_trailPositionsVemiath or {}
_G.g_bossDeadVemiath = _G.g_bossDeadVemiath or false
_G.g_vemiathLastPositions = _G.g_vemiathLastPositions or {} -- Para rastrear a posição do Vemiath

-- Constantes para mecânicas de piso
local DARKLIGHT_SPARK_ID = 43929 -- Item ID para Darklight Spark (já presente)
local DARKLIGHT_FIELD_ID = 43930 -- Novo Item ID para Darklight Field
local SPARK_TO_FIELD_DELAY = 3000 -- Tempo para Spark virar Field em ms (3 segundos)
local FIELD_DURATION = 2000      -- Duração do Field em ms (2 segundos)

local PLAYER_FLOOR_DAMAGE_PERCENTAGE = 0.03 -- 3% HP máximo de dano ao pisar em Spark/Field
local VEMIATH_HEAL_SPARK = 200    -- Cura do Vemiath ao pisar em Spark
local VEMIATH_HEAL_FIELD = 400    -- Cura do Vemiath ao pisar em Field

local PLAYER_COUNTER_INCREMENT_RATE = 2 -- Incrementa em 2 por segundo
local PLAYER_COUNTER_MAX_STACKS = 21
local PLAYER_COUNTER_AGONY_DAMAGE_PERCENTAGE = 0.15 -- 15% HP máximo de dano em stacks máximas

-- Zonas do boss
_G.g_zonesVemiath = {
    {start = Position(33033, 32326, 15), endPos = Position(33051, 32343, 15)},
    {start = Position(33051, 32326, 15), endPos = Position(33033, 32343, 15)}
}

function getPositionKey(position)
    return position.x .. "," .. position.y .. "," .. position.z
end

function isInZoneVemiath(position)
    if g_bossDeadVemiath then return false end
    for _, zone in pairs(g_zonesVemiath) do
        local minX, maxX = math.min(zone.start.x, zone.endPos.x), math.max(zone.start.x, zone.endPos.x)
        local minY, maxY = math.min(zone.start.y, zone.endPos.y), math.max(zone.start.y, zone.endPos.y)
        if position.x >= minX and position.x <= maxX and position.y >= minY and position.y <= maxY and position.z == zone.start.z then
            return true
        end
    end
    return false
end

-- Função para remover um item específico da trilha
function removeTrailItemVemiath(position, itemId)
    local tile = Tile(position)
    if tile then
        local item = tile:getItemById(itemId)
        if item then item:remove() end
    end
    -- Remove da lista global de trilhas apenas se for o último item
    local key = getPositionKey(position)
    local tileItems = Tile(position):getItems()
    local hasOtherTrailItems = false
    for _, item in ipairs(tileItems) do
        if item:getId() == DARKLIGHT_SPARK_ID or item:getId() == DARKLIGHT_FIELD_ID then
            hasOtherTrailItems = true
            break
        end
    end
    if not hasOtherTrailItems then
        g_trailPositionsVemiath[key] = nil
    end
end

-- Função que transforma Spark em Field ou remove Field
function handleTrailItemLifeCycleVemiath(position, currentItemId)
    local tile = Tile(position)
    if not tile then return end

    if currentItemId == DARKLIGHT_SPARK_ID then
        -- Remove Spark e cria Field
        removeTrailItemVemiath(position, DARKLIGHT_SPARK_ID)
        Game.createItem(DARKLIGHT_FIELD_ID, 1, position)
        g_trailPositionsVemiath[getPositionKey(position)] = position -- Atualiza para o Field

        -- Agenda a remoção do Field após 2 segundos
        addEvent(removeTrailItemVemiath, FIELD_DURATION, position, DARKLIGHT_FIELD_ID)
    elseif currentItemId == DARKLIGHT_FIELD_ID then
        -- Já é um Field e foi agendado para remoção, apenas garante que está na lista para a limpeza do boss
        -- ou remova se for um caso excepcional. O addEvent já cuida disso.
        -- removeTrailItemVemiath(position, DARKLIGHT_FIELD_ID)
    end
end

function saveTrailVemiath(player)
    local position = player:getPosition()
    if g_tileBrokenActiveVemiath and isInZoneVemiath(position) then
        local key = getPositionKey(position)
        if not g_trailPositionsVemiath[key] then -- Se não existe Spark ou Field nessa posição
            Game.createItem(DARKLIGHT_SPARK_ID, 1, position)
            g_trailPositionsVemiath[key] = position

            -- Agenda a transformação de Spark em Field após 3 segundos
            addEvent(handleTrailItemLifeCycleVemiath, SPARK_TO_FIELD_DELAY, position, DARKLIGHT_SPARK_ID)
        end
    end
end

function stopCounterAndRemoveTrailsVemiath(playerId)
    if g_playerCountersVemiath[playerId] and g_playerCountersVemiath[playerId].eventId then
        stopEvent(g_playerCountersVemiath[playerId].eventId)
    end

    local player = Player(playerId)
    if player then
        player:setIcon("step-counter", CreatureIconCategory_None)
        player:setIcon("waiting-arrow", CreatureIconCategory_None) -- Remove o outro ícone também
    end

    g_playerCountersVemiath[playerId] = nil
end

function startStepCounterVemiath(playerId)
    local player = Player(playerId)
    if not player or not isInZoneVemiath(player:getPosition()) then
        stopCounterAndRemoveTrailsVemiath(playerId)
        return
    end

    -- Garante que um contador anterior seja parado
    if g_playerCountersVemiath[playerId] and g_playerCountersVemiath[playerId].eventId then
        stopEvent(g_playerCountersVemiath[playerId].eventId)
    end

    g_playerCountersVemiath[playerId] = { count = 0, eventId = nil, damageMultiplier = 1 }
    player:setIcon("step-counter", CreatureIconCategory_Quests, CreatureIconQuests_ArrowUp)

    local function updateStepCounter()
        local counterData = g_playerCountersVemiath[playerId]
        if not counterData or not isInZoneVemiath(player:getPosition()) then
            stopCounterAndRemoveTrailsVemiath(playerId)
            return
        end

        counterData.count = math.min(counterData.count + PLAYER_COUNTER_INCREMENT_RATE, PLAYER_COUNTER_MAX_STACKS)

        if counterData.count >= PLAYER_COUNTER_MAX_STACKS then
            local damage = math.floor(player:getMaxHealth() * PLAYER_COUNTER_AGONY_DAMAGE_PERCENTAGE)
            player:addHealth(-damage)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Você está sendo corroído pela escuridão! Dano: %d HP!", damage))
            player:getPosition():sendMagicEffect(CONST_ME_MORTAREA) -- Efeito de dano de Agony
        end

        player:setIcon("step-counter", CreatureIconCategory_Quests, CreatureIconQuests_ArrowUp, counterData.count)

        -- Adiciona um pequeno delay antes de criar o rastro para permitir o movimento
        addEvent(saveTrailVemiath, 100, player)

        counterData.eventId = addEvent(updateStepCounter, 1000)
    end

    updateStepCounter()
end

local tileVemiath = MoveEvent()

tileVemiath.onStepIn = function(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player or player:isInGhostMode() then return true end

    local playerId = player:getId()

    if not isInZoneVemiath(position) then
        stopCounterAndRemoveTrailsVemiath(playerId)
        return true
    end

    -- Dano imediato ao pisar em Spark ou Field
    if item:getId() == DARKLIGHT_SPARK_ID or item:getId() == DARKLIGHT_FIELD_ID then
        local damage = math.floor(player:getMaxHealth() * PLAYER_FLOOR_DAMAGE_PERCENTAGE)
        player:addHealth(-damage)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Você sofreu %d de dano ao pisar na energia sombria!", damage))
        player:getPosition():sendMagicEffect(249) -- Efeito de dano
    end

    -- Reduz o contador em um ao pisar (mover)
    local counterData = g_playerCountersVemiath[playerId]
    if counterData then
        counterData.count = math.max(0, counterData.count - 1)
        player:setIcon("step-counter", CreatureIconCategory_Quests, CreatureIconQuests_ArrowUp, counterData.count)
    end

    -- Garante que o contador esteja ativo ao pisar na zona
    if not g_playerCountersVemiath[playerId] then
        startStepCounterVemiath(playerId)
    end

    -- O rastro é salvo pelo startStepCounterVemiath agora, com pequeno delay
    return true
end

tileVemiath:aid(1260)
tileVemiath:type("stepin")

-- Evita duplicidade no registro
for _, zone in pairs(g_zonesVemiath) do
    local minX, maxX = math.min(zone.start.x, zone.endPos.x), math.max(zone.start.x, zone.endPos.x)
    local minY, maxY = math.min(zone.start.y, zone.endPos.y), math.max(zone.start.y, zone.endPos.y)
    local z = zone.start.z

    for x = minX, maxX do
        for y = minY, maxY do
            local key = string.format("%d|%d|%d", x, y, z)
            if not registeredPositionsVemiath[key] then
                tileVemiath:position(Position(x, y, z))
                registeredPositionsVemiath[key] = true
            end
        end
    end
end
tileVemiath:register()

local onDeathVemiath = CreatureEvent("TileBrokenOnMonsterDeath_Vemiath")
function onDeathVemiath.onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
    local monster = creature:getMonster()
    if not monster or monster:getName():lower() ~= "vemiath" then
        return true
    end

    g_bossDeadVemiath = true
    g_tileBrokenActiveVemiath = false

    -- Limpa todos os contadores de jogadores
    for playerId in pairs(g_playerCountersVemiath) do
        stopCounterAndRemoveTrailsVemiath(playerId)
    end
    g_playerCountersVemiath = {}

    -- Remove todos os itens de rastro do chão
    for _, position in pairs(g_trailPositionsVemiath) do
        local tile = Tile(position)
        if tile then
            for _, item in ipairs(tile:getItems() or {}) do
                if item:getId() == DARKLIGHT_SPARK_ID or item:getId() == DARKLIGHT_FIELD_ID then
                    item:remove()
                end
            end
        end
    end
    g_trailPositionsVemiath = {}
    return true
end
onDeathVemiath:register()

function g_bossVerificationVemiath(monster)
    if not monster then return end
    g_bossDeadVemiath = false
    g_tileBrokenActiveVemiath = true
    g_vemiathLastPositions[monster:getId()] = monster:getPosition() -- Inicializa a posição do boss
end

-- Evento onThink para o Vemiath (registrado em vemiath.lua)
local vemiathThink = CreatureEvent("VemiathThink")

function vemiathThink.onThink(creature)
    if not creature or not creature:isMonster() or creature:getName():lower() ~= "vemiath" then
        return true
    end

    local creatureId = creature:getId()
    local currentPos = creature:getPosition()
    local oldPos = g_vemiathLastPositions[creatureId]

    -- Rastreia o movimento do boss e cura ao pisar em Darklight Sparks/Fields
    local dx = currentPos.x - (oldPos and oldPos.x or currentPos.x)
    local dy = currentPos.y - (oldPos and oldPos.y or currentPos.y)
    local steps = math.max(math.abs(dx), math.abs(dy))

    for i = 0, steps do
        local intermediatePos = Position(
            (oldPos and oldPos.x or currentPos.x) + math.floor((dx / steps) * i),
            (oldPos and oldPos.y or currentPos.y) + math.floor((dy / steps) * i),
            currentPos.z
        )
        local tile = Tile(intermediatePos)
        if tile then
            local spark = tile:getItemById(DARKLIGHT_SPARK_ID)
            local field = tile:getItemById(DARKLIGHT_FIELD_ID)

            if spark then
                creature:addHealth(VEMIATH_HEAL_SPARK)
                removeTrailItemVemiath(intermediatePos, DARKLIGHT_SPARK_ID)
                intermediatePos:sendMagicEffect(CONST_ME_MAGIC_GREEN)
            elseif field then
                creature:addHealth(VEMIATH_HEAL_FIELD)
                removeTrailItemVemiath(intermediatePos, DARKLIGHT_FIELD_ID)
                intermediatePos:sendMagicEffect(CONST_ME_MAGIC_GREEN)
            end
        end
    end
    g_vemiathLastPositions[creatureId] = {x = currentPos.x, y = currentPos.y, z = currentPos.z}

    -- Lógica de spawns (herdada do Murcion, caso Vemiath invoque)
    local chagorzConfig = { -- Re-declarar ou passar como global se for de outro script
        Storage = {
            Initialized = 1,
            SpawnPos = 2,
            NextMonsterSpawn = 3,
            PrimalBeasts = 2, -- Lista de monstros spawnados
        },
        SpawnRadius = 5,
        SpawnOffset = 2,
        MonsterConfig = {
            IntervalBase = 30,
            IntervalReductionPer10PercentHp = 0.95,
            CountBase = 2,
            CountVarianceRate = 0.5,
            CountMax = 3,
            TotalMax = 5,
            MonsterPool = {
                "Elder Bloodjaw",
                "Mushroom",
                "Pillar of Dark Energy", -- Garantir que está aqui também
            },
        },
    }

    local nextSpawnTime = creature:getStorageValue(chagorzConfig.Storage.NextMonsterSpawn)
	if nextSpawnTime == -1 or os.time() >= nextSpawnTime then
		-- As funções countActiveSummons, isPositionValid, spawnMonsters precisam ser acessíveis
        -- Se elas estiverem apenas dentro de vemiath.lua, você precisará trazê-las para cá
        -- ou garantir que vemiath.lua as registre como globais, o que é menos comum.
        -- Vou re-implementar as funções básicas de spawn aqui, para evitar dependência cíclica ou globals excessivos
        -- ou assumir que o mType.onThink em vemiath.lua já as chama.

        -- Como o mType.onThink em vemiath.lua já cuida do spawn, este onThink aqui foca nas mecânicas.
        -- Podemos deixar a lógica de spawn no onThink do monstro em vemiath.lua.
        -- Se quiser que este script controle o spawn, as funções countActiveSummons, isPositionValid, spawnMonsters
        -- teriam que ser movidas para este arquivo ou tornadas globais em vemiath.lua.
	end

    return true
end
function activateAllChainCounters(player)
    local playerId = player:getId()
    local counterData = g_playerChainCountersVemiath[playerId]

    if counterData and counterData.count > 0 then
        local totalDamage = counterData.count * PLAYER_CHAIN_DAMAGE_PER_TICK
        player:doCombat(player, COMBAT_ENERGYDAMAGE, -totalDamage, -totalDamage, nil)
        player:getPosition():sendMagicEffect(CONST_ME_ENERGYHIT)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("O feixe de energia ativou suas cargas, sofrendo %d de dano!", totalDamage))
        stopCounterAndRemoveTrailsVemiath(playerId) -- Função para limpar ícones e dados de contador.
        g_playerChainCountersVemiath[playerId] = nil -- Limpa o contador do pilar
    end
end
vemiathThink:register()

-- Funções para o contador de passos
-- A descrição fala em "acumula charges" e "reduz o contador em um ao se mover".
-- O script atual incrementa por segundo e reduz no onStepIn. Isso está consistente.
-- A descrição do jogador diz "incrementing by two per second to a maximum of 21" - o script está incrementando de 2 em 2.
-- "When under maximum stacks, characters will take 15% maximum health Agony Damage per second." - script faz isso.
-- "Each time a player moves, they "drop" these charges on the ground, leaving Darklight Spark Darklight Spark as tracks and reducing the counter by one." - script reduz e cria spark.