local boardUtils = mod_loader.mods[modApi.currentMod].libs.boardUtils

local a = ANIMS

-- The loading paths and image loading approach are super finicky for pawns apparantly
-- This finally seems to be a location and load apporach that works for whatever reason
a.jp_rst_decoy = a.BaseUnit:new{
	Image = "units/passive/fake_building_standing.png",
	PosX = -28,
	PosY = -10,
}
a.jp_rst_decoy2 = a.jp_rst_decoy:new{
	Image = "units/passive/fake_building2_standing.png",
}

local shutterTime = 0.05
local pauseTime = 0.25
local fallTime = 0.09
a.jp_rst_decoyd = a.jp_rst_decoy:new{
	Image = "units/passive/fake_building_a.png",
	PosX = -53,
	PosY = -10,
	NumFrames = 13,
	Lengths = {
		shutterTime, shutterTime, shutterTime, pauseTime,
		fallTime, fallTime, fallTime, fallTime, fallTime,
		fallTime, fallTime, fallTime, fallTime,
	},
	Loop = false,
}
a.jp_rst_decoy2d = a.jp_rst_decoyd:new{
	Image = "units/passive/fake_building2_a.png",
}

Jefepassives_RstDecoy_Pawn = Pawn:new{
	Name = "RST Decoy",
	Health = 1,
	Neutral = true,
	Image = "jp_rst_decoy",
	MoveSpeed = 0,
	SkillList = { },
	DefaultTeam = TEAM_PLAYER,
	Pushable = false,
	IgnoreSmoke = true,
	IgnoreFlip = true,
	IsPortrait = false,
	SpaceColor = false,
}
AddPawn("Jefepassives_RstDecoy_Pawn")

Jefepassives_RstDecoy_Pawn_Reinforced = Pawn:new{
	Name = "RST Decoy",
	Health = 4,
	Neutral = true,
	Image = "jp_rst_decoy2",
	MoveSpeed = 0,
	SkillList = { },
	DefaultTeam = TEAM_PLAYER,
	Pushable = false,
	IgnoreSmoke = true,
	IgnoreFlip = true,
	IgnoreFire = true,
	IsPortrait = false,
	SpaceColor = false,
}
AddPawn("Jefepassives_RstDecoy_Pawn_Reinforced")

Jefepassives_RstDecoy = PassiveSkill:new{
	Name = "RST Decoy",
	Description = "At mission start setups a decoy on a random tile.",
	Icon = "weapons/passives/passive_rst_decoy.png",
	Rarity = 1,
	PowerCost = 1,
	Damage = 0,
	Upgrades = 2,
	UpgradeCost = {2, 2},
	DecoyCount = 1,
	Reinforced = false,
	TipImage = {
		CustomPawn = "Jefepassives_RstDecoy_Pawn",
		Unit = Point(2, 2),
		Building = Point(2, 1),
		Enemy = Point(2,3),
	},
	DecoyPawnTypes = {
		Jefepassives_RstDecoy_Pawn = true,
		Jefepassives_RstDecoy_Pawn_Reinforced = true,
	},
	PlanEnvOriginalKey = "_jefepassivesRstDecoyPlanEnvOriginal",
	Debug = true,
}

local passiveEffect = mod_loader.mods[modApi.currentMod].libs.passiveEffect
Jefepassives_RstDecoy.passiveEffect = passiveEffect

Weapon_Texts.Jefepassives_RstDecoy_Upgrade1 = "Reinforced"
Jefepassives_RstDecoy_A = Jefepassives_RstDecoy:new{
	UpgradeDescription = "Decoys have +3 Health.",
	Reinforced = true,
	TipImage = {
		CustomPawn = "Jefepassives_RstDecoy_Pawn_Reinforced",
		Unit = Point(2, 2),
		Building = Point(2, 1),
		Enemy = Point(2,3),
	},
}

Weapon_Texts.Jefepassives_RstDecoy_Upgrade2 = "Mass Produce"
Jefepassives_RstDecoy_B = Jefepassives_RstDecoy:new{
	UpgradeDescription = "Places an additional decoy.",
	DecoyCount = 2,
}

Jefepassives_RstDecoy_AB = Jefepassives_RstDecoy_A:new{
	DecoyCount = 2,
}

-- only a preview for passive skills
function Jefepassives_RstDecoy:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local spaceDamage = SpaceDamage(Point(2, 2), 3)
	spaceDamage.sAnimation = "SwipeClaw2"
	spaceDamage.sSound = "/enemy/scorpion_soldier_2/attack"
	ret:AddMelee(Point(2, 3), spaceDamage)
	return ret
end


function Jefepassives_RstDecoy:getDecoyPawnType()
	if self.Reinforced then
		return "Jefepassives_RstDecoy_Pawn_Reinforced"
	end
	return "Jefepassives_RstDecoy_Pawn"
end

function Jefepassives_RstDecoy:GetPassiveSkillEffect_MissionStartHook(mission)
	local pawnType = self:getDecoyPawnType()
	-- TODO: Decide on if I want it massive or not and what that means for the pathing
	local choices = boardUtils.getSafeSpawnTiles(PATH_GROUND)
	local spawnCount = math.min(self.DecoyCount, #choices)
	if self.Debug then LOG(string.format("Jefepassives RST Decoy: Spawning %d pawns", spawnCount)) end

	if spawnCount < self.DecoyCount and self.Debug then
		LOG(string.format("Jefepassives RST Decoy: only %d safe tile(s) available for %d decoy(s)",
				#choices, self.DecoyCount))
	end

	for i = 1, spawnCount do
		local choice = random_removal(choices)
		local decoy = PAWN_FACTORY:CreatePawn(pawnType)
		Board:AddPawn(decoy, choice)
		if self.Debug then LOG(string.format("Jefepassives RST Decoy: Spawned pawn at %s", choice:GetString())) end
	end
end

passiveEffect:addPassiveEffect(
	"Jefepassives_RstDecoy",
	{"missionStartHook"}
)

function Jefepassives_RstDecoy:isDecoyPawn(pawn)
	return pawn and self.DecoyPawnTypes[pawn:GetType()]
end

function Jefepassives_RstDecoy:tempSetDecoysAsBuildings(changedTiles)
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

function Jefepassives_RstDecoy:restoreDecoyOriginalTerrain(changedTiles)
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

function Jefepassives_RstDecoy:installPlanEnvironmentWrapper()
	if Mission[self.PlanEnvOriginalKey] then
		return
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
	Jefepassives_RstDecoy:installPlanEnvironmentWrapper()
end)