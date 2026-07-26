-- Vek migrate to the right at the start of the enemy turn.
local MIGRATION_DIRECTION = DIR_VECTORS[DIR_RIGHT]
local MIGRATION_DIRECTION_LEFT = DIR_VECTORS[DIR_UP]
local DUCK_FLYOVER_IMAGE = "effects/flying_duck.png"
local DUCK_FLYOVER_STAGGER = 0.12
local MIGRATION_MOVE_DELAY = 0.1

local boardUtils = mod_loader.mods[modApi.currentMod].libs.boardUtils

Jefepassives_MigratoryEvoker = PassiveSkill:new{
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
	Debug = false,
}

local passiveEffect = mod_loader.mods[modApi.currentMod].libs.passiveEffect
Jefepassives_MigratoryEvoker.passiveEffect = passiveEffect

Weapon_Texts.Jefepassives_MigratoryEvoker_Upgrade1 = "Potency"
Jefepassives_MigratoryEvoker_A = Jefepassives_MigratoryEvoker:new{
	UpgradeDescription = "Vek move up to half their move speed (rounded down, minimum 1) instead.",
	ExtendedMigration = true,
	minDucks = 5,
	maxDucks = 8,
}

-- Preview only
function Jefepassives_MigratoryEvoker:GetSkillEffect(p1, p2)
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

function Jefepassives_MigratoryEvoker:getReachableMigrationSpaces(pawn, maxSteps, occupied)
	local start = pawn:GetSpace()
	local terrainMatcher = boardUtils.makeGenericMatcher(pawn, "none")
	local isFlying = boardUtils.isPawnFlying(pawn)

	local function stoppable(point, hash)
		if not terrainMatcher(point, hash) then
			return false
		end
		return not occupied[hash]
	end

	local reachable = PointList()
	boardUtils.getReachableInRange(reachable, maxSteps, start, terrainMatcher, stoppable)

	local filtered = {}
	for i = 1, reachable:size() do
		local p = reachable:index(i)
		if not Board:IsPod(p) then
			table.insert(filtered, p)
		end
	end
	return filtered
end

function Jefepassives_MigratoryEvoker:getMigrationSpeed(pawn)
	local pawnSpeed = pawn:GetMoveSpeed()
	if pawnSpeed == 0 then
		return 0
	end
	if not self.ExtendedMigration then
		return 1
	end
	return math.max(1, math.floor(pawnSpeed / 2))
end

function Jefepassives_MigratoryEvoker:scoreMigrationDestination(start, point, direction)
	local delta = point - start
	local progress = delta.x * direction.x + delta.y * direction.y

	if progress <= 0 then
		return nil
	end

	local perpendicular = math.abs(delta.x * direction.y - delta.y * direction.x)
	return progress * 1000 - perpendicular
end

function Jefepassives_MigratoryEvoker:getMigrationDestination(pawn, direction, maxSteps, occupied)
	if maxSteps <= 0 then
		return nil
	end

	local start = pawn:GetSpace()
	local best = nil
	local bestScore = nil

	for _, point in ipairs(self:getReachableMigrationSpaces(pawn, maxSteps, occupied)) do
		if point ~= start and not occupied[boardUtils.getSpaceHash(point)] then
			local score = self:scoreMigrationDestination(start, point, direction)
			if score and (not bestScore or score > bestScore) then
				bestScore = score
				best = point
			end
		end
	end
	return best
end

function Jefepassives_MigratoryEvoker:buildOccupancy()
	local occupied = {}
	for _, pawnId in ipairs(extract_table(Board:GetPawns(TEAM_ANY))) do
		local pawn = Board:GetPawn(pawnId)
		if pawn and Board:IsPawnAlive(pawnId) and not pawn:IsDead() then
			local hash = boardUtils.getSpaceHash(pawn:GetSpace())
			occupied[hash] = pawnId
			LOG("occupied " .. pawn:GetSpace():GetString() .. " with pawn " .. pawn:GetType())
		end
	end
	return occupied
end

function Jefepassives_MigratoryEvoker:addMigrationMove(effect, pawn, from, to)
	if pawn:IsTeleporter() then
		effect:AddTeleport(from, to, MIGRATION_MOVE_DELAY)
	else
		local path = Board:GetPath(from, to, pawn:GetPathProf())
		if pawn:IsJumper() then
			effect:AddLeap(path, MIGRATION_MOVE_DELAY)
		elseif pawn:IsBurrower() then
			effect:AddBurrow(path, MIGRATION_MOVE_DELAY)
		else
			effect:AddMove(path, MIGRATION_MOVE_DELAY)
		end
	end
end

