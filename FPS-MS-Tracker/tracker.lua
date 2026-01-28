--[[
    ============================================================================
    FPS & MS Monitor
    Copyright (c) 2021-2026 Pytilix
    All rights reserved.

    This Add-on and its source code are proprietary. 
    Unauthorized copying, modification, or distribution of this file, 
    via any medium, is strictly prohibited.
    
    The source code is provided for personal use and educational purposes 
    only, as per Blizzard's UI Add-On Development Policy.
    ============================================================================
--]]

-- Hauptframe erstellen
local StatsFrame = CreateFrame("Frame", "StatsFrame", UIParent)
local movable = true

-- Kompatibilität für API-Änderungen (Patch 11.0/12.0)
local GetNumAddOns = GetNumAddOns or (C_AddOns and C_AddOns.GetNumAddOns)
local GetAddOnInfo = GetAddOnInfo or (C_AddOns and C_AddOns.GetAddOnInfo)
local GetAddOnMemoryUsage = GetAddOnMemoryUsage or (C_AddOns and C_AddOns.GetAddOnMemoryUsage)
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage or (C_AddOns and C_AddOns.UpdateAddOnMemoryUsage)
local IsAddOnLoaded = IsAddOnLoaded or (C_AddOns and C_AddOns.IsAddOnLoaded)

-- Standard-Position: Unten Links 
StatsFrame:ClearAllPoints()
StatsFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 10)

if movable then
    StatsFrame:SetClampedToScreen(true)
    StatsFrame:SetMovable(true)
    StatsFrame:EnableMouse(true)
    StatsFrame:SetUserPlaced(true)
    
    StatsFrame:SetScript("OnMouseDown", function(self, button)
        if IsAltKeyDown() and button == "LeftButton" then
            self:StartMoving()
        end
    end)
    StatsFrame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
    end)
end

local CF = CreateFrame("Frame")
CF:RegisterEvent("PLAYER_LOGIN")
CF:SetScript("OnEvent", function(self, event)
    local fontSize = 12
    local fontFlag = "THINOUTLINE"
    local customColor = true
    local addonList = 50

    local color = {r = 1, g = 1, b = 1}
    if customColor then
        local _, class = UnitClass("player")
        color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
    end

    local function memFormat(number)
        if number > 1024 then
            return string.format("%.2f mb", (number / 1024))
        else
            return string.format("%.1f kb", math.floor(number))
        end
    end

    -- Tooltip Funktion
    local function addonTooltip(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:ClearLines()
        if UpdateAddOnMemoryUsage then UpdateAddOnMemoryUsage() end
        
        local blizz = collectgarbage("count")
        local addons = {}
        local total = 0
        
        local numAddons = GetNumAddOns() or 0
        for i = 1, numAddons do
            if IsAddOnLoaded(i) then
                local name = GetAddOnInfo(i)
                local memory = GetAddOnMemoryUsage(i)
                table.insert(addons, {name = name, memory = memory})
                total = total + memory
            end
        end
        
        table.sort(addons, function(a, b) return a.memory > b.memory end)
        
        GameTooltip:AddLine("AddOns", color.r, color.g, color.b)
        for i = 1, math.min(#addons, addonList) do
            local entry = addons[i]
            GameTooltip:AddDoubleLine(entry.name, memFormat(entry.memory), 1, 1, 1, 1, 1, 1)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Total Addon Memory", memFormat(total), 1, 1, 1)
        
        local _, _, latencyHome, latencyWorld = GetNetStats()
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Network", color.r, color.g, color.b)
        GameTooltip:AddDoubleLine("Local Latency", latencyHome .. " ms", 1, 1, 1)
        GameTooltip:AddDoubleLine("World Latency", latencyWorld .. " ms", 1, 1, 1)
        
        -- Hinweis zum Bewegen (Englisch)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("<Alt + Left Click to Drag>", 0, 1, 0)
        
        GameTooltip:Show()
    end

    StatsFrame:SetScript("OnEnter", addonTooltip)
    StatsFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    StatsFrame.text = StatsFrame:CreateFontString(nil, "OVERLAY")
    StatsFrame.text:SetPoint("CENTER", StatsFrame)
    StatsFrame.text:SetFont(STANDARD_TEXT_FONT, fontSize, fontFlag)
    StatsFrame.text:SetTextColor(color.r, color.g, color.b)

    local lastUpdate = 0
    StatsFrame:SetScript("OnUpdate", function(self, elapsed)
        lastUpdate = lastUpdate + elapsed
        if lastUpdate > 1 then
            lastUpdate = 0
            local fps = math.floor(GetFramerate())
            local _, _, _, lag = GetNetStats()
            StatsFrame.text:SetText("|c00ffffff" .. fps .. "|r fps |c00ffffff" .. lag .. "|r ms")
            self:SetWidth(StatsFrame.text:GetStringWidth())
            self:SetHeight(StatsFrame.text:GetStringHeight())
        end
    end)
end)