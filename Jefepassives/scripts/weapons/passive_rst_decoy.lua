local a = ANIMS

-- TODO: Need to actually position right
a.jp_rst_decoy = a.BaseUnit:new{
	Image = "effects/fake_building_standing.png",
	PosX = -18,
	PosY = -1,
}

a.jp_rst_decoyd = a.jp_rst_decoy:new{
	Image = "effects/fake_building_a.png",
	PosX = -34,
	PosY = -9,
	NumFrames = 10,
	Time = 0.09,
	Loop = false,
}

a.jp_rst_decoy_flat = a.BaseUnit:new{
	Image = "effects/fake_building_flat.png",
	PosX = -18,
	PosY = -1,
}

-- TODO: Need to make on players team but originally when I tried it kept crashing the game
-- Its still crashing as it is when I try to attack with mechs for some reason
Jefepassives_RstDecoy_Pawn = {
	Name = "RST Decoy",
	Health = 1,
	Neutral = true,
	MoveSpeed = 0,
	Image = "jp_rst_decoy",
	Pushable = false,
	IsPortrait = false,
	DefaultTeam = TEAM_NONE,
	IgnoreSmoke = true,
	ImpactMaterial = IMPACT_ROCK,
	SoundLocation = "/support/rock/",
}
AddPawn("Jefepassives_RstDecoy_Pawn")

-- TODO: Eventually use a different image that is metal instead of wood/cardboard looking
Jefepassives_RstDecoy_Pawn_Reinforced = {
	Name = "RST Decoy",
	Health = 4,
	Neutral = true,
	MoveSpeed = 0,
	Image = "jp_rst_decoy",
	Pushable = false,
	IsPortrait = false,
	DefaultTeam = TEAM_NONE,
	IgnoreSmoke = true,
	ImpactMaterial = IMPACT_ROCK,
	SoundLocation = "/support/rock/",
}
AddPawn("Jefepassives_RstDecoy_Pawn_Reinforced")

Jefepassives_RstDecoy = PassiveSkill:new{
	Name = "RST Decoy",
	Description = "At mission start, sets up a decoy structure on a random, open tile.",
	Icon = "weapons/passives/passive_rst_decoy.png",
	Rarity = 1,
	PowerCost = 0,
	Damage = 0,
	Upgrades = 2,
	UpgradeCost = {2, 2},
	DecoyCount = 1,
	Reinforced = false,
	TipImage = {
		Unit = Point(2, 2),
	},
}

local passiveEffect = mod_loader.mods[modApi.currentMod].libs.passiveEffect
Jefepassives_RstDecoy.passiveEffect = passiveEffect

Weapon_Texts.Jefepassives_RstDecoy_Upgrade1 = "Reinforced"
Jefepassives_RstDecoy_A = Jefepassives_RstDecoy:new{
	UpgradeDescription = "Decoys have +3 Health.",
	Reinforced = true,
}

Weapon_Texts.Jefepassives_RstDecoy_Upgrade2 = "Mass Produce"
Jefepassives_RstDecoy_B = Jefepassives_RstDecoy:new{
	UpgradeDescription = "Places an additional decoy.",
	DecoyCount = 2,
}

Jefepassives_RstDecoy_AB = Jefepassives_RstDecoy_A:new{
	DecoyCount = 2,
}

local DECOY_PAWN_TYPES = {
	"Jefepassives_RstDecoy_Pawn",
	"Jefepassives_RstDecoy_Pawn_Reinforced",
}

local function isDecoyPawn(pawn)
	local pawnType = pawn:GetType()
	for _, decoyType in ipairs(DECOY_PAWN_TYPES) do
		if pawnType == decoyType then
			return true
		end
	end
	return false
end

local function getOccupiableTiles()
	local candidates = {}
	local boardSize = Board:GetSize()

	for x = 0, boardSize.x - 1 do
		for y = 0, boardSize.y - 1 do
			local point = Point(x, y)
			if Board:IsValid(point)
				and not Board:IsPawnSpace(point)
				and not Board:IsBuilding(point)
				and Board:GetTerrain(point) ~= TERRAIN_MOUNTAIN
				and not Board:IsBlocked(point, PATH_GROUND) then
				table.insert(candidates, point)
			end
		end
	end

	return candidates
end

local function pickRandomTiles(count)
	local candidates = getOccupiableTiles()
	local picked = {}

	for _ = 1, count do
		if #candidates == 0 then
			break
		end

		local index = math.random(1, #candidates)
		table.insert(picked, candidates[index])
		table.remove(candidates, index)
	end

	return picked
end

function Jefepassives_RstDecoy:getDecoyPawnType()
	if self.Reinforced then
		return "Jefepassives_RstDecoy_Pawn_Reinforced"
	end
	return "Jefepassives_RstDecoy_Pawn"
end

-- TODO: Need to mark to avoid environment effects
function Jefepassives_RstDecoy:spawnDecoys()
	if not Board then
		return
	end

	local pawnType = self:getDecoyPawnType()
	local locations = pickRandomTiles(self.DecoyCount)

	for _, location in ipairs(locations) do
		if Board:IsValid(location) and not Board:IsPawnSpace(location) then
			Board:AddPawn(pawnType, location)
		end
	end
end

function Jefepassives_RstDecoy:GetPassiveSkillEffect_MissionStartHook(mission)
	self:spawnDecoys()
end

function Jefepassives_RstDecoy:GetPassiveSkillEffect_PawnKilledHook(mission, pawn)
	if not isDecoyPawn(pawn) then
		return
	end

	local location = pawn:GetSpace()
	if Board:IsValid(location) then
		Board:AddAnimation(location, "jp_rst_decoy_flat", 1)
	end
end

passiveEffect:addPassiveEffect(
	"Jefepassives_RstDecoy",
	{"missionStartHook", "pawnKilledHook"}
)
