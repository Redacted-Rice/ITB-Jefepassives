-- paths and libs
local path = mod_loader.mods[modApi.currentMod].resourcePath
local armorDetection = mod_loader.mods[modApi.currentMod].libs.armorDetection

-- add assets from our mod so the game can find them.
modApi:appendAsset("img/weapons/passives/Jefepassives_passive_loneliness.png", path .."img/weapons/passives/passive_loneliness.png")
modApi:appendAsset("img/weapons/passives/Jefepassives_passive_awkwardness.png", path .."img/weapons/passives/passive_awkwardness.png")
modApi:appendAsset("img/effects/Jefepassives_emotional_damage.png",path.."img/effects/emotional_damage.png")
modApi:appendAsset("img/effects/Jefepassives_social_anxiety.png",path.."img/effects/social_anxiety.png")

-- add animations
ANIMS.Jefepassives_Emotional_Damage = Animation:new{
	Image = "effects/Jefepassives_emotional_damage.png",
	NumFrames = 6,
	Time = 0.1,
	PosX = -28,
	PosY = -8,
	layer = LAYER_FRONT
}

ANIMS.Jefepassives_Social_Anxiety = Animation:new{
	Image = "effects/Jefepassives_social_anxiety.png",
	NumFrames = 8,
	Time = 0.15,
	PosX = -26,
	PosY = 22,
	layer = LAYER_FRONT
}


-- loneliness
Jefepassives_Loneliness = PassiveSkill:new{
	Name = "Loneliness Amplifier",
	Description = "Vek take emotional damage if ending turn with no adjacent units.",
	PowerCost = 2,
	Icon = "weapons/passives/Jefepassives_passive_loneliness.png",
	Upgrades = 0,
	Passive = "Jefepassives_Loneliness",
	TipImage = {
		Unit = Point(1,3),
		CustomPawn = "PunchMech",
		Target = Point(2,2),
		Enemy = Point(2,3),
		Friendly = Point(1,2),
		Enemy2 = Point(3,1),
	}
}

function Jefepassives_Loneliness:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
	local dir = GetDirection(p2 - p1)
	local dano = SpaceDamage(Point(3,1),1)
	dano.sAnimation = "Jefepassives_Emotional_Damage"
	ret:AddDamage(dano)
	return ret
end

-- awkwardness
Jefepassives_Awkwardness = PassiveSkill:new{
	Name = "Awkwardness Inducer",
	Description = "Vek take social anxiety damage if ending turn adjacent to other units.",
	PowerCost = 2,
	Icon = "weapons/passives/Jefepassives_passive_awkwardness.png",
	Upgrades = 0,
	Passive = "Jefepassives_Awkwardness",
	TipImage = {
		Unit = Point(1,3),
		CustomPawn = "PunchMech",
		Target = Point(2,2),
		Enemy = Point(2,3),
		Friendly = Point(1,2),
		Enemy2 = Point(3,1),
	}
}

function Jefepassives_Awkwardness:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
	local dir = GetDirection(p2 - p1)
	local dano = SpaceDamage(Point(2,3),1)
	dano.sAnimation = "Jefepassives_Social_Anxiety"
	ret:AddDamage(dano)
	return ret
end

-- events
local function applyDamage(fx)
	local Awkwardness = IsPassiveSkill("Jefepassives_Awkwardness")
	local loneliness = IsPassiveSkill("Jefepassives_Loneliness")
	if (Game:GetTeamTurn() == TEAM_ENEMY or fx) and Board:GetTurn() > 0 and (Awkwardness or loneliness) then
		local effect = SkillEffect()
		local delay = fx and 0.5 or 1
		local pawnList = extract_table(Board:GetPawns(TEAM_ENEMY))
		for i = 1, #pawnList do
			local currPawn = Board:GetPawn(pawnList[i])
			local currSpace = currPawn:GetSpace()
			local lonely = loneliness
			local awkward = false
			for i = DIR_START, DIR_END do
				if Board:GetPawn(currSpace + DIR_VECTORS[i]) then
					lonely = false
					awkward = Awkwardness
				end
			end
			if lonely or awkward then
				-- currPawn:SetHealth(currPawn:GetHealth()-1)
				-- local sound = _G[currPawn:GetType()].SoundLocation..'hurt'
				-- Game:TriggerSound(sound)
				local damage = SpaceDamage(currSpace,1)
				if lonely then damage.sAnimation = "Jefepassives_Emotional_Damage" end
				if awkward then damage.sAnimation = "Jefepassives_Social_Anxiety" end
				-- damage.sSound = _G[currPawn:GetType()].SoundLocation..'hurt'
				if armorDetection.IsArmor(currPawn) then damage.iDamage = 2 end
				local shield = currPawn:IsShield()
				local acid = currPawn:IsAcid()
				local ice = currPawn:IsFrozen()
				local crack = Board:IsCracked(currSpace)
				effect:AddScript([[
					local pawn = Board:GetPawn(]]..currSpace:GetString()..[[)
					if ]]..tostring(shield)..[[ then
						pawn:SetShield(false,true)
					end
					if ]]..tostring(acid)..[[ then
						pawn:SetAcid(false,true)
					end
					if ]]..tostring(ice)..[[ then
						pawn:SetFrozen(false,true)
					end
					if ]]..tostring(crack)..[[ then
						Board:SetCracked(pawn:GetSpace(),false)
					end
				]])
				effect:AddSafeDamage(damage)
				effect:AddBounce(currSpace,-2)
				effect:AddScript([[
					local pawn = Board:GetPawn(]]..currSpace:GetString()..[[)
					if ]]..tostring(shield)..[[ then
						pawn:SetShield(true,true)
					end
					if ]]..tostring(acid)..[[ then
						pawn:SetAcid(true,true)
					end
					if ]]..tostring(ice)..[[ then
						pawn:SetFrozen(true,true)
					end
					if ]]..tostring(crack)..[[ then
						Board:SetCracked(pawn:GetSpace(),true)
					end
				]])
				effect:AddDelay(delay)
			end
		end
		Board:AddEffect(effect)
	end
end

function onNextTurn(mission)
	applyDamage(false)
end

function onPreprocessVekRetreat(mission,fx)
	applyDamage(fx)
end

modApi.events.onNextTurn:subscribe(onNextTurn)
modApi.events.onPreprocessVekRetreat:subscribe(onPreprocessVekRetreat)
-- modApi.events.onPostEnvironment:subscribe(onPostEnvironment)
-- modApi.events.onMissionEnd:subscribe(endMission)
