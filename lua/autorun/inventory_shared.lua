local PlayerMeta = FindMetaTable("Player")

INVENTORY = {}
INVENTORY.Items = {}

--[[hook.Add("ShowSpare2", "InventoryMenu", function(Plr)
	Plr:ConCommand("inventory")
end)]]

function INVENTORY:RegisterItem(Unique, ItemTable)
	INVENTORY.Items[Unique] = ItemTable
	INVENTORY.Items[Unique].Name = ItemTable.Name or ""
	INVENTORY.Items[Unique].Info = ItemTable.Info or ""
	INVENTORY.Items[Unique].Model = ItemTable.Model or ""
	INVENTORY.Items[Unique].Useable = (ItemTable.Useable ~= nil and ItemTable.Useable) or true
	INVENTORY.Items[Unique].Dropable = (ItemTable.Dropable ~= nil and ItemTable.Dropable)  or true
	
	if SERVER then
		INVENTORY.Items[Unique].Use = ItemTable.Use or function() end
		INVENTORY.Items[Unique].Drop = ItemTable.Drop or function() end
	end
end

for _, v in pairs(file.Find("inventoryitems/*.lua", "LUA")) do
	include("inventoryitems/"..v)
	if SERVER then
		AddCSLuaFile("inventoryitems/"..v)
	end
end

if SERVER then
	util.AddNetworkString("InventorySetItem")
	util.AddNetworkString("InventoryItems")
	function PlayerMeta:SpawnItem(Item)
		if INVENTORY.Items[Item] then
			local Trace = self:GetEyeTrace()
			
			local New = ents.Create("inventory_item")
			New:SetPos(Trace.StartPos + Trace.Normal * Vector(100, 100, 0))
			New.Unique = Item
			New:Spawn()
			New:PhysWake()
		end
	end

	function PlayerMeta:HasItem(Item)
		if (self.InventoryItems[Item] == nil) then
			return false
		end
		
		return self.InventoryItems[Item] >= 1
	end

	function PlayerMeta:GiveItem(Item, Amount)
		self.InventoryItems[Item] = (self.InventoryItems[Item] or 0) + Amount
		
		net.Start("InventorySetItem")
			net.WriteString(Item)
			net.WriteInt(self.InventoryItems[Item], 32)
		net.Send(self)
	end

	function PlayerMeta:RemoveItem(Item, Amount)
		local Inventory = self.InventoryItems
		
		if Inventory[Item] and Inventory[Item] >= 1 then
			Inventory[Item] = Inventory[Item] - Amount
			
			net.Start("InventorySetItem")
				net.WriteString(Item)
				net.WriteInt(Inventory[Item], 32)
			net.Send(self)
		end
		
		if Inventory[Item] == 0 then
			Inventory[Item] = nil
		end
	end

	function PlayerMeta:SaveInventory()
		if not file.IsDir("codenil", "DATA") then
			file.CreateDir("codenil", "DATA")
		end
		if not file.IsDir("codenil/inventory/", "DATA") then
			file.CreateDir("codenil/inventory/", "DATA")
		end
		local Data = von.serialize(self.InventoryItems)
		file.Write("codenil/inventory/"..self:UniqueID()..".txt", Data, "DATA")
	end

	hook.Add("PlayerInitialSpawn", "InventoryAddon", function(Plr)
		Plr.InventoryItems = {}
		if file.Exists("codenil/inventory/"..Plr:UniqueID()..".txt", "DATA") then
			local Data = von.deserialize(file.Read("codenil/inventory/"..Plr:UniqueID()..".txt", "DATA"))
			Plr.InventoryItems = Data
			
			timer.Simple(2, function()
				net.Start("InventoryItems")
					net.WriteTable(Plr.InventoryItems)
				net.Send(Plr)
			end)
		else
			Plr:SaveInventory()
		end
	end)
	
	timer.Simple(0.2, function()
		for _, v in pairs(player.GetAll()) do
			net.Start("InventoryItems")
				net.WriteTable(v.InventoryItems)
			net.Send(v)
		end
	end)

	hook.Add("PlayerDisconnected", "InventoryAddon", function(Plr)
		Plr:SaveInventory()
	end)

	hook.Add("ShutDown", "InventoryAddon", function()
		for _, Plr in ipairs(player.GetAll()) do
			Plr:SaveInventory()
		end
	end)

	concommand.Add("inventoryspawnitem", function(Plr, Cmd, Args)
		if Plr:IsAdmin() then
			local Item = Args[1] or ""
			
			if INVENTORY.Items[Item] then
				Plr:SpawnItem(Item)
			else	
				Plr:PrintMessage(HUD_PRINTCONSOLE, "Invalid item: '"..Item.."'\nType 'inventoryshowitems' in console to see available items!")
			end
		end
	end)

	concommand.Add("inventoryshowitems", function(Plr, Cmd, Args)
		if Plr:IsAdmin() then
			Plr:PrintMessage(HUD_PRINTCONSOLE, "====== Items ======"..string.char(10))
			
			for v, _ in pairs(INVENTORY.Items) do
				Plr:PrintMessage(HUD_PRINTCONSOLE, v..string.char(10))
			end
		end
	end)

	concommand.Add("inventoryuse", function(Plr, Cmd, Args)
		local Item = Args[1]
		if INVENTORY.Items[Item] then
			if Plr:HasItem(Item) then
				INVENTORY.Items[Item]:Use(Plr)
			end
		end
	end)
	
	concommand.Add("inventorydrop", function(Plr, Cmd, Args)
		local Item = Args[1]
		if INVENTORY.Items[Item] then
			if Plr:HasItem(Item) then
				INVENTORY.Items[Item]:Drop(Plr)
				Plr:EmitSound("items/ammocrate_close.wav")
			end
		end
	end)
