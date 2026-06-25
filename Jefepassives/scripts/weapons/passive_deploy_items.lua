--[[
Idea: Truelch
Code: Truelch

Vanilla mines:
- Repair pad:    "Item_Repair_Mine"
- Freezing mine: "Freeze_Mine"
- Archive mine:  "Item_Mine"

############
### TODO ###
############

Bug to fix: In the high tides mission, mines aren't destroyed by the water.

Add 2nd phase mission.

#############
### DEBUG ###
#############

for _, pos in ipairs(extract_table(Board:GetZone("deployment"))) do LOG("deploy pos: "..pos:GetString()) end

LOG(save_table(GetCurrentMission().deployment))
LOG(save_table(GetCurrentMission()))


#############
### NOTES ###
#############

A time pod landed on a repair pad. It doesn't matter, but if it was a archive mine, idk what would happen.
I hope it wouldn't destroy the time pod!
EDIT: I tested it and the pod juste replace the item there, without taking damage.

Maybe I should wait a bit before doing this? Maybe first player turn?

]]

Jefepassives_DeployItems_Passive = PassiveSkill:new{
	--Infos
	Name = "Mines Dispenser",
	Description = [[At the start mission deploy 3 "Items" on random empty tiles.]].."\n"..[[These "Items" are Repair Platforms, but can also be Mines with upgrades.]],
	PowerCost = 0,
	Icon = "weapons/passives/passive_deploy_items.png",

	--Upgrades
	Upgrades = 2,
	UpgradeCost = { 1, 2 },
	UpgradeList = { "Freeze Mines", "Old Earth Mines" },

	--Passive
	Passive = "Jefepassives_DeployItems_Passive",

	--Tip image
	TipRepairMineSpawns = { Point(1, 2), Point(3, 2), Point(0, 2), },
	TipFreezeMineSpawns = {},
	TipExplosMineSpawns = {},
	TipImage = {
		Unit = Point(2, 3),
		Target = Point(2, 2),
	}
}

function Jefepassives_DeployItems_Passive:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	--"Item_Repair_Mine", "Freeze_Mine", "Item_Mine"
	for _, pos in ipairs(self.TipRepairMineSpawns) do
		--Board:SetItem(pos, "Item_Repair_Mine")
		ret:AddScript([[Board:SetItem(]]..pos:GetString()..[[, "Item_Repair_Mine")]])
	end

	for _, pos in ipairs(self.TipFreezeMineSpawns) do
		--Board:SetItem(pos, "Freeze_Mine")
		ret:AddScript([[Board:SetItem(]]..pos:GetString()..[[, "Freeze_Mine")]])
	end

	for _, pos in ipairs(self.TipExplosMineSpawns) do
		--Board:SetItem(pos, "Item_Mine")
		ret:AddScript([[Board:SetItem(]]..pos:GetString()..[[, "Item_Mine")]])
	end

	local damage = SpaceDamage(p2, 0)
	ret:AddDamage(damage)

	return ret
end


Jefepassives_DeployItems_Passive_A = Jefepassives_DeployItems_Passive:new{
	UpgradeDescription = "Add Freeze Mines to the pool.\nAlso deploy one additional item at the start of the mission.",
	TipRepairMineSpawns = { Point(1, 2), Point(3, 2) },
	TipFreezeMineSpawns = { Point(0, 2), Point(2, 1) },
	Passive = "Jefepassives_DeployItems_Passive_A",
}

Jefepassives_DeployItems_Passive_B = Jefepassives_DeployItems_Passive:new{
	UpgradeDescription = "Add Old Earth Mines to the pool.\nAlso deploy one additional item at the start of the mission.",
	TipRepairMineSpawns = { Point(1, 2), Point(3, 2) },
	TipExplosMineSpawns = { Point(0, 2), Point(2, 1) },
	Passive = "Jefepassives_DeployItems_Passive_B",
}

Jefepassives_DeployItems_Passive_AB = Jefepassives_DeployItems_Passive:new{
	TipRepairMineSpawns = { Point(1, 2), Point(3, 2) },
	TipFreezeMineSpawns = { Point(0, 2) },
	TipExplosMineSpawns = { Point(2, 1) },
	Passive = "Jefepassives_DeployItems_Passive_AB",
}

