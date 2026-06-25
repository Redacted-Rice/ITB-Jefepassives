local mod = {
	id = "jefepassives",
	name = "Jefe Passives",
	icon = "img/mod_icon.png",
	version = "0.1.1",
	modApiVersion = "2.9.5",
	gameVersion = "1.2.93",
	description = "A community pack of passive weapons made for our community YouTuber Jefepato",
	dependencies = {
		modApiExt = "1.24",
	},
	libs = {},
}

function mod:init()
	self.libs.passiveEffect = require(self.scriptPath .. "libs/passiveEffect")
	self.libs.boardUtils = require(self.scriptPath .. "libs/boardUtils")
	require(self.scriptPath .. "libs/boardEvents")

	require(self.scriptPath .. "images")

	require(self.scriptPath .. "weapons/passive_acid_rain")
	require(self.scriptPath .. "weapons/passive_cancel_nearby_attack")
	require(self.scriptPath .. "weapons/passive_deploy_items")
	require(self.scriptPath .. "weapons/passive_migration_instincts")
	require(self.scriptPath .. "weapons/passive_random_swap")
	require(self.scriptPath .. "weapons/passive_rst_decoy")

	modApi:addWeaponDrop("Jefepassives_AcidRain_Passive")
	modApi:addWeaponDrop("Jefepassives_CancelNearbyAttacks_Passive")
	modApi:addWeaponDrop("jefepassives_DeployItems_Passive")
	modApi:addWeaponDrop("Jefepassives_MigratoryEvoker")
	modApi:addWeaponDrop("Jefepassives_RandomSwap_Passive")
	modApi:addWeaponDrop("Jefepassives_RstDecoy")
end

function mod:load(options, version)
end

return mod
