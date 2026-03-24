-- data/creaturescripts/piso ichgahal.lua

-- Variáveis globais exclusivas para Ichgahal (se ainda não existirem, são inicializadas)
_G.g_trailPositionsIchgahal = _G.g_trailPositionsIchgahal or {} -- Para rastrear os itens no chão e seus estágios
_G.g_bossIchgahal = _G.g_bossIchgahal or nil -- Referência para o boss Ichgahal
_G.g_bossDeadIchgahal = _G.g_bossDeadIchgahal or false -- Flag para controlar a morte do boss
_G.g_tileBrokenActiveIchgahal = _G.g_tileBrokenActiveIchgahal or true -- Flag para ativar/desativar a criação de rastros

-- Configurações de Dano e Estágios
local SPORE_ITEM_ID = 43294 -- Estágio 1: Spore Tracks
local VOLATILE_FUNGHI_ITEM_ID = 43295 -- Estágio 2: Volatile Funghi
local SPORE_CLOUD_ITEM_ID = 43296 -- Estágio 3: Spore Cloud

local SPORE_DURATION_BEFORE_FUNGHI = 5 -- Segundos para Spore virar Volatile Funghi
local FUNGHI_DURATION_AFTER_CLOUD = 10 -- Segundos para Spore Cloud ser removida (ou defina como 0 se for permanente até o boss morrer)

local SPORE_DAMAGE_PERCENT = 1 -- 1% HP para Spores (menor dano)
local FUNGHI_DAMAGE_PERCENT = 5 -- 5% HP para Volatile Funghi
local CLOUD_DAMAGE_PERCENT = 10 -- 10% HP para Spore Cloud (maior dano)
local HEX_CHANCE = 10 -- % de chance de aplicar hex
local HEX_DURATION = 10 -- Duração do hex em segundos
local HEX_EFFECT = CONST_ME_MAGIC_BLUE -- Efeito visual para o hex
local PLAYER_HEAL_ON_FUNGHI_PERCENT = 0.01 -- 1% da vida máxima do player
local ICHGAHAL_HEAL_ON_CLOUD_PERCENT = 0.02 -- 2% da vida máxima do boss

-- Zonas onde a mecânica do piso funciona
_G.g_zonesIchgahal = {
    {start = Position(33017, 32344, 15), endPos = Position(33031, 32356, 15)},
    {start = Position(33017, 32344, 15), endPos = Position(33031, 32356, 15)}
}

function isInZoneIchgahal(position)
    if _G.g_bossDeadIchgahal then return false end
    for _, zone in pairs(_G.g_zonesIchgahal) do
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

function getPositionKeyIchgahal(position)
    return position.x .. "," .. position.y .. "," .. position.z
end

-- Função para transformar Spore Tracks em Volatile Funghi
local function transformSporeToFunghi(positionKey)
    local data = _G.g_trailPositionsIchgahal[positionKey]
    if data and data.itemId == SPORE_ITEM_ID then
        local pos = Position(data.position.x, data.position.y, data.position.z)
        local tile = Tile(pos)
        if tile then
            local item = tile:getItemById(SPORE_ITEM_ID)
            if item then
                item:transform(VOLATILE_FUNGHI_ITEM_ID)
                data.itemId = VOLATILE_FUNGHI_ITEM_ID
            end
        end
        -- Agendar a próxima transformação para Spore Cloud
        data.transitionEventId = addEvent(transformFunghiToCloud, FUNGHI_DURATION_AFTER_CLOUD * 1000, positionKey)
    end
end

-- Função para transformar Volatile Funghi em Spore Cloud
local function transformFunghiToCloud(positionKey)
    local data = _G.g_trailPositionsIchgahal[positionKey]
    if data and data.itemId == VOLATILE_FUNGHI_ITEM_ID then
        local pos = Position(data.position.x, data.position.y, data.position.z)
        local tile = Tile(pos)
        if tile then
            local item = tile:getItemById(VOLATILE_FUNGHI_ITEM_ID)
            if item then
                item:transform(SPORE_CLOUD_ITEM_ID)
                data.itemId = SPORE_CLOUD_ITEM_ID
            end
        end
        -- Agendar a remoção da Spore Cloud após sua duração
        data.removalEventId = addEvent(removeSporeCloud, FUNGHI_DURATION_AFTER_CLOUD * 1000, positionKey)
    end
end

-- Função para remover Spore Cloud
local function removeSporeCloud(positionKey)
    local data = _G.g_trailPositionsIchgahal[positionKey]
    if data and data.itemId == SPORE_CLOUD_ITEM_ID then
        local pos = Position(data.position.x, data.position.y, data.position.z)
        local tile = Tile(pos)
        if tile then
            local item = tile:getItemById(SPORE_CLOUD_ITEM_ID)
            if item then
                item:remove()
            end
        end
        _G.g_trailPositionsIchgahal[positionKey] = nil
    end
end

