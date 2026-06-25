-- Vek migrate to the right at the start of the enemy turn.
local MIGRATION_DIRECTION = DIR_VECTORS[DIR_RIGHT]
local MIGRATION_DIRECTION_LEFT = DIR_VECTORS[DIR_UP]
local DUCK_FLYOVER_IMAGE = "effects/flying_duck.png"
local DUCK_FLYOVER_STAGGER = 0.12

local boardUtils = mod_loader.mods[modApi.currentMod].libs.boardUtils

Jefepassives_MigratoryInvoker = PassiveSkill:new{
	Name = "Migratory Evoker",
	Description = "At the start of the Vek turn, each Vek attempts to move one tile to the right.",
	Icon = "weapons/passives/passive_migration_instincts.png",
	Rarity = 1,
	PowerCost = 0,
	Damage = 0,
	Upgrades = 1,
	UpgradeCost = {1},
	ExtendedMigration = false,
	minDucks = 4,
	maxDucks = 6,
	TipImage = {
		Unit = Point(2, 2),
		Enemy = Point(1, 1),
	},
}

local passiveEffect = mod_loader.mods[modApi.currentMod].libs.passiveEffect
Jefepassives_MigratoryInvoker.passiveEffect = passiveEffect

Weapon_Texts.Jefepassives_MigratoryInvoker_Upgrade1 = "Potency"
Jefepassives_MigratoryInvoker_A = Jefepassives_MigratoryInvoker:new{
	UpgradeDescription = "Vek move up to half their move speed (rounded down, minimum 1) instead.",
	ExtendedMigration = true,
	minDucks = 5,
	maxDucks = 8,
}

-- Preview only
function Jefepassives_MigratoryInvoker:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	self:addDuckFlyover(ret)

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
	ret:AddDelay(3)
	return ret
end

function Jefepassives_MigratoryInvoker:getReachableMigrationSpaces(pawn, maxSteps)
	local start = pawn:GetSpace()
	return extract_table(Board:GetReachable(start, maxSteps, pawn:GetPathProf()))
end

function Jefepassives_MigratoryInvoker:getMigrationSpeed(pawn)
	local pawnSpeed = pawn:GetMoveSpeed()
	if pawnSpeed == 0 then
		return 0
	end
	if not self.ExtendedMigration then
		return 1
	end
	return math.max(1, math.floor(pawnSpeed / 2))
end

function Jefepassives_MigratoryInvoker:scoreMigrationDestination(start, point, direction)
	local delta = point - start
	local progress = delta.x * direction.x + delta.y * direction.y

	if progress <= 0 then
		return nil
	end

	local perpendicular = math.abs(delta.x * direction.y - delta.y * direction.x)
	return progress * 1000 - perpendicular
end

function Jefepassives_MigratoryInvoker:getMigrationDestination(pawn, direction, maxSteps, reserved)
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

