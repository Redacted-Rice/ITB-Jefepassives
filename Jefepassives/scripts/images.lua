local mod = mod_loader.mods[modApi.currentMod]
local resourcePath = mod.resourcePath

modApi:appendAssets("img/effects/", "img/effects/")
modApi:appendAssets("img/weapons/", "img/weapons/")

modApi:appendAsset("img/weapons/passives/passive_random_swap.png",          resourcePath.."img/weapons/passives/passive_random_swap.png")
modApi:appendAsset("img/weapons/passives/passive_cancel_nearby_attack.png", resourcePath.."img/weapons/passives/passive_cancel_nearby_attack.png")
modApi:appendAsset("img/weapons/passives/passive_deploy_items.png",         resourcePath.."img/weapons/passives/passive_deploy_items.png")
modApi:appendAsset("img/weapons/passives/passive_acid_rain.png",            resourcePath.."img/weapons/passives/passive_acid_rain.png")