local DEFAULT_DEPLOYMENT_ZONE = {}
for x = 1, 3 do
	for y = 1, 6 do
		table.insert(DEFAULT_DEPLOYMENT_ZONE, Point(x, y))
	end
end

local function isInsideDeployZone(point)
	local deploymentZone = extract_table(Board:GetZone("deployment"))
	if #deploymentZone == 0 then
		deploymentZone = DEFAULT_DEPLOYMENT_ZONE
	end

	for _, pos in ipairs(deploymentZone) do
		if pos == point then
			--LOG("point: "..point:GetString().." is inside deploy zone!")
			return true
		end
	end

	return false
end

local function getRandomPos()
	local list = {}

	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)
			--[[TODO: maybe also check:
				and not Board:IsDangerous(curr)
				and not Board:IsDangerousItem(curr)
				and not Board:IsSpawning(curr)

				--unnecessary with not Board:IsItem(curr)
				and not Board:IsPod(curr)
				and (Board:GetItem(curr) == nil or Board:GetItem(curr) == "")

				and not Board:GetTerrain(curr) ~= TERRAIN_WATER then --what about lava?

				and not Board:IsEnvironmentDanger(curr)
			]]

			if not Board:IsBlocked(curr, PATH_PROJECTILE)
					and not Board:IsItem(curr)
					and (Board:GetTerrain(curr) == TERRAIN_ROAD or Board:GetTerrain(curr) == TERRAIN_FOREST or Board:GetTerrain(curr) == TERRAIN_SAND) 
					and not Board:IsFire(curr)
					and not Board:IsEdge(curr) --exclude edge tiles?
					and not isInsideDeployZone(curr) then
				list[#list + 1] = curr
			end
		end
	end

	--Pick a random one
	if #list > 0 then
		return list[math.random(1, #list)]
	else
		LOG("getRandomTile() -> nil")
		return nil
	end
end


local items = { "Item_Repair_Mine", "Freeze_Mine", "Item_Mine" }
local function isDeployItem(item)
	return list_contains(items, item)
end

BoardEvents.onTerrainChanged:subscribe(function(p, terrain, terrain_prev)
	local item = Board:GetItem(p)
	if item ~= nil and item ~= "" and isDeployItem(item) then
		--LOG("isDeployItem(item: "..item..") -> YES!")
		if terrain == TERRAIN_HOLE or terrain == TERRAIN_WATER then
			Board:RemoveItem(p)
		end
	end
end)


local function createMines()
	local itemAmount = 0
	local items = {}

	if IsPassiveSkill("Jefepassives_DeployItems_Passive_AB") then --Archive Mines + Freeze Mines
		items = { "Item_Repair_Mine", "Freeze_Mine", "Item_Mine" }
		itemAmount = 5

	elseif IsPassiveSkill("Jefepassives_DeployItems_Passive_A") then --Freeze Mines
		items = { "Item_Repair_Mine", "Freeze_Mine" }
		itemAmount = 4

	elseif IsPassiveSkill("Jefepassives_DeployItems_Passive_B") then --Archive Mines
		items = { "Item_Repair_Mine", "Item_Mine" }
		itemAmount = 4

	elseif IsPassiveSkill("Jefepassives_DeployItems_Passive") then
		items = { "Item_Repair_Mine" }
		itemAmount = 3
	else
		return
	end

	--itemAmount = 40 --just for the tests
	--items = { "Item_Mine" }

	--[[
	if amount == 0 then
		return
	end
	]]

	--LOG("----------------- #items: "..tostring(#items))

	--Loop
	for i = 1, itemAmount do
		local item = items[math.random(1, #items)]
		local pos = getRandomPos()

		if pos == nil or item == nil or item == "" then
			--LOG("------------------ BREAK")
			break --could even be return
		else
			--TODO: create an anim. Or maybe a board alert.
			Board:AddAlert(pos, "DEPLOYED") --not showing up?
			--ret:AddReverseAirstrike(p2, "effects/tif_biplane.png")
			Board:SetItem(pos, item)
		end
	end
end

local EVENT_onMissionStart = function(mission)
	createMines()
end

local EVENT_onMissionNextPhaseCreated = function(prevMission, nextMission)
	createMines()
end

modApi.events.onMissionStart:subscribe(EVENT_onMissionStart)
modApi.events.onMissionNextPhaseCreated:subscribe(EVENT_onMissionNextPhaseCreated)