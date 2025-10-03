-- ModuleScript: PlatformEnum.lua
local enums = {}

enums.ShopItemType = {
	RobuxOnly = "RobuxOnly",
	MoneyOnly = "MoneyOnly",
	RobuxAndMoney = "RobuxAndMoney",
	GroupJoin = "GroupJoin",
	StartsWith = "StartsWith",
}

enums.EndGameScreen = {
	Win = "Win",
	Lose = "Lose",
	Afk = "Afk",
	Trolled = "Trolled",
}

enums.Analytics = {
	Onboarding = {
		Joined = { Name = "Joined", step = 1, stepname = "Player Joined" },
		StartedFirstGame = { Name = "StartedFirstGame", step = 2, stepname = "First game started" },
		CompletedFirstGame = { Name = "CompletedFirstGame", step = 3, stepname = "First game completed" },
		BoughtFirstItem = { Name = "BoughtFirstItem", step = 4, stepname = "First item bought" },
		TotalSteps = 4,
	},
}

enums.Actions = {}

return enums
