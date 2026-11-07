--[[
================================================================================
    LaxissTM — Rivals 
    Aimbot / ESP / Movement / Skin Unlocker
    
================================================================================
    USE ALTS
================================================================================
]]

-- ============================================================================
-- SAFE BOOTSTRAP
-- ============================================================================
local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- capability probes
local HAS_DRAWING = false
pcall(function()
    if Drawing and Drawing.new then
        local d = Drawing.new("Line")
        d:Remove()
        HAS_DRAWING = true
    end
end)

local HAS_META = (getrawmetatable ~= nil and setreadonly ~= nil)
local HAS_HOOK = (hookfunction ~= nil)

local ViewportCenter = Vector2.new(
    Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
)

local function refreshCenter()
    if Camera then
        ViewportCenter = Vector2.new(
            Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
        )
    end
end

pcall(function()
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshCenter)
end)

-- ============================================================================
-- STATE
-- ============================================================================
local S = {
    -- aim
    Aimbot=false, AimPart="Head", FOV=120, Smoothness=0.2, Prediction=0.15,
    TeamCheck=true, VisibleCheck=false,

    -- silent
    SilentAim=false, SilentFOV=180, SilentPart="Head", SilentTeamCheck=true,

    -- esp
    ESPEnabled=false, ESPBox=false, ESPName=false, ESPHealth=false,
    ESPDistance=false, ESPTracer=false, ESPMaxDist=600, ESPTeamCheck=true,

    -- movement
    WalkSpeed=16, JumpPower=50, InfJump=false, Fly=false, FlySpeed=60,
    Noclip=false,

    -- world
    FullBright=false, NoFog=false, CamFOV=90,

    -- skin
    UnlockSkins=false,

    Unloaded=false,

    Drawings={}, FlyBV=nil, FlyBG=nil,
    SilentHooked=false, WorldRestore={},
}
getgenv().LaxissRivals = S

-- ============================================================================
-- HELPERS
-- ============================================================================
local function getChar() return LP.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function alive(plr)
    if not plr or not plr.Character then return false end
    local h = plr.Character:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end
local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title=title, Text=text, Duration=3,
        })
    end)
end
local function worldToScreen(pos)
    local sp, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), on
end

local function teamSafe(plr, check)
    if plr == LP then return false end
    if not check then return true end
    local myTeam, myColor = LP.Team, LP.TeamColor
    local pTeam, pColor = plr.Team, plr.TeamColor
    if pTeam and pTeam.Name:lower():find("spectator") then return false end
    if myTeam and myTeam.Name:lower():find("spectator") then return false end
    if myTeam and pTeam then return myTeam ~= pTeam end
    if myColor and pColor then return myColor ~= pColor end
    return true
end

-- ============================================================================
-- COMPACT MOBILE UI (no Kavo)
-- ============================================================================
local Theme = {
    Bg=Color3.fromRGB(14,15,20), Surface=Color3.fromRGB(22,24,32),
    Card=Color3.fromRGB(28,31,42), Accent=Color3.fromRGB(90,200,255),
    Text=Color3.fromRGB(215,220,230), Dim=Color3.fromRGB(120,126,142),
    Danger=Color3.fromRGB(255,95,110), OnAccent=Color3.fromRGB(10,12,18),
}

local old = CoreGui:FindFirstChild("LaxissRivals")
if old then old:Destroy() end

local Gui = Instance.new("ScreenGui")
Gui.Name = "LaxissRivals"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 999
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = CoreGui

local uiScale = Instance.new("UIScale")
uiScale.Scale = IS_MOBILE and 1.05 or 1.0
uiScale.Parent = Gui

local Root = Instance.new("Frame")
Root.Size = UDim2.fromOffset(IS_MOBILE and 320 or 380, 390)
Root.Position = UDim2.new(0.5, -(IS_MOBILE and 160 or 190), 0.5, -195)
Root.BackgroundColor3 = Theme.Bg
Root.BorderSizePixel = 0
Root.Active = true
Root.ClipsDescendants = true
Root.Parent = Gui

local rootCorner = Instance.new("UICorner")
rootCorner.CornerRadius = UDim.new(0, 10)
rootCorner.Parent = Root

