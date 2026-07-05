--[[
Weird, I think I managed to taunt a Gastropod while being an obstacle, which made it target an objective :(

Also, I need to do the taunt again after a reset turn, I think.

Also, the Moth has limited artillery range. It was taunted by one of my mech that was aligned, but out of range!


UNDOING TURN WILL REMOVE PAWN!!!
for _, id in ipairs(extract_table(Board:GetPawns(TEAM_ENEMY))) do LOG("pawn: "..Board:GetPawn(id):GetType()..", pos: "..Board:GetPawn(id):GetSpace():GetString()) end

-> Unlike what I thought, it's not always a webbing enemies that's locked outside the terrain

TODO:
- don't taunt when the target doesn't change!

I was able to taunt a Bouncer1
taunt.canTargetNewPoint(pawn: Bouncer1 (Point( 4, 4 )), target: Point( 0, 4 ), mustBeAbleToHit: true)
canTargetNewPoint -> All Else
queuedWeaponName == nil -> return false

Beetle was also confirmed as "other ranged"
]]



local mod = mod_loader.mods[modApi.currentMod]
local scriptPath = mod.scriptPath
local taunt = require(scriptPath.."/taunt/taunt")
--LOG("taunt: "..tostring(taunt))

Jefepassives_TauntingField = PassiveSkill:new{
	--Infos
	Name = "Taunting Field",
	Description = "When an enemy queue an attack, it'll redirect its attack toward a Mech, if possible.",
	PowerCost = 0,
	Icon = "weapons/passives/passive_taunt_field.png",

	--Passive
	Passive = "Jefepassives_TauntingField",

	--Tip image
	TipImage = {
		Unit   = Point(2, 3),
		Target = Point(2, 1),
		Enemy1 = Point(2, 2),
		CustomEnemy = "Beetle1",
	}
}

local function computeTaunt2()
	if not IsPassiveSkill("Jefepassives_TauntingField") then return end

	--I really need to remember how to just pick the enemy list...
	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)
			local enemy = Board:GetPawn(curr)
			if enemy ~= nil and enemy:IsEnemy() then
				for i = 0, 2 do
					local mech = Board:GetPawn(i)
					if mech ~= nil and taunt.canBeTauntedByPoint(enemy, mech:GetSpace(), true) then
						local effect = SkillEffect()
						taunt.addTauntEffectEnemy(effect, enemy:GetId(), mech:GetSpace(), 0, false)
						--LOG("enemy: "..enemy:GetType().." ("..enemy:GetSpace():GetString()..") was taunted by mech: "..mech:GetType().." ("..mech:GetSpace():GetString()..")")
						Board:AddEffect(effect)
						Board:AddAlert(enemy:GetSpace(), "TAUNTED")
						break --we don't want the pawn to be taunted by multiple mechs at the same time lol
					end
				end
			end
		end
	end
end

--[[
--Doesn't solve the issue
local function computeTaunt()
	if IsPassiveSkill("Jefepassives_RandomSwap") then
		modApi:scheduleHook(550, function()
			computeTaunt2()
		end)
	else
		computeTaunt2()
	end
end
]]

local EVENT_onNextTurn = function(mission)
	if Game:GetTeamTurn() == TEAM_PLAYER then
		computeTaunt2()	
	end
end
modApi.events.onNextTurn:subscribe(EVENT_onNextTurn)


local EVENT_onResetTurn = function(mission)
	modApi:scheduleHook(550, function() --TODO: change that into an appropriate conditional hook
		computeTaunt2()
	end)
end
modapiext.events.onResetTurn:subscribe(EVENT_onResetTurn)