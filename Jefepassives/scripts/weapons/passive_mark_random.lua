Jefepassives_MarkRandom = PassiveSkill:new{
	--Infos
	Name = "AESA Radar", --"Passive Radar"
	Description = "At player's turn start, mark a random enemy.",
	PowerCost = 1,
	Icon = "weapons/passives/passive_mark_random.png", --TODO

	--Passive
	Passive = "Jefepassives_MarkRandom",

	--Tip image
	TipImage = {
		Unit   = Point(2, 3),
		Target = Point(2, 1),
		Enemy1 = Point(2, 1),
		Length = 2, --test
	}
}

function Jefepassives_MarkRandom:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	
	ret:AddDelay(1)

	--[[
	Board:AddAlert(p2, "MARKED")
	Board:AddAnimation(p2, "truelch_tip_mark_medium", 1)
	]]

	ret:AddScript([[		
		Board:AddAlert(]]..p2:GetString()..[[, "MARKED")
		Board:AddAnimation(]]..p2:GetString()..[[, "truelch_tip_mark_medium", 1)
	]])

	return ret
end

local EVENT_onNextTurn = function(mission)
	if Game:GetTeamTurn() == TEAM_PLAYER and IsPassiveSkill("Jefepassives_MarkRandom") then
		--LOG("Jefepassives_MarkRandom -> EVENT_onNextTurn")
		--redundant with mission?
		local m = GetCurrentMission()
		if m == nil then
			LOG("m == nil WTF!")
		else
			m.passive_marked = {}
		end
		
		local markAmount = 1
		local markables = {} --pawns that can be marked (enemies that aren't already marked)

		--LOG(">>>>> markables:")
		for j = 0, 7 do
			for i = 0, 7 do
				local curr = Point(i, j)
				local pawn = Board:GetPawn(Point(i, j))
				if pawn ~= nil and pawn:IsEnemy() and truelch_mark_lib:canMark(curr) then
					--LOG(" -> markable: "..pawn:GetType())
					markables[#markables+1] = pawn
				end
			end
		end

		--LOG("Jefepassives_MarkRandom -> truelch_mark_lib: "..tostring(truelch_mark_lib))

		local effect = SkillEffect()

		--LOG(">>>>> marked:")
		for i = 1, markAmount do
			if #markables > 0 then
				local randIndex = math.random(1, #markables)
				local pawn = markables[randIndex]
				table.remove(markables, randIndex)

				local damage = SpaceDamage(pawn:GetSpace(), 0)
				truelch_mark_lib:markEnemy(effect, damage, pawn)
				effect:AddDamage(damage)
				Board:AddAlert(pawn:GetSpace(), "MARKED")

				--LOG(" -> marked: "..pawn:GetType()..", id: "..tostring(pawn:GetId()))

				--Save in mission data
				m.passive_marked[#m.passive_marked+1] = pawn:GetId()
			else
				--LOG("No more markables!")
				break
			end
		end

		Board:AddEffect(effect)
	end
end
modApi.events.onNextTurn:subscribe(EVENT_onNextTurn)

local function reapplyMark()
	--LOG("Jefepassives_MarkRandom -> reset turn -> OK!")

	local m = GetCurrentMission()

	if m ~= nil then
		--LOG("---> m ~= nil, m.passive_marked: "..tostring(#m.passive_marked))
		local effect = SkillEffect()

		for _, pawnId in ipairs(m.passive_marked) do
			local pawn = Board:GetPawn(pawnId)
			--LOG("pawnId: "..tostring(pawnId))
			if pawn ~= nil then
				local damage = SpaceDamage(pawn:GetSpace(), 0)
				truelch_mark_lib:markEnemy(effect, damage, pawn)
				effect:AddDamage(damage)
				Board:AddAlert(pawn:GetSpace(), "MARKED")
			else
				LOG("WTF")
			end
		end

		Board:AddEffect(effect)
	else
		--LOG("Jefepassives_MarkRandom -> reset turn -> ")
	end
end

local EVENT_onResetTurn = function(mission)

	modApi:scheduleHook(550, function() --TODO: change that into an appropriate conditional hook
		reapplyMark()
	end)

	--Okay, this wait is too short I think.
	--[[
	modApi:conditionalHook(
		function()
			LOG("Jefepassives_MarkRandom -> reset turn -> WAIT A FRAME")
			return GetCurrentMission() ~= nil
		end,
		function()
			reapplyMark()
		end
	)
	]]
end
modapiext.events.onResetTurn:subscribe(EVENT_onResetTurn)

--TODO: wait pre env to clear m.passive_marked data? -> Also do that for the other passives that do something similar.
local EVENT_onPreEnvironment = function(mission)
	if not IsPassiveSkill("Jefepassives_MarkRandom") then return end

	--Clear data
	local m = GetCurrentMission()
	if m == nil then
		--LOG("m == nil!")
		return
	end

	--LOG("EVENT_onPreEnvironment -> clear m.passive_marked")
	m.passive_marked = {} --clear
end
modApi.events.onPreEnvironment:subscribe(EVENT_onPreEnvironment)