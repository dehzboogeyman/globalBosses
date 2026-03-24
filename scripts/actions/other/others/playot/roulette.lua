-- Instalacao automatica de tabelas se ainda nao as tivermos (primeira instalacao)
db.query([[
	CREATE TABLE IF NOT EXISTS `roleta_plays` (
		`id` int unsigned NOT NULL AUTO_INCREMENT,
		`player_id` int NOT NULL,
		`uuid` varchar(255) NOT NULL,
		`recompensa_id` smallint unsigned NOT NULL,
		`recompensa_quantidade` smallint unsigned NOT NULL,
		`status` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '0 = rolling | 1 = pending | 2 = delivered',
		`created_at` bigint unsigned NOT NULL,
		`updated_at` bigint unsigned NOT NULL,
		PRIMARY KEY (`id`),
		UNIQUE KEY (`uuid`),
		CONSTRAINT `roleta_plays_players_fk`
		FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
]])

-- #######################################################################################################
local roletaActionId = 18567

local roletasConfig = {
	[roletaActionId] = {
		itemNecessario = { id = 61703, quantidade = 1 },
		pisosPorRoleta = 9,
		leverPosition = Position(32469, 32394, 7),
		posicaoDoCentro = Position(32470, 32392, 6),
		items = {
			{ id = 43866, quantidade = 1, chance = 5, raro = true }, -- SANGUINE CUDGEL
			{ id = 43872, quantidade = 1, chance = 5, raro = true }, -- SANGUINE BLUDGEON
			{ id = 43864, quantidade = 1, chance = 5, raro = true }, -- SANGUINE BLADE
			{ id = 51480, quantidade = 1, chance = 6, raro = true }, -- ROULETTE COIN
			{ id = 37160, quantidade = 30, chance = 4, raro = true }, -- 30 EXALTED DUST
			{ id = 37110, quantidade = 15, chance = 5, raro = true }, -- 15 EXALTED CORE
			{ id = 37338, quantidade = 1, chance = 7, raro = true }, -- REMOVE RED SKULL
			{ id = 9594, quantidade = 1, chance = 8, raro = true }, -- Sneaky Stabber of Eliteness  -CANIVETE
			{ id = 9596, quantidade = 1, chance = 8, raro = true }, -- Squeezing Gear of Girlpower  -CANIVETE
			{ id = 9598, quantidade = 1, chance = 8, raro = true }, -- Whacking Driller of Fate  -CANIVETE
			{ id = 3587, quantidade = 1, chance = 3, raro = true }, -- BANANA
			{ id = 51971, quantidade = 1, chance = 4, raro = true }, -- SOULWAR BACKPACK
			{ id = 51972, quantidade = 1, chance = 4, raro = true }, -- SANGUINE BACKPACK
			{ id = 51980, quantidade = 1, chance = 3, raro = true }, -- RANDOM OUTFIT CHEST
			{ id = 51965, quantidade = 1, chance = 3, raro = true }, -- AUTO BANK PORTABLE
			{ id = 51981, quantidade = 20, chance = 3, raro = true }, -- 20 PREY WILDCARD
			{ id = 33313, quantidade = 1, chance = 8, raro = true }, -- TELEPORT CUBE BOSSES
			{ id = 44179, quantidade = 1, chance = 8, raro = true }, -- STAMINA REFILL
			{ id = 3043, quantidade = 100, chance = 7, raro = true } -- 100 CRYSTAL COINS
		},
		itemChances = {},
	}

	--[[
	[17322] = {
		itemNecessario = {id = 44785, quantidade = 1},
		pisosPorRoleta = 11,
		posicaoDoCentro = Position(32512, 32401, 7),
		items = ...
	},
	]]--
}

-- #######################################################################################################

local Constantes = {
	DUMMY_NAME = "R",
	PLAY_STATUS_ROLLING = 0,
	PLAY_STATUS_PENDING = 1,
	PLAY_STATUS_DELIVERED = 2,
}

-- #######################################################################################################

local random = math.random
local function generate_uuid()
	local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
	return string.gsub(template, '[xy]', function(c)
		local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
		return string.format('%x', v)
	end)
end

local function inserirRecompensaDaRoletaNoBancoDeDados(uuid, playerId, recompensa)
	local tempoAgora = os.time()
	db.query("INSERT INTO `roleta_plays` (`player_id`, `uuid`, `recompensa_id`, `recompensa_quantidade`, `created_at`, `updated_at`) VALUES (" ..
		playerId .. ", " .. db.escapeString(uuid) .. ", " .. recompensa.id .. ", " .. recompensa.quantidade .. ", " .. tempoAgora .. ", " .. tempoAgora .. ");")
end

local function atualizarStatusDaEntregaDaRecompensaDaRoletaNoBancoDeDados(uuid, status)
	db.query("UPDATE `roleta_plays` SET `status` = " .. status .. ", `updated_at` = " .. os.time() .. " WHERE `uuid` = " .. db.escapeString(uuid) .. ";")
end

local function retornarDadosDaRecompensaDaRoletaNoBancoDeDados(uuid)
	local retornoDaConsulta = db.storeQuery("SELECT `player_id`, `recompensa_id`, `recompensa_quantidade` FROM `roleta_plays` WHERE `uuid` = " .. db.escapeString(uuid) .. ";")
	if retornoDaConsulta then
		local guild = Result.getNumber(retornoDaConsulta, 'player_id')
		local recompensaId = Result.getNumber(retornoDaConsulta, 'recompensa_id')
		local recompensaQuantidade = Result.getNumber(retornoDaConsulta, 'recompensa_quantidade')
		Result.free(retornoDaConsulta)

		return {
			playerGuid = guild,
			uuid = uuid,
			id = recompensaId,
			quantidade = recompensaQuantidade
		}
	end
end

local function retornarDadosDaRecompensaDaRoletaNoBancoDeDadosDeJogadoresComStatusDePendencia(playerGuid)
	local recompensas = {}

	local retornoDaConsulta = db.storeQuery("SELECT `uuid`, `recompensa_id`, `recompensa_quantidade` FROM `roleta_plays` WHERE `player_id` = " .. playerGuid .. " AND `status` = 1;")
	if retornoDaConsulta then
		repeat
			local uuid = Result.getString(retornoDaConsulta, 'uuid')
			local recompensaId = Result.getNumber(retornoDaConsulta, 'recompensa_id')
			local recompensaQuantidade = Result.getNumber(retornoDaConsulta, 'recompensa_quantidade')

			recompensas[#recompensas + 1] = {
				uuid = uuid,
				id = recompensaId,
				quantidade = recompensaQuantidade
			}
		until not Result.next(retornoDaConsulta)
		Result.free(retornoDaConsulta)
	end

	return recompensas
end

local function atualizarJogadoresComRoletaEmUsoNoBancoDeDados()
	db.query("UPDATE `roleta_plays` SET `status` = 1 WHERE `status` = 0;")
end

-- #######################################################################################################

local function entregarRecompensaDaRoleta(player, recompensa)
	local item = Game.createItem(recompensa.id, recompensa.quantidade)
	if not item then
		return false
	end

	if player:addItemEx(item) ~= RETURNVALUE_NOERROR then
		player:sendTextMessage(MESSAGE_FAILURE, "The item could not be delivered. Check if your backpack has space and relogin.")
		atualizarStatusDaEntregaDaRecompensaDaRoletaNoBancoDeDados(recompensa.uuid, Constantes.PLAY_STATUS_PENDING)
		return false
	end

	atualizarStatusDaEntregaDaRecompensaDaRoletaNoBancoDeDados(recompensa.uuid, Constantes.PLAY_STATUS_DELIVERED)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Congratulations, you received %dx %s.",
		recompensa.quantidade,
		ItemType(recompensa.id):getName()
	))

	return true
