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
        easyEdit = "2.0.8",
	},
	libs = {},
}

local function isOptionEnabled(options, optionId)
	return options
		and options[optionId]
		and options[optionId].enabled
end

local function isMemhackAvailableAndEnabled()
	local initData = mod_loader.mods["redactedrice_memhack"]
	local settingData = modApi:getCurrentModConfiguration()["redactedrice_memhack"]
	return initData and initData.initialized and 
			settingData and settingData.enabled
end

local function showChronoMemhackWarning()
	modApi:scheduleHook(50, function()
		sdlext.showInfoDialog(
			"Requirement Warning",
			"!! RESTART REQUIRED !!\n\n"..
			"The Jefepassive's Chrono Beacons requires RedactedRice Memhack extension which is not installed and enabled." .. 
			" Either install and enable it or disable \"Include Chrono Beacon passive\" in Jefepassives settings. Then restart the game.",
			nil,
			{
				minW = 600,
				minH = 200,
			}
		)
	end)
end

function mod:metadata()
	modApi:addGenerationOption(
		"includeChronoBeacon",
		"Include Chrono Beacon passive",
		"Adds the Chrono Beacons passive weapon to the drop pool. Requires the RedactedRice Memhack extension.",
		{ enabled = true }
	)
end

function mod:init(options)
	options = options or {}

	self.libs.armorDetection = require(self.scriptPath .. "libs/armorDetection")
	self.libs.boardUtils = require(self.scriptPath .. "libs/boardUtils")
	self.libs.passiveEffect = require(self.scriptPath .. "libs/passiveEffect")
	self.libs.pawnTypeUtils = require(self.scriptPath .. "libs/pawnTypeUtils")

	require(self.scriptPath .. "libs/boardEvents")
	require(self.scriptPath .."libs/orbitalPawn")
	require(self.scriptPath .."libs/NClickLib")
	require(self.scriptPath .."libs/orbitalIcon")

	require(self.scriptPath .. "images")

	require(self.scriptPath .. "weapons/passive_acid_rain")
	require(self.scriptPath .. "weapons/passive_cancel_nearby_attack")
	require(self.scriptPath .. "weapons/passive_deploy_items")
	require(self.scriptPath .. "weapons/passive_lonely_awkward")
	require(self.scriptPath .. "weapons/passive_materia")
	require(self.scriptPath .. "weapons/passive_migration_instincts")
	require(self.scriptPath .. "weapons/passive_random_swap")
	require(self.scriptPath .. "weapons/passive_rebound")
	require(self.scriptPath .. "weapons/passive_rst_decoy")
	require(self.scriptPath .. "weapons/passive_spikycleats")

	modApi:addWeaponDrop("Jefepassives_AcidRain_Passive")
	modApi:addWeaponDrop("Jefepassives_Awkwardness_Passive")
	modApi:addWeaponDrop("Jefepassives_CancelNearbyAttacks_Passive")
	modApi:addWeaponDrop("jefepassives_DeployItems_Passive")
	modApi:addWeaponDrop("Jefepassives_Loneliness_Passive")
	modApi:addWeaponDrop("Jefepassives_Materia_Passive")
	modApi:addWeaponDrop("Jefepassives_MigratoryEvoker")
	modApi:addWeaponDrop("Jefepassives_RandomSwap_Passive")
	modApi:addWeaponDrop("Jefepassives_Rebound_Passive")
	modApi:addWeaponDrop("Jefepassives_RstDecoy")
	modApi:addWeaponDrop("Jefepassives_SpikyCleats_Passive")

	if isOptionEnabled(options, "includeChronoBeacon") then
		LOG("ENABLED")
		modApi:appendAsset(
			"img/weapons/passives/passive_chrono_homing.png",
			self.resourcePath .. "img/weapons/passives/passive_chrono_homing.png"
		)
		modApi:appendAsset(
			"img/effects/chrono_debris.png",
			self.resourcePath .. "img/effects/chrono_debris.png"
		)
		require(self.scriptPath .. "weapons/passive_chrono_beacons")
		modApi:addWeaponDrop("Jefepassives_ChronoBeacons")
	end
end

function mod:load(options, version)
	if isOptionEnabled(options, "includeChronoBeacon") and 
			not isMemhackAvailableAndEnabled() then
		showChronoMemhackWarning()
		LOG("Jefepassives: Chrono Beacons is enabled in mod options but Mem Hack is not enabled.")
	end
end

return mod
