export type PlayerRewardsData = {
	DoubleRewards: boolean,
}

export type Globals = {
	flushStarted: boolean,
	group: { [string]: PlayerRewardsData },
	premium: { [string]: PlayerRewardsData },
}

local globals: Globals = {
	flushStarted = false,
	group = {},
	premium = {},
}

return globals