end

-- #######################################################################################################

local MAX_DROPSET_RATE = 10000

local function gerarPosicoesDaRoleta(actionId)
	local roleta = roletasConfig[actionId]
	if not roleta then
		return
	end

	local posDoCentro = roleta.posicaoDoCentro
	roleta.posicoes = {}

	local half = math.floor(roleta.pisosPorRoleta / 2)
	roleta.startPosition = Position(posDoCentro.x - half, posDoCentro.y, posDoCentro.z)
	roleta.endPosition = Position(posDoCentro.x + half, posDoCentro.y, posDoCentro.z)

	for i = 0, roleta.pisosPorRoleta - 1 do
		local pos = roleta.startPosition + Position(i, 0, 0)
		local tile = Tile(pos)
		if tile then
			roleta.posicoes[#roleta.posicoes + 1] = pos
		end
	end
end

local function limparManequinsDaRoleta(posicoesDaRoleta)
	for _, posicao in ipairs(posicoesDaRoleta) do
		local tile = Tile(posicao)
		if tile then
			local manequim = tile:getTopCreature()
			if manequim then
				posicao:sendMagicEffect(CONST_ME_POFF)
				manequim:remove()
			end
		end
	end
end

local function slotRegistrarChanceItem(roleta, item)
	local rate = item.chance

	if rate < 0.01 or rate > 100 then
		print("Item with id %d cannot be less than 0.01% or greater than 100%.")
		return false
	end

	for i = 1, (rate / 100) * MAX_DROPSET_RATE do
		roleta.itemChances[#roleta.itemChances + 1] = item
	end
end

local function slotCarregarChances(actionId)
	local roleta = roletasConfig[actionId]
	if not roleta then
		return
	end

	roleta.itemChances = {}

	for _, item in pairs(roleta.items) do
		slotRegistrarChanceItem(roleta, item)
	end

	local itemChancesTotalTabela = #roleta.itemChances
	if itemChancesTotalTabela ~= MAX_DROPSET_RATE then
		logger.info(string.format("action %d has not precise drop, result: %s%%", roletaActionId, (itemChancesTotalTabela / MAX_DROPSET_RATE) * 100))
	end
end

local function SlotConstruirAnimacaoItems(roleta, recompensaId)
	local list = {}

	local metadeDosTiles = math.floor(roleta.pisosPorRoleta / 2)
	local itemsQuantidade = 42

	for i = 1, itemsQuantidade do
		local itemId = roleta.itemChances[math.random(#roleta.itemChances)].id
		if i == (itemsQuantidade - metadeDosTiles) then
			itemId = recompensaId
		end

		list[#list + 1] = itemId
	end

	return list
end

local function preparacaoDaEntregaDaRecompensaDaRoleta(uuid)
	local recompensa = retornarDadosDaRecompensaDaRoletaNoBancoDeDados(uuid)
	if not recompensa then
		return false
	end

	local player = Player(recompensa.playerGuid)
	if not player then
		atualizarStatusDaEntregaDaRecompensaDaRoletaNoBancoDeDados(recompensa.uuid, Constantes.PLAY_STATUS_PENDING)
		return false
	end

	entregarRecompensaDaRoleta(player, recompensa)
end

-- #######################################################################################################

local function animacaoDoMovimentoDoManaquimDaRoleta(roleta, velocidade)
	local posicao = Position(roleta.startPosition)
	for i = 1, roleta.pisosPorRoleta do
		local piso = Tile(posicao)
		if piso then
			local manequim = piso:getTopCreature()
			if manequim then
				if posicao.x == roleta.startPosition.x then
					manequim:remove()
				else
					manequim:setSpeed(velocidade)
					manequim:move(DIRECTION_WEST)
				end
			end
			posicao.x = posicao.x + 1
		end
	end
end

local function animacaoAoCriarUmManequim(roleta, velocidadePadrao, lookTypeEx)
	local manequim = Game.createMonster(Constantes.DUMMY_NAME, roleta.endPosition, false, true)
	if manequim then
		manequim:setSpeed(velocidadePadrao) -- setBaseSpeed
		manequim:setOutfit { lookTypeEx = lookTypeEx }
	end
	return manequim
end

local function animacaoDeJogarJogosDeArtificioNaRoleta(roleta)
	local quantidade = 0

	local function decrease()
		if roleta.emUso then
			return
		end

		local time = 20 - quantidade
		if time > 0 then
			quantidade = quantidade + 1
			for _, posicao in ipairs(roleta.posicoes) do
				posicao:sendMagicEffect(CONST_ME_PIXIE_EXPLOSION)
			end
			addEvent(decrease, 850)
		end
	end

	decrease()
end

local function AnimationDrawRecompensaHighlight(positionsTable, recompensaId)
	for _, posicao in ipairs(positionsTable) do
		local piso = Tile(posicao)
		if piso then
			local manequim = piso:getTopCreature()
			if manequim then
				manequim:setOutfit { lookTypeEx = recompensaId }
				manequim:getPosition():sendMagicEffect(CONST_ME_HEARTS)
				manequim:getPosition():sendMagicEffect(CONST_ME_HOLYDAMAGE)
			end
		end
	end
end

local function AnimationStart(args)
	local speeds = {}
	local events = {}

	-- Velocidade base (início/fim) e pico (meio da animação)
	-- Ajusta estes dois valores para controlar o feeling da animação:
	--   baseSpeed -> quão devagar começa e termina (valor mais baixo = mais lento)
	--   topSpeed  -> velocidade máxima no meio da animação
	local frameCount = 42
	local baseSpeed  = 900
	local topSpeed   = 6500

	-- Curva em arco suave: acelera na 1ª metade, desacelera na 2ª metade
	-- O intervalo entre frames é sempre derivado da velocidade (100000 / speed),
	-- garantindo que o cliente tem tempo de animar o movimento antes do próximo frame
	for i = 1, frameCount do
		local phase = i / frameCount  -- 0.0 → 1.0

		local speed
		if phase < 0.5 then
			-- acelera progressivamente na primeira metade
			speed = baseSpeed + (topSpeed - baseSpeed) * (phase * 2)
		else
			-- desacelera progressivamente na segunda metade (espelho)
			speed = topSpeed - (topSpeed - baseSpeed) * ((phase - 0.5) * 2)
		end

		speeds[i] = math.floor(speed)
		events[i] = math.floor(100000 / speed)  -- proporcional à velocidade
	end

	local roleta = args.roleta
	local recompensaId = args.recompensa.id
	local animationItems = SlotConstruirAnimacaoItems(roleta, recompensaId)
	local i = 1
	local function move()
		animacaoDoMovimentoDoManaquimDaRoleta(roleta, speeds[i])
		animacaoAoCriarUmManequim(roleta, speeds[i], animationItems[i])
		if i >= frameCount then
			addEvent(function()
				roleta.startPosition:sendDistanceEffect(roleta.posicaoDoCentro, CONST_ANI_SMALLICE)
				roleta.endPosition:sendDistanceEffect(roleta.posicaoDoCentro, CONST_ANI_SMALLICE)
				roleta.posicaoDoCentro:sendMagicEffect(CONST_ME_PINK_VORTEX)

				addEvent(function()
					args.aoFinalizarJogada()
					if args.recompensa.raro then
						animacaoDeJogarJogosDeArtificioNaRoleta(roleta)
						AnimationDrawRecompensaHighlight(roleta.posicoes, recompensaId)
					end
				end, 500)
			end, 700)
		else
			addEvent(move, events[i])
		end

		i = i + 1
	end
	move()
end

-- #######################################################################################################

local function girarRoleta(player, roleta, item)
    if roleta.emUso then
        player:sendCancelMessage("Wait to spin.")
        return false
    end

    local recompensa = roleta.itemChances[math.random(#roleta.itemChances)]
    if not recompensa then
        player:sendTextMessage(MESSAGE_FAILURE, "Something is wrong, contact the administrator.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    local itemNecessario = roleta.itemNecessario
    local itemNecessarioName = ItemType(itemNecessario.id):getName()

    if not player:removeItem(itemNecessario.id, itemNecessario.quantidade) then
        player:sendTextMessage(MESSAGE_FAILURE, string.format("You need %dx %s to spin.",
            itemNecessario.quantidade,
            itemNecessarioName
        ))
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    if item.itemid == 21126 then
        item:transform(21130)
    elseif item.itemid == 21130 then
        item:transform(21126)
    end

    roleta.uuid = generate_uuid()
    inserirRecompensaDaRoletaNoBancoDeDados(roleta.uuid, player:getGuid(), recompensa)

    roleta.emUso = true -- Atualiza o estado da roleta para "em uso"

    local aoFinalizarJogada = function()
        preparacaoDaEntregaDaRecompensaDaRoleta(roleta.uuid)
        roleta.emUso = false -- Atualiza o estado da roleta para "não em uso"

        if recompensa.raro then
            Game.broadcastMessage(string.format("[Roulette]: Player %s found %dx %s, amazing.",
                player:getName(),
                recompensa.quantidade,
                ItemType(recompensa.id):getName()
            ), MESSAGE_EVENT_ADVANCE)
        end
    end

    AnimationStart({
        roleta = roleta,
        recompensa = recompensa,
        aoFinalizarJogada = aoFinalizarJogada
    })

    return true
end

local function roletaStartup()
    atualizarJogadoresComRoletaEmUsoNoBancoDeDados()

    for actionId, value in pairs(roletasConfig) do
        gerarPosicoesDaRoleta(actionId)
        slotCarregarChances(actionId)
    end
end

local globalevent = GlobalEvent("RouletteMega")
function globalevent.onStartup()
    roletaStartup()
end

globalevent:register()

local action = Action()

function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local roleta = roletasConfig[item.actionid]
    if not roleta then
        player:sendTextMessage(MESSAGE_FAILURE, "Slot not implemented yet.")
        item:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    girarRoleta(player, roleta, item)

    return true
end

action:position(roletasConfig[roletaActionId].leverPosition)
action:register()

local creatureevent = CreatureEvent('Roleta_Login')

function creatureevent.onLogin(player)
    local pendingPlayrecompensas = retornarDadosDaRecompensaDaRoletaNoBancoDeDadosDeJogadoresComStatusDePendencia(player:getGuid())

    if #pendingPlayrecompensas > 0 then
        for _, recompensa in ipairs(pendingPlayrecompensas) do
            entregarRecompensaDaRoleta(player, recompensa)
        end
    end

    return true
end

creatureevent:register()

-- #######################################################################################################

--[[
local ec = EventCallback
ec.onLook = function(self, thing, position, distance, description)
	if thing:getName() == Constantes.DUMMY_NAME then
		local item = ItemType(thing:getOutfit().lookTypeEx)

		return ('You see %s.\n%s'):format(
			item:getName(),
			item:getDescription()
		)
	end
	return description
end
ec:register(1)
]]--
