AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self.ItemTable = INVENTORY.Items[self.Unique]
	
	self:SetModel(self.ItemTable.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType( MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	
	local pObject = self:GetPhysicsObject()
	if IsValid(pObject) then
		pObject:Wake()
	end
	
	self:SetNetworkedString("Inventory_Name", self.ItemTable.Name)
end

function ENT:PhysgunPickup(Plr)
	return false
end

function ENT:CanTool(Plr)
	return false
end

function ENT:Use(Activator)
	if IsValid(Activator) and Activator:IsPlayer() then
		Activator:GiveItem(self.Unique, 1)
		Activator:EmitSound("items/ammocrate_open.wav")
		Activator:ChatPrint("Picked up " .. self.ItemTable.Name .. ".")
		self:Remove()
	end
end