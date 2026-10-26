-- By Hedera

Jefepassives_Shrapnel = PassiveSkill:new{
	Name = "Mega Shrapnel",
	Description = "When a damaged Vek would be healed from any source, it is damaged by one instead.",
	PowerCost = 0,
	Icon = "weapons/passives/passive_shrapnel.png",
	Upgrades = 0,
	Passive = "Jefepassives_Shrapnel",
	TipImage = {
		Unit = Point(0,0),
		Enemy = Point (2,2),
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

function Jefepassives_Shrapnel:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
		local direction = GetDirection(p2 - p1)
		local heal = SpaceDamage(Point(2,2), -2)
		ret:AddDamage(heal)
		ret:AddBurst(Point(2,2),"Emitter_Scrap",DIR_NONE)
		local unheal = SpaceDamage(Point(2,2),3)
		unheal.bHide = true
		ret:AddDamage(unheal)
		ret:AddDelay(.7)
			
	return ret
end

	local hook = function(mission, pawn, healingTaken)
		if IsPassiveSkill("Jefepassives_Shrapnel") and pawn:GetTeam() == TEAM_ENEMY then
			Board:AddBurst(pawn:GetSpace(),"Emitter_Scrap",DIR_NONE)
			Board:DamageSpace(pawn:GetSpace(),healingTaken + 1)
		end
	end


	local function EVENT_onModsFirstLoaded()
		modapiext:addPawnHealedHook(hook)
	end
	
modApi.events.onModsLoaded:subscribe(EVENT_onModsFirstLoaded)
