local boardUtils = mod_loader.mods[modApi.currentMod].libs.boardUtils

local a = ANIMS

-- The loading paths and image loading approach are super finicky for pawns apparantly
-- This finally seems to be a location and load apporach that works for whatever reason
a.jp_rst_decoy = a.BaseUnit:new{
	Image = "units/passive/fake_building_standing.png",
	PosX = -28,
	PosY = -10,
}

-- TODO: Consider massive or not and if we can do water images and a water death

local DAT = 0.09
local SAT = DAT * 4
a.jp_rst_decoyd = a.jp_rst_decoy:new{
	Image = "units/passive/fake_building_a.png",
	PosX = -53,
	PosY = -10,
	NumFrames = 11,
	Lengths = {
		SAT, DAT, DAT, DAT, DAT, DAT, DAT, DAT, DAT, DAT, DAT},
	Loop = false,
}

Jefepassives_RstDecoy_Pawn = Pawn:new{
	Name = "RST Decoy",
	Health = 1,
	Neutral = true,
	Image = "jp_rst_decoy",
	MoveSpeed = 0,
	SkillList = { },
	DefaultTeam = TEAM_PLAYER,
	IgnoreSmoke = true,
	IgnoreFlip = true,
	IsPortrait = false,
	SpaceColor = false,
}
AddPawn("Jefepassives_RstDecoy_Pawn")

-- TODO: Eventually use a different image that is metal instead of wood/cardboard looking
-- TODO: Maybe make these unpushable?
Jefepassives_RstDecoy_Pawn_Reinforced = Pawn:new{
	Name = "RST Decoy",
	Health = 4,
	Neutral = true,
	Image = "jp_rst_decoy",
	MoveSpeed = 0,
	SkillList = { },
	DefaultTeam = TEAM_PLAYER,
	IgnoreSmoke = true,
	IgnoreFlip = true,
	IgnoreFire = true,
	IsPortrait = false,
	SpaceColor = false,
}
AddPawn("Jefepassives_RstDecoy_Pawn_Reinforced")

Jefepassives_RstDecoy_Passive = PassiveSkill:new{
	Name = "RST Decoy",
	Description = "At mission start setups a decoy on a random tile.",
	Icon = "weapons/passives/passive_rst_decoy.png",
	Rarity = 1,
	PowerCost = 0,
	Damage = 0,
	Upgrades = 2,
	UpgradeCost = {2, 2},
	DecoyCount = 1,
	Reinforced = false,
	Passive = "Jefepassives_RstDecoy_Passive",
	TipImage = {
		Unit = Point(2, 2),
	},
	DecoyPawnTypes = {
		Jefepassives_RstDecoy_Pawn = true,
		Jefepassives_RstDecoy_Pawn_Reinforced = true,
	},
	PlanEnvOriginalKey = "_jefepassivesRstDecoyPlanEnvOriginal",
	PlanEnvWrapperInstalledKey = "_jefepassivesRstDecoyPlanEnvWrapped",
	Debug = true,
}

local passiveEffect = mod_loader.mods[modApi.currentMod].libs.passiveEffect
Jefepassives_RstDecoy_Passive.passiveEffect = passiveEffect

Weapon_Texts.Jefepassives_RstDecoy_Passive_Upgrade1 = "Reinforced"
Jefepassives_RstDecoy_Passive_A = Jefepassives_RstDecoy_Passive:new{
	UpgradeDescription = "Decoys have +3 Health.",
	Reinforced = true,
	Passive = "Jefepassives_RstDecoy_Passive_A",
}

Weapon_Texts.Jefepassives_RstDecoy_Passive_Upgrade2 = "Mass Produce"
Jefepassives_RstDecoy_Passive_B = Jefepassives_RstDecoy_Passive:new{
	UpgradeDescription = "Places an additional decoy.",
	DecoyCount = 2,
	Passive = "Jefepassives_RstDecoy_Passive_B",
}

Jefepassives_RstDecoy_Passive_AB = Jefepassives_RstDecoy_Passive_A:new{
	DecoyCount = 2,
	Passive = "Jefepassives_RstDecoy_Passive_AB",
}

function Jefepassives_RstDecoy_Passive:getDecoyPawnType()
	if self.Reinforced then
		return "Jefepassives_RstDecoy_Pawn_Reinforced"
	end
	return "Jefepassives_RstDecoy_Pawn"
