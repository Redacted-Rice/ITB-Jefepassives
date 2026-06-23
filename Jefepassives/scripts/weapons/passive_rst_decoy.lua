local a = ANIMS

-- The loading paths and image loading approach are super finicky for pawns apparantly
-- This finally seems to be a location and load apporach that works for whatever reason
a.jp_rst_decoy = a.BaseUnit:new{
	Image = "units/passive/fake_building_standing.png",
	PosX = -28,
	PosY = -10,
}

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
	NonGrid = true,
	IgnoreSmoke = true,
	IgnoreFlip = true,
	Pushable = false,
	IsPortrait = false,
}
AddPawn("Jefepassives_RstDecoy_Pawn")

-- TODO: Eventually use a different image that is metal instead of wood/cardboard looking
Jefepassives_RstDecoy_Pawn_Reinforced = Pawn:new{
	Name = "RST Decoy",
	Health = 4,
	Neutral = true,
	Image = "jp_rst_decoy",
	MoveSpeed = 0,
	SkillList = { },
	DefaultTeam = TEAM_PLAYER,
	NonGrid = true,
	IgnoreSmoke = true,
	IgnoreFlip = true,
	IgnoreFire = true,
	SoundLocation = "/support/train",
	Pushable = false,
	IsPortrait = false,
}
AddPawn("Jefepassives_RstDecoy_Pawn_Reinforced")

Jefepassives_RstDecoy = PassiveSkill:new{
	Name = "RST Decoy",
	Description = "At mission start, replaces a building with a decoy structure.",
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

function Jefepassives_RstDecoy:getDecoyPawnType()
	if self.Reinforced then
		return "Jefepassives_RstDecoy_Pawn_Reinforced"
	end
	return "Jefepassives_RstDecoy_Pawn"
end

function Jefepassives_RstDecoy:GetPassiveSkillEffect_MissionStartHook(mission)
	local choices = mission:GetReplaceableBuildings()
	
	LOG("Decoy count" .. self.DecoyCount)
	for i = 1, self.DecoyCount do
		local choice = random_removal(choices)
		Board:ClearSpace(choice)
		Board:AddPawn(self:getDecoyPawnType(), choice)
	end
end

passiveEffect:addPassiveEffect(
	"Jefepassives_RstDecoy",
	{
		"missionStartHook",
	}
)
