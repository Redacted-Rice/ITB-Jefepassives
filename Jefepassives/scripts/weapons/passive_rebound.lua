local a = ANIMS

-- The loading paths and image loading approach are super finicky for pawns apparantly
-- This finally seems to be a location and load apporach that works for whatever reason
a.ReboundPawn = a.BaseUnit:new{
	Image = "units/passive/pawn_rebound.png",
	PosX = -28,
	PosY = -10,
}



Jefepassives_Rebound_Pawn = Pawn:new {
	Health = 1,
	Image = "ReboundPawn",
	Orbital = true,
	Name = "Rebound Satellite",
	ImageOffset = 0,
	MoveSpeed = 0,
	SkillList = { "Jefepassives_Rebound_Weapon" },
	SoundLocation = "/mech/science/science_mech/",
	DefaultTeam = TEAM_PLAYER,
	OrbitalSummon = true,
	ImpactMaterial = IMPACT_METAL,
	SpaceColor = false,
	Orbital = true,
	OrbitalIcon = true,
}

Jefepassives_Rebound_Pawn_A = Jefepassives_Rebound_Pawn:new {
	SkillList = { "Jefepassives_Rebound_Weapon_A" },
}
Jefepassives_Rebound_Pawn_B = Jefepassives_Rebound_Pawn:new {
	SkillList = { "Jefepassives_Rebound_Weapon_B" },
}
Jefepassives_Rebound_Pawn_AB = Jefepassives_Rebound_Pawn:new {
	SkillList = { "Jefepassives_Rebound_Weapon_AB" },
}

Jefepassives_Rebound = PassiveSkill:new{
	Name = "Rebound Satellite",
	Description = "At mission start, summon an Orbital Unit which can rebound pushing artilleries off allied units.",
	PowerCost = 2,
	Icon = "weapons/passives/passive_rebound.png",
	Upgrades = 2,
	uDamage = 0,
	UpgradeCost = {2,2},
	UpgradeList = { "+1 Range","+1 Damage" },
	Passive = "Jefepassives_Rebound",
	Point = Point(2,1),
	TipImage = {
		Unit = Point (2,3),
        	Target = Point(2,2),
        	Enemy = Point(2,1),
	}
}
function Jefepassives_Rebound:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
	local fx = SpaceDamage(p1, 0)
	fx.sAnimation = "ExploRaining1"
	ret:AddDamage(fx)
	ret:AddDelay(.1)
	local damage = SpaceDamage(self.Point, self.uDamage, 1)
	if self.uDamage == 1 then
		damage.sAnimation = "explopush1_"..1
	else
		damage.sAnimation = "airpush_"..1
	end
	ret:AddArtillery(damage, "effects/shotup_missileswarm.png", NO_DELAY)
	return ret
end

Jefepassives_Rebound_A = Jefepassives_Rebound:new{
	UpgradeDescription = "Increases the artillery's range by one.",
	Point = Point(2,0),
	TipImage = {
		Unit = Point (2,3),
        	Target = Point(2,2),
        	Enemy = Point(2,0),
	},
	Passive = "Jefepassives_Rebound_A",
}
Jefepassives_Rebound_B = Jefepassives_Rebound:new{
	UpgradeDescription = "Increases the artillery's damage by one.",
	Passive = "Jefepassives_Rebound_B",
	uDamage = 1
}
Jefepassives_Rebound_AB = Jefepassives_Rebound_A:new{
	Passive = "Jefepassives_Rebound_AB",
	uDamage = 1
}

Rebound_TargetAreas = {
function(ret, p1, self, p2)
	for i = 0, 2 do
		if Board:GetPawn(i) then
		ret:push_back(Board:GetPawn(i):GetSpace())
		end
	end
end,
function(ret, p1, self, p2)
	for j = 2, self.Range do
		for dir = DIR_START, DIR_END do
			ret:push_back((p2 or Clicks[1])+DIR_VECTORS[dir]*j)
		end
	end
end,
function(ret, p1, self, p2)
	for dir = DIR_START, DIR_END do
		ret:push_back((p2 or Clicks[2])+DIR_VECTORS[dir])
	end
end
}

Rebound_SkillEffects = {
function(ret, p1, p2, self)
end,
function(ret, p1, p2, self)
	local damage = SpaceDamage(p2, 0)
	ret:AddArtillery(Clicks[1], SpaceDamage(p2, self.Damage), "", NO_DELAY)
end,
function(ret, p1, p2, self)
	local fx = SpaceDamage(Clicks[1], 0)
	fx.sAnimation = "ExploRaining1"
	fx.sSound = "/weapons/raining_volley_tile"
	ret:AddDamage(fx)
	ret:AddDelay(.1)
	local dir = GetDirection(p2-Clicks[2])
	local damage = SpaceDamage(Clicks[2], self.Damage, dir)
	if self.Damage == 1 then
		damage.sAnimation = "explopush1_"..dir
	else
		damage.sAnimation = "airpush_"..dir
	end
	damage.sSound = "/impact/generic/explosion"
	ret:AddArtillery(Clicks[1], damage, "effects/shotup_missileswarm.png", NO_DELAY)
end
}

