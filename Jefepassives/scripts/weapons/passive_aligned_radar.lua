--[[

###############
### CREDITS ###
###############

Idea: Truelch
Code: Truelch
Art : Truelch


############
### MISC ###
############

V1: aligned enemies
V2: aligned allies


############
### TODO ###
############

Animations of the "data flux".

Check if TC weapons get +1 damage or cumulate bonus twice.

Only OTHER allies? (so, excluding self?)

]]


local mod = mod_loader.mods[modApi.currentMod]
local resourcePath = mod.resourcePath
local scriptPath   = mod.scriptPath
local customAnim   = require(scriptPath.."libs/customAnim")
local weaponArmed  = require(scriptPath.."libs/weaponArmed")


for dir = DIR_START, DIR_END do
	modApi:appendAsset("img/effects/jp_aligned_v2_"..dir..".png", resourcePath.."img/effects/jp_aligned_v2_"..dir..".png")
		Location["effects/jp_aligned_v2_"..dir..".png"] = Point(-27, 2)
	ANIMS["jp_aligned_v2_"..dir] = Animation:new{
		Image = "effects/jp_aligned_v2_"..dir..".png",
		PosX = -27,
		PosY = 2,
		Time = 0.1,
		NumFrames = 7,
		Loop = true,
		Layer = ANIMS.LAYER_BACK, --this is still displayed ON TOP of a pod. (I'll avoid time pod anyway)
	}
end

modApi:appendAsset("img/effects/jp_radar_target.png", resourcePath.."img/effects/jp_radar_target.png")
	Location["effects/jp_radar_target.png"] = Point(-27, 2)
ANIMS.jp_radar_target = Animation:new{
	Image = "effects/jp_radar_target.png",
	PosX = -27,
	PosY = 2,
	Time = 0.2, --0.175, --0.1,
	NumFrames = 4,
	Loop = true,
	Layer = ANIMS.LAYER_BACK, --this is still displayed ON TOP of a pod. (I'll avoid time pod anyway)
}


local SHOW_LOGS = false

local EXCLUDE_RADAR_OWNER = true
local CHECK_ALIGNED_WITH_ENEMIES = true --V1
local CHECK_ALIGNED_WITH_ALLIES = false --V2

Jefepassives_AlignedRadar = PassiveSkill:new{
	--Infos
	Name = "Data-Link", --Directional Radar --AESA Radar --Directional Fire Control System Support --Passive Radar

	--If owner is excluded, let's say that OTHER allies benefit from it.
	Description = "Other allies get +1 damage against enemies aligned with the Radar.", --V1
	--Description = "Other Aligned allies get +1 damage on their weapons.", --V2

	PowerCost = 1, --I'm not sure, certainly should be 2 cores
	Icon = "weapons/passives/passive_mark_random.png", --TODO

	--Passive
	Passive = "Jefepassives_AlignedRadar",

	--Tip image
	--V1: Mech aligned with enemy
	TipImage = {
		Unit   = Point(2, 3),
		Enemy  = Point(2, 1),
		Target = Point(2, 1),
	}
}

local function isAligned(pos1, pos2)
	return pos1.x == pos2.x or pos1.y == pos2.y
end

local function getRadarPos()
	local radarPos = nil
	for i = 0, 2 do
		local mech = Board:GetPawn(i)
		if mech ~= nil then
			local poweredWeapons = mech:GetPoweredWeapons()
			for i, weapon in ipairs(poweredWeapons) do
				if weapon == "Jefepassives_AlignedRadar" then --TODO: change that line if I do upgraded versions!!
					radarPos = mech:GetSpace()
					if (SHOW_LOGS) then LOG("radarPos: "..radarPos:GetString()) end
					break
				end
			end
		end
	end
	return radarPos
end

local function isValidForBonusDamage(radarPos, p1, spaceDamage)

	local shooter = Board:GetPawn(p1)
	if shooter == nil then
		if (SHOW_LOGS) then LOG("isValidForBonusDamage -> Shooter is nil -> RETURN FALSE") end
		return false
	elseif shooter:IsEnemy() then
		if (SHOW_LOGS) then LOG("isValidForBonusDamage -> Shooter is enemy -> RETURN FALSE") end
		return false
	end

	--Maybe also return true if targetPawn == nil?
	local targetPawn = Board:GetPawn(spaceDamage.loc)
	if targetPawn ~= nil and not targetPawn:IsEnemy() then
		if (SHOW_LOGS) then LOG("isValidForBonusDamage -> Target is an ally -> RETURN FALSE") end
		return false
	end

	--V1: target aligned with radar?
	if CHECK_ALIGNED_WITH_ENEMIES and not isAligned(radarPos, spaceDamage.loc) then
		if (SHOW_LOGS) then LOG("isValidForBonusDamage -> Target is not aligned with the Radar -> RETURN FALSE") end
		return false
	end
	
	--V2: shooter aligned with radar?
	if CHECK_ALIGNED_WITH_ALLIES and not isAligned(radarPos, p1) then
		if (SHOW_LOGS) then LOG("isValidForBonusDamage -> Ally is not aligned with the Radar -> RETURN FALSE") end
		return false
	end

	--Shooter is the owner of the radar (exclude it!)
	if EXCLUDE_RADAR_OWNER and p1 == radarPos then
		if (SHOW_LOGS) then LOG("isValidForBonusDamage -> Radar owner is the one shooting and we're exluding it -> RETURN FALSE") end
		return false
	end

	--Unauthorized damage values
	local damages = { DAMAGE_DEATH, DAMAGE_ZERO, SERIOUSLY_JUST_ONE }
	if spaceDamage.iDamage <= 0 or list_contains(damages, spaceDamage.iDamage) then
		if (SHOW_LOGS) then LOG("isValidForBonusDamage -> Unauthorized damage value -> RETURN FALSE") end
		return false
	end

	--Unauthorized custom tiles (tosx' rocks, but maybe others in the future?)
	if Board:GetCustomTile(spaceDamage.loc) == "tosx_rocks_0.png" then
		if (SHOW_LOGS) then LOG("isValidForBonusDamage -> tosx' rocks! -> RETURN FALSE") end
		return false
	end

	--ALL GOOD!
	if (SHOW_LOGS) then LOG("isValidForBonusDamage -> ALL GOOD -> RETURN TRUE") end
	return true
end

local function computeAlignedBonusDamage(mission, pawn, weaponId, p1, p2, skillEffect)
	if IsPassiveSkill("Jefepassives_AlignedRadar") then
		local radarPos = getRadarPos()

		if radarPos ~= nil then
			--Damage loop
			for i = 1, skillEffect.effect:size() do
				local spaceDamage = skillEffect.effect:index(i)
				if isValidForBonusDamage(radarPos, p1, spaceDamage) then
					if (SHOW_LOGS) then LOG(" -> is valid for bonus damage!") end
					spaceDamage.iDamage = spaceDamage.iDamage + 1
				end
			end
		else
			if (SHOW_LOGS) then LOG("computeAlignedBonusDamage -> radarPos is nil!") end
		end
	end
end

local EVENT_onSkillBuild = function(mission, pawn, weaponId, p1, p2, skillEffect)
	computeAlignedBonusDamage(mission, pawn, weaponId, p1, p2, skillEffect)
end

local EVENT_onFinalEffectBuild = function(mission, pawn, weaponId, p1, p2, p3, skillEffect)
	computeAlignedBonusDamage(mission, pawn, weaponId, p1, p2, skillEffect)
end



modapiext.events.onSkillBuild:subscribe(EVENT_onSkillBuild)
modapiext.events.onFinalEffectBuild:subscribe(EVENT_onFinalEffectBuild)


local function showAnimations()
	local radarPos = getRadarPos()

	if radarPos ~= nil then
		for dir = DIR_START, DIR_END do
			local lastEnemy
			local animPositions = {}

			--First loop
			for k = 1, 7 do
				local curr = radarPos + DIR_VECTORS[dir] * k				
				if Board:IsValid(curr) then
					local pawn = Board:GetPawn(curr)
					if pawn ~= nil and pawn:IsEnemy() then
						--customAnim:add(curr, "jp_radar_target")
						lastEnemy = pawn
					else
						--customAnim:add(curr, "jp_aligned_v2_"..dir)
					end
				else
					break
				end
			end

			if lastEnemy ~= nil then
				--Second loop
				for k = 1, 7 do
					local curr = radarPos + DIR_VECTORS[dir] * k
					local pawn = Board:GetPawn(curr)
					if pawn ~= nil and pawn:IsEnemy() then
						customAnim:add(curr, "jp_radar_target")
						if pawn:GetId() == lastEnemy:GetId() then
							break
						end
					else
						customAnim:add(curr, "jp_aligned_v2_"..dir)
					end
				end
			end
		end
	end
end

local function hideAnimations()
	--Brutal way
	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)

			for dir = DIR_START, DIR_END do
				customAnim:rem(curr, "jp_aligned_v2_"..dir)
			end

			customAnim:rem(curr, "jp_radar_target")
		end
	end
end


local function onWeaponArmed(weapon, pawnId)
	--LOGF("Pawn id %s armed weapon %s", tostring(pawnId), tostring(weapon.__Id))

	if weapon.__Id ~= "Move" and IsPassiveSkill("Jefepassives_AlignedRadar") then
		showAnimations()
	end
end
weaponArmed.events.onWeaponArmed:subscribe(onWeaponArmed)


local function onWeaponUnarmed(weapon, pawnId)
	--LOGF("Pawn id %s unarmed weapon %s", tostring(pawnId), tostring(weapon.__Id))

	--if IsPassiveSkill("Jefepassives_AlignedRadar") then
	hideAnimations()
	--end
end
weaponArmed.events.onWeaponUnarmed:subscribe(onWeaponUnarmed)