local rootStroke = Instance.new("UIStroke")
rootStroke.Color = Theme.Card
rootStroke.Thickness = 1
rootStroke.Parent = Root

-- header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Theme.Surface
Header.BorderSizePixel = 0
Header.Parent = Root

local hCorner = Instance.new("UICorner")
hCorner.CornerRadius = UDim.new(0, 10)
hCorner.Parent = Header

local hCover = Instance.new("Frame")
hCover.Size = UDim2.new(1, 0, 0, 12)
hCover.Position = UDim2.new(0, 0, 1, -12)
hCover.BackgroundColor3 = Theme.Surface
hCover.BorderSizePixel = 0
hCover.Parent = Header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.fromOffset(14, 0)
title.BackgroundTransparency = 1
title.Text = "LaxissTM  ·  Rivals"
title.TextColor3 = Theme.Accent
title.Font = Enum.Font.GothamBlack
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = Header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.Position = UDim2.new(1, -36, 0.5, -16)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.TextColor3 = Theme.Danger
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.Parent = Header
closeBtn.MouseButton1Click:Connect(function()
    Gui.Enabled = false
end)

-- drag (touch + mouse)
do
    local dragStart, startPos
    Header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragStart = i.Position
            startPos = Root.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragStart and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            Root.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragStart = nil
        end
    end)
end

-- tabs
local tabStrip = Instance.new("Frame")
tabStrip.Size = UDim2.new(1, 0, 0, 30)
tabStrip.Position = UDim2.fromOffset(0, 38)
tabStrip.BackgroundColor3 = Theme.Surface
tabStrip.BorderSizePixel = 0
tabStrip.Parent = Root

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 3)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabStrip

local tabPad = Instance.new("UIPadding")
tabPad.PaddingLeft = UDim.new(0, 6)
tabPad.PaddingRight = UDim.new(0, 6)
tabPad.PaddingTop = UDim.new(0, 4)
tabPad.Parent = tabStrip

-- content
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -16, 1, -84)
content.Position = UDim2.fromOffset(8, 74)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = Theme.Accent
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = Root

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 5)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content

-- status
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, 0, 0, 24)
statusBar.Position = UDim2.new(0, 0, 1, -24)
statusBar.BackgroundColor3 = Theme.Surface
statusBar.BorderSizePixel = 0
statusBar.Parent = Root

local sCorner = Instance.new("UICorner")
sCorner.CornerRadius = UDim.new(0, 10)
sCorner.Parent = statusBar

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -14, 1, 0)
statusLabel.Position = UDim2.fromOffset(14, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Theme.Dim
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusBar

-- ============================================================================
-- WIDGETS
-- ============================================================================
local Tabs = {}
local TabButtons = {}
local activeTab = nil

local function selectTab(name)
    for n, f in pairs(Tabs) do f.Visible = (n == name) end
    for n, b in pairs(TabButtons) do
        b.BackgroundColor3 = (n == name) and Theme.Accent or Theme.Card
        b.TextColor3 = (n == name) and Theme.OnAccent or Theme.Dim
    end
    activeTab = name
end

local function makeTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(IS_MOBILE and 62 or 76, 22)
    btn.BackgroundColor3 = Theme.Card
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Theme.Dim
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.AutoButtonColor = false
    btn.Parent = tabStrip
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 5)
    bc.Parent = btn

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = content
    local fl = Instance.new("UIListLayout")
    fl.Padding = UDim.new(0, 5)
    fl.SortOrder = Enum.SortOrder.LayoutOrder
    fl.Parent = frame

    Tabs[name] = frame
    TabButtons[name] = btn
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    return frame
end

local function section(parent, text)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, 0, 0, 22)
    h.BackgroundTransparency = 1
    h.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.Accent
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = h
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, -1)
    line.BackgroundColor3 = Theme.Card
    line.BorderSizePixel = 0
    line.Parent = h
end

