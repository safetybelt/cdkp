-----------------------------------------------------------------------------------------------
-- Client Lua Script for CDKP
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
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
	["bShowHealer"] 			= false,
	["bShowTank"] 				= false,
	["bShowWarrior"]			= false,
	["bShowStalker"]			= false,
	["bShowSpellslinger"] = false,
	["bShowEngineer"] 		= false,
	["bShowEsper"] 				= false,
	["bShowMedic"]		 		= false,
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

function TooltipTests:OnDependencyError(strDep, strError)
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
	-- TODO: Remove this test window shit and add a real config window
	local t = self:GetCDKPValue(2000, { "life", "earth" }, 2, "warrior")
	self.wndMain:FindChild("Test_Result"):SetText(t)

	-- self:SetupOptions()

	self.wndMain:Invoke()
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
	local this = Apollo.GetAddon("ETooltip")
	
	wndControl:SetTooltipDoc(nil)
	local wndTooltip = origItemToolTipForm(self, wndControl, item, bStuff, nCount)
	
	if wndTooltip then
		-- t = wndTooltip:FindChild("ItemTooltip_Header_Types")
		-- t:SetText(t:GetText() .. " Power: " .. item:GetItemPower() .. " | ID: " .. item.GetItemId())
		local wndCDKPVals = Apollo.LoadForm(self.xmlDoc, "CDKP_Vals", wndControl:FindChild("Items"), self)
		if wndCDKPVals then
			wndCDKPVals:SetText("Test")
		end
	end
	return wndTooltip, wndTooltipComp
end

-- TODO: make this take an item instead of power/slots/modifier; class should stay
-- get the CDKP value, based on item power, rune slots, weapon/gadget modifiers, class
function CDKP:GetCDKPValue(ipower, slots, modifier, class)
	return math.ceil(ipower * 0.05 * (modifier + self:GetRuneModifier(slots, class)))
end

-- given slots and class, return a modifier
function CDKP:GetRuneModifier(slots, class)
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
