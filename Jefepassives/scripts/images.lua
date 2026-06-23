local mod = mod_loader.mods[modApi.currentMod]
local resourcePath = mod.resourcePath

modApi:appendAsset("img/effects/flying_duck.png", resourcePath .."img/effects/flying_duck.png")

modApi:appendAsset("img/weapons/passives/passive_acid_rain.png",            resourcePath.."img/weapons/passives/passive_acid_rain.png")
modApi:appendAsset("img/weapons/passives/passive_cancel_nearby_attack.png", resourcePath.."img/weapons/passives/passive_cancel_nearby_attack.png")
modApi:appendAsset("img/weapons/passives/passive_deploy_items.png",         resourcePath.."img/weapons/passives/passive_deploy_items.png")
modApi:appendAsset("img/weapons/passives/passive_migration_instincts.png",  resourcePath.."img/weapons/passives/passive_migration_instincts.png")
modApi:appendAsset("img/weapons/passives/passive_random_swap.png",          resourcePath.."img/weapons/passives/passive_random_swap.png")
modApi:appendAsset("img/weapons/passives/passive_rst_decoy.png",            resourcePath.."img/weapons/passives/passive_rst_decoy.png")

modApi:appendAsset("img/units/passive/fake_building_a.png", resourcePath .."img/units/passive/fake_building_a.png")
modApi:appendAsset("img/units/passive/fake_building_standing.png", resourcePath .."img/units/passive/fake_building_standing.png")