local function toggle(parent, label, default, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, 0, 0, 30)
    h.BackgroundTransparency = 1
    h.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = h
    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(40, 20)
    track.Position = UDim2.new(1, -40, 0.5, -10)
    track.BackgroundColor3 = default and Theme.Accent or Theme.Card
    track.BorderSizePixel = 0
    track.Parent = h
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(1, 0)
    tc.Parent = track
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.Position = UDim2.new(0, default and 23 or 3, 0.5, -7)
    knob.BackgroundColor3 = default and Theme.OnAccent or Theme.Dim
    knob.BorderSizePixel = 0
    knob.Parent = track
    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0)
    kc.Parent = knob
    local state = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = track
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(track, TweenInfo.new(0.12), {
            BackgroundColor3 = state and Theme.Accent or Theme.Card,
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.12), {
            Position = UDim2.new(0, state and 23 or 3, 0.5, -7),
            BackgroundColor3 = state and Theme.OnAccent or Theme.Dim,
        }):Play()
        if cb then pcall(cb, state) end
    end)
end

local function slider(parent, label, min, max, default, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, 0, 0, 46)
    h.BackgroundTransparency = 1
    h.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": " .. tostring(default)
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = h
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -12, 0, 4)
    track.Position = UDim2.fromOffset(0, 28)
    track.BackgroundColor3 = Theme.Card
    track.BorderSizePixel = 0
    track.Parent = h
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(1, 0)
    tc.Parent = track
    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale((default - min) / (max - min), 1)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0)
    fc.Parent = fill
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(12, 12)
    knob.Position = UDim2.new(fill.Size.X.Scale, -6, 0.5, -6)
    knob.BackgroundColor3 = Theme.Text
    knob.BorderSizePixel = 0
    knob.Parent = track
    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0)
    kc.Parent = knob
    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel + 0.5)
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.new(rel, -6, 0.5, -6)
        lbl.Text = label .. ": " .. tostring(val)
        if cb then pcall(cb, val) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function button(parent, text, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 28)
    b.BackgroundColor3 = Theme.Card
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Theme.Text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.AutoButtonColor = false
    b.Parent = parent
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = b
    b.MouseButton1Click:Connect(function()
        if cb then pcall(cb) end
    end)
end

local function paragraph(parent, text, height)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, height or 40)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Theme.Dim
    l.Font = Enum.Font.Gotham
    l.TextSize = 10
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Top
    l.Parent = parent
end

local function dropdown(parent, label, opts, default, cb)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, 0, 0, 30)
    h.BackgroundTransparency = 1
    h.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -130, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = h
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(120, 24)
    btn.Position = UDim2.new(1, -120, 0.5, -12)
    btn.BackgroundColor3 = Theme.Card
    btn.BorderSizePixel = 0
    btn.Text = "◂ " .. default .. " ▸"
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 10
    btn.AutoButtonColor = false
    btn.Parent = h
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 5)
    bc.Parent = btn
    local index = 1
    for i, o in ipairs(opts) do if o == default then index = i break end end
    btn.MouseButton1Click:Connect(function()
        index = index % #opts + 1
        btn.Text = "◂ " .. opts[index] .. " ▸"
        if cb then pcall(cb, opts[index]) end
    end)
end

-- ============================================================================
-- TABS + CONTENT
-- ============================================================================
makeTab("Aim"); makeTab("Silent"); makeTab("ESP")
makeTab("Move"); makeTab("Skin"); makeTab("Cfg")

local aimTab = Tabs["Aim"]
section(aimTab, "AIMBOT")
toggle(aimTab, "Enable Aimbot", false, function(v) S.Aimbot = v end)
dropdown(aimTab, "Aim Part", {"Head","HumanoidRootPart","UpperTorso","Torso"},
    "Head", function(v) S.AimPart = v end)
slider(aimTab, "FOV", 20, 500, 120, function(v) S.FOV = v end)
slider(aimTab, "Smoothness", 1, 100, 20, function(v) S.Smoothness = v/100 end)
slider(aimTab, "Prediction", 0, 100, 15, function(v) S.Prediction = v/100 end)
section(aimTab, "CHECKS")
toggle(aimTab, "Team Check", true, function(v) S.TeamCheck = v end)
toggle(aimTab, "Visible Check", false, function(v) S.VisibleCheck = v end)
paragraph(aimTab, IS_MOBILE
    and "Mobile: aim origin is screen center. Enable max aim assist in Rivals settings too."
    or  "PC: aim measures from cursor.", 40)

