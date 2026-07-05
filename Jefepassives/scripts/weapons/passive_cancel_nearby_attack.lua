--[[
Idea: Generic
Code: Truelch
]]

Jefepassives_CancelNearbyAttacks = PassiveSkill:new{
	--Infos
	Name = "Intimidating Presence",
	Description = "At the end of player's turn, Mechs cancel attacks of nearby enemies with fewer HP.",
	PowerCost = 1, --maybe even 2??
	Icon = "weapons/passives/passive_cancel_nearby_attack.png",

	--Passive
	Passive = "Jefepassives_CancelNearbyAttacks",

	--Tip image
	TipImage = {
		Unit = Point(2, 3),
		Target = Point(2, 1),
		Enemy1 = Point(2, 2),
		CustomEnemy = "Beetle1",
	}
}

function Jefepassives_CancelNearbyAttacks:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	local damage = SpaceDamage(0)
	damage.bHide = true
	damage.sScript = "Board:GetPawn(Point(2, 2)):FireWeapon(Point(2, 3), 1)"
	ret:AddDamage(damage)

	damage = SpaceDamage(0)
	damage.bHide = true
	damage.fDelay = 1.5
	ret:AddDamage(damage)

	ret:AddScript("Board:GetPawn(Point(2, 2)):ClearQueued()")
	ret:AddScript([[Board:AddAlert(Point(2, 2), "INTIMIDATED")]])

	return ret
end


local EVENT_onPreEnvironment = function(mission)
	if not IsPassiveSkill("Jefepassives_CancelNearbyAttacks") then return end

	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)
			local enemy = Board:GetPawn(curr)
			if enemy ~= nil and enemy:IsEnemy() then
				for dir = DIR_START, DIR_END do
					local curr2 = curr + DIR_VECTORS[dir]
					local mech = Board:GetPawn(curr2)
					if mech ~= nil and mech:IsMech() and enemy:GetHealth() < mech:GetHealth() --[[not mech:IsDead()]] then
						enemy:ClearQueued()
						Board:AddAlert(enemy:GetSpace(), "INTIMIDATED")
					end
				end
			end
		end
	end
end
modApi.events.onPreEnvironment:subscribe(EVENT_onPreEnvironment)