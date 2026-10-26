--[[
Idea: Hedera
Code: Hedera but mostly Truelch (based on passive_deploy_items)

############
### TODO ###
############

Bug to fix: In the high tides mission, mines aren't destroyed by the water.

Add 2nd phase mission.

Undo move is so buggy!

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

--=========================[SETUP]===================================
local mod = mod_loader.mods[modApi.currentMod]
local scriptPath   = mod.scriptPath
local resourcePath = mod.resourcePath
local boardEvents  = require(scriptPath.."libs/boardEvents")

local resourcePath = mod.resourcePath
modApi:appendAsset("img/combat/mine_directional_0.png", resourcePath.."img/combat/mine_directional_0.png")
Location["combat/mine_directional_0.png"] = Point(-16,-6)
modApi:appendAsset("img/combat/mine_directional_1.png", resourcePath.."img/combat/mine_directional_1.png")
Location["combat/mine_directional_1.png"] = Point(-16,-6)
modApi:appendAsset("img/combat/mine_directional_2.png", resourcePath.."img/combat/mine_directional_2.png")
Location["combat/mine_directional_2.png"] = Point(-16,-6)
modApi:appendAsset("img/combat/mine_directional_3.png", resourcePath.."img/combat/mine_directional_3.png")
Location["combat/mine_directional_3.png"] = Point(-16,-6)

modApi:appendAsset("img/effects/mine_directional_0_emerge.png", resourcePath .."img/effects/mine_directional_0_emerge.png")
	ANIMS.emerge_mine_0 = Animation:new{
		Image = "effects/mine_directional_0_emerge.png",
		NumFrames = 11,
		Time = 0.05,
		
		PosX = -16,
		PosY = -6
	}
modApi:appendAsset("img/effects/mine_directional_1_emerge.png", resourcePath .."img/effects/mine_directional_1_emerge.png")
	ANIMS.emerge_mine_1 = Animation:new{
		Image = "effects/mine_directional_1_emerge.png",
		NumFrames = 11,
		Time = 0.05,
		
		PosX = -16,
		PosY = -6
	}
modApi:appendAsset("img/effects/mine_directional_2_emerge.png", resourcePath .."img/effects/mine_directional_2_emerge.png")
	ANIMS.emerge_mine_2 = Animation:new{
		Image = "effects/mine_directional_2_emerge.png",
		NumFrames = 11,
		Time = 0.05,
		
		PosX = -16,
		PosY = -6
	}
modApi:appendAsset("img/effects/mine_directional_3_emerge.png", resourcePath .."img/effects/mine_directional_3_emerge.png")
	ANIMS.emerge_mine_3 = Animation:new{
		Image = "effects/mine_directional_3_emerge.png",
		NumFrames = 11,
		Time = 0.05,
		
		PosX = -16,
		PosY = -6
	}
--================================================================================
Jefepassives_ComboMines = PassiveSkill:new{
	--Infos
	Name = "Combo Mines",
	Description = [[At the start of each mission, deploy 3 pushing mines on random empty tiles.]].."\n"..[[These mines do not push into Buildings.]],
	PowerCost = 0,
	Icon = "weapons/passives/passive_combo_mines.png",

	--Upgrades
	Upgrades = 2,
	UpgradeCost = { 1, 2 },
	UpgradeList = { "More Mines", "Even More Mines" },

	--Passive
	Passive = "Jefepassives_ComboMines",

	--Tip image
	TipMineSpawns = { Point(1, 2), Point(3, 2), Point(0, 2), },
	TipImage = {
		Unit = Point(2, 3),
		Target = Point(2, 2),
	}
}

MINE_TYPES = {"Item_PushMine_0","Item_PushMine_1","Item_PushMine_2","Item_PushMine_3"}

TILE_TOOLTIPS = {
	Item_PushMine_0 = {"Combo Mine", "Pushes units north when triggered."},
	Item_PushMine_1 = {"Combo Mine", "Pushes units east when triggered."},
	Item_PushMine_2 = {"Combo Mine", "Pushes units south when triggered."},
	Item_PushMine_3 = {"Combo Mine", "Pushes units west when triggered."},
}

local placeholder = SpaceDamage(0)
Item_PushMine_0 = { Image = "combat/mine_directional_0.png", Damage = placeholder, Tooltip = "Item_PushMine_0", Icon = "combat/icons/icon_arrow_0_glow.png", UsedImage = ""}
Item_PushMine_1 = { Image = "combat/mine_directional_1.png", Damage = placeholder, Tooltip = "Item_PushMine_1", Icon = "combat/icons/icon_arrow_1_glow.png", UsedImage = ""}
Item_PushMine_2 = { Image = "combat/mine_directional_2.png", Damage = placeholder, Tooltip = "Item_PushMine_2", Icon = "combat/icons/icon_arrow_2_glow.png", UsedImage = ""}
Item_PushMine_3 = { Image = "combat/mine_directional_3.png", Damage = placeholder, Tooltip = "Item_PushMine_3", Icon = "combat/icons/icon_arrow_3_glow.png", UsedImage = ""}

function Jefepassives_ComboMines:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	for _, pos in ipairs(self.TipMineSpawns) do
		local index = tostring(math.random(0,3))
		local anim = SpaceDamage(pos,0)
		anim.sAnimation = "emerge_mine_"..index
		ret:AddDamage(anim)
		ret:AddDelay(0.05 * 11) -- anim time
		ret:AddScript([[Board:SetItem(]]..pos:GetString()..[[, "Item_PushMine_]]..index..[[")]])
		
	end

	local damage = SpaceDamage(p2, 0)
	ret:AddDamage(damage)

	return ret
end


Jefepassives_ComboMines_A = Jefepassives_ComboMines:new{
	UpgradeDescription = "Deploy two additional items at the start of the mission.",
	TipMineSpawns = { Point(1, 2), Point(3, 2), Point(0, 2), Point(2, 1), Point(2 , 2) },
	Passive = "Jefepassives_ComboMines_A",
}

Jefepassives_ComboMines_B = Jefepassives_ComboMines:new{
	UpgradeDescription = "Deploy two additional items at the start of the mission.",
	TipMineSpawns = { Point(1, 2), Point(3, 2), Point(0, 2), Point(2, 1), Point(2 , 2) },
	Passive = "Jefepassives_ComboMines_B",
}

Jefepassives_ComboMines_AB = Jefepassives_ComboMines:new{
	TipMineSpawns = { Point(1, 2), Point(3, 2), Point(0, 2), Point(2, 1), Point(2 , 2), Point(0 , 1), Point(1 , 0) },
	Passive = "Jefepassives_ComboMines_AB",
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

local function isInsidePylonZone(point)
	for _, pos in ipairs(extract_table(Board:GetZone("pylons"))) do
		if pos == point then
			--LOG("point: "..point:GetString().." is inside pylon zone!")
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
			if not Board:IsBlocked(curr, PATH_PROJECTILE)
					and not isInsidePylonZone(curr)
					and not Board:IsItem(curr)
					and not Board:IsPod(curr)
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


local function isDeployItem(item)
	return list_contains(MINE_TYPES, item)
end

BoardEvents.onTerrainChanged:subscribe(function(p, terrain, terrain_prev)
	local item = Board:GetItem(p)
	if item ~= nil and item ~= "" and isDeployItem(item) then
		if terrain == TERRAIN_HOLE or terrain == TERRAIN_WATER then
			Board:RemoveItem(p)
		end
	end
end)

local function createMines()
	local itemAmount = 0

	if IsPassiveSkill("Jefepassives_ComboMines_AB") then
		itemAmount = 7

	elseif IsPassiveSkill("Jefepassives_ComboMines_B") then 
		itemAmount = 5
		
	elseif IsPassiveSkill("Jefepassives_ComboMines_A") then
		itemAmount = 5
	
	elseif IsPassiveSkill("Jefepassives_ComboMines") then
		itemAmount = 3
	else
		return
	end

	--Loop
	for i = 1, itemAmount do
		local index = math.random(0,#MINE_TYPES - 1) --curse you lua for not being 0 indexed
		local item = MINE_TYPES[index + 1]
		local pos = getRandomPos()

		if pos == nil or item == nil or item == "" then
			--LOG("------------------ BREAK")
			break --could even be return
		else
			--TODO: create an anim. Or maybe a board alert.
			--Board:AddAlert(pos, "DEPLOYED")
			--ret:AddReverseAirstrike(p2, "effects/tif_biplane.png")
			
			if Board:IsBlocked(pos+DIR_VECTORS[index],PATH_FLYER) then 
				index = (index + 1)%4  --avoid buildings/mountains/etc.
				if Board:IsBlocked(pos+DIR_VECTORS[index],PATH_FLYER) then 
					index = (index + 1)%4
					if Board:IsBlocked(pos+DIR_VECTORS[index],PATH_FLYER) then 
						index = (index + 1)%4
						if Board:IsBlocked(pos+DIR_VECTORS[index],PATH_FLYER) then 
							index = (index + 1)%4 -- well, at least we tried. 
			end end end end
			
			Board:AddAnimation(pos,"emerge_mine_"..index,ANIM_DELAY)
			Board:SetItem(pos, item)
		end
	end
end

boardEvents.onItemRemoved:subscribe(function(loc, removed_item)
    if removed_item == "Item_PushMine_0" then
		local ret = SkillEffect()
		local launch = SpaceDamage(loc,0,0)
		launch.sAnimation = "explopush1_0"
		ret:AddDamage(launch)
		Board:AddEffect(ret)
		
    elseif removed_item == "Item_PushMine_1" then
		local ret = SkillEffect()
		local launch = SpaceDamage(loc,0,1)
		launch.sAnimation = "explopush1_1"
		ret:AddDamage(launch)
		Board:AddEffect(ret)
        
    elseif removed_item == "Item_PushMine_2" then
		local ret = SkillEffect()
		local launch = SpaceDamage(loc,0,2)
		launch.sAnimation = "explopush1_2"
		ret:AddDamage(launch)
		Board:AddEffect(ret)
       
	elseif removed_item == "Item_PushMine_3" then
		local ret = SkillEffect()
		local launch = SpaceDamage(loc,0,3)
		launch.sAnimation = "explopush1_3"
		ret:AddDamage(launch)
		Board:AddEffect(ret)
      
    end
end)

local EVENT_onMissionStart = function(mission)
	firstEnemyTurn = true
end

local EVENT_onMissionNextPhaseCreated = function(prevMission, nextMission)
	firstEnemyTurn = true
end

local EVENT_onNextTurn = function(mission)
	if Game:GetTeamTurn() == TEAM_ENEMY and firstEnemyTurn then
		createMines()
		firstEnemyTurn = false
	end
end

modApi.events.onMissionStart:subscribe(EVENT_onMissionStart)
modApi.events.onMissionNextPhaseCreated:subscribe(EVENT_onMissionNextPhaseCreated)
modApi.events.onNextTurn:subscribe(EVENT_onNextTurn)