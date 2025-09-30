export type PlayerGroupData = {
	DoubleRewards: boolean,
}

export type Globals = {
	flushStarted: boolean,
	group: { [string]: PlayerGroupData },
}

local globals: Globals = {
	flushStarted = false,
	group = {},
}

return globals
