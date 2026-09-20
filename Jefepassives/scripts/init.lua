local mod = {
	id = "JefePassives",
	name = "JefePassives",
	icon = "img/mod_icon.png",
	version = "1.2.0",
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

local warningShown = false
local function showChronoMemhackWarning()
	if warningShown then return end
	modApi:scheduleHook(50, function()
		sdlext.showInfoDialog(
			"Requirement Warning",
			"RedactedRice Memhack is not installed and enabled.\n\n"..
			"Chrono Beacons will still be available, but without Memhack it only "..
			"will do its upgrade effect as the primary effect - "..
			"It will not redirect Time Pods.\n\n"..
			"Install and enable RedactedRice Memhack for the full effect, then restart the game "..
			"or you can remove this warning by disabling the full effect in the mod options.",
			nil,
			{
				minW = 600,
				minH = 200,
			}
		)
	end)
	warningShown = true
end

function mod:metadata()
	modApi:addGenerationOption(
		"fullChronoBeacons",
		"Enabled Full Chrono Beacon Effect",
		"!!! REQUIRES RESTART !!!\n\nEnables the full effect of the Chrono Beacons passive weapon. If not enabled, "..
		"the upgrade effect will become the primary effect. Requires the RedactedRice Memhack extension.",
		{ enabled = true }
	)
end

function mod:init(options)
	options = options or {}

	self.libs.boardUtils = require(self.scriptPath .. "libs/boardUtils")
	self.libs.passiveEffect = require(self.scriptPath .. "libs/passiveEffect")
	self.libs.pawnTypeUtils = require(self.scriptPath .. "libs/pawnTypeUtils")

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
	--require(self.scriptPath .. "weapons/passive_mark_random")
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
	modApi:addWeaponDrop("Jefepassives_Awkwardness")
	modApi:addWeaponDrop("Jefepassives_CancelNearbyAttacks")
	modApi:addWeaponDrop("Jefepassives_DeployItems")
	modApi:addWeaponDrop("Jefepassives_Loneliness")	
	--modApi:addWeaponDrop("Jefepassives_MarkRandom")
	modApi:addWeaponDrop("Jefepassives_Materia")
	modApi:addWeaponDrop("Jefepassives_MigratoryEvoker")
	modApi:addWeaponDrop("Jefepassives_RandomSwap")
	modApi:addWeaponDrop("Jefepassives_Rebound")
	modApi:addWeaponDrop("Jefepassives_RstDecoy")
	modApi:addWeaponDrop("Jefepassives_SpikyCleats")
	modApi:addWeaponDrop("Jefepassives_TauntingField")
	modApi:addWeaponDrop("Jefepassives_Waterfall")

	-- chrono beacons has some special handling
	local chronoBeacons = require(self.scriptPath .. "weapons/passive_chrono_beacons")
	chronoBeacons:init(isOptionEnabled(options, "fullChronoBeacons"))
	modApi:addWeaponDrop("Jefepassives_ChronoBeacons")
end

function mod:load(options, version)
	if isOptionEnabled(options, "fullChronoBeacons") and
            not isMemhackAvailableAndEnabled() then
		showChronoMemhackWarning()
		LOG("Jefepassives: Memhack is not enabled. Chrono Beacons will use its reduced effect only.")
	end
end

return mod
