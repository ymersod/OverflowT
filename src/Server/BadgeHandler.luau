local BadgeService = game:GetService("BadgeService")
local badgeHandler = {}

local badges = {
	[1] = {
		BadgeId = 1278113049094639,
		name = "T",
	},
	[2] = {
		BadgeId = 2044484092123435,
		name = "O",
	},
	[3] = {
		BadgeId = 2319748316983710,
		name = "I",
	},
	[4] = {
		BadgeId = 3285216877704453,
		name = "L",
	},
	[5] = {
		BadgeId = 4119807668478742,
		name = "E",
	},
}

function badgeHandler.GiveBadges(player: Player)
	task.defer(function()
		if BadgeService:UserHasBadgeAsync(player.UserId, 1278113049094639) then
			return
		end
		for _, badge in ipairs(badges) do
			local success, result = pcall(function()
				return BadgeService:AwardBadge(player.UserId, badge.BadgeId)
			end)

			if success then
				if result then
					print(player.Name .. " has received the badge!")
				else
					print(player.Name .. " already has this badge.")
				end
			else
				warn("Failed to award badge: " .. tostring(result))
			end
		end
	end)
end

return badgeHandler
