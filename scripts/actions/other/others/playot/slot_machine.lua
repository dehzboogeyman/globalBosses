local slotmachine = Action()
slotmachine:aid(34121)

local requiredItemId = 61704
local requiredItemCount = 1
local cooldownTime = 1
local spinTime = 8
local moveDelay = 40
local winChance = 40 -- Porcentagem de chance de ganhar

local positions = {
    {Position(32523, 32406, 6), Position(32523, 32407, 6), Position(32523, 32408, 6)},
    {Position(32524, 32406, 6), Position(32524, 32407, 6), Position(32524, 32408, 6)},
    {Position(32525, 32406, 6), Position(32525, 32407, 6), Position(32525, 32408, 6)}
}

local possibleItems = {2854, 39693, 22721, 14674, 28571, 14249, 20347, 16100, 14248, 34109, 30197, 32620, 39754, 48114, 24393, 22084, 9594, 9596, 9598, 3397, 3396, 3398, 36723, 36724, 36725, 36726, 36730, 36729, 36728, 36727, 36734, 36731, 36732, 36733, 36738, 36735, 36736, 36737, 36742, 36739, 36740, 36741, 22516, 22720, 22722, 22723, 16107, 16105, 16104, 16106, 16256, 16255, 16253, 16252, 16153, 16110, 16112, 16109, 16111, 16116, 16253, 16256, 3043}

local activeMachines = {}

function moveItems(columns, cycle, callback)
    if cycle > (spinTime * 4) then
        if callback then callback() end
        return
    end

    for col = 1, #columns do
        local column = columns[col]
        local tempItems = {}

        for row = 1, #column do
            local tile = Tile(column[row])
            if tile then
                local item = tile:getTopDownItem()
                if item then
                    tempItems[#tempItems + 1] = item:getId()
                    item:remove()
                end
            end
        end

        for row = #column, 2, -1 do
            if tempItems[row - 1] then
                Game.createItem(tempItems[row - 1], 1, column[row])
            end
        end

        Game.createItem(possibleItems[math.random(#possibleItems)], 1, column[1])
    end

    addEvent(moveItems, moveDelay, columns, cycle + 1, callback)
end

function stopAndSetWinningItems(callback)
    local wonItem = nil

    if math.random(100) <= winChance then
        wonItem = possibleItems[math.random(#possibleItems)] -- Escolhe um item aleatório para prêmio

        -- Define os três itens do meio como o mesmo item vencedor
        for col = 1, 3 do
            local tile = Tile(positions[col][2]) -- Posição do meio (segunda linha)
            if tile then
                local item = tile:getTopDownItem()
                if item then
                    item:remove()
                end
                Game.createItem(wonItem, 1, positions[col][2])
            end
        end
    end

    if callback then
        callback(wonItem)
    end
end

function slotmachine.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local playerId = player:getId()
    
    if activeMachines[playerId] then
        player:sendCancelMessage("The slot machine is in use. Please wait for it to finish spinning.")
        return true
    end

    local cooldownStorage = player:getStorageValue(34121)
    if cooldownStorage > os.time() then
        player:sendCancelMessage("You must wait before playing again.")
        return true
    end

    if player:getItemCount(requiredItemId) < requiredItemCount then
        local itemType = ItemType(requiredItemId)
        local itemName = itemType and itemType:getName() or "required item"
        player:sendCancelMessage("You need " .. requiredItemCount .. " " .. itemName .. " to play.")
        return true
    end

    player:removeItem(requiredItemId, requiredItemCount)
    activeMachines[playerId] = true

    moveItems(positions, 0, function()
        stopAndSetWinningItems(function(wonItem)
            if wonItem then
                local itemType = ItemType(wonItem)
                local itemName = itemType and itemType:getName() or "???"
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You win " .. itemName .. "!")
                player:addItem(wonItem, 1)
            else
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You didn't win this time. Try again!")
            end

            player:setStorageValue(34121, os.time() + cooldownTime)
            activeMachines[playerId] = nil
        end)
    end)

    return true
end

slotmachine:register()