-- Função para aplicar o efeito de hex ao jogador
local function applyHexEffect(player)
    if player and player:isPlayer() and player:getHealth() > 0 then
        -- Simplesmente aplica o efeito visual, sem debuff real a menos que haja um sistema de condições
        player:sendMagicEffect(player:getPosition(), HEX_EFFECT)
        player:say("Você foi afetado pelo hex de Ichgahal!", TALKTYPE_MONSTER_SAY) -- Mensagem para o jogador
    end
end

-- MoveEvent para o piso de Ichgahal
local g_tileIchgahal = MoveEvent()
_G.g_registeredPositionsIchgahal = _G.g_registeredPositionsIchgahal or {} -- Para evitar registros duplicados

function g_tileIchgahal.onStepIn(creature, item, position, fromPosition)
    if not creature or not creature:isPlayer() then return true end
    local player = creature:getPlayer()
    if not player then return true end

    if not isInZoneIchgahal(position) then return true end

    local positionKey = getPositionKeyIchgahal(position)
    local data = _G.g_trailPositionsIchgahal[positionKey]

    if data then
        local maxHealth = player:getMaxHealth()
        local currentHealth = player:getHealth()
        local damage = 0

        if data.itemId == SPORE_ITEM_ID then
            damage = math.floor(maxHealth * (SPORE_DAMAGE_PERCENT / 100))
            player:sendMagicEffect(CONST_ME_POFF)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Você pisou em Spore Tracks e sentiu um leve dano!")
        elseif data.itemId == VOLATILE_FUNGHI_ITEM_ID then
            damage = math.floor(maxHealth * (FUNGHI_DAMAGE_PERCENT / 100))
            player:sendMagicEffect(CONST_ME_FIREAREA) -- Exemplo de efeito
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "O Volatile Funghi queimou você!")
            -- Cura o jogador
            local healAmount = math.floor(maxHealth * PLAYER_HEAL_ON_FUNGHI_PERCENT)
            player:addHealth(healAmount)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Você se curou em %d HP do Volatile Funghi!", healAmount))
        elseif data.itemId == SPORE_CLOUD_ITEM_ID then
            damage = math.floor(maxHealth * (CLOUD_DAMAGE_PERCENT / 100))
            player:sendMagicEffect(CONST_ME_POISON) -- Exemplo de efeito
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "A Spore Cloud te envolveu, causando dano pesado!")

            -- Chance de aplicar hex
            if math.random(1, 100) <= HEX_CHANCE then
                applyHexEffect(player)
            end
        end

        if damage > 0 then
            player:addHealth(-damage)
        end
    end

    return true
end

g_tileIchgahal:type("stepin")
-- Registra o MoveEvent para todas as posições na zona
for _, zone in pairs(_G.g_zonesIchgahal) do
    local minX, maxX = math.min(zone.start.x, zone.endPos.x), math.max(zone.start.x, zone.endPos.x)
    local minY, maxY = math.min(zone.start.y, zone.endPos.y), math.max(zone.start.y, zone.endPos.y)
    local z = zone.start.z

    for x = minX, maxX do
        for y = minY, maxY do
            local pos = Position(x, y, z)
            local key = getPositionKeyIchgahal(pos)
            if not _G.g_registeredPositionsIchgahal[key] then
                g_tileIchgahal:position(pos)
                _G.g_registeredPositionsIchgahal[key] = true
            end
        end
    end
end
g_tileIchgahal:register()


-- Evento onDeath do boss para limpar os efeitos do piso
_G.g_tileBrokenOnMonsterDeathIchgahal = CreatureEvent("TileBrokenOnMonsterDeath_Ichgahal")

function _G.g_tileBrokenOnMonsterDeathIchgahal.onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
    local monster = creature:getMonster()
    if not monster or monster:getName():lower() ~= "ichgahal" then
        return true
    end

    _G.g_bossDeadIchgahal = true
    _G.g_tileBrokenActiveIchgahal = false

    -- Limpa todos os rastros e eventos associados
    for positionKey, data in pairs(_G.g_trailPositionsIchgahal) do
        local pos = Position(data.position.x, data.position.y, data.position.z)
        local tile = Tile(pos)
        if tile then
            for _, item in ipairs(tile:getItems() or {}) do
                if item:getId() == SPORE_ITEM_ID or item:getId() == VOLATILE_FUNGHI_ITEM_ID or item:getId() == SPORE_CLOUD_ITEM_ID then
                    item:remove()
                end
            end
        end
        if data.transitionEventId then
            stopEvent(data.transitionEventId)
        end
        if data.removalEventId then
            stopEvent(data.removalEventId)
        end
    end
    _G.g_trailPositionsIchgahal = {} -- Limpa a tabela de rastros
    _G.g_registeredPositionsIchgahal = {} -- Limpa as posições registradas para um novo spawn do boss

    -- Remova quaisquer condições de hex ativas nos jogadores se for necessário
    -- Isso exigiria rastrear os players com hexes, o que tornaria o script mais complexo.
    -- Por enquanto, as condições expirarão ou serão sobrescritas.

    return true
end
g_tileBrokenOnMonsterDeathIchgahal:register()