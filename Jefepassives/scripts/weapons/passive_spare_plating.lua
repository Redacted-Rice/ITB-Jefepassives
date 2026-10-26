-- By Hedera

Jefepassives_SparePlating = PassiveSkill:new{
	Name = "Spare Plating",
	Description = "The first time a Mech is damaged each mission, fully repair it. Cannot revive from lethal damage.",
	PowerCost = 0,
	Icon = "weapons/passives/passive_spare_plating.png",
	Upgrades = 0,
	Passive = "Jefepassives_SparePlating",
	TipImage = {
		Unit = Point (2,2),
	}
}

Emitter_Scrap = Emitter_Burst_Heal:new{
	image = "effects/particle_scrap.png",
	max_alpha = 1,
	lifespan = 2,
	burst_count = 5,
	variance_x = 15,
	speed = 2,
	gravity = true,
}

function Jefepassives_SparePlating:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
		local direction = GetDirection(p2 - p1)
		local damage = SpaceDamage(Point(2,2), 2)
		ret:AddProjectile(Point(2,5),damage,"effects/shot_quickfire",FULL_DELAY)
		ret:AddBurst(Point(2,2),"Emitter_Scrap",DIR_NONE)
		ret:AddDelay(.7)
		ret:AddDamage(SpaceDamage(Point(2,2),-10))
		ret:AddDelay(.7)
			
	return ret
end

	local hook = function(mission, pawn, damageTaken)
		if IsPassiveSkill("Jefepassives_SparePlating") and mission.JS_Plating_Used ~= true and pawn:IsMech() and not pawn:IsDead() then
			mission.JS_Plating_Used = true
			Board:AddBurst(pawn:GetSpace(),"Emitter_Scrap",DIR_NONE)
			Board:DamageSpace(pawn:GetSpace(),-10)
		end
	end
	
	local CleanMissionVariables = function(mission)
		mission.JS_Plating_Used = false
	end



	local function EVENT_onModsFirstLoaded()
		modapiext:addPawnDamagedHook(hook)
		modApi.events.onMissionStart:subscribe(CleanMissionVariables)
		modApi.events.onMissionNextPhaseCreated:subscribe(CleanMissionVariables)
	end
	
modApi.events.onModsLoaded:subscribe(EVENT_onModsFirstLoaded)
