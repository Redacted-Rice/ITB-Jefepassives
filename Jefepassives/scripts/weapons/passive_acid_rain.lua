--[[
Idea: Truelch
Code: Truelch

Should the A.C.I.D. spawn be allowed on a tile occupied by a Pawn? Maybe only when upgraded.

Should the amount of A.C.I.D. spawns increase? Maybe when both upgraded, 1 -> 2?

TODO:
- maybe, after the start of mission (or at player's first turn), check whether
--> or just use a hook / event that a pawn is acidified? (does that exist?) It would cover more cases (like the modded Roach)

- I need to check if i'm not softlocking when a pawn move on ACID water!!
---> YES IT DOES! But only for non flying units apparently


>>>>>>>>> modapiext:addPawnIsAcidHook(function(mission, pawn, isAcid) --thx tosx!
-----------------> So that when a Mech is inflicted with ACID, the effect is also triggered!

https://github.com/tos-x/ITB-tosx_mods/blob/main/mods/other/mods/CauldronPilots/Scripts/pilot_cypher.lua
line 122 (and after) tosx does a weird complicated logic, I need to understand why.
This pilot DO neutralize A.C.I.D., but on the tile, not the pilot. Plus, it doesn't work either with push + A.C.I.D. (like A.C.I.D. Projector)

Acid without push: "Acid_Tank_Attack"
Acid with push: 


Check game loaded (continue) and turn reset.

Known issues:
- When there are two acid rains spawns, the weather shows up for only one of them (since there can be only one weather played at a given moment)
  -> I could add long delay and shorten the weather effect
]]


Jefepassives_AcidRain_Passive = PassiveSkill:new{
	--Infos
	Name = "A.C.I.D. Rain",
	Description = "At the start of every turn, create an A.C.I.D. pool randomly on the map.",
	PowerCost = 0,
	Icon = "weapons/passives/passive_acid_rain.png",

	--Upgrades
	Upgrades = 2,
	UpgradeCost = { 1, 2 },
	UpgradeList = { "Heal", "Boost" },

	--Passive
	Passive = "Jefepassives_AcidRain_Passive",

	--Tip image
	TipHeal = false,
	TipBoost = false,
	TipImage = {
		Unit = Point(2, 3), --is actually the acid tank
		CustomPawn = "Acid_Tank",
		Friendly = Point(2, 1), --is the mech
		Target = Point(2, 1),
		Acid1  = Point(2, 1),
	},
}

function Jefepassives_AcidRain_Passive:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	if not self.TipHeal and not self.TipBoost then
		ret:AddScript([[
			Board:SetWeather(5, RAIN_ACID, Point(2, 2), Point(1, 1), 2)
			Board:SetAcid(Point(2, 2), true)
			Board:AddAlert(Point(2, 2), "A.C.I.D. RAIN")
		]])
	else
		Board:GetPawn(p2):SetHealth(1)

		--Shoot acid
		local direction = GetDirection(p2 - p1)
		local target = GetProjectileEnd(p1, p2, PATH_PROJECTILE)
		local d2 = SpaceDamage(target, 0)
		d2.iAcid = 1
		d2.sAnimation = "ExploAcid1"
		ret:AddProjectile(d2, "effects/shot_tankacid", FULL_DELAY) --NO_DELAY

		--Heal / boost
		if self.TipHeal then
			local d3 = SpaceDamage(p2, 0)
			d3.iDamage = -1
			ret:AddDamage(d3)
		end
		if self.TipBoost then
			ret:AddScript("Board:GetPawn(Point(2, 1)):SetBoosted(true)")
		end
	end

	return ret
end

Jefepassives_AcidRain_Passive_A = Jefepassives_AcidRain_Passive:new{
	UpgradeDescription = "Standing on A.C.I.D. removes A.C.I.D. and repairs Mech.\nA.C.I.D. can now appear on pawns.\nPowering both upgrades increases the A.C.I.D. spawn amount by 1.",
	TipHeal = true,
	Passive = "Jefepassives_AcidRain_Passive_A",
}

Jefepassives_AcidRain_Passive_B = Jefepassives_AcidRain_Passive:new{
	UpgradeDescription = "Standing on A.C.I.D. removes A.C.I.D. and gives the Mech Boost.\nA.C.I.D. can now appear on pawns.\nPowering both upgrades increases the A.C.I.D. spawn amount by 1.",
	TipBoost = true,
	Passive = "Jefepassives_AcidRain_Passive_B",
}

Jefepassives_AcidRain_Passive_AB = Jefepassives_AcidRain_Passive:new{
	TipHeal = true,
	TipBoost = true,
	Passive = "Jefepassives_AcidRain_Passive_AB",
}

--Create A.C.I.D. pool randomly on the map
local function getRandomPos(allowPawns)
	local list = {}

	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)
			--maybe I should allow tiles occupied by pawns? I don't think so but I'm asking myself
			if (allowPawns and Board:IsPawnSpace(curr) or not Board:IsBlocked(curr, PATH_PROJECTILE))				 
				and not Board:IsItem(curr)
				--Or just exclude water?
				and (Board:GetTerrain(curr) == TERRAIN_ROAD or Board:GetTerrain(curr) == TERRAIN_FOREST or Board:GetTerrain(curr) == TERRAIN_SAND)
				--and not Board:IsFire(curr) --maybe?
				and not Board:IsAcid(curr) then
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

local function computeAcidSpawns(points)
	for _, pos in ipairs(points) do
		--Board:SetWeather(3, RAIN_ACID, Point(0,0), Point(8,8), 2)
		Board:SetWeather(5, RAIN_ACID, pos, Point(1, 1), 2) --maybe super intense just on the point?
		--Board:SetWeather(5, RAIN_ACID, pos - Point(1, 1), Point(2, 2), 2) --maybe super intense just on the point?
		Board:SetAcid(pos, true)
		Board:AddAlert(pos, "A.C.I.D. RAIN")
	end
end

local EVENT_onNextTurn = function(mission)
	if Game:GetTeamTurn() == TEAM_PLAYER then

		--Reset mission data
		local m = GetCurrentMission()
		if m == nil then
			LOG("mission is nil, WTF!")
			return
		else
			m.passive_acid_rain_boost = {}
			m.passive_acid_rain_spawns = {}
		end
		
		if IsPassiveSkill("Jefepassives_AcidRain_Passive") then --also works for upgraded versions right?

			local spawnAmount = 1
			if IsPassiveSkill("Jefepassives_AcidRain_Passive_AB") then
				spawnAmount = 2
			end

			local allowPawns = false
			if IsPassiveSkill("Jefepassives_AcidRain_Passive_A") or IsPassiveSkill("Jefepassives_AcidRain_Passive_B") then
				allowPawns = true
			end

			local points = {}

			for i = 1, spawnAmount do
				local pos = getRandomPos(allowPawns)

				points[#points+1] = pos

				--Save that in mission data so that in turn reset, I'll do this again with the exact same point(s)
				--Can't recall if we can save points in the mission data? -> apparently yes (according to my Hell Breachers at least)
				m.passive_acid_rain_spawns[#m.passive_acid_rain_spawns+1] = pos
			end

			computeAcidSpawns(points)
		end

	end
end
modApi.events.onNextTurn:subscribe(EVENT_onNextTurn)


local EVENT_onResetTurn = function(mission)
	--LOG("jefepassives_AcidRain_Passive -> EVENT_onResetTurn")
	modApi:scheduleHook(550, function() --can't recall if it's really a needed precaution, but...
		if mission ~= nil and mission.passive_acid_rain_spawns ~= nil then
			computeAcidSpawns(mission.passive_acid_rain_spawns)
		end
	end)
end
modapiext.events.onResetTurn:subscribe(EVENT_onResetTurn)

local HOOK_onPawnIsAcid = function(mission, pawn, isAcid)
	--IsPassiveSkill("jefepassives_AcidRain_Passive_B") should work for both _B and _AB but for some reason, it's false for _AB
	local isHeal  = IsPassiveSkill("Jefepassives_AcidRain_Passive_A") or IsPassiveSkill("Jefepassives_AcidRain_Passive_AB")
	local isBoost = IsPassiveSkill("Jefepassives_AcidRain_Passive_B") or IsPassiveSkill("Jefepassives_AcidRain_Passive_AB")

	--[[
	LOG(">>>>>>>>>> HOOK_onPawnIsAcid -> isHeal: "..tostring(isHeal)..", isBoost: "..tostring(isBoost))

	LOG("-> is jefepassives_AcidRain_Passive   : "..tostring(IsPassiveSkill("Jefepassives_AcidRain_Passive"   )))
	LOG("-> is jefepassives_AcidRain_Passive_A : "..tostring(IsPassiveSkill("Jefepassives_AcidRain_Passive_A" )))
	LOG("-> is jefepassives_AcidRain_Passive_B : "..tostring(IsPassiveSkill("Jefepassives_AcidRain_Passive_B" ))) --this was false with _AB, wtf
	LOG("-> is jefepassives_AcidRain_Passive_AB: "..tostring(IsPassiveSkill("Jefepassives_AcidRain_Passive_AB")))
	]]


	local m = GetCurrentMission()
	if m == nil then
		--LOG("mission is nil, WTF!")
		return
	end

	if not isHeal and not isBoost then
		return
	end

	--I can't recall if someone made a mod with enemy mechs, better be safe...
	if isHeal and pawn:IsMech() and not pawn:IsEnemy() then
		--LOG("HOOK_onPawnIsAcid -> HEAL")

		-- CONDITIONAL HOOK --
		local oldPos = pawn:GetSpace()
		--LOG("[BEFORE] Conditional hook -> pawn pos: "..pawn:GetSpace():GetString())

		modApi:conditionalHook(
			function()
				return not Board:IsBusy()
			end,
			function()
				--[[
				if pawn == nil then
					LOG(" ----------> after wait -> PAWN IS NIL")
				else
					LOG(" ----------> after wait -> PAWN EXISTS! -> pos: "..pawn:GetSpace():GetString())
				end
				]]

				--Problem: this is triggered twice when the pawn is pushed!
				local doHeal = false

				if pawn:IsAcid() then
					--LOG(" > Is still acid!") --> heal
					doHeal = true
				else
					--LOG(" > Is no longer acid!") --> NO heal
				end

				if oldPos == pawn:GetSpace() then --this fix doesn't work, acid isn't triggered twice when I do this verification
					--LOG(" > Hasn't moved -> heal") --> heal
				else
					--LOG(" > Has moved -> NO heal") --> NO heal
				end

				if doHeal then
					local heal = SpaceDamage(pawn:GetSpace(), -1)
					heal.iFire = EFFECT_REMOVE
					heal.iAcid = EFFECT_REMOVE
					Board:AddEffect(heal)
				end

				--Note: don't register pawn if it was already boosted! Otherwise, after undoing move, we'll remove boost :(
				if isBoost and pawn:IsMech() and not pawn:IsEnemy() and not pawn:IsBoosted() then
					--LOG("HOOK_onPawnIsAcid -> BOOST")

					pawn:SetBoosted(true)
					pawn:SetAcid(false)
				end

				-- tosx trick to avoid soft lock ----------------------------->
				local point = pawn:GetSpace()
				Board:GetPawn(pawn:GetId()):SetSpace(Point(-1, -1))
				Board:GetPawn(pawn:GetId()):SetAcid(false)
				
				Board:SetAcid(point, false)
				Board:GetPawn(pawn:GetId()):SetSpace(point)
				-- <----------------------------- tosx trick to avoid soft lock

			end
		)

	end
end

local function EVENT_onModsLoaded()
	modapiext:addPawnIsAcidHook(HOOK_onPawnIsAcid)
end

modApi.events.onModsLoaded:subscribe(EVENT_onModsLoaded)