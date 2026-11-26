-- FieldGuide - minimap button (round and square minimaps, e.g. ElvUI)
local _, ns = ...
local L = ns.L

local Minimap_ = {}
ns.Minimap = Minimap_

local function IsSquare()
    return GetMinimapShape and GetMinimapShape() == "SQUARE"
end

function Minimap_:UpdatePosition()
    local b = self.button
    local angle = math.rad(ns.db.profile.minimap.angle or 215)
    local x, y = math.cos(angle), math.sin(angle)
    local w, h = Minimap:GetWidth() / 2 + 10, Minimap:GetHeight() / 2 + 10
    if IsSquare() then
        -- Project the direction onto the square border
        local m = math.max(math.abs(x), math.abs(y))
        x, y = x / m, y / m
    end
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", x * w, y * h)
end

function Minimap_:Init()
    -- Same look as the other minimap buttons: dark round background and the gold tracking ring
    local b = CreateFrame("Button", "FieldGuideMinimapButton", Minimap)
    self.button = b
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    local icon = b:CreateTexture(nil, "ARTWORK")
    -- Centred on the ring's hole (same centre as the round background). The medallion's circle fills the hole;
    -- its outer points go under the gold ring, which is drawn on top
    local ICON_SIZE, CX, CY = 25, 17, -15
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("CENTER", b, "TOPLEFT", CX, CY)
    icon:SetTexture(ns.MEDIA .. "Logo")
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    b.icon = icon
    b:SetScript("OnMouseDown", function() icon:SetPoint("CENTER", b, "TOPLEFT", CX + 1, CY - 1) end)
    b:SetScript("OnMouseUp", function() icon:SetPoint("CENTER", b, "TOPLEFT", CX, CY) end)

    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnClick", function(_, button)
        if button == "RightButton" then ns.Options:Open() else ns.Window:Toggle() end
    end)
    b:SetScript("OnDragStart", function(self)
        if ns.db.profile.minimap.lock then return end
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            local cx, cy = GetCursorPosition()
            cx, cy = cx / scale, cy / scale
            ns.db.profile.minimap.angle = math.deg(math.atan2(cy - my, cx - mx)) % 360
            Minimap_:UpdatePosition()
        end)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Field|cff3aa0e8Guide|r")
        GameTooltip:AddLine("|cff40c040" .. L["Left-click"] .. "|r" .. ns.COLON .. L["open the window"], 1, 1, 1)
        GameTooltip:AddLine("|cff40c040" .. L["Right-click"] .. "|r" .. ns.COLON .. L["options"], 1, 1, 1)
        if not ns.db.profile.minimap.lock then
            GameTooltip:AddLine("|cff40c040" .. L["Drag"] .. "|r" .. ns.COLON .. L["move the icon"], 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    self:Refresh()
end

function Minimap_:Refresh()
    if not self.button then return end
    self.button:SetShown(not ns.db.profile.minimap.hide)
    self:UpdatePosition()
end
