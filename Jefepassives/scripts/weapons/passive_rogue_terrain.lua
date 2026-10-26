--[[
Idea: Hedera
Code: Hedera (but mostly Truelch, based on passive_random_swap)

Generic think it'll be useless, I think it'll be helpful, let's find out!
]]



Jefepassives_RogueTerrain = PassiveSkill:new{
	--Infos
	Name = "Rogue Terraformer",
	Description = "At the start of player's turn, swap two random spaces' terrain types three times.",
	PowerCost = 0,
	Upgrades = 2,
	UpgradeCost = { 1, 2 },
	UpgradeList = { "More Shifts", "Even More Shifts" },
	Icon = "weapons/passives/passive_rogue_terrain.png",

	--Passive
	Passive = "Jefepassives_RogueTerrain",

	--Tip image
	TipImage = {
		Unit   = Point(0, 0),
		Mountain = Point(2,2),
	}
}

Jefepassives_RogueTerrain_A = Jefepassives_RogueTerrain:new{
	UpgradeDescription = "Swap an additional pair of tiles.",
	Passive = "Jefepassives_RogueTerrain_A",
}

Jefepassives_RogueTerrain_B = Jefepassives_RogueTerrain:new{
	UpgradeDescription = "Swap two additional pairs of tiles.",
	Passive = "Jefepassives_RogueTerrain_B",
}

Jefepassives_RogueTerrain_AB = Jefepassives_RogueTerrain:new{
	Passive = "Jefepassives_RogueTerrain_AB",
}

TileScramble = Animation:new{ -- not working :(
	Image = "effects/explo_random_ground.png",
	PosX = -30, PosY = 0,
	Time = 0.07,
	Loop = false,
	NumFrames = 19,
	--Layer = LAYER_LESS_BACK,
}

function Jefepassives_RogueTerrain:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	local swapper = SpaceDamage(Point(2,2),0)
	swapper.iTerrain = 0
	ret:AddDamage(swapper)
	local swapper = SpaceDamage(Point(3,1),0)
	swapper.iTerrain = TERRAIN_MOUNTAIN
	ret:AddDamage(swapper)
	ret:AddBurst(Point(2,2),"Emitter_Crack_Start2",DIR_NONE)
	ret:AddBurst(Point(3,1),"Emitter_Crack_Start2",DIR_NONE)
	ret:AddDelay(1)
	local swapper = SpaceDamage(Point(3,1),0)
	swapper.iTerrain = 0
	ret:AddDamage(swapper)
	local swapper = SpaceDamage(Point(1,0),0)
	swapper.iTerrain = TERRAIN_MOUNTAIN
	ret:AddDamage(swapper)
	ret:AddBurst(Point(1,0),"Emitter_Crack_Start2",DIR_NONE)
	ret:AddBurst(Point(3,1),"Emitter_Crack_Start2",DIR_NONE)
	ret:AddDelay(1)
	local swapper = SpaceDamage(Point(1,0),0)
	swapper.iTerrain = 0
	ret:AddDamage(swapper)
	local swapper = SpaceDamage(Point(2,2),0)
	swapper.iTerrain = TERRAIN_MOUNTAIN
	ret:AddDamage(swapper)
	ret:AddBurst(Point(2,2),"Emitter_Crack_Start2",DIR_NONE)
	ret:AddBurst(Point(1,0),"Emitter_Crack_Start2",DIR_NONE)
	ret:AddDelay(1)

	return ret
end

local function swap2(loc1, loc2)

	local effect = SkillEffect()
	
	local terr1 = Board:GetTerrain(loc1)
	local terr2 = Board:GetTerrain(loc2)
	
	--effect:AddBounce(loc1, -4)
	--effect:AddBounce(loc2, -4)
	local sfx = SpaceDamage(loc1, 0)
	sfx.sSound = "/weapons/swap"
	local vfx = SpaceDamage(loc1,0)
	vfx.iTerrain = terr2
	effect:AddDamage(vfx)
	effect:AddBurst(loc1,"Emitter_Crack_Start2",DIR_NONE)
	vfx = SpaceDamage(loc2,0)
	vfx.iTerrain = terr1
	effect:AddDamage(vfx)
	Board:AddEffect(effect)
	effect:AddBurst(loc2,"Emitter_Crack_Start2",DIR_NONE)
	effect:AddDelay(0.15)
end

local EVENT_onNextTurn = function(mission)
	if Game:GetTeamTurn() == TEAM_PLAYER then
		if IsPassiveSkill("Jefepassives_RogueTerrain") or IsPassiveSkill("Jefepassives_RogueTerrain_A") or IsPassiveSkill("Jefepassives_RogueTerrain_B") or IsPassiveSkill("Jefepassives_RogueTerrain_AB") then
			local SwapCount = 3
			if IsPassiveSkill("Jefepassives_RogueTerrain_A") then SwapCount = 4
			elseif IsPassiveSkill("Jefepassives_RogueTerrain_B") then SwapCount = 5
			elseif IsPassiveSkill("Jefepassives_RogueTerrain_AB") then SwapCount = 6 end
			
			local candidates = {}
			for j = 0, 7 do
				for i = 0, 7 do
					local curr = Point(i, j)
					--shouldn't bother anything important with all these
					if not Board:IsBuilding(curr) and not Board:IsPawnSpace(curr) and (Board:GetCustomTile(curr) == "" or Board:GetCustomTile(curr) == nil) and (Board:GetItem(curr) == "" or Board:GetItem(curr) == nil) then 
						candidates[#candidates + 1] = curr
					end
				end
			end

			Board:StartShake(1.5)
			for i = 1,SwapCount do
				if #candidates >= 2 then
					local loc1 = table.remove(candidates, math.random(1, #candidates))
					local loc2 = table.remove(candidates, math.random(1, #candidates))

					swap2(loc1,loc2)
				end
			end
		end
	end
end

modApi.events.onNextTurn:subscribe(EVENT_onNextTurn)

local EVENT_onResetTurn = function(mission)
	modApi:scheduleHook(550, function() 
		EVENT_onNextTurn(mission) -- cant be bothered to track and redo all the swaps. come back to this and fix it.
	end)
end
modapiext.events.onResetTurn:subscribe(EVENT_onResetTurn)