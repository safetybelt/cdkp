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
local classQualities = {
    ["healer"] = { ["omni"] = "great", ["fusion"] = "great", ["life"] = "great", ["water"] = "great", ["air"] = "good", ["fire"] = "good", ["earth"] = "bad", ["logic"] = "bad" },
    ["tank"] = { ["omni"] = "great", ["fusion"] = "good", ["life"] = "great", ["water"] = "bad", ["air"] = "great", ["fire"] = "bad", ["earth"] = "great", ["logic"] = "good" },
    ["warrior"] = { ["omni"] = "great", ["fusion"] = "great", ["life"] = "good", ["water"] = "bad", ["air"] = "bad", ["fire"] = "great", ["earth"] = "good", ["logic"] = "bad" },
    ["stalker"] = { ["omni"] = "great", ["fusion"] = "great", ["life"] = "good", ["water"] = "bad", ["air"] = "bad", ["fire"] = "great", ["earth"] = "good", ["logic"] = "bad" },
    ["spellslinger"] = { ["omni"] = "great", ["fusion"] = "great", ["life"] = "good", ["water"] = "good", ["air"] = "good", ["fire"] = "great", ["earth"] = "bad", ["logic"] = "bad" },
    ["engineer"] = { ["omni"] = "great", ["fusion"] = "great", ["life"] = "good", ["water"] = "good", ["air"] = "good", ["fire"] = "great", ["earth"] = "bad", ["logic"] = "bad" },
    ["esper"] = { ["omni"] = "great", ["fusion"] = "great", ["life"] = "bad", ["water"] = "bad", ["air"] = "good", ["fire"] = "great", ["earth"] = "bad", ["logic"] = "good" },
    ["medic"] = { ["omni"] = "great", ["fusion"] = "great", ["life"] = "bad", ["water"] = "bad", ["air"] = "good", ["fire"] = "great", ["earth"] = "good", ["logic"] = "good" },
}


-----------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CDKP:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

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
-- CDKP Functions
-----------------------------------------------------------------------------------------------
-- adjust the default tooltip
function CDKP:ItemToolTip(wndControl, item, bStuff, nCount)
	local this = Apollo.GetAddon("ETooltip")
	
	wndControl:SetTooltipDoc(nil)
	local wndTooltip = origItemToolTipForm(self, wndControl, item, bStuff, nCount)
	
	if wndTooltip then
		-- t = wndTooltip:FindChild("ItemTooltip_Header_Types")
		-- t:SetText(t:GetText() .. " Power: " .. item:GetItemPower())
		local wndCDKPVals = Apollo.LoadForm(self.xmlDoc, "CDKP_Vals", wndControl:FindChild("Items"), self)
		if wndCDKPVals then
			wndCDKPVals:SetText("Test")
		end
	end
	return wndTooltip, wndTooltipComp
end

-- on SlashCommand "/cdkp"
function CDKP:OnCDKPOn()
	local t = self:GetCDKPValue(2000, { "life", "earth" }, 2, "warrior")
	
	self.wndMain:FindChild("Test_Result"):SetText(t)
	
	self.wndMain:Invoke() -- show the window
end

-- get the CDKP value, based on item power, rune slots, weapon/gadget modifiers, class
function CDKP:GetCDKPValue(ipower, slots, modifier, class)
	return math.ceil(ipower * 0.05 * (modifier + self:GetRuneModifier(slots, class)))
end

-- given slots and class, return a modifier
function CDKP:GetRuneModifier(slots, class)
	-- slot quality values, { bad, good, great }
	local qualVals = { ["bad"] = 1, ["good"] = 2, ["great"] = 4 }
	-- slot penalties { 1st slot, 2nd slot, etc }
	local slotPenalties = { 1.0, 0.78, 0.66, 0.57, 0.51, 0.51 }
	
	local r = 0
		
	for i = 1, #slots do
		r = r + (qualVals[classQualities[class][slots[i]]] * slotPenalties[i])
	end
	
	r = (math.sqrt(200) / 10.26 * (r - 1.78)) ^ 2
	r = r / 100
	
	return r
end


-----------------------------------------------------------------------------------------------
-- CDKPForm Functions
-----------------------------------------------------------------------------------------------
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
