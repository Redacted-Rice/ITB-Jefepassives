-- By Hedera

Jefepassives_Acidifier = PassiveSkill:new{
	Name = "Acidifier",
	Description = "Dying Vek leave a puddle of A.C.I.D.",
	PowerCost = 0,
	Icon = "weapons/passives/passive_acidifier.png",
	Upgrades = 1,
	Splash = false,
	UpgradeCost = { 1 },
	UpgradeList = { "Splash Zone" },
	Passive = "Jefepassives_Acidifier",
	TipImage = {
		Unit = Point(0,0),
		Enemy = Point (2,2),
	}
}

Jefepassives_Acidifier_A = Jefepassives_Acidifier:new{
	UpgradeDescription = "Coat adjacent Vek in A.C.I.D. too.",
	Passive = "Jefepassives_Acidifier_A",
	Splash = true,
	TipImage = {
		Unit = Point(0,0),
		Enemy = Point (2,2),
		Enemy2 = Point (1,2),
		Enemy3 = Point (3,2),
	}
}

function Jefepassives_Acidifier:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
		local direction = GetDirection(p2 - p1)
		local liquify = SpaceDamage(Point(2,2), DAMAGE_DEATH)
		liquify.iAcid = EFFECT_CREATE
		liquify.sAnimation = "ExploAcid1"
		ret:AddDamage(liquify)
		if self.Splash then
			local liquid2 = SpaceDamage(Point(1,2),0)
			liquid2.sAnimation = "ExploAcid1"
			liquid2.iAcid = EFFECT_CREATE
			liquid2.bHide = true
			ret:AddDamage(liquid2)
			liquid2 = SpaceDamage(Point(3,2),0)
			liquid2.sAnimation = "ExploAcid1"
			liquid2.bHide = true
			liquid2.iAcid = EFFECT_CREATE
			ret:AddDamage(liquid2)
		end
		ret:AddDelay(1)
	return ret
end

	local hook = function(mission, pawn)
		if IsPassiveSkill("Jefepassives_Acidifier") or IsPassiveSkill("Jefepassives_Acidifier_A") and pawn:GetTeam() == TEAM_ENEMY then
			Board:AddAnimation(pawn:GetSpace(),"ExploAcid1",ANIM_REVERSE)
			local acid = SpaceDamage(pawn:GetSpace(),0)
			acid.iAcid = EFFECT_CREATE
			Board:DamageSpace(acid)
			if IsPassiveSkill("Jefepassives_Acidifier_A") then
				for i = DIR_START,DIR_END do
					local check = pawn:GetSpace() + DIR_VECTORS[i]
					if Board:IsPawnSpace(check) and Board:IsPawnTeam(check, TEAM_ENEMY) then
						Board:AddAnimation(check,"ExploAcid1",ANIM_REVERSE)
						local acid2 = SpaceDamage(check,0)
						acid2.iAcid = EFFECT_CREATE
						Board:DamageSpace(acid2)
					end
				end
			end
		end
	end


	local function EVENT_onModsFirstLoaded()
		modapiext:addPawnKilledHook(hook)
	end
	
modApi.events.onModsLoaded:subscribe(EVENT_onModsFirstLoaded)