elseif CLIENT then
	local LocalInventory = {}
	
	local MaterialCache = {}
	local function GetMaterial(Item)
		if MaterialCache[Item] then
			return MaterialCache[Item]
		else
			MaterialCache[Item] = Material(INVENTORY.Items[Item].SpawnIcon or "spawnicons/"..INVENTORY.Items[Item].Model:gsub("mdl", "png"):lower())
			return MaterialCache[Item]
		end
	end
	
	local Grid = {}
	local MaxWeight = 8
	
	local Menu
	local MenuOpen = false
	local function OpenMenu()
		if Menu and IsValid(Menu) then
			Menu:Remove()
		end
		MenuOpen = true
		Menu = vgui.Create("DFrame")
		Menu:SetSize(ScrW() * 0.4, ScrH() * 0.5)
		Menu:SetTitle("Inventory")
		Menu:Center()
		Menu:ShowCloseButton(true)
		Menu:SetDraggable(false)
		Menu:MakePopup()
		Menu.lblTitle:SetFont("EMPLOYMENT_FONT_LARGE")
		Menu.btnMaxim:SetVisible(false)
		Menu.btnMinim:SetVisible(false)
		function Menu.btnClose:DoClick()
			Menu:Close()
			MenuOpen = false
		end
		function Menu.btnClose:Paint(w, h)
			draw.RoundedBoxEx(8, 0, h * 0.1, w, h * 0.58, Color(220, 80, 80), false, true, true, false)
		end
		function Menu:Paint(w, h)
			draw.RoundedBoxEx(8, 0, 0, w, 24, Color(32, 178, 170), false, true, false, false)
			draw.RoundedBoxEx(8, 0, 24, w, h - 24, Color(245, 245, 245), false, false, true, false)
		end
		
		local Scroll = vgui.Create("DScrollPanel", Menu)
		Scroll:Dock(FILL)
		
		local Layout = vgui.Create("DIconLayout", Scroll)
		Layout:Dock(FILL)
		Layout:SetSpaceX(5)
		Layout:SetSpaceY(5)
		Layout:SetBorder(10)
		Layout:InvalidateLayout(true)
		local Size = Menu:GetWide() - 19
		for i, v in pairs(LocalInventory) do
			local New = vgui.Create("DButton")
			New:SetText("")
			New:SetSize(Size/6, Size/6)
			New.Image = GetMaterial(i)
			function New:Paint(w, h)
				draw.RoundedBoxEx(8, 0, 0, w, h, self:IsDown() and Color(120, 200, 195) or self.Hovered and Color(180, 230, 225) or Color(220, 240, 240), false, true, true, false)
				draw.SimpleTextOutlined("x"..v, "DermaLarge", w - 5, h - 5, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 1, color_black)
				
				surface.SetDrawColor(255, 255, 255)
				surface.SetMaterial(self.Image)
				surface.DrawTexturedRect(25, 25, w - 50, h - 50)
			end
			function New:DoClick()
				local DMenu = DermaMenu()
				if INVENTORY.Items[i].Useable then
					DMenu:AddOption("Use", function()
						RunConsoleCommand("inventoryuse", i)
						if MenuOpen then
							OpenMenu()
						end
					end)
				end
				if INVENTORY.Items[i].Dropable then
					DMenu:AddOption("Drop", function()
						RunConsoleCommand("inventorydrop", i)
						if MenuOpen then
							OpenMenu()
						end
					end)
				end
				DMenu:Open()
			end
			Layout:Add(New)
		end
	end
	
	hook.Add("HUDPaint", "InventoryHUD", function()
		local Trace = LocalPlayer():GetEyeTrace()
		if Trace.Entity:IsValid() and Trace.Entity:GetClass() == "inventory_item" then
			local Name = Trace.Entity:GetNetworkedString("Inventory_Name")
			local Pos =  Trace.Entity:GetPos():ToScreen()
			
			draw.SimpleTextOutlined(Name, "DermaLarge", Pos.x, Pos.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
		end
	end)
	
	concommand.Add("inventory", function()
		OpenMenu()
	end)
	
	net.Receive("InventoryItems", function(Len, Plr)
		LocalInventory = net.ReadTable()
		if MenuOpen then
			OpenMenu()
		end
	end)
	
	net.Receive("InventorySetItem", function(Len, Plr)
		local Name, Amount = net.ReadString(), net.ReadInt(32)
		LocalInventory[Name] = Amount == 0 and nil or Amount
		if MenuOpen then
			OpenMenu()
		end
	end)
end