function Jefepassives_MigratoryEvoker:appendDuckAirstrike(effect, space)
	effect:AddAirstrike(space, DUCK_FLYOVER_IMAGE)
	local tbl = extract_table(effect.effect)
	tbl[#tbl].fDelay = 0
end

function Jefepassives_MigratoryEvoker:getNumDucks()
	local min = math.min(Board:GetSize().y, self.minDucks)
	local max = math.min(Board:GetSize().y, self.maxDucks)
	return math.random(min, max)
end

function Jefepassives_MigratoryEvoker:chooseLeadOffset(duckCount)
	return math.random(1, duckCount - 2)
end

function Jefepassives_MigratoryEvoker:getFormationOffset(duckCount)
	local boardSize = Board:GetSize().y
	-- board size is 8. For 5 this chooses between 0 and 3. for 7 it chooses between 0 and 1.
	return math.random(0, boardSize - duckCount)
end

function Jefepassives_MigratoryEvoker:addDuckFlyover(effect)
	effect:AddSound("/props/airstrike")

	local duckCount = self:getNumDucks()
	local leadDuckOffset = self:chooseLeadOffset(duckCount)
	local spaceOffset = self:getFormationOffset(duckCount)
	local leadSpaceY = spaceOffset + leadDuckOffset
	local leadSpace = Point(0, leadSpaceY)

	if self.Debug then
		LOG("duckCount: " .. duckCount)
		LOG("leadSpace: " .. leadSpace:GetString())
		LOG("leadDuckOffset: " .. leadDuckOffset)
		LOG("spaceOffset: " .. spaceOffset)
		LOG("leadSpaceY: " .. leadSpaceY)
	end

	self:appendDuckAirstrike(effect, leadSpace)

	-- duck count is just a convinient max
	local leftSpace, rightSpace = leadSpace, leadSpace
	local leftEnded, rightEnded = false, false
	for i = 1, duckCount do
		effect:AddDelay(DUCK_FLYOVER_STAGGER)

		-- Subtracting VEC_UP moves downward (same as +VEC_DOWN). Add UP to go left on the V.
		leftSpace = leftSpace + MIGRATION_DIRECTION_LEFT
		rightSpace = rightSpace - MIGRATION_DIRECTION_LEFT
		if self.Debug then
			LOG("leftSpace: " .. leftSpace:GetString() .. " " .. leadDuckOffset - i)
			LOG("rightSpace: " .. rightSpace:GetString() .. " " .. leadDuckOffset + i)
		end
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

function Jefepassives_MigratoryEvoker:addMigrationMoves(effect)
	local occupied = self:buildOccupancy()
	local processedPawns = {}
	local size = Board:GetSize()
	local anyMoved = false

	for x = size.x - 1, 0, -1 do
		for y = 0, size.y - 1 do
			local space = Point(x, y)
			if Board:IsValid(space) then
				local hash = boardUtils.getSpaceHash(space)
				local pawn = Board:GetPawn(space)
				local pawnId = pawn and pawn:GetId()

				if pawn and pawn:GetTeam() == TEAM_ENEMY and not processedPawns[pawnId] 
						and Board:IsPawnAlive(pawnId) and not pawn:IsDead() and 
						not pawn:IsFrozen() then
					local maxSteps = self:getMigrationSpeed(pawn)
					local destination = self:getMigrationDestination(
							pawn, MIGRATION_DIRECTION, maxSteps, occupied)

					if destination then
						self:addMigrationMove(effect, pawn, space, destination)
						occupied[hash] = nil
						LOG("moved pawn " .. pawn:GetType() .. " from " .. space:GetString() .. " to " .. destination:GetString())

						local destHash = boardUtils.getSpaceHash(destination)
						occupied[destHash] = pawnId
						anyMoved = true
					end
					LOG("processed pawn " .. pawn:GetType() .. " at " .. space:GetString())
					processedPawns[pawnId] = true
				end
			end
		end
	end

	effect:AddDelay(1.2)
	return anyMoved
end

function Jefepassives_MigratoryEvoker:migrateEnemies()
	local effect = SkillEffect()
	self:addDuckFlyover(effect)
	self:addMigrationMoves(effect)
	Board:AddEffect(effect)
end

local oldPlanEnv = Mission.PlanEnvironment
Mission.PlanEnvironment = function(self, ...)
	if self.jefepassivesMigrationTurn  ~= Game:GetTurnCount() then
		self.jefepassivesMigrationTurn = Game:GetTurnCount()
		if IsPassiveSkill("Jefepassives_MigratoryEvoker") then
			local weapon = Jefepassives_MigratoryEvoker
			if IsPassiveSkill("Jefepassives_MigratoryEvoker_A") then
				weapon = Jefepassives_MigratoryEvoker_A
			end
			weapon:migrateEnemies()
			-- True will prevent the first env from planning before the effect
			return true
		end
	end

	return oldPlanEnv(self, ...)
end

passiveEffect:addPassiveEffect(
	"Jefepassives_MigratoryEvoker",
	{}
)
