Jefepassives_Materia_Passive = PassiveSkill:new{
	Name = "Materia Nanobots",
	Description = "Mechs are Boosted when they destroy a mountain.",
	PowerCost = 1,
	Icon = "weapons/passives/passive_materia.png",
	Upgrades = 0,
	Passive = "Jefepassives_Materia_Passive",
	TipImage = {
		Unit = Point (2,2),
		CustomPawn = "PunchMech",
        	Target = Point(3,2),
		Mountain = Point(3,2),
	}
}
function Jefepassives_Materia_Passive:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
		local direction = GetDirection(p2 - p1)
		local damage = SpaceDamage(p2, DAMAGE_DEATH)
		damage.sAnimation = "explopunch1_"..direction
		ret:AddMelee(p1, damage)
		ret:AddDelay(.7)
		ret:AddScript("Board:GetPawn(Point(2,2)):SetBoosted(true)")
		ret:AddDelay(.7)
			
	return ret
end

BRUHHHHH = PunchMech:new{
	SkillList = { "boost" },
}

boost = SelfTarget:new{
}
function boost:GetSkillEffect(p1,p2)
	ret = SkillEffect()
		ret:AddScript("Board:GetPawn(Point(2,2)):SetBoosted(true)")
	return ret
end

local function getMountainPreCount(mission, pawn, weaponId, p1, p2)
	local count = 0
	Jefepassive_MountainPawn = pawn
	

		for _, p in ipairs(Board) do
			if Board:IsTerrain(p,TERRAIN_MOUNTAIN) then
				count = count + 1
			end
		end

	
	Jefepassive_mountains_precount = count
	
	return count
end

--This function is the same as the above one but without the global variable so that when the post-fire count occurs, it does not update global_mountains_precount
local function getMountainPostCount()
	local count = 0
	
		for _, p in ipairs(Board) do
			if Board:IsTerrain(p,TERRAIN_MOUNTAIN) then
				count = count + 1
			end
		end

	return count
end

local function mountainChecker(mission)
	if Board then
	local pawn = Jefepassive_MountainPawn
	local precount = Jefepassive_mountains_precount
	local postcount = getMountainPostCount()
	local ret = SkillEffect()
	if pawn and (precount > postcount) then
		if IsPassiveSkill("Jefepassives_Materia_Passive") and (Board:IsPawnTeam(pawn:GetSpace(), TEAM_PLAYER)) then
			pawn:SetBoosted(true)
			Jefepassive_MountainPawn = nil
		end
	end
	end
end



	local function EVENT_onModsFirstLoaded()
			Jefepassive_MountainPawn = nil
			Jefepassive_mountains_precount = 0
			modapiext.events.onSkillStart:subscribe(getMountainPreCount)
			modApi.events.onSaveGame:subscribe(mountainChecker)
	end
	
	modApi.events.onModsFirstLoaded:subscribe(EVENT_onModsFirstLoaded)