end

function Jefepassives_RstDecoy_Passive:GetPassiveSkillEffect_MissionStartHook(mission)
	local pawnType = self:getDecoyPawnType()
	-- TODO: Decide on if I want it massive or not and what that means for the pathing
	local choices = boardUtils.getSafeSpawnTiles(PATH_GROUND)
	local spawnCount = math.min(self.DecoyCount, #choices)

	if spawnCount < self.DecoyCount and self.Debug then
		LOG(string.format("Jefepassives RST Decoy: only %d safe tile(s) available for %d decoy(s)",
				#choices, self.DecoyCount))
	end

	for i = 1, spawnCount do
		local choice = random_removal(choices)
		local decoy = PAWN_FACTORY:CreatePawn(pawnType)
		Board:AddPawn(decoy, choice)
	end
end

passiveEffect:addPassiveEffect(
	"Jefepassives_RstDecoy_Passive",
	{"missionStartHook"}
)

function Jefepassives_RstDecoy_Passive:isDecoyPawn(pawn)
	return pawn and self.DecoyPawnTypes[pawn:GetType()]
end

function Jefepassives_RstDecoy_Passive:tempSetDecoysAsBuildings(changedTiles)
	if not Board then
		if self.Debug then LOG("Jefepassives RST Decoy: PlanEnvironment changing terrain skipped (no board or mission)") end
		return 0
	end

	local count = 0
	for _, pawnId in ipairs(extract_table(Board:GetPawns(TEAM_ANY))) do
		local pawn = Board:GetPawn(pawnId)
		if self:isDecoyPawn(pawn) then
			local space = pawn:GetSpace()
			if Board:IsValid(space) and changedTiles[space] == nil then
				local terrain = Board:GetTerrain(space)
				changedTiles[space] = terrain
				Board:SetTerrain(space, TERRAIN_BUILDING)
				count = count + 1
				if self.Debug then
					LOG(string.format("Jefepassives RST Decoy: changing %s (%s) terrain %d -> TERRAIN_BUILDING",
							pawn:GetType(), space:GetString(), terrain))
				end
			end
		end
	end

	if count == 0 and self.Debug then
		LOG("Jefepassives RST Decoy: PlanEnvironment found no decoy tiles")
	end
	return count
end

function Jefepassives_RstDecoy_Passive:restoreDecoyOriginalTerrain(changedTiles)
	local count = 0
	for space, terrain in pairs(changedTiles) do
		if Board and Board:IsValid(space) then
			Board:SetTerrain(space, terrain)
			count = count + 1
			if self.Debug then
				LOG(string.format("Jefepassives RST Decoy: restored %s to terrain %d",
						space:GetString(), terrain))
			end
		end
	end
	return count
end

function Jefepassives_RstDecoy_Passive:installPlanEnvironmentWrapper()
	if Mission[self.PlanEnvOriginalKey] then
		Returns
	end
	Mission[self.PlanEnvOriginalKey] = Mission.PlanEnvironment
	local oldPlanEnvironment = Mission[self.PlanEnvOriginalKey]
	local passive = self

	if self.Debug then LOG("Jefepassives RST Decoy: PlanEnvironment wrapper installed") end

	function Mission:PlanEnvironment(...)
		local turn = Game and Game:GetTurnCount() or -1
		if passive.Debug then
			LOG(string.format("Jefepassives RST Decoy: PlanEnvironment start (turn %d)", turn))
		end

		local changedTiles = {}
		local disguisedCount = passive:tempSetDecoysAsBuildings(changedTiles)

		local ok, result = pcall(oldPlanEnvironment, self, ...)
		local restoredCount = passive:restoreDecoyOriginalTerrain(changedTiles)

		if not ok then
			if passive.Debug then
				LOG(string.format("Jefepassives RST Decoy: PlanEnvironment failed after restoring %d tile(s): %s",
						restoredCount, tostring(result)))
			end
			error(result)
		end

		if passive.Debug then
			LOG(string.format("Jefepassives RST Decoy: PlanEnvironment done (turn %d, result=%s, disguised=%d, restored=%d)",
				turn, tostring(result), disguisedCount, restoredCount))
		end
		return result
	end
end

modApi.events.onModsLoaded:subscribe(function()
	Jefepassives_RstDecoy_Passive:installPlanEnvironmentWrapper()
end)