local silentTab = Tabs["Silent"]
section(silentTab, "SILENT AIM")
if not HAS_META then
    paragraph(silentTab,
        "Silent aim needs getrawmetatable and setreadonly. This executor "
        .. "lacks them, so silent aim is unavailable. Aimbot still works.", 55)
else
    toggle(silentTab, "Enable Silent Aim", false, function(v)
        S.SilentAim = v
        if v then setupSilentAim() end
    end)
    dropdown(silentTab, "Target Part", {"Head","HumanoidRootPart","UpperTorso","Torso"},
        "Head", function(v) S.SilentPart = v end)
    slider(silentTab, "Silent FOV", 20, 600, 180, function(v) S.SilentFOV = v end)
    toggle(silentTab, "Team Check", true, function(v) S.SilentTeamCheck = v end)
    paragraph(silentTab,
        "Silent aim redirects shots at the closest enemy to screen center "
        .. "without moving your camera. Centered on both PC and mobile.", 45)
end

local espTab = Tabs["ESP"]
section(espTab, "ESP")
if not HAS_DRAWING then
    paragraph(espTab,
        "ESP needs the Drawing API. This executor doesn't expose it, so "
        .. "ESP is unavailable. Aimbot and movement still work.", 55)
else
    toggle(espTab, "Enable ESP", false, function(v)
        S.ESPEnabled = v
        if not v then
            for plr in pairs(S.Drawings) do destroyESP(plr) end
        end
    end)
    toggle(espTab, "Box", false, function(v)
        S.ESPBox = v
        for plr in pairs(S.Drawings) do destroyESP(plr) end
    end)
    toggle(espTab, "Name", false, function(v)
        S.ESPName = v
        for plr in pairs(S.Drawings) do destroyESP(plr) end
    end)
    toggle(espTab, "Health", false, function(v)
        S.ESPHealth = v
        for plr in pairs(S.Drawings) do destroyESP(plr) end
    end)
    toggle(espTab, "Distance", false, function(v)
        S.ESPDistance = v
        for plr in pairs(S.Drawings) do destroyESP(plr) end
    end)
    toggle(espTab, "Tracer", false, function(v)
        S.ESPTracer = v
        for plr in pairs(S.Drawings) do destroyESP(plr) end
    end)
    toggle(espTab, "Team Check", true, function(v) S.ESPTeamCheck = v end)
    slider(espTab, "Max Distance", 50, 2000, 600, function(v) S.ESPMaxDist = v end)
end

local moveTab = Tabs["Move"]
section(moveTab, "GROUND")
slider(moveTab, "WalkSpeed", 16, 150, 16, function(v) S.WalkSpeed = v end)
slider(moveTab, "JumpPower", 50, 150, 50, function(v) S.JumpPower = v end)
toggle(moveTab, "Infinite Jump", false, function(v) S.InfJump = v end)
section(moveTab, "AIR")
toggle(moveTab, "Fly", false, function(v) S.Fly = v end)
slider(moveTab, "Fly Speed", 10, 200, 60, function(v) S.FlySpeed = v end)
toggle(moveTab, "Noclip", false, function(v) S.Noclip = v end)
section(moveTab, "CAMERA")
slider(moveTab, "Camera FOV", 60, 120, 90, function(v)
    S.CamFOV = v
    if Camera then Camera.FieldOfView = v end
end)

local skinTab = Tabs["Skin"]
section(skinTab, "COSMETICS")
toggle(skinTab, "Unlock All Skins (local)", false, function(v)
    S.UnlockSkins = v
end)
paragraph(skinTab,
    "Local skin unlocks only change what you see. They don't grant weapons "
    .. "or keys. Rivals cosmetics are client-side for the most part, so this "
    .. "may show locked skins on your screen without spending keys.", 60)

