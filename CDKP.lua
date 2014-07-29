-----------------------------------------------------------------------------------------------
-- Client Lua Script for CDKP
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Apollo"
require "Window"
require "math"
 
-----------------------------------------------------------------------------------------------
-- CDKP Module Definition
-----------------------------------------------------------------------------------------------
local CDKP = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- TODO: Make these customizable in UI?  Probably not so everyone sees same values...
local tClassQualities = {
    ["healer"] = { ["omni"] = "great", ["fusion"] = "great", ["life"] = "great", ["water"] = "great", ["air"] = "good", ["fire"] = "good", ["earth"] = "bad", ["logic"] = "bad" },
    ["tank"] = { ["omni"] = "great", ["fusion"] = "good", ["life"] = "great", ["water"] = "bad", ["air"] = "great", ["fire"] = "bad", ["earth"] = "great", ["logic"] = "good" },
    ["warrior"] = { ["omni"] = "great", ["fusion"] = "great", ["life"] = "good", ["water"] = "bad", ["air"] = "bad", ["fire"] = "great", ["earth"] = "good", ["logic"] = "bad" },
    ["stalker"] = { ["omni"] = "great", ["fusion"] = "great", ["life"] = "good", ["water"] = "bad", ["air"] = "bad", ["fire"] = "great", ["earth"] = "good", ["logic"] = "bad" },
    ["spellslinger"] = { ["omni"] = "great", ["fusion"] = "great", ["life"] = "good", ["water"] = "good", ["air"] = "good", ["fire"] = "great", ["earth"] = "bad", ["logic"] = "bad" },
    ["engineer"] = { ["omni"] = "great", ["fusion"] = "great", ["life"] = "good", ["water"] = "good", ["air"] = "good", ["fire"] = "great", ["earth"] = "bad", ["logic"] = "bad" },
    ["esper"] = { ["omni"] = "great", ["fusion"] = "great", ["life"] = "bad", ["water"] = "bad", ["air"] = "good", ["fire"] = "great", ["earth"] = "bad", ["logic"] = "good" },
    ["medic"] = { ["omni"] = "great", ["fusion"] = "great", ["life"] = "bad", ["water"] = "bad", ["air"] = "good", ["fire"] = "great", ["earth"] = "good", ["logic"] = "good" },
}

local tDefaultSettings = {
	["bShowHealer"] 			= true,
	["bShowTank"] 				= true,
	["bShowWarrior"]			= true,
	["bShowStalker"]			= true,
	["bShowSpellslinger"] 		= true,
	["bShowEngineer"] 			= true,
	["bShowEsper"] 				= true,
	["bShowMedic"]		 		= true,
	["bShowItemId"]				= true,
}

local tRunes =
{
  [Item.CodeEnumSigilType.Air]		= "air",
  [Item.CodeEnumSigilType.Earth]	= "earth",
  [Item.CodeEnumSigilType.Fire]		= "fire",
  [Item.CodeEnumSigilType.Fusion]	= "fusion",
  [Item.CodeEnumSigilType.Life]		= "life",
  [Item.CodeEnumSigilType.Logic]	= "logic",
  [Item.CodeEnumSigilType.Omni]		= "omni",
  [Item.CodeEnumSigilType.Water]	= "water",
}


-----------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CDKP:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- initialize variables here
    o.tSettings = {}

    return o
end

function CDKP:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function CDKP:OnDependencyError(strDep, strError)
	if strDep == "ToolTips" then
		local tReplacements = Apollo.GetReplacement(strDep)
		if #tReplacements ~= 1 then
			return false
		end
		self.TTReplacement = tReplacements[1]
		return true
	end
end
 

