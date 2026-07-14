-- paths and libs
local path = mod_loader.mods[modApi.currentMod].resourcePath

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
	Description = "Vek take emotional damage if ending turn adjacent to no units.",
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

-- target
local function targetPawn(pawn)
	if pawn
		and pawn:GetTeam() == TEAM_ENEMY
		and _G[pawn:GetType()].DefaultTeam == TEAM_ENEMY
		and _G[pawn:GetType()].DefaultFaction ~= FACTION_BOTS
		and not _G[pawn:GetType()].NonGrid
		and not _G[pawn:GetType()].Neutral
		and not _G[pawn:GetType()].Corporate
		-- and not _G[pawn:GetType()].Minor
	then
		return true
	end
end

-- exceptions
-- local exceptions = {
-- 	BonusDebris = true,
-- 	Wall = true,
-- 	RockThrown = true,
-- 	BombRock = true
-- }

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
			if targetPawn(currPawn) then
				local currSpace = currPawn:GetSpace()
				local lonely = loneliness
				local awkward = false
				for i = DIR_START, DIR_END do
					local adjPawn = Board:GetPawn(currSpace + DIR_VECTORS[i])
					if adjPawn
						-- and not _G[adjPawn:GetType()].NonGrid
						-- and not exceptions[adjPawn:GetType()]
					then
						lonely = false
						awkward = Awkwardness
					end
				end
				if lonely or awkward then
					local damage = SpaceDamage(currSpace)
					if lonely then damage.sAnimation = "Jefepassives_Emotional_Damage" end
					if awkward then damage.sAnimation = "Jefepassives_Social_Anxiety" end
					damage.sSound = _G[currPawn:GetType()].SoundLocation..'hurt'
					effect:AddDamage(damage)
					effect:AddScript([[
						local pawn = Board:GetPawn(]]..currSpace:GetString()..[[)
						pawn:ModifyHealth(-1,true,0)
					]])
					effect:AddBounce(currSpace,-1)
					effect:AddDelay(delay)
				end
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