local cfgTab = Tabs["Cfg"]
section(cfgTab, "INTERFACE")
button(cfgTab, "Hide UI", function() Gui.Enabled = false end)
section(cfgTab, "DANGER")
button(cfgTab, "Panic — Disable Everything", function()
    S.Aimbot = false
    S.SilentAim = false
    S.ESPEnabled = false
    S.Fly = false
    S.Noclip = false
    for plr in pairs(S.Drawings) do destroyESP(plr) end
    notify("Panic", "All features disabled.")
end)
button(cfgTab, "Unload", function()
    S.Unloaded = true
    if S.FlyBV then S.FlyBV:Destroy() end
    if S.FlyBG then S.FlyBG:Destroy() end
    for plr in pairs(S.Drawings) do destroyESP(plr) end
    Gui:Destroy()
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    notify("LaxissTM", "Unloaded.")
end)
section(cfgTab, "CAPABILITIES")
paragraph(cfgTab, string.format(
    "Drawing: %s\nMeta hooks: %s\nMobile: %s\nRivals bans cheaters permanently.",
    tostring(HAS_DRAWING), tostring(HAS_META), tostring(IS_MOBILE)), 70)

selectTab("Aim")

-- ============================================================================
-- FOV CIRCLE
-- ============================================================================
local fovCircle = nil
if HAS_DRAWING then
    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1.5
        fovCircle.NumSides = 48
        fovCircle.Filled = false
        fovCircle.Transparency = 0.55
        fovCircle.Color = Theme.Accent
    end)
end

local function updateFOV()
    if not fovCircle then return end
    local show = S.Aimbot or S.SilentAim
    fovCircle.Visible = show
    if not show then return end
    if S.SilentAim then
        fovCircle.Position = ViewportCenter
        fovCircle.Radius = S.SilentFOV
    elseif IS_MOBILE then
        fovCircle.Position = ViewportCenter
        fovCircle.Radius = S.FOV
    else
        fovCircle.Position = UserInputService:GetMouseLocation()
        fovCircle.Radius = S.FOV
    end
end

-- ============================================================================
-- TARGETING
-- ============================================================================
local function getMouseTarget()
    local origin = IS_MOBILE and ViewportCenter or UserInputService:GetMouseLocation()
    local best, bestDist = nil, S.FOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and alive(plr) and teamSafe(plr, S.TeamCheck) then
            local part = plr.Character:FindFirstChild(S.AimPart)
            if part then
                local sp, on = worldToScreen(part.Position)
                if on then
                    local d = (sp - origin).Magnitude
                    if d < bestDist then
                        if S.VisibleCheck then
                            local ray = Ray.new(Camera.CFrame.Position,
                                (part.Position - Camera.CFrame.Position).Unit * 500)
                            local hit = Workspace:FindPartOnRayWithIgnoreList(ray,
                                {LP.Character, Camera})
                            if hit and not hit:IsDescendantOf(plr.Character) then
                                goto cont
                            end
                        end
                        best, bestDist = plr, d
                    end
                end
            end
        end
        ::cont::
    end
    return best
end

local function getSilentTarget()
    local best, bestDist = nil, S.SilentFOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if alive(plr) and teamSafe(plr, S.SilentTeamCheck) then
            local part = plr.Character:FindFirstChild(S.SilentPart)
            if part then
                local sp, on = worldToScreen(part.Position)
                if on then
                    local d = (sp - ViewportCenter).Magnitude
                    if d < bestDist then best, bestDist = plr, d end
                end
            end
        end
    end
    return best
end

local function predict(plr, part, mult)
    local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not root then return part.Position end
    return part.Position + (root.AssemblyLinearVelocity * mult)
end

-- ============================================================================
-- AIMBOT LOOP
-- ============================================================================
task.spawn(function()
    while task.wait() do
        if S.Unloaded then break end
        updateFOV()
        if S.Aimbot then
            local target = getMouseTarget()
            if target and target.Character then
                local part = target.Character:FindFirstChild(S.AimPart)
                if part then
                    local pos = predict(target, part, S.Prediction)
                    local goal = CFrame.new(Camera.CFrame.Position, pos)
                    Camera.CFrame = Camera.CFrame:Lerp(goal, S.Smoothness)
                end
            end
        end
    end
end)

