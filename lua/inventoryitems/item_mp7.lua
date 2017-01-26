local ITEM = {}

ITEM.Name = "MP7"
ITEM.Info = "A ammo eating gun"
ITEM.Model = "models/weapons/w_smg1.mdl"
ITEM.SpawnIcon = "spawnicons/models/weapons/w_smg_mp7.png"
ITEM.Weight = 2

function ITEM:Drop(Plr)
	Plr:SpawnItem("item_mp7")
	Plr:RemoveItem("item_mp7", 1)
end

function ITEM:Use(Plr)
	Plr:Give("weapon_smg1")
	Plr:RemoveItem("item_mp7", 1)
end

INVENTORY:RegisterItem("item_mp7", ITEM)