--[[

###############
### CREDITS ###
###############

Idea: Truelch
Code: Truelch
Art : Truelch


############
### MISC ###
############

Upgrade: can target pawn tile: sounds a bit too good when RNG is with the player.

Should it be possible to target:
- Chasm tiles? <---------------- NO
- Cracked tiles?
- spawns -> never happened <------- NO
]]

Jefepassives_Waterfall = PassiveSkill:new{
	--Infos
	Name = "Water-Former",
	Description = "At the start of your turn, change 2 unoccupied tiles into water.",
	PowerCost = 0,
	Icon = "weapons/passives/passive_waterfall.png",

	--Passive
	Passive = "Jefepassives_Waterfall",

	--Tip image
	TipImage = {
		Unit = Point(2, 3),
		Target = Point(2, 1),
	}
}

function Jefepassives_Waterfall:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	ret:AddScript([[
		local damage = SpaceDamage(Point(2, 2), 0)
		damage.sAnimation = "Splash"
		Board:AddEffect(damage)
		Board:SetWeather(5, RAIN_NORMAL, Point(2, 2), Point(1, 1), 2)
		Board:SetTerrain(Point(2, 2), TERRAIN_WATER)
		Board:AddAlert(Point(2, 2), "Water-forming")
	]])

	return ret
end

--[[
Need to check:
- Regular train
- Armored train
- Nautilus' cart
]]
--[[
local function isTrainTrack(point)
	local train_track = {}

	--Try to find the train(s??)
	local size = Board:GetSize()
	for j = 0, size.y do
		for i = 0, size.x do
			local curr = Point(i, j)
			local train = Board:GetPawn(curr)
			if train:GetType() == "Train_Pawn" then
				for k = 0, size.y do
					local curr2 = Point(curr.x, k)
					if curr2 == point then
						return true
					end
				end
			end
		end
	end

	return false
end
]]

--for j = 0, 7 do for i = 0, 7 do if Board:IsSpawning(Point(i, j)) then LOG("Spawning at: "..Point(i, j):GetString()) end end end
local function getRandomPos(points)
	local list = {}

	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)

			--[[
			local customTile = Board:GetCustomTile(curr)
			if customTile ~= nil and customTile ~= "" then
				LOG("Custom tile: "..customTile.." at: "..curr:GetString())
			end
			]]

			local unauthorizeTerrains = { TERRAIN_WATER, TERRAIN_HOLE }

			--Train (and armored trains allegedly): "ground_rail.png"

			--maybe I should allow tiles occupied by pawns? I don't think so but I'm asking myself
			if not Board:IsBlocked(curr, PATH_PROJECTILE)
				and not Board:IsItem(curr)
				and not Board:IsPod(curr)
				and not list_contains(unauthorizeTerrains, Board:GetTerrain(curr))
				--and not Board:IsTerrain(curr, TERRAIN_WATER) --it still happened twice on the same tile
				--and not isTrainTrack(curr)
				and (Board:GetCustomTile(curr) == nil or Board:GetCustomTile(curr) == "")
				and not list_contains(points, curr) --this should fix the fact that I got twice the same point
				and not Board:IsSpawning(curr)
				then
					list[#list + 1] = curr
			end
		end
	end

	--Pick a random one
	if #list > 0 then
		return list[math.random(1, #list)]
	else
		LOG("getRandomTile() -> nil")
		return nil
	end
end

local function computeWaterSpawns()
	local m = GetCurrentMission()

	if m == nil or m.passive_water_spawns == nil then
		--LOG("m == nil or m.passive_water_spawns == nil")
		return
	end

	local effect = SkillEffect()
	for _, pos in ipairs(m.passive_water_spawns) do

		if pos == nil then
			--LOG(" -> computeWaterSpawns -> loop -> pos is nil!")
		end

		local damage = SpaceDamage(pos, 0)
		damage.sAnimation = "Splash"
		effect:AddDamage(damage)

		effect:AddScript([[
			Board:SetWeather(5, RAIN_NORMAL, ]]..pos:GetString()..[[, Point(1, 1), 2)
			Board:SetTerrain(]]..pos:GetString()..[[, TERRAIN_WATER)
			Board:AddAlert(]]..pos:GetString()..[[, "Water-forming")]])
		effect:AddSound("/props/tide_flood")
		effect:AddBounce(pos, 6) --was -6
		effect:AddDelay(2)
	end
	Board:AddEffect(effect)
end

local EVENT_onNextTurn = function(mission)
	if IsPassiveSkill("Jefepassives_Waterfall") then
		if Game:GetTeamTurn() == TEAM_PLAYER then
			local spawnAmount = 2

			--redundant with mission?
			local m = GetCurrentMission()
			if m == nil then
				LOG("mission is nil, WTF!")
				return
			end

			m.passive_water_spawns = {} --necessary again I think

			for i = 1, spawnAmount do
				m.passive_water_spawns[#m.passive_water_spawns+1] = getRandomPos(m.passive_water_spawns)
			end

			computeWaterSpawns()

		--[[
		elseif Game:GetTeamTurn() == TEAM_ENEMY then
			local m = GetCurrentMission()
			if m == nil then
				LOG("mission is nil, WTF!")
				return
			else
				m.passive_water_spawns = {}
			end

		]]
		end
	end
end
modApi.events.onNextTurn:subscribe(EVENT_onNextTurn)

--TODO: clear at player end turn the mission.passive_water_spawns data?
local EVENT_onResetTurn = function(mission)
	modApi:scheduleHook(550, function() --can't recall if it's really a needed precaution, but...
		local m = GetCurrentMission()
		--if mission ~= nil and mission.passive_water_spawns ~= nil then
		if m ~= nil and m.passive_water_spawns ~= nil then
			--LOG("EVENT_onResetTurn -> mission.passive_water_spawns: "..tostring(#mission.passive_water_spawns))
			--LOG("EVENT_onResetTurn -> m.passive_water_spawns: "..tostring(#m.passive_water_spawns))
			--computeWaterSpawns(mission.passive_water_spawns)
			computeWaterSpawns(m.passive_water_spawns)
		end
	end)
end
modapiext.events.onResetTurn:subscribe(EVENT_onResetTurn)