-- ============================================================================
-- SILENT AIM
-- ============================================================================
function setupSilentAim()
    if S.SilentHooked or not HAS_META then return end
    pcall(function()
        local mt = getrawmetatable(game)
        if not mt then return end
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            if not checkcaller() and S.SilentAim then
                local method = getnamecallmethod()
                if method == "FindPartOnRayWithIgnoreList" or method == "Raycast" then
                    local target = getSilentTarget()
                    if target then
                        local part = target.Character
                            and target.Character:FindFirstChild(S.SilentPart)
                        if part then
                            local args = {...}
                            local pos = predict(target, part, S.Prediction)
                            local origin = Camera.CFrame.Position
                            args[1] = Ray.new(origin, (pos - origin).Unit * 1000)
                            return old(self, unpack(args))
                        end
                    end
                end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
        S.SilentHooked = true
    end)
end

-- ============================================================================
-- ESP
-- ============================================================================
function destroyESP(plr)
    local e = S.Drawings[plr]
    if e then
        for _, obj in pairs(e) do pcall(function() obj:Remove() end) end
        S.Drawings[plr] = nil
    end
end

local function ensureESP(plr)
    if not HAS_DRAWING or S.Drawings[plr] then return end
    local e = {}
    if S.ESPBox then
        e.Box = {}
        for i = 1, 4 do
            local l = Drawing.new("Line")
            l.Thickness = 1
            l.Color = Theme.Accent
            e.Box[i] = l
        end
    end
    if S.ESPName then
        e.Name = Drawing.new("Text")
        e.Name.Size = 13
        e.Name.Center = true
        e.Name.Outline = true
        e.Name.Color = Color3.new(1,1,1)
    end
    if S.ESPHealth then
        e.Health = Drawing.new("Text")
        e.Health.Size = 12
        e.Health.Center = true
        e.Health.Outline = true
        e.Health.Color = Color3.fromRGB(90,255,140)
    end
    if S.ESPDistance then
        e.Dist = Drawing.new("Text")
        e.Dist.Size = 11
        e.Dist.Center = true
        e.Dist.Outline = true
        e.Dist.Color = Color3.fromRGB(200,200,210)
    end
    if S.ESPTracer then
        e.Tracer = Drawing.new("Line")
        e.Tracer.Thickness = 1
        e.Tracer.Color = Color3.fromRGB(255,90,90)
    end
    S.Drawings[plr] = e
end

local function updateESP()
    if not S.ESPEnabled then
        for _, e in pairs(S.Drawings) do
            for _, obj in pairs(e) do pcall(function() obj.Visible = false end) end
        end
        return
    end
    local myPos = Camera.CFrame.Position
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then goto skip end
        if not alive(plr) or not teamSafe(plr, S.ESPTeamCheck) then
            if S.Drawings[plr] then
                for _, obj in pairs(S.Drawings[plr]) do
                    pcall(function() obj.Visible = false end)
                end
            end
            goto skip
        end
        local root = plr.Character:FindFirstChild("HumanoidRootPart")
        local head = plr.Character:FindFirstChild("Head")
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        if not (root and head and hum) then goto skip end
        local dist = (root.Position - myPos).Magnitude
        if dist > S.ESPMaxDist then
            if S.Drawings[plr] then
                for _, obj in pairs(S.Drawings[plr]) do
                    pcall(function() obj.Visible = false end)
                end
            end
            goto skip
        end
        ensureESP(plr)
        local e = S.Drawings[plr]
        if not e then goto skip end

        if e.Box then
            local top, ton = worldToScreen(head.Position + Vector3.new(0,0.5,0))
            local bot, bon = worldToScreen(root.Position - Vector3.new(0,3,0))
            if ton and bon then
                local h = math.abs(bot.Y - top.Y)
                local w = h * 0.55
                local l = top.X - w/2
                local r = top.X + w/2
                local c = {
                    Vector2.new(l,top.Y), Vector2.new(r,top.Y),
                    Vector2.new(r,bot.Y), Vector2.new(l,bot.Y),
                }
                for i = 1, 4 do
                    if e.Box[i] then
                        e.Box[i].From = c[i]
                        e.Box[i].To = c[(i%4)+1]
                        e.Box[i].Visible = true
                    end
                end
                if e.Name then
                    e.Name.Text = plr.Name
                    e.Name.Position = Vector2.new(top.X, top.Y - 16)
                    e.Name.Visible = true
                end
                if e.Health then
                    e.Health.Text = math.floor(hum.Health).." HP"
                    e.Health.Position = Vector2.new(top.X, bot.Y + 2)
                    e.Health.Visible = true
                end
                if e.Dist then
                    e.Dist.Text = math.floor(dist).."m"
                    e.Dist.Position = Vector2.new(top.X, bot.Y + 16)
                    e.Dist.Visible = true
                end
            else
                if e.Box then for _, l in ipairs(e.Box) do l.Visible = false end end
                if e.Name then e.Name.Visible = false end
                if e.Health then e.Health.Visible = false end
                if e.Dist then e.Dist.Visible = false end
            end
        end
        if e.Tracer then
            local sp, on = worldToScreen(root.Position)
            if on then
                e.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                e.Tracer.To = sp
                e.Tracer.Visible = true
            else
                e.Tracer.Visible = false
            end
        end
        ::skip::
    end
