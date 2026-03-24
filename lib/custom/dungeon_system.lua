DUNGEON_SYSTEM = {
	Storages = {
		timerDungeon = 49356,
		timerCooldown = 50203,
		storageReward = 50205,
	},

	Modal = {
		IDType = 2049,
		TitleType = "Type Dungeon, by: Tataboy67",
		MsgType = "Select this type:",

		ID = 2050,
		Title = "Dungeon System, by: Tataboy67!",
		Msg = "Select your Dungeon:",

		IDDetails = 2051,
		TitleDetails = "Details Dungeon",
	},

	Messages = {
		ToEntry = "Welcome to Dungeon",
		ToFail = "You were unable to complete the dungeon\n\nPlease try again!",

		WaitFriendsCooldown = "Wait your friend: %s",
		ToCooldown = "You're in cooldown to enter in a dungeon again. Cooldown: %s.",
		MsgNeedLevel = "You don't have level required. You need level %s.",
		MsgUniqueNeedParty = "You need party, to entry in dungeon",
		MsgNeedParty = "You need to be at a party to enter the dungeon. You need %s players",
		MsgLeaderParty = "You are not the leader of the Party.",

		MsgDistanceLeader = "Your friends need to be close to you.",

		NeedPzSoloMsg = "You need to be in a safe area [PZ].",
		NeedPzMsg = "Your team needs to go a safe area [PZ].",

		PlayerInside = "Already has inside.",
	},

	CooldownTime = 1,
	PzToEntry = true,
	SQMsDistanceOfLeader = 5,

	Dungeons = {
		[1] = {
			Name = "Diabolic Hyper",
			NeedParty = true,
			AmountParty = 2,
			NeedLevel = false,
			Level = 50,
			DungeonTime = 10,
			DungeonPos = Position(32369, 32234, 7),
			FromPos = {x = 32369, y = 32234, z = 7},
			ToPos = {x = 1226, y = 940, z = 7},
			SpawnMonsters = true,
			Monsters = {
				["Demon"] = Position(1170, 934, 7),
				["Rat"] = Position(1170, 935, 7),
				["Hydra"] = Position(1167, 932, 7),
			},
		},

		[2] = {
			Name = "Supreme Rat's",
			NeedParty = false,
			AmountParty = 1,
			NeedLevel = false,
			Level = 50,
			DungeonTime = 10,
			DungeonPos = Position(1165, 934, 7),
			FromPos = {x = 32369, y = 32234, z = 7},
			ToPos = {x = 1226, y = 940, z = 7},
			SpawnMonsters = true,
			Monsters = {
				["Demon"] = Position(32369, 32234, 7),
				["Rat"] = Position(1170, 935, 7),
				["Hydra"] = Position(1167, 932, 7),
			},
		},

		[3] = {
			Name = "Triple",
			NeedParty = true,
			AmountParty = 3,
			NeedLevel = false,
			Level = 50,
			DungeonTime = 10,
			DungeonPos = Position(1165, 934, 7),
			FromPos = {x = 1161, y = 930, z = 7},
			ToPos = {x = 1226, y = 940, z = 7},
			SpawnMonsters = true,
			Monsters = {
				["Demon"] = Position(1170, 934, 7),
				["Rat"] = Position(1170, 935, 7),
				["Hydra"] = Position(1167, 932, 7),
			},
		},
	}
}

function Player.sendDungeonTypeModal(self)
	local modal = ModalWindow {
		title = DUNGEON_SYSTEM.Modal.TitleType,
		message = DUNGEON_SYSTEM.Modal.MsgType,
	}

	-- Debug log: ao criar modal
	self:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[DEBUG] Criando modal de dungeon")

	for index, dungeon in pairs(DUNGEON_SYSTEM.Dungeons) do
		modal:addChoice(dungeon.Name, function(player, button, choice)
			-- Debug log: quando clicado numa dungeon
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[DEBUG] Botao '" .. button.name .. "' clicado na dungeon '" .. dungeon.Name .. "'")

			if button.name ~= "Enter" then
				return true
			end

			if not DUNGEON_SYSTEM.Dungeons[index] then
				player:sendCancelMessage("Invalid dungeon selected.")
				return true
			end

			player:teleportTo(dungeon.DungeonPos)
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			player:sendTextMessage(MESSAGE_INFO_DESCR, DUNGEON_SYSTEM.Messages.ToEntry)

			return true
		end)
	end

	modal:addButton("Enter")
	modal:addButton("Cancel")
	modal:setDefaultEnterButton(1)
	modal:setDefaultEscapeButton(2)
	modal:sendToPlayer(self)

	-- Debug log: modal enviado
	self:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[DEBUG] Modal enviado para o player")
end

local talkAction = TalkAction("!dungeon", function(player, words, param)
	-- Debug log: comando digitado
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[DEBUG] Comando !dungeon digitado")

	if DUNGEON_SYSTEM.PzToEntry then
		if not player:isInPz() then
			player:sendTextMessage(MESSAGE_STATUS_SMALL, DUNGEON_SYSTEM.Messages.NeedPzSoloMsg)
			return false
		else
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[DEBUG] Player está em PZ")
		end
	end

	player:sendDungeonTypeModal()
	return false
end)

talkAction:separator(" ")
talkAction:groupType("normal")
talkAction:register()
