local PlayerMeta = FindMetaTable("Player")

function PlayerMeta:SavePocketInventory()
	if self.darkRPPocket then
		if not file.IsDir("codenil", "DATA") then
			file.CreateDir("codenil", "DATA")
		end
		if not file.IsDir("codenil/inventory/", "DATA") then
			file.CreateDir("codenil/inventory/", "DATA")
		end
		file.Write("codenil/inventory/" .. self:UniqueID() .. ".txt", von.serialize(self.darkRPPocket), "DATA")
	end
end

hook.Add("PlayerInitialSpawn", "InventoryAddon", function(Plr)
	if file.Exists("codenil/inventory/" .. Plr:UniqueID() .. ".txt", "DATA") then
		Plr.darkRPPocket = von.deserialize(file.Read("codenil/inventory/" .. Plr:UniqueID() .. ".txt", "DATA"))
	    net.Start("DarkRP_Pocket")
	        net.WriteTable(Plr:getPocketItems())
	    net.Send(Plr)
	end
end)

hook.Add("PlayerDisconnected", "InventoryAddon", function(Plr)
	Plr:SavePocketInventory()
end)

hook.Add("ShutDown", "InventoryAddon", function()
	for _, Plr in ipairs(player.GetAll()) do
		Plr:SavePocketInventory()
	end
end)