Jefepassives_Rebound_Weapon_Tip = SelfTarget:new{
	Damage = 0,
	Point = Point(2,1),
	TipImage = {
		Unit = Point(2,3),
        	Target = Point(2,3),
        	Enemy = Point(2,1),
	},
}
Jefepassives_Rebound_Weapon_Tip_A = Jefepassives_Rebound_Weapon_Tip:new{
	Point = Point(2,0),
	TipImage = {
		Unit = Point(2,3),
        	Target = Point(2,3),
        	Enemy = Point(2,0),
	},
}
Jefepassives_Rebound_Weapon_Tip_B = Jefepassives_Rebound_Weapon_Tip:new{
	Damage = 1,
}
Jefepassives_Rebound_Weapon_Tip_AB = Jefepassives_Rebound_Weapon_Tip_A:new{
	Damage = 1
}
function Jefepassives_Rebound_Weapon_Tip:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
	local fx = SpaceDamage(p1, 0)
	fx.sAnimation = "ExploRaining1"
	ret:AddDamage(fx)
	ret:AddDelay(.1)
	local damage = SpaceDamage(self.Point, self.Damage, 1)
	if self.Damage == 1 then
		damage.sAnimation = "explopush1_"..1
	else
		damage.sAnimation = "airpush_"..1
	end
	ret:AddArtillery(damage, "effects/shotup_missileswarm.png", NO_DELAY)
	return ret
end

Jefepassives_Rebound_Weapon = NClickSkill:new{
	Name = "Rebound Artillery",
	Description = "Rebound a pushing artillery off an allied unit.",
	Range = 2,
	Phases = 3,
	Damage = 0,
	Icon = "weapons/weapons/weapon_rebound.png",
	TargetAreas = Rebound_TargetAreas,
	SkillEffects = Rebound_SkillEffects,
	CustomTipImage = "Jefepassives_Rebound_Weapon_Tip",
}



Jefepassives_Rebound_Weapon_A = Jefepassives_Rebound_Weapon:new{
	CustomTipImage = "Jefepassives_Rebound_Weapon_Tip_A",
	Range = 3
}
Jefepassives_Rebound_Weapon_B = Jefepassives_Rebound_Weapon:new{
	CustomTipImage = "Jefepassives_Rebound_Weapon_Tip_B",
	Damage = 1
}
Jefepassives_Rebound_Weapon_AB = Jefepassives_Rebound_Weapon_A:new{
	CustomTipImage = "Jefepassives_Rebound_Weapon_Tip_AB",
	Damage = 1
}


local function EVENT_MissionStart(mission)
		local passive = "Jefepassives_Rebound"
		local words = {"_A","_B","_AB"}
		if IsPassiveSkill(passive) then
			local level = ""
			for i = 1, 3 do
				if IsPassiveSkill(passive..words[i]) then
					level = words[i]
				end
			end
			local ret = SkillEffect()
			local final = false
			for i = 0, 7 do
				for j = 0, 7 do
					curr = Point(i,j)
					if (not final) and (not Board:IsBlocked(curr, PATH_FLYER)) then
						final = curr
					end
				end
			end

			local damage = SpaceDamage(final,0)
			damage.sPawn = "Jefepassives_Rebound_Pawn"..level
			ret:AddDamage(damage)

			Board:AddEffect(ret)
		end
end




local function EVENT_MissionNextPhaseCreated(prevMission, nextMission)
	modApi:scheduleHook(100, function()
		if Board then
			local passive = "Jefepassives_Rebound"
			local words = {"_A","_B","_AB"}
			if IsPassiveSkill(passive) then
				local level = ""
				for i = 1, 3 do
					if IsPassiveSkill(passive..words[i]) then
						level = words[i]
					end
				end
				local ret = SkillEffect()
				local final = false
				for i = 0, 7 do
					for j = 0, 7 do
						curr = Point(i,j)
						if (not final) and (not Board:IsBlocked(curr, PATH_FLYER)) then
							final = curr
						end
					end
				end

				local damage = SpaceDamage(final,0)
				damage.sPawn = "Jefepassives_Rebound_Pawn"..level
				ret:AddDamage(damage)

				Board:AddEffect(ret)
			end
		end
	end)
end

local HideSatellite = function(mission, pawn)
	if _G[pawn:GetType()].OrbitalSummon then
		pawn:SetSpace(Point(-1,-1))
		pawn:SetInvisible(false)
		pawn:SetFlying(false)
	end
end

local function EVENT_onModsFirstLoaded()
		modapiext.events.onPawnTracked:subscribe(HideSatellite)
		modApi.events.onMissionStart:subscribe(EVENT_MissionStart)
		modApi.events.onMissionNextPhaseCreated:subscribe(EVENT_MissionNextPhaseCreated)
		modApi.events.onTestMechEntered:subscribe(EVENT_MissionStart)
end
	
modApi.events.onModsFirstLoaded:subscribe(EVENT_onModsFirstLoaded)