function Jefepassives_MigratoryInvoker:appendDuckAirstrike(effect, space)
	effect:AddAirstrike(space, DUCK_FLYOVER_IMAGE)
	local tbl = extract_table(effect.effect)
	tbl[#tbl].fDelay = 0
end

function Jefepassives_MigratoryInvoker:getNumDucks()
	local min = math.min(Board:GetSize().y, self.minDucks)
	local max = math.min(Board:GetSize().y, self.maxDucks)
	return math.random(min, max)
end

function Jefepassives_MigratoryInvoker:chooseLeadOffset(duckCount)
	return math.random(1, duckCount - 2)
end

function Jefepassives_MigratoryInvoker:getFormationOffset(duckCount)
	local boardSize = Board:GetSize().y
	-- board size is 8. For 5 this chooses between 0 and 3. for 7 it chooses between 0 and 1.
	return math.random(0, boardSize - duckCount)
end

function Jefepassives_MigratoryInvoker:addDuckFlyover(effect)
	effect:AddSound("/props/airstrike")

	local duckCount = self:getNumDucks()
	local leadDuckOffset = self:chooseLeadOffset(duckCount)
	local spaceOffset = self:getFormationOffset(duckCount)
	local leadSpaceY = spaceOffset + leadDuckOffset
	local leadSpace = Point(0, leadSpaceY)

	LOG("duckCount: " .. duckCount)
	LOG("leadSpace: " .. leadSpace:GetString())
	LOG("leadDuckOffset: " .. leadDuckOffset)
	LOG("spaceOffset: " .. spaceOffset)
	LOG("leadSpaceY: " .. leadSpaceY)

	self:appendDuckAirstrike(effect, leadSpace)

	-- duck count is just a convinient max
	local leftSpace, rightSpace = leadSpace, leadSpace
	local leftEnded, rightEnded = false, false
	for i = 1, duckCount do
		effect:AddDelay(DUCK_FLYOVER_STAGGER)

		-- Subtracting VEC_UP moves downward (same as +VEC_DOWN). Add UP to go left on the V.
		leftSpace = leftSpace + MIGRATION_DIRECTION_LEFT
		rightSpace = rightSpace - MIGRATION_DIRECTION_LEFT
		LOG("leftSpace: " .. leftSpace:GetString() .. " " .. leadDuckOffset - i)
		LOG("rightSpace: " .. rightSpace:GetString() .. " " .. leadDuckOffset + i)
		if Board:IsValid(leftSpace) and leadDuckOffset - i >= 0 then
			self:appendDuckAirstrike(effect, leftSpace)
		else
			leftEnded = true
		end
		if Board:IsValid(rightSpace) and leadDuckOffset + i < duckCount then
			self:appendDuckAirstrike(effect, rightSpace)
		else
			rightEnded = true
		end
		if leftEnded and rightEnded then
			break
		end
	end
	-- TODO: Maybe have it staggered instead - go row by row with the ducks
	effect:AddDelay(1)
end

function Jefepassives_MigratoryInvoker:addMigrationMoves(effect)
	local reserved = {}
	local moves = {}

	for _, pawnId in ipairs(extract_table(Board:GetPawns(TEAM_ENEMY))) do
		local pawn = Board:GetPawn(pawnId)
		if pawn and Board:IsPawnAlive(pawnId) and not pawn:IsDead() and not pawn:IsFrozen() then
			local maxSteps = self:getMigrationSpeed(pawn)
			local destination = self:getMigrationDestination(pawn,
					MIGRATION_DIRECTION, maxSteps, reserved)

			if destination then
				reserved[boardUtils.getSpaceHash(destination)] = true

				if Pawn:IsTeleporter() then
					effect:AddTeleport(pawn:GetSpace(), destination, NO_DELAY)
				else
					local path = Board:GetPath(pawn:GetSpace(), destination, pawn:GetPathProf())
					if pawn:IsJumper() then
						effect:AddLeap(path, NO_DELAY)
					elseif pawn:IsBurrower() then
						effect:AddBurrow(path, NO_DELAY)
					else
						effect:AddMove(path, NO_DELAY)
					end
				end
			end
		end
	end

	effect:AddDelay(1.2)
	return #moves > 0
end

function Jefepassives_MigratoryInvoker:migrateEnemies()
	local effect = SkillEffect()
	self:addDuckFlyover(effect)
	self:addMigrationMoves(effect)
	Board:AddEffect(effect)
end

function Jefepassives_MigratoryInvoker:GetPassiveSkillEffect_OnNextTurn(mission)
	if Game:GetTeamTurn() ~= TEAM_ENEMY then
		LOG("NO MIGRATE " .. Game:GetTeamTurn() .. " -----------")
		return
	end
	LOG("MIGRATING -----------")
	self:migrateEnemies()
end

passiveEffect:addPassiveEffect(
	"Jefepassives_MigratoryInvoker",
	{"onNextTurn"}
)
