-- FieldGuide - ElvUI-style toast notifications
local _, ns = ...

local Alerts = {}
ns.Alerts = Alerts

local BACKDROP = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }
local KIND = {
    new     = { 0.227, 0.627, 0.910, bg = { 0.075, 0.161, 0.227 } },
    grey    = { 0.55, 0.55, 0.55, bg = { 0.15, 0.15, 0.15 } },
    tool    = { 1.00, 0.42, 0.42, bg = { 0.227, 0.078, 0.078 } },
    trainer = { 0.227, 0.627, 0.910, bg = { 0.075, 0.161, 0.227 } },
}
local MAX = 4
local active, pool = {}, {}

local function Create()
    local f = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
    f:SetSize(340, 48)
    f:SetFrameStrata("HIGH")
    f:SetBackdrop(BACKDROP)
    f:SetBackdropColor(0.1, 0.1, 0.1, 0.94)
    f:SetBackdropBorderColor(0, 0, 0, 1)

    f.iconBox = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    f.iconBox:SetSize(36, 36)
    f.iconBox:SetPoint("LEFT", 6, 0)
    f.iconBox:SetBackdrop(BACKDROP)
    f.iconBox:SetBackdropBorderColor(0, 0, 0, 1)
    f.icon = f.iconBox:CreateTexture(nil, "ARTWORK")
    f.icon:SetPoint("TOPLEFT", 1, -1)
    f.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetPoint("TOPLEFT", f.iconBox, "TOPRIGHT", 8, -1)
    f.title:SetPoint("RIGHT", -8, 0)
    f.title:SetJustifyH("LEFT")
    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)
    f.text:SetPoint("RIGHT", -8, 0)
    f.text:SetJustifyH("LEFT")
    f.text:SetWordWrap(false)

    f:EnableMouse(true)
    f:SetScript("OnMouseUp", function(self) Alerts:Release(self) end)
    f:SetScript("OnUpdate", function(self, elapsed)
        self.left = self.left - elapsed
        if self.left <= 0 then
            Alerts:Release(self)
        elseif self.left < 0.6 then
            self:SetAlpha(self.left / 0.6)
        end
    end)
    return f
end

function Alerts:Layout()
    for i, f in ipairs(active) do
        f:ClearAllPoints()
        f:SetPoint("TOP", UIParent, "TOP", 0, -140 - (i - 1) * 54)
    end
end

function Alerts:Release(f)
    for i, a in ipairs(active) do
        if a == f then table.remove(active, i) break end
    end
    f:Hide()
    pool[#pool + 1] = f
    self:Layout()
end

-- kind: new | grey | tool | trainer ; icon: texture path or file/item icon
function Alerts:Show(kind, title, text, icon)
    local f = table.remove(pool) or Create()
    local font = ns.Font()
    local k = KIND[kind] or KIND.new
    f.title:SetFont(font, 14, "")
    f.text:SetFont(font, 13, "")
    f.title:SetText(title)
    f.title:SetTextColor(k[1], k[2], k[3])
    f.text:SetText(text)
    f.text:SetTextColor(0.95, 0.95, 0.95)
    f.iconBox:SetBackdropColor(k.bg[1], k.bg[2], k.bg[3], 1)
    f.icon:SetTexture(icon or (ns.MEDIA .. "Logo"))
    f.icon:SetTexCoord(icon and 0.08 or 0, icon and 0.92 or 1, icon and 0.08 or 0, icon and 0.92 or 1)
    f.left = (ns.db and ns.db.profile.alerts.duration) or 6
    f:SetAlpha(1)
    f:Show()
    table.insert(active, 1, f)
    while #active > MAX do self:Release(active[#active]) end
    self:Layout()
    if ns.db and ns.db.profile.alerts.sound then
        PlaySound((SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959, "Master")
    end
end

function Alerts:Test()
    local L = ns.L
    self:Show("new", L["New node available"], L["%s: %s %d reached"]:format(ns.L["NODE_mithril"], L["PROF_ore"], 175), ns.GetItemIcon(3858))
    self:Show("grey", L["Turned grey"], L["%s no longer gives skill points"]:format(ns.GetItemInfo(785) or "Mageroyal"), ns.GetItemIcon(785))
    self:Show("tool", L["Missing tool"], L["No %s in your bags"]:format(ns.GetItemInfo(6256) or "Fishing Pole"), ns.GetItemIcon(6256))
end
