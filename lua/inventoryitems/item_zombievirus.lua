local ITEM = {}

ITEM.Name = "Zombie Virus"
ITEM.Info = "Zombie Virus left over from some lab in area 51, be carefull!"
ITEM.Model = "models/props_lab/jar01a.mdl"
ITEM.Weight = 1

function ITEM:Drop(Plr)
	Plr:SpawnItem("item_zombievirus")
	Plr:RemoveItem("item_zombievirus", 1)
end

function ITEM:Use(Plr)
	Plr:SetHealth(Plr:Health() + 400)
	Plr:SetModel("models/Zombie/Classic.mdl")
	Plr:EmitSound("npc/zombie/zombie_voice_idle1.wav")
	
	Plr:RemoveItem("item_zombievirus", 1)
end

INVENTORY:RegisterItem("item_zombievirus", ITEM)