end

task.spawn(function()
    while task.wait(0.12) do
        if S.Unloaded then break end
        updateESP()
    end
end)

-- ============================================================================
-- MOVEMENT
-- ============================================================================
UserInputService.JumpRequest:Connect(function()
    if S.InfJump then
        local h = getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Heartbeat:Connect(function()
    if S.Unloaded then return end
    local c = getChar()
    local hr = c and c:FindFirstChild("HumanoidRootPart")
    local h = getHum()
    if h then
        h.WalkSpeed = S.WalkSpeed
        h.JumpPower = S.JumpPower
        h.UseJumpPower = true
    end
    if S.Fly and hr then
        if not S.FlyBV or S.FlyBV.Parent ~= hr then
            if S.FlyBV then S.FlyBV:Destroy() end
            if S.FlyBG then S.FlyBG:Destroy() end
            S.FlyBV = Instance.new("BodyVelocity", hr)
            S.FlyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
            S.FlyBG = Instance.new("BodyGyro", hr)
            S.FlyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
            S.FlyBG.P = 3000
            S.FlyBG.D = 200
        end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then dir = dir.Unit end
        S.FlyBV.Velocity = dir * S.FlySpeed
        S.FlyBG.CFrame = Camera.CFrame
    elseif S.FlyBV then
        S.FlyBV:Destroy(); S.FlyBV = nil
        if S.FlyBG then S.FlyBG:Destroy(); S.FlyBG = nil end
    end
    if S.Noclip and c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end
end)

-- ============================================================================
-- WORLD
-- ============================================================================
local function setFullBright(on)
    if on then
        if not S.WorldRestore.B then
            S.WorldRestore.B = Lighting.Brightness
            S.WorldRestore.C = Lighting.ClockTime
        end
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
    elseif S.WorldRestore.B then
        Lighting.Brightness = S.WorldRestore.B
        Lighting.ClockTime = S.WorldRestore.C
        S.WorldRestore.B = nil
    end
end

-- ============================================================================
-- STATUS
-- ============================================================================
task.spawn(function()
    while task.wait(0.5) do
        if S.Unloaded then break end
        statusLabel.Text = string.format(
            "%s  ·  Draw:%s  Meta:%s  Mobile:%s",
            activeTab or "—",
            HAS_DRAWING and "✓" or "×",
            HAS_META and "✓" or "×",
            IS_MOBILE and "✓" or "×"
        )
    end
end)

-- ============================================================================
-- BOOT
-- ============================================================================
notify("LaxissTM Rivals",
    "Loaded. Drawing=" .. tostring(HAS_DRAWING)
    .. " Meta=" .. tostring(HAS_META)
    .. " Mobile=" .. tostring(IS_MOBILE), 5)

print("[LaxissTM Rivals] loaded.")
print("  Drawing:", HAS_DRAWING, " Meta:", HAS_META, " Mobile:", IS_MOBILE)
print("  RIVALS BANS CHEATERS PERMANENTLY. ALT ACCOUNTS ONLY.")