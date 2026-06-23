local mod = {
	id = "jefepassives",
	name = "Jefe Passives",
	icon = "img/mod_icon.png",
	version = "0.1.0",
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
	self.libs.armorDetection = require(self.scriptPath .. "libs/armorDetection")

	require(self.scriptPath .. "images")
	require(self.scriptPath .. "weapons/passive_rst_decoy")
	require(self.scriptPath .. "weapons/passive_lonely_awkward")

	modApi:addWeaponDrop("Jefepassives_RstDecoy")
	modApi:addWeaponDrop("Jefepassives_Loneliness_Passive")
	modApi:addWeaponDrop("Jefepassives_Awkwardness_Passive")
end

function mod:load(options, version)
	self.libs.passiveEffect:load()
end

return mod
