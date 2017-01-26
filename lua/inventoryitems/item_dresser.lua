local ITEM = {}

ITEM.Name = "Dresser"
ITEM.Info = "A dresser prop!"
ITEM.Model = "models/props_c17/FurnitureDresser001a.mdl"
ITEM.Useable = false
ITEM.Weight = 3

function ITEM:Drop(Plr)
	Plr:SpawnItem("item_dresser")
	Plr:RemoveItem("item_dresser", 1)
end

INVENTORY:RegisterItem("item_dresser", ITEM)