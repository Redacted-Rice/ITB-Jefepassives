local passiveEffect = mod_loader.mods[modApi.currentMod].libs.passiveEffect
local pawnTypeUtils = mod_loader.mods[modApi.currentMod].libs.pawnTypeUtils

local VEKTIER_NORMAL = 1
local VEKTIER_ALPHA = 2
local VEKTIER_BOSS = 3

Jefepassives_ChronoBeacons_Passive = PassiveSkill:new{
	Name = "Chrono Beacons",
	Description = "Time Pods targets the strongest Vek on the board.",
	PowerCost = 0,
	Icon = "weapons/passives/passive_chrono_homing.png",
	Passive = "Jefepassives_ChronoBeacons_Passive",
	TipImage = {
		Unit = Point(2, 3),
		Enemy = Point(3, 2),
		CustomEnemy = "Firefly1",
	},
	TargetId = nil,
}

function Jefepassives_ChronoBeacons_Passive:GetSkillEffect(p1, p2)
	-- TODO: Preview
	return SkillEffect()
end

function Jefepassives_ChronoBeacons_Passive:getVekPriorityTier(pawn)
	if pawnTypeUtils.isBoss(pawn) then
		return VEKTIER_BOSS
	end
	if pawnTypeUtils.isSpawnCategory(pawn, "Leader") then
		return VEKTIER_ALPHA
	end
	return VEKTIER_NORMAL
end

function Jefepassives_ChronoBeacons_Passive:isBetterVekTarget(tier, health, pawnId, bestTier, bestHealth, bestId)
	-- Tier first
	if tier > bestTier then
		return true
	end
	if tier < bestTier then
		return false
	end
	-- Health second
	if health > bestHealth then
		return true
	end
	if health < bestHealth then
		return false
	end
	-- ID tie breaker
	return pawnId > bestId
end

function Jefepassives_ChronoBeacons_Passive:findStrongestVekSpace()
	if not Board then
		return nil
	end

	local bestSpace = nil
	local bestTier = -1
	local bestHealth = -1
	local bestId = -1

	for _, pawnId in ipairs(extract_table(Board:GetPawns(TEAM_ANY))) do
		local pawn = Board:GetPawn(pawnId)
		if pawn and pawn:IsEnemy() and pawn:GetHealth() > 0 then
			local tier = self:getVekPriorityTier(pawn)
			local health = pawn:GetMaxHealth()
			if self:isBetterVekTarget(tier, health, pawnId, bestTier, bestHealth, bestId) then
				bestTier = tier
				bestHealth = health
				bestId = pawnId
				bestSpace = pawn:GetSpace()
			end
		end
	end

	return bestSpace, bestId
end

function Jefepassives_ChronoBeacons_Passive:GetPassiveSkillEffect_OnDeploymentPhaseEnd()
	if not Board then
		return
	end
	if not Board.SetPodLandingPoint then
		LOG("WARNING: Chrono Beacons active but RedactedRice Memhack is not enabled! Passive will not fully function")
		return
	end

	local target, id = self:findStrongestVekSpace()
	if not target or not Board:IsValid(target) then
		return
	end
	
	self.TargetId = id
	Board:SetPodLandingPoint(target)
end

function Jefepassives_ChronoBeacons_Passive:GetPassiveSkillEffect_OnPodLanded()
	local pawn = Board:GetPawn(self.TargetId)
	if pawn then
		Board:RemovePawn(pawn)
	end
end

passiveEffect:addPassiveEffect(
	"Jefepassives_ChronoBeacons_Passive",
	{"onDeploymentPhaseEnd", "onPodLanded"}
)
