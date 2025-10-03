export type PlayerRewardsData = {
	DoubleRewards: boolean,
}

export type Globals = {
	flushStarted: boolean,
	group: { [string]: PlayerRewardsData },
	premium: { [string]: PlayerRewardsData },
	BlowBackDir: Vector3,
}

local globals: Globals = {
	flushStarted = false,
	group = {},
	premium = {},
	BlowBackDir = Vector3.new(0, 1, 1),
}

return globals