-----------------------------------------------------------------------------------------------
-- CDKP OnLoad
-----------------------------------------------------------------------------------------------
function CDKP:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("CDKP.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	
	local tt = Apollo.GetAddon("ToolTips")
	if tt then
		self:HookToolTip(tt)
	end
end

function CDKP:HookToolTip(aAddon)
	local origCreateCallNames = aAddon.CreateCallNames
	aAddon.CreateCallNames = function(luaCaller)
		origCreateCallNames(luaCaller)
		origItemToolTipForm = Tooltip.GetItemTooltipForm
		Tooltip.GetItemTooltipForm = function (luaCaller, wndControl, item, bStuff, nCount)
			return self.ItemToolTip(luaCaller, wndControl, item, bStuff, nCount)
		end
	end
	return true
end

-----------------------------------------------------------------------------------------------
-- CDKP OnDocLoaded
-----------------------------------------------------------------------------------------------
function CDKP:OnDocLoaded()
	if self.TTReplacement then
		self:HookToolTip(Apollo.GetAddon(self.TTReplacement))
	end
	self:DefaultSettings()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	  	self.wndMain = Apollo.LoadForm(self.xmlDoc, "CDKPForm", nil, self)
			if self.wndMain == nil then
				Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
				return
			end
		  self.wndMain:Show(false, true)
		
		-- Register handlers for events, slash commands and timer, etc.
		Apollo.RegisterSlashCommand("cdkp", "OnCDKPOn", self)

		-- Do additional Addon initialization here
	end
end


-----------------------------------------------------------------------------------------------
-- CDKP Config Functions
-----------------------------------------------------------------------------------------------
-- on SlashCommand "/cdkp"
function CDKP:OnCDKPOn()
	-- self:SetupOptions()

	-- self.wndMain:Invoke()
end

-- reset the settings to default
function CDKP:DefaultSettings()
	self.tSettings = {}
	for i,val in pairs(tDefaultSettings) do
		self.tSettings[i] = tDefaultSettings[i]
	end
end

-----------------------------------------------------------------------------------------------
-- CDKP Functions
-----------------------------------------------------------------------------------------------
-- adjust the default tooltip
function CDKP:ItemToolTip(wndControl, item, bStuff, nCount)
	local this = Apollo.GetAddon("CDKP")
	
	wndControl:SetTooltipDoc(nil)
	local wndTooltip, wndTooltipComp = origItemToolTipForm(self, wndControl, item, bStuff, nCount)
	
	if wndTooltip then
		local wndCDKPVals = Apollo.LoadForm(this.xmlDoc, "CDKP_Summary", wndTooltip:FindChild("Items"), this)
		local wndList = wndCDKPVals:FindChild("CDKP_List")
		local wndVals = Apollo.LoadForm(this.xmlDoc, "CDKP_Vals", wndList, this)

		wndVals:SetText(CDKP:GetCDKPString(item))
		wndVals:SetHeightToContentHeight()
		
		local sumHeight = wndList:ArrangeChildrenVert()
		wndCDKPVals:SetAnchorOffsets(0, 0, 0, sumHeight)
		wndTooltip:FindChild("Items"):ArrangeChildrenVert()
		wndTooltip:Move(0, 0, wndTooltip:GetWidth(), wndTooltip:GetHeight() + sumHeight)
	end
	return wndTooltip, wndTooltipComp
end

-- get the string to add to the tooltip, based on user settings
function CDKP:GetCDKPString(item)
	if item:IsEquippable() then
		-- get all the item information
		local ipower = item:GetItemPower()
		local tItemInfo = item:GetDetailedInfo().tPrimary
		local tSlots = {}
		local tSlotInfo = tItemInfo.tSigils
		if tSlotInfo then
			for i = 1, #tSlotInfo.arSigils do
				tSlots[i] = tRunes[tSlotInfo.arSigils[i].eElement]
			end
		end
		--tSlots = { "air", "life", "water", "earth" }
		
		local t = ""
		if tDefaultSettings["bShowItemId"] then t = t .. "Item ID: " .. item:GetItemId() .. "\n" end
		if tDefaultSettings["bShowHealer"] then t = t .. "Healer: " .. CDKP:GetCDKPValue(ipower, tSlots, 1, "healer") .. "\n" end
		if tDefaultSettings["bShowTank"] then t = t .. "Tank: " .. CDKP:GetCDKPValue(ipower, tSlots, 1, "tank") .. "\n" end
		if tDefaultSettings["bShowWarrior"] then t = t .. "Warrior: " .. CDKP:GetCDKPValue(ipower, tSlots, 1, "warrior") .. "\n" end
		if tDefaultSettings["bShowStalker"] then t = t .. "Stalker: " .. CDKP:GetCDKPValue(ipower, tSlots, 1, "stalker") .. "\n" end
		if tDefaultSettings["bShowSpellslinger"] then t = t .. "Spellslinger: " .. CDKP:GetCDKPValue(ipower, tSlots, 1, "spellslinger") .. "\n" end
		if tDefaultSettings["bShowEngineer"] then t = t .. "Engineer: " .. CDKP:GetCDKPValue(ipower, tSlots, 1, "engineer") .. "\n" end
		if tDefaultSettings["bShowEsper"] then t = t .. "Esper: " .. CDKP:GetCDKPValue(ipower, tSlots, 1, "esper") .. "\n" end
		if tDefaultSettings["bShowMedic"] then t = t .. "Medic: " .. CDKP:GetCDKPValue(ipower, tSlots, 1, "medic") .. "\n" end
		
		return t
	else
		return nil
	end
end

-- TODO: make this take an item instead of power/slots/modifier; class should stay
-- get the CDKP value, based on item power, rune slots, weapon/gadget modifiers, class
function CDKP:GetCDKPValue(ipower, slots, modifier, class)
	return math.ceil(ipower * 0.05 * (modifier + self:GetRuneModifier(slots, class)))
end

-- given slots and class, return a modifier
function CDKP:GetRuneModifier(slots, class)
	if #slots == 0 then
		return 0
	end
	
	-- TODO: Consider making quality values customizable; slot penalties not hard-coded here
	-- slot quality values, { bad, good, great }
	local qualVals = { ["bad"] = 1, ["good"] = 2, ["great"] = 4 }
	-- slot penalties { 1st slot, 2nd slot, etc }
	local slotPenalties = { 1.0, 0.78, 0.66, 0.57, 0.51, 0.51 }
	
	local r = 0
		
	for i = 1, #slots do
		r = r + (qualVals[tClassQualities[class][slots[i]]] * slotPenalties[i])
	end
	
	-- TODO: Consider making this formula customizable, or at least not hard-coded here
	-- algorithm created and provided by Ivellis of <Crisis>
	r = (math.sqrt(200) / 10.26 * (r - 1.78)) ^ 2
	r = r / 100
	
	return r
end


-----------------------------------------------------------------------------------------------
-- CDKPForm Functions
-----------------------------------------------------------------------------------------------
-- TODO: make ok/cancel actually save the changes or revert them, respectively
-- when the OK button is clicked
function CDKP:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function CDKP:OnCancel()
	self.wndMain:Close() -- hide the window
end


-----------------------------------------------------------------------------------------------
-- CDKP Instance
-----------------------------------------------------------------------------------------------
local CDKPInst = CDKP:new()
CDKPInst:Init()
