local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local economyFunnels = {}

local function MockFunnel(
	player: Player,
	flowType: Enum.AnalyticsEconomyFlowType,
	currencyType: "Money" | "Robux" | "Wins" | "WinStreak",
	toAddRemove: number,
	endBalance: number,
	transactionType: string,
	Identifier: string?
)
	local s = Identifier or "nil"
	print(
		`[LOGGING TRANSACTION] Player: {player.UserId} `
			.. `FlowType: {flowType.Name} `
			.. `TransactionType: {transactionType} `
			.. `MoneyToAddOrRemove: {toAddRemove} `
			.. `EndBalance: {endBalance} `
			.. `CurrencyType: {currencyType} `
			.. `Identifier: {s}`
	)
end

function economyFunnels.LogEconomyEventPlayers(
	players: { Player },
	flowType: Enum.AnalyticsEconomyFlowType,
	currencyType: "Money" | "Robux" | "Wins" | "WinStreak",
	toAddRemove: number,
	endBalance: number,
	transactionType: string,
	Identifier: string?
)
	task.defer(function()
		for _, player in ipairs(players) do
			AnalyticsService:LogEconomyEvent(
				player,
				flowType,
				currencyType,
				toAddRemove,
				endBalance,
				transactionType,
				Identifier
			)
			MockFunnel(player, flowType, currencyType, toAddRemove, endBalance, transactionType, Identifier)
		end
	end)
end

function economyFunnels.LogEconomyEventPlayerIds(
	playerIds: { string },
	flowType: Enum.AnalyticsEconomyFlowType,
	currencyType: "Money" | "Robux" | "Wins" | "WinStreak",
	toAddRemove: number,
	endBalance: number,
	transactionType: string,
	Identifier: string?
)
	task.defer(function()
		for _, playerId in ipairs(playerIds) do
			local player = Players:GetPlayerByUserId(playerId)

			if player then
				AnalyticsService:LogEconomyEvent(
					player,
					flowType,
					currencyType,
					toAddRemove,
					endBalance,
					transactionType,
					Identifier
				)
				MockFunnel(player, flowType, currencyType, toAddRemove, endBalance, transactionType, Identifier)
			end
		end
	end)
end

return economyFunnels
