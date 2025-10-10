local enums = {}

enums.ShopItemType = {
	RobuxOnly = "RobuxOnly",
	MoneyOnly = "MoneyOnly",
	RobuxAndMoney = "RobuxAndMoney",
	GroupJoin = "GroupJoin",
	StartsWith = "StartsWith",
	EasterEgg = "EasterEgg",
}

enums.EndGameScreen = {
	Win = "Win",
	Lose = "Lose",
	Afk = "Afk",
	Trolled = "Trolled",
	EasterEgg = "EasterEgg",
}

enums.Analytics = {
	Onboarding = {
		Joined = { Name = "Joined", step = 1, stepname = "Player Joined" },
		StartedFirstGame = { Name = "StartedFirstGame", step = 2, stepname = "First game started" },
		CompletedFirstGame = { Name = "CompletedFirstGame", step = 3, stepname = "First game completed" },
		BoughtFirstItem = { Name = "BoughtFirstItem", step = 4, stepname = "First item bought" },
		TotalSteps = 4,
	},

	Shop = {
		Opened = { Name = "Opened", step = 1, stepname = "Shop opened" },
		SwitchOverview = { Name = "SwitchOverview", step = 2, stepname = "Viewed other shop window" },
		TryBuy = { Name = "TryBuy", step = 3, stepname = "Tried to buy item (insufficient funds)" },
		BuyItem = { Name = "BuyItem", step = 4, stepname = "Purchased item" },
		EquipItem = { Name = "EquipItem", step = 5, stepname = "Equipped purchased item" },
		Closed = { Name = "Closed", step = 6, stepname = "Shop closed" },
		SessionName = "Shop",
		TotalSteps = 6,
	},

	PlaytimeRewards = {
		Reached5Min = { Name = "Reached5Min", step = 1, stepname = "Reached 5 minutes of playtime" },
		Clicked5MinReward = { Name = "Clicked5MinReward", step = 2, stepname = "Clicked 5-minute reward" },
		Reached10Min = { Name = "Reached10Min", step = 3, stepname = "Reached 10 minutes of playtime" },
		Clicked10MinReward = { Name = "Clicked10MinReward", step = 4, stepname = "Clicked 10-minute reward" },
		Reached15Min = { Name = "Reached15Min", step = 5, stepname = "Reached 15 minutes of playtime" },
		Clicked15MinReward = { Name = "Clicked15MinReward", step = 6, stepname = "Clicked 15-minute reward" },
		SessionName = "PlaytimeRewards",
		TotalSteps = 6,
	},

	EasyObby = {
		Started = { Name = "Started", step = 1, stepname = "Easy obby started" },
		Died = { Name = "Died", step = 2, stepname = "Died on easy obby" },
		Completed = { Name = "Completed", step = 3, stepname = "Completed easy obby" },
		SessionName = "EasyObby",
	},

	MediumObby = {
		Started = { Name = "Started", step = 1, stepname = "Medium obby started" },
		Died = { Name = "Died", step = 2, stepname = "Died on medium obby" },
		Completed = { Name = "Completed", step = 3, stepname = "Completed medium obby" },
		SessionName = "MediumObby",
	},

	HardObby = {
		Started = { Name = "Started", step = 1, stepname = "Hard obby started" },
		Died = { Name = "Died", step = 2, stepname = "Died on hard obby" },
		Completed = { Name = "Completed", step = 3, stepname = "Completed hard obby" },
		SessionName = "HardObby",
	},

	OpObby = {
		Started = { Name = "Started", step = 1, stepname = "OP obby started" },
		Died = { Name = "Died", step = 2, stepname = "Died on OP obby" },
		Completed = { Name = "Completed", step = 3, stepname = "Completed OP obby" },
		SessionName = "OpObby",
	},

	Game = {
		StartedGame = { Name = "StartedGame", step = 1, stepname = "Joined a game" },
		FlushedToilet = { Name = "FlushedToilet", step = 2, stepname = "Flushed toilet" },
		TryUseAction = { Name = "TryUseAction", step = 3, stepname = "Tried to use an action" },
		UsedActon = { Name = "UsedActon", step = 4, stepname = "Used an action" },
		FinishedGame = { Name = "FinishedGame", step = 5, stepname = "Finished a game" },
		SessionName = "Game",
	},
}

enums.Actions = {}

return enums
