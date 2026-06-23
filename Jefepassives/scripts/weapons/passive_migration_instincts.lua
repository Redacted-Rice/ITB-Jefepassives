-- Vek migrate to the right at the start of the enemy turn.
local MIGRATION_DIRECTION = VEC_RIGHT
local DUCK_FLYOVER_IMAGE = "effects/flying_duck.png"
local DUCK_FLYOVER_STAGGER = 0.12

local boardUtils = mod_loader.mods[modApi.currentMod].libs.boardUtils

Jefepassives_MigrationInstincts_Passive = PassiveSkill:new{
	Name = "Migration Instincts",
	Description = "At the start of the Vek turn, each Vek attempts to move one tile to the right.",
	Icon = "weapons/passives/passive_migration_instincts.png",
	Rarity = 1,
	PowerCost = 0,
	Damage = 0,
	Upgrades = 1,
	UpgradeCost = {1},
	ExtendedMigration = false,
	Passive = "Jefepassives_MigrationInstincts_Passive",
	TipImage = {
		Unit = Point(2, 3),
		CustomEnemy = "Scorpion1",
		Enemy = Point(1, 2),
	},
}

local passiveEffect = mod_loader.mods[modApi.currentMod].libs.passiveEffect
Jefepassives_MigrationInstincts_Passive.passiveEffect = passiveEffect

Weapon_Texts.Jefepassives_MigrationInstincts_Passive_Upgrade1 = "Stampede"
Jefepassives_MigrationInstincts_Passive_A = Jefepassives_MigrationInstincts_Passive:new{
	UpgradeDescription = "Vek move up to half their move speed (rounded down, minimum 1) instead.",
	ExtendedMigration = true,
	Passive = "Jefepassives_MigrationInstincts_Passive_A",
}

-- Preview only
function Jefepassives_MigrationInstincts_Passive:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local from = self.TipImage.Enemy
	local stepCount = self.ExtendedMigration and 2 or 1

	local path = PointList()
	path:push_back(from)

	local current = from
	for _ = 1, stepCount do
		current = current + MIGRATION_DIRECTION
		path:push_back(current)
	end

	ret:AddMove(path, FULL_DELAY)
	return ret
end

function Jefepassives_MigrationInstincts_Passive:getReachableMigrationSpaces(pawn, maxSteps)
	local start = pawn:GetSpace()
	return extract_table(Board:GetReachable(start, maxSteps, pawn:GetPathProf()))
end

function Jefepassives_MigrationInstincts_Passive:getMigrationSpeed(pawn)
	local pawnSpeed = pawn:GetMoveSpeed()
	if pawnSpeed == 0 then
		return 0
	end
	if not self.ExtendedMigration then
		return 1
	end
	return math.max(1, math.floor(pawnSpeed / 2))
end

function Jefepassives_MigrationInstincts_Passive:scoreMigrationDestination(start, point, direction)
	local delta = point - start
	local progress = delta.x * direction.x + delta.y * direction.y

	if progress <= 0 then
		return nil
	end

	local perpendicular = math.abs(delta.x * direction.y - delta.y * direction.x)
	return progress * 1000 - perpendicular
end

function Jefepassives_MigrationInstincts_Passive:getMigrationDestination(pawn, direction, maxSteps, reserved)
	if maxSteps <= 0 then
		return nil
	end

	local start = pawn:GetSpace()
	local best = nil
	local bestScore = nil

	for _, point in ipairs(self:getReachableMigrationSpaces(pawn, maxSteps)) do
		if point ~= start and not (reserved and reserved[boardUtils.getSpaceHash(point)]) then
			local score = self:scoreMigrationDestination(start, point, direction)
			if score and (not bestScore or score > bestScore) then
				bestScore = score
				best = point
			end
		end
	end
	return best
end

function Jefepassives_MigrationInstincts_Passive:getCenterColumns(boardSize)
	local startX = math.max(0, math.floor(boardSize.x / 2) - 2)
	local columns = {}
	for x = startX, startX + 3 do
		if x < boardSize.x then
			table.insert(columns, x)
		end
	end
	return columns
end

function Jefepassives_MigrationInstincts_Passive:buildDuckFlyoverFormation()
	local boardSize = Board:GetSize()
	local columns = self:getCenterColumns(boardSize)
	local leadColumn = columns[math.random(1, #columns)]
	local leadRow = math.floor(boardSize.y / 2)
	local lead = Point(leadColumn, leadRow)
	local perpendicular = Point(-MIGRATION_DIRECTION.y, MIGRATION_DIRECTION.x)
	local duckCount = math.random(3, 8)
	local formation = {{space = lead, stagger = 0}}

	local depth = 1
	while #formation < duckCount do
		local back = lead - MIGRATION_DIRECTION * depth
		for side = -1, 1, 2 do
			if #formation >= duckCount then
				break
			end

			local space = back + perpendicular * depth * side
			if Board:IsValid(space) then
				table.insert(formation, {
					space = space,
					stagger = depth * DUCK_FLYOVER_STAGGER,
				})
			end
		end
		depth = depth + 1
	end

	return formation
end

-- TODO: this isn't working right ATM. Images are invisible but I think its also doing them in serial since there is a long delay
function Jefepassives_MigrationInstincts_Passive:addDuckFlyover(effect)
	-- TODO: Airstrike sound effect will likely be comical - need to decide if it fits enough or a different one to use
	effect:AddSound("/props/airstrike")
	local formation = self:buildDuckFlyoverFormation()
	for index, duck in ipairs(formation) do
		if index > 1 then
			effect:AddDelay(duck.stagger)
		end
		-- TODO: Make sure I can do this with a delay or try to modify it out
		effect:AddAirstrike(duck.space, DUCK_FLYOVER_IMAGE)
	end

	-- TODO: Determine delay
	effect:AddDelay(0.35)
end

function Jefepassives_MigrationInstincts_Passive:addMigrationMoves(effect)
	local reserved = {}
	local moves = {}

	for _, pawnId in ipairs(extract_table(Board:GetPawns(TEAM_ENEMY))) do
		local pawn = Board:GetPawn(pawnId)
		if pawn and Board:IsPawnAlive(pawnId) and not pawn:IsDead() then
			local maxSteps = self:getMigrationSpeed(pawn)
			local destination = self:getMigrationDestination(pawn,
					MIGRATION_DIRECTION, maxSteps, reserved)

			if destination then
				reserved[boardUtils.getSpaceHash(destination)] = true
				table.insert(moves, Board:GetPath(
						pawn:GetSpace(), destination, pawn:GetPathProf()))
			end
		end
	end

	for index, path in ipairs(moves) do
		local delay = (index == #moves) and FULL_DELAY or NO_DELAY
		effect:AddMove(path, delay)
	end

	return #moves > 0
end

function Jefepassives_MigrationInstincts_Passive:migrateEnemies()
	local effect = SkillEffect()
	self:addDuckFlyover(effect)
	self:addMigrationMoves(effect)
	Board:AddEffect(effect)
end

function Jefepassives_MigrationInstincts_Passive:GetPassiveSkillEffect_OnNextTurn(mission)
	if Game:GetTeamTurn() ~= TEAM_ENEMY then
		return
	end
	self:migrateEnemies()
end

passiveEffect:addPassiveEffect(
	"Jefepassives_MigrationInstincts_Passive",
	{"onNextTurn"}
)
