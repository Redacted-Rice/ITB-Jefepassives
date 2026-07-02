local mod = {
	id = "jefepassives",
	name = "Jefe Passives",
	icon = "img/mod_icon.png",
	version = "0.1.2",
	modApiVersion = "2.9.5",
	gameVersion = "1.2.93",
	description = "A community pack of passive weapons made for our community YouTuber Jefepato",
	dependencies = {
		modApiExt = "1.24",
	},
	libs = {},
}

function mod:init()
	self.libs.passiveEffect  = require(self.scriptPath .. "libs/passiveEffect")
	self.libs.armorDetection = require(self.scriptPath .. "libs/armorDetection")
	self.libs.boardUtils     = require(self.scriptPath .. "libs/boardUtils")
	require(self.scriptPath .. "libs/boardEvents")
	require(self.scriptPath .. "libs/customAnim")
	require(self.scriptPath .. "libs/NClickLib")
	require(self.scriptPath .. "libs/orbitalPawn")
	require(self.scriptPath .. "libs/orbitalIcon")

	require(self.scriptPath .. "images")

	require(self.scriptPath .. "weapons/passive_acid_rain")
	require(self.scriptPath .. "weapons/passive_aligned_radar")
	require(self.scriptPath .. "weapons/passive_cancel_nearby_attack")
	require(self.scriptPath .. "weapons/passive_deploy_items")
	require(self.scriptPath .. "weapons/passive_lonely_awkward")	
	require(self.scriptPath .. "weapons/passive_mark_random")
	require(self.scriptPath .. "weapons/passive_materia")
	require(self.scriptPath .. "weapons/passive_migration_instincts")
	require(self.scriptPath .. "weapons/passive_random_swap")
	require(self.scriptPath .. "weapons/passive_rebound")
	require(self.scriptPath .. "weapons/passive_rst_decoy")
	require(self.scriptPath .. "weapons/passive_spikycleats")
	require(self.scriptPath .. "weapons/passive_taunting_field")
	require(self.scriptPath .. "weapons/passive_waterfall")

	modApi:addWeaponDrop("Jefepassives_AcidRain")
	modApi:addWeaponDrop("Jefepassives_AlignedRadar")
	modApi:addWeaponDrop("Jefepassives_Awkwardness_Passive")
	modApi:addWeaponDrop("Jefepassives_CancelNearbyAttacks")
	modApi:addWeaponDrop("Jefepassives_DeployItems")
	modApi:addWeaponDrop("Jefepassives_Loneliness_Passive")	
	modApi:addWeaponDrop("Jefepassives_MarkRandom")
	modApi:addWeaponDrop("Jefepassives_Materia_Passive")
	modApi:addWeaponDrop("Jefepassives_MigratoryEvoker")
	modApi:addWeaponDrop("Jefepassives_RandomSwap")
	modApi:addWeaponDrop("Jefepassives_Rebound_Passive")
	modApi:addWeaponDrop("Jefepassives_RstDecoy")
	modApi:addWeaponDrop("Jefepassives_SpikyCleats_Passive")
	modApi:addWeaponDrop("Jefepassives_TauntingField")
	modApi:addWeaponDrop("Jefepassives_Waterfall")
end

function mod:load(options, version)
end

return mod
