local internalNpcName = "Eldran"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 3

npcConfig.outfit = {
    lookType = 1822,
    lookHead = 0,
    lookBody = 122,
    lookLegs = 0,
    lookFeet = 39,
    lookAddons = 3,
}

npcConfig.flags = {
    floorchange = false,
}

npcConfig.voices = {
    interval = 15000,
    chance = 50,
    { text = "Troque suas recompensas por exercise weapons!" },
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

npcType.onThink = function(npc, interval)
    npcHandler:onThink(npc, interval)
end

npcType.onAppear = function(npc, creature)
    npcHandler:onAppear(npc, creature)
end

npcType.onDisappear = function(npc, creature)
    npcHandler:onDisappear(npc, creature)
end

npcType.onMove = function(npc, creature, fromPosition, toPosition)
    npcHandler:onMove(npc, creature, fromPosition, toPosition)
end

npcType.onSay = function(npc, creature, type, message)
    npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
    npcHandler:onCloseChannel(npc, creature)
end

local function creatureSayCallback(npc, creature, type, message)
    local player = Player(creature)
    local playerId = player:getId()

    if not npcHandler:checkInteraction(npc, creature) then
        return false
    end

    if MsgContains(message, "trocar") then
        npcHandler:say("Voce quer trocar o item por um exercise weapon aleatorio?", npc, creature)
        npcHandler:setTopic(playerId, 1)
    elseif MsgContains(message, "yes") then
        if npcHandler:getTopic(playerId) == 1 then
            local player = Player(creature)
            local requiredItem = 43861  -- Substitua pelo ID do item necessário para a troca

if player:removeItem(requiredItem, 1) then
    local exerciseWeapons = {
        {id = 35280, charges = 50}, --Durable Exercise Axe
        {id = 35282, charges = 50}, --Durable Exercise Bow
        {id = 35281, charges = 50}, --Durable Exercise Club
        {id = 35283, charges = 50}, --Durable Exercise Rod
        {id = 35279, charges = 50}, --Durable Exercise Sword
        {id = 35284, charges = 50}, --Durable Exercise Wand
        {id = 44066, charges = 50}, --Durable Exercise Shield
        {id = 28553, charges = 30}, --Exercise Axe
        {id = 28555, charges = 30}, --Exercise Bow
        {id = 28554, charges = 30}, --Exercise Club
        {id = 28556, charges = 30}, --Exercise Rod
        {id = 28552, charges = 30}, --Exercise Sword
        {id = 28557, charges = 30}, --Exercise Wand
        {id = 44065, charges = 30}, --Exercise Shield
        {id = 35286, charges = 80}, --Lasting Exercise Axe
        {id = 35288, charges = 80}, --Lasting Exercise Bow
        {id = 35287, charges = 80}, --Lasting Exercise Club
        {id = 35289, charges = 80}, --Lasting Exercise Rod
        {id = 35285, charges = 80}, --Lasting Exercise Sword
        {id = 35290, charges = 80}, --Lasting Exercise Wand
        {id = 44067, charges = 80}  --Lasting Exercise Shield
    }

    local randomIndex = math.random(#exerciseWeapons)
    local chosenExerciseWeapon = exerciseWeapons[randomIndex]

    if chosenExerciseWeapon then
        -- Adicione o item com carga
        local newItem = player:addItem(chosenExerciseWeapon.id, 1)
        
        if newItem then
            newItem:setAttribute(ITEM_ATTRIBUTE_CHARGES, chosenExerciseWeapon.charges)
            npcHandler:say("Pronto, se precisar novamente estamos aqui.", npc, creature)
        else
            player:addItem(requiredItem, 1)  -- Devolvendo o item original em caso de falha
            npcHandler:say("Houve um problema ao adicionar a exercise weapon. Por favor, entre em contato com a equipe de suporte.", npc, creature)
        end
    else
        npcHandler:say("Houve um problema ao escolher a exercise weapon. Por favor, entre em contato com a equipe de suporte.", npc, creature)
    end
else
    npcHandler:say("Voce nao tem o item necessario para a troca.", npc, creature)
end

            npcHandler:setTopic(playerId, 0)
        end
    end
    return true
end

-- Basic

npcHandler:setMessage(MESSAGE_GREET, "Ola, |PLAYERNAME|. Eu troco os itens de recompensa por exercise weapons, digite {trocar}")
npcHandler:setMessage(MESSAGE_FAREWELL, "Ate breve.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Ate logo.")
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcConfig.shop = {}

-- On buy npc shop message
npcType.onBuyItem = function(npc, player, itemId, subType, amount, ignore, inBackpacks, totalCost)
    npc:sellItem(player, itemId, amount, subType, 0, ignore, inBackpacks)
end

-- On sell npc shop message
npcType.onSellItem = function(npc, player, itemId, subtype, amount, ignore, name, totalCost)
    player:sendTextMessage(MESSAGE_INFO_DESCR, string.format("Sold %ix %s for %i gold.", amount, name, totalCost))
end

-- On check npc shop message (look item)
npcType.onCheckItem = function(npc, player, clientId, subType)
end

npcType:register(npcConfig)