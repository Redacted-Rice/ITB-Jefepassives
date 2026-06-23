local mod = mod_loader.mods[modApi.currentMod]
local resourcePath = mod.resourcePath

modApi:appendAsset("img/weapons/passives/passive_random_swap.png",          resourcePath.."img/weapons/passives/passive_random_swap.png")
modApi:appendAsset("img/weapons/passives/passive_cancel_nearby_attack.png", resourcePath.."img/weapons/passives/passive_cancel_nearby_attack.png")
modApi:appendAsset("img/weapons/passives/passive_deploy_items.png",         resourcePath.."img/weapons/passives/passive_deploy_items.png")
modApi:appendAsset("img/weapons/passives/passive_acid_rain.png",            resourcePath.."img/weapons/passives/passive_acid_rain.png")

modApi:appendAsset("img/units/passive/fake_building_standing.png", resourcePath .."img/units/passive/fake_building_standing.png")
modApi:appendAsset("img/units/passive/fake_building_a.png", resourcePath .."img/units/passive/fake_building_a.png")
modApi:appendAsset("img/units/passive/fake_building_flat.png", resourcePath .."img/units/passive/fake_building_flat.png")