-- ============================================================================
-- NOVA UI v3.3 — SAFE MODE EDITION  [FIXED by Nova Fix Patch]
-- FIX LIST:
--   [FIX 1] AddDropdown sekarang punya method Refresh(newOptions)
--   [FIX 2] Select Player auto-refresh saat player join/leave
--   [FIX 3] Tombol Refresh Player List manual ditambahkan
--   [FIX 4] Validasi targetPlayer.Parent sebelum teleport
--   [FIX 5] Spectate otomatis update saat target player keluar
--   [FIX 6] Dropdown aktif menutup saat dropdown lain dibuka
-- ============================================================================

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local Stats            = game:GetService("Stats")
local Lighting         = game:GetService("Lighting")
local TeleportService  = game:GetService("TeleportService")
local VirtualInput     = game:GetService("VirtualInputManager")
local VirtualUser      = game:GetService("VirtualUser")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()
local IsMobile    = UserInputService.TouchEnabled

local ParentTarget = CoreGui
if not pcall(function() local _ = CoreGui.Name end) then
    ParentTarget = LocalPlayer:WaitForChild("PlayerGui")
end
if ParentTarget:FindFirstChild("NovaUILibrary") then
    ParentTarget:FindFirstChild("NovaUILibrary"):Destroy()
end

local hasHookMeta   = type(hookmetamethod) == "function"
local hasFireTouch  = type(firetouchinterest) == "function"
local hasFirePrompt = type(fireproximityprompt) == "function"
local hasDrawing    = type(Drawing) == "table"
local hasWriteFile  = type(writefile) == "function"
local hasReadFile   = type(readfile) == "function"
local hasIsFile     = type(isfile) == "function"
local hasHttpGet    = type(game.HttpGet) == "function"

local function Safe(name, fn)
    local ok, err = pcall(fn)
    if not ok then warn("[Nova UI] Fitur '"..name.."' error: "..tostring(err)) end
end

--------------------------------------------------------------------------------
-- THEME
--------------------------------------------------------------------------------
local Library = {
    Theme = {
        Background=Color3.fromRGB(13,13,19), Background2=Color3.fromRGB(18,18,26),
        Header1=Color3.fromRGB(24,24,34),   Header2=Color3.fromRGB(16,16,23),
        Sidebar=Color3.fromRGB(16,16,23),   Container=Color3.fromRGB(23,23,33),
        Element=Color3.fromRGB(31,31,44),   ElementHover=Color3.fromRGB(40,40,57),
        Accent=Color3.fromRGB(96,118,255),  Accent2=Color3.fromRGB(168,96,255),
        TextPrimary=Color3.fromRGB(244,244,250), TextSecondary=Color3.fromRGB(128,128,150),
        Border=Color3.fromRGB(38,38,54),    Success=Color3.fromRGB(52,211,153),
        Warning=Color3.fromRGB(251,191,36), Danger=Color3.fromRGB(248,113,113),
    },
    Name="NOVA HUB PRO", Version="v3.3",
    ToggleKey=Enum.KeyCode.RightControl,
    Watermark=true, Notifications=true,
    Tabs={}, ConfigData={}, Connections={}, Themeables={}, Registry={},
}
local function AddConn(c) table.insert(Library.Connections, c); return c end

local Utils = {}
function Utils.Create(cn, props, children)
    local i = Instance.new(cn)
    for k, v in pairs(props or {}) do pcall(function() i[k] = v end) end
    for _, c in ipairs(children or {}) do c.Parent = i end
    return i
end
function Utils.Tween(inst, t, props, style, dir)
    local info = TweenInfo.new(t or 0.25, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    local ok, tw = pcall(function() return TweenService:Create(inst, info, props) end)
    if ok and tw then tw:Play() return tw end
end
function Utils.Spring(inst, t, props) return Utils.Tween(inst, t or 0.35, props, Enum.EasingStyle.Back) end
function Utils.Draggable(go, handle)
    handle = handle or go
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = go.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    AddConn(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local d = input.Position - dragStart
            go.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
end
function Utils.Gradient(c1, c2, rot)
    return Utils.Create("UIGradient", { Color = ColorSequence.new{ColorSequenceKeypoint.new(0,c1), ColorSequenceKeypoint.new(1,c2)}, Rotation = rot or 90 })
end
local TH = Library.Theme

-- [FIX 6] Global tracker untuk menutup dropdown lain saat satu dibuka
local ActiveDropdownClose = nil

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------
local State = {
    Aimbot=false, AimbotSmooth=3, AimbotFOV=150, AimbotTeam=false, AimbotVisible=false,
    AimbotPrediction=false, AimbotBone="Head",
    SilentAim=false, SilentBone="Head",
    Triggerbot=false, TriggerDelay=20, TriggerFOV=10,
    MagicBullet=false, AutoClicker=false, AutoClickerCPS=15,
    HitboxExpand=false, HitboxSize=5, NoRecoil=false,
    BoxESP=false, NameESP=false, DistESP=false, HealthBarESP=false,
    TracerESP=false, TracerOrigin="Bottom", SkeletonESP=false, HighlightESP=false,
    ItemESP=false, VehicleESP=false, NPCESP=false,
    OffscreenArrows=false, Radar=false, RadarSize=170, FOVCircle=false,
    Crosshair=false, CrosshairStyle="Cross", ChinaHat=false,
    Fly=false, FlySpeed=50,
    SpeedHack=false, WalkSpeed=100, JumpMod=false, JumpPower=120, InfJump=false,
    Noclip=false, VehicleNoclip=false, Spider=false, BHop=false, AutoJump=false,
    LongJump=false, Airwalk=false, Wallhop=false, Dash=false, DashKey=Enum.KeyCode.Q,
    FreezePos=false, Gravity=196, NoFall=false,
    Godmode=false, AntiVoid=false, AntiRagdoll=false, AntiStun=false, AntiFling=false,
    InfStamina=false, FakeLag=false, Spinbot=false, SpinbotSpeed=50,
    Headless=false, Korblox=false,
    Spectate=false, SpectateTarget=nil,
    Fullbright=false, NoFog=false, XRay=false, TimeOfDay=14,
    Weather="Clear", RemoveTextures=false,
    FPSBooster=false, AntiAFK=true, AutoCollect=false, InstantInteract=false,
    ChatSpy=false, AdminAlert=true, ChatSpam=false, ChatSpamMsg="Nova Hub on top!",
    ESPColor=Color3.fromRGB(96,118,255), TracerColor=Color3.fromRGB(255,80,80),
    WatermarkPos={X=14, Y=14},
    _SilentTarget=nil, _HookInstalled=false,
}

--------------------------------------------------------------------------------
-- SCREEN GUI
--------------------------------------------------------------------------------
local ScreenGui = Utils.Create("ScreenGui", {
    Name="NovaUILibrary", Parent=ParentTarget, ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=999, IgnoreGuiInset=true,
})

--------------------------------------------------------------------------------
-- NOTIFICATIONS
--------------------------------------------------------------------------------
local NotifHolder = Utils.Create("Frame", {
    Parent=ScreenGui, AnchorPoint=Vector2.new(1,0), Size=UDim2.new(0,300,1,-20),
    Position=UDim2.new(1,-12,0,12), BackgroundTransparency=1, ClipsDescendants=true, ZIndex=200,
}, {
    Utils.Create("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,8) }),
    Utils.Create("UIPadding", { PaddingTop=UDim.new(0,4) }),
})

function Library.Notify(title, msg, dur, nType)
    if not Library.Notifications then return end
    dur, nType = dur or 4, nType or "Info"
    local accent = TH.Accent
    if nType == "Success" then accent = TH.Success
    elseif nType == "Warning" then accent = TH.Warning
    elseif nType == "Danger" then accent = TH.Danger end
    local dismissed = false
    local Card = Utils.Create("Frame", {
        Parent=NotifHolder, Size=UDim2.new(1,0,0,0), BackgroundColor3=TH.Background2,
        BorderSizePixel=0, ClipsDescendants=true,
    }, {
        Utils.Create("UICorner", { CornerRadius=UDim.new(0,10) }),
        Utils.Create("UIStroke", { Color=TH.Border, Thickness=1, Transparency=0.3 }),
        Utils.Create("Frame", { Size=UDim2.new(0,4,1,0), BackgroundColor3=accent, BorderSizePixel=0 },
            { Utils.Create("UICorner", { CornerRadius=UDim.new(0,2) }) }),
        Utils.Create("TextLabel", { Position=UDim2.new(0,14,0,8), Size=UDim2.new(1,-24,0,16),
            BackgroundTransparency=1, Text=title, TextColor3=TH.TextPrimary, TextSize=13,
            Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left }),
        Utils.Create("TextLabel", { Position=UDim2.new(0,14,0,25), Size=UDim2.new(1,-24,0,26),
            BackgroundTransparency=1, Text=msg, TextColor3=TH.TextSecondary, TextSize=12,
            Font=Enum.Font.Gotham, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left,
            TextYAlignment=Enum.TextYAlignment.Top }),
        Utils.Create("Frame", { Name="Progress", AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,0,1,0),
            Size=UDim2.new(1,0,0,2), BackgroundColor3=accent, BorderSizePixel=0 }),
        Utils.Create("TextButton", { Name="Dismiss", Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=2 }),
    })
    local function dismiss()
        if dismissed then return end
        dismissed = true
        local tw = Utils.Tween(Card, 0.25, { Size=UDim2.new(1,0,0,0) })
        if tw then tw.Completed:Connect(function() Card:Destroy() end) else Card:Destroy() end
    end
    Card.Dismiss.MouseButton1Click:Connect(dismiss)
    Utils.Tween(Card, 0.3, { Size=UDim2.new(1,0,0,58) })
    local prog = Utils.Tween(Card.Progress, dur, { Size=UDim2.new(0,0,0,2) }, Enum.EasingStyle.Linear)
    if prog then prog.Completed:Connect(dismiss) end
end

--------------------------------------------------------------------------------
-- WATERMARK
--------------------------------------------------------------------------------
local Watermark = Utils.Create("Frame", {
    Parent=ScreenGui,
    Position=UDim2.new(0, State.WatermarkPos.X, 0, State.WatermarkPos.Y),
    Size=UDim2.new(0,320,0,32),
    BackgroundColor3=TH.Background2, BorderSizePixel=0, Visible=Library.Watermark,
    Active=true,
}, {
    Utils.Create("UICorner", { CornerRadius=UDim.new(0,8) }),
    Utils.Create("UIStroke", { Color=TH.Border, Thickness=1, Transparency=0.3 }),
    Utils.Gradient(TH.Header1, TH.Header2, 90),
    Utils.Create("TextLabel", { Name="Grip", Position=UDim2.new(0,8,0,0), Size=UDim2.new(0,14,1,0),
        BackgroundTransparency=1, Text="⋮⋮", TextColor3=TH.TextSecondary, TextSize=12,
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left }),
    Utils.Create("TextLabel", { Name="Tag", Position=UDim2.new(0,24,0,0), Size=UDim2.new(0,52,1,0),
        BackgroundTransparency=1, Text="NOVA", TextColor3=TH.Accent, TextSize=13,
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left }),
    Utils.Create("TextLabel", { Name="Stats", Position=UDim2.new(0,72,0,0), Size=UDim2.new(1,-78,1,0),
        BackgroundTransparency=1, Text="-- | FPS: -- | Ping: --", TextColor3=TH.TextSecondary,
        TextSize=12, Font=Enum.Font.GothamMedium, TextXAlignment=Enum.TextXAlignment.Left }),
})

Utils.Draggable(Watermark, Watermark)
Watermark.MouseEnter:Connect(function() Utils.Tween(Watermark.UIStroke, 0.15, { Color=TH.Accent, Transparency=0.2 }) end)
Watermark.MouseLeave:Connect(function() Utils.Tween(Watermark.UIStroke, 0.15, { Color=TH.Border, Transparency=0.3 }) end)
AddConn(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        pcall(function()
            State.WatermarkPos = { X = Watermark.Position.X.Offset, Y = Watermark.Position.Y.Offset }
            Library.ConfigData["WatermarkPos"] = State.WatermarkPos
        end)
    end
end))

local FrameCount, LastStat = 0, os.clock()
AddConn(RunService.RenderStepped:Connect(function()
    FrameCount += 1
    local now = os.clock()
    if now - LastStat >= 1 and Library.Watermark then
        local fps = math.floor(FrameCount / math.max(now - LastStat, 0.001))
        local ping = 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        FrameCount, LastStat = 0, now
        pcall(function()
            Watermark.Stats.Text = string.format("%s | FPS: %d | Ping: %dms | Act: %d",
                LocalPlayer.Name, fps, ping,
                (State.Aimbot and 1 or 0) + (State.SilentAim and 1 or 0) + (State.Fly and 1 or 0)
                + (State.SpeedHack and 1 or 0) + (State.BoxESP and 1 or 0) + (State.Noclip and 1 or 0))
        end)
    end
end))

--------------------------------------------------------------------------------
-- MAIN WINDOW
--------------------------------------------------------------------------------
local VP = Camera and Camera.ViewportSize or Vector2.new(1280,720)
local WIN_W = math.min(780, VP.X - 40)
local WIN_H = math.min(520, VP.Y - 40)
local WIN_X, WIN_Y = -math.floor(WIN_W/2), -math.floor(WIN_H/2)

local MainWindow = Utils.Create("Frame", {
    Name="MainWindow", Parent=ScreenGui, Size=UDim2.new(0,WIN_W,0,WIN_H),
    Position=UDim2.new(0.5,WIN_X,0.5,WIN_Y), BackgroundColor3=TH.Background,
    BorderSizePixel=0, ClipsDescendants=true,
}, {
    Utils.Create("UICorner", { CornerRadius=UDim.new(0,14) }),
    Utils.Create("UIStroke", { Color=TH.Border, Thickness=1 }),
    Utils.Gradient(TH.Background, Color3.fromRGB(10,10,15), 115),
})

local Header = Utils.Create("Frame", {
    Parent=MainWindow, Size=UDim2.new(1,0,0,54), BackgroundColor3=TH.Header1, BorderSizePixel=0,
}, {
    Utils.Create("UICorner", { CornerRadius=UDim.new(0,14) }),
    Utils.Create("Frame", { AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,0,1,0),
        Size=UDim2.new(1,0,0,14), BackgroundColor3=TH.Header1, BorderSizePixel=0 }),
    Utils.Gradient(TH.Header1, TH.Header2, 90),
})

local Logo = Utils.Create("Frame", {
    Parent=Header, Position=UDim2.new(0,16,0.5,-13), Size=UDim2.new(0,26,0,26),
    BackgroundColor3=TH.Accent, BorderSizePixel=0,
}, {
    Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }),
    Utils.Gradient(TH.Accent, TH.Accent2, 45),
    Utils.Create("TextLabel", { Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text="N", TextColor3=Color3.new(1,1,1), TextSize=14, Font=Enum.Font.GothamBold }),
})

Utils.Create("TextLabel", { Parent=Header, Position=UDim2.new(0,52,0,10), Size=UDim2.new(0,250,0,20),
    BackgroundTransparency=1, Text=Library.Name, TextColor3=TH.TextPrimary, TextSize=15,
    Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left })
Utils.Create("TextLabel", { Parent=Header, Position=UDim2.new(0,52,0,30), Size=UDim2.new(0,250,0,14),
    BackgroundTransparency=1, Text="universal script  •  " .. Library.Version,
    TextColor3=TH.TextSecondary, TextSize=11, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left })

Utils.Draggable(MainWindow, Header)

local function HeaderButton(text, color)
    return Utils.Create("TextButton", { Size=UDim2.new(0,30,0,30), BackgroundColor3=TH.Element,
        Text=text, TextColor3=color or TH.TextSecondary, Font=Enum.Font.GothamBold,
        TextSize=13, AutoButtonColor=false, BorderSizePixel=0 },
        { Utils.Create("UICorner", { CornerRadius=UDim.new(0,8) }) })
end
local MinBtn, CloseBtn = HeaderButton("–"), HeaderButton("✕", TH.Danger)
MinBtn.Parent = Header; MinBtn.Position = UDim2.new(1,-84,0.5,-15)
CloseBtn.Parent = Header; CloseBtn.Position = UDim2.new(1,-46,0.5,-15)
MinBtn.MouseEnter:Connect(function() Utils.Tween(MinBtn, 0.15, { BackgroundColor3=TH.ElementHover, TextColor3=TH.TextPrimary }) end)
MinBtn.MouseLeave:Connect(function() Utils.Tween(MinBtn, 0.15, { BackgroundColor3=TH.Element, TextColor3=TH.TextSecondary }) end)
CloseBtn.MouseEnter:Connect(function() Utils.Tween(CloseBtn, 0.15, { BackgroundColor3=TH.Danger, TextColor3=Color3.new(1,1,1) }) end)
CloseBtn.MouseLeave:Connect(function() Utils.Tween(CloseBtn, 0.15, { BackgroundColor3=TH.Element, TextColor3=TH.TextSecondary }) end)

local function Unload()
    ScreenGui:Destroy()
    for _, c in ipairs(Library.Connections) do pcall(function() c:Disconnect() end) end
end
CloseBtn.MouseButton1Click:Connect(Unload)

--------------------------------------------------------------------------------
-- SIDEBAR
--------------------------------------------------------------------------------
local Sidebar = Utils.Create("Frame", {
    Parent=MainWindow, Position=UDim2.new(0,0,0,54), Size=UDim2.new(0,178,1,-54),
    BackgroundColor3=TH.Sidebar, BorderSizePixel=0,
}, {
    Utils.Create("Frame", { AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,0,0,0),
        Size=UDim2.new(0,1,1,0), BackgroundColor3=TH.Border, BorderSizePixel=0 }),
})
local TabListHolder = Utils.Create("Frame", { Parent=Sidebar, Size=UDim2.new(1,0,1,-46), BackgroundTransparency=1 }, {
    Utils.Create("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4),
        HorizontalAlignment=Enum.HorizontalAlignment.Center }),
    Utils.Create("UIPadding", { PaddingTop=UDim.new(0,12), PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10) }),
})
Utils.Create("TextLabel", { Parent=Sidebar, AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,0,1,-10),
    Size=UDim2.new(1,0,0,16), BackgroundTransparency=1, Text=Library.Name.."  "..Library.Version,
    TextColor3=TH.TextSecondary, TextSize=10, Font=Enum.Font.GothamMedium })

local Content = Utils.Create("Frame", { Parent=MainWindow, Position=UDim2.new(0,178,0,54),
    Size=UDim2.new(1,-178,1,-54), BackgroundTransparency=1, ClipsDescendants=true })

local ActiveTab = nil

local Minimized = false
MinBtn.MouseButton1Click:Connect(function()
    Minimized = not Minimized
    Sidebar.Visible = not Minimized
    Content.Visible = not Minimized
    Utils.Tween(MainWindow, 0.35, { Size = Minimized and UDim2.new(0,WIN_W,0,54) or UDim2.new(0,WIN_W,0,WIN_H) }, Enum.EasingStyle.Quint)
end)

--------------------------------------------------------------------------------
-- TAB BUILDER
--------------------------------------------------------------------------------
function Library.CreateTab(tabName, icon)
    local TabObject = { Name=tabName, Elements={} }
    local label = (icon and (icon.."  ") or "   ") .. tabName

    local TabBtn = Utils.Create("TextButton", {
        Name=tabName.."Btn", Parent=TabListHolder, Size=UDim2.new(1,0,0,36),
        BackgroundColor3=TH.Element, BackgroundTransparency=1, Text=label,
        TextColor3=TH.TextSecondary, Font=Enum.Font.GothamMedium, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, AutoButtonColor=false, BorderSizePixel=0,
    }, {
        Utils.Create("UICorner", { CornerRadius=UDim.new(0,8) }),
        Utils.Create("Frame", { Name="Indicator", AnchorPoint=Vector2.new(0,0.5),
            Position=UDim2.new(0,0,0.5,0), Size=UDim2.new(0,3,0,0), BackgroundColor3=TH.Accent,
            BorderSizePixel=0, BackgroundTransparency=1 },
            { Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }) }),
    })

    local Page = Utils.Create("Frame", { Name=tabName.."Page", Parent=Content,
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Visible=false })

    local SearchBox = Utils.Create("Frame", { Parent=Page, Position=UDim2.new(0,16,0,12),
        Size=UDim2.new(1,-32,0,34), BackgroundColor3=TH.Container, BorderSizePixel=0,
    }, {
        Utils.Create("UICorner", { CornerRadius=UDim.new(0,8) }),
        Utils.Create("UIStroke", { Color=TH.Border, Thickness=1, Transparency=0.4 }),
        Utils.Create("TextLabel", { Position=UDim2.new(0,12,0,0), Size=UDim2.new(0,16,1,0),
            BackgroundTransparency=1, Text="⌕", TextColor3=TH.TextSecondary, TextSize=14,
            Font=Enum.Font.GothamBold }),
    })
    local SearchInput = Utils.Create("TextBox", { Parent=SearchBox, Position=UDim2.new(0,34,0,0),
        Size=UDim2.new(1,-44,1,0), BackgroundTransparency=1, PlaceholderText="Cari fitur...",
        PlaceholderColor3=TH.TextSecondary, Text="", TextColor3=TH.TextPrimary,
        Font=Enum.Font.Gotham, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false })

    local Scroll = Utils.Create("ScrollingFrame", { Parent=Page, Position=UDim2.new(0,16,0,54),
        Size=UDim2.new(1,-32,1,-64), BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=TH.Border, CanvasSize=UDim2.new(0,0,0,0),
    }, { Utils.Create("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,8) }) })

    Scroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0, Scroll.UIListLayout.AbsoluteContentSize.Y + 10)
    end)
    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local q = string.lower(SearchInput.Text)
        for _, el in ipairs(TabObject.Elements) do
            if el.Instance then el.Instance.Visible = (q == "" or string.find(string.lower(el.Name), q, 1, true) ~= nil) end
        end
    end)

    local function Activate()
        if ActiveTab == TabObject then return end
        if ActiveTab then
            ActiveTab.Page.Visible = false
            Utils.Tween(ActiveTab.Btn, 0.2, { BackgroundTransparency=1, TextColor3=TH.TextSecondary })
            Utils.Tween(ActiveTab.Btn.Indicator, 0.2, { Size=UDim2.new(0,3,0,0), BackgroundTransparency=1 })
        end
        ActiveTab = TabObject
        Page.Visible = true
        Utils.Tween(TabBtn, 0.2, { BackgroundTransparency=0, TextColor3=TH.Accent, BackgroundColor3=TH.Element })
        Utils.Spring(TabBtn.Indicator, 0.35, { Size=UDim2.new(0,3,0,16), BackgroundTransparency=0 })
    end
    TabBtn.MouseEnter:Connect(function()
        if ActiveTab ~= TabObject then Utils.Tween(TabBtn, 0.15, { BackgroundTransparency=0.5, TextColor3=TH.TextPrimary }) end
    end)
    TabBtn.MouseLeave:Connect(function()
        if ActiveTab ~= TabObject then Utils.Tween(TabBtn, 0.15, { BackgroundTransparency=1, TextColor3=TH.TextSecondary }) end
    end)
    TabBtn.MouseButton1Click:Connect(Activate)
    TabObject.Page, TabObject.Btn, TabObject.Scroll = Page, TabBtn, Scroll

    if #Library.Tabs == 0 then
        TabObject.Btn.BackgroundTransparency = 0
        TabObject.Btn.TextColor3 = TH.Accent
        TabObject.Btn.BackgroundColor3 = TH.Element
        TabObject.Btn.Indicator.Size = UDim2.new(0,3,0,16)
        TabObject.Btn.Indicator.BackgroundTransparency = 0
        ActiveTab = TabObject; Page.Visible = true
    end
    table.insert(Library.Tabs, TabObject)

    function TabObject.AddSection(title)
        local Holder = Utils.Create("Frame", { Parent=Scroll, Size=UDim2.new(1,0,0,32), BackgroundTransparency=1 })
        local bar = Utils.Create("Frame", { Parent=Holder, AnchorPoint=Vector2.new(0,0.5),
            Position=UDim2.new(0,0,0.5,0), Size=UDim2.new(0,3,0,12),
            BackgroundColor3=TH.Accent, BorderSizePixel=0 },
            { Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }) })
        Utils.Create("TextLabel", { Parent=Holder, Position=UDim2.new(0,12,0,0), Size=UDim2.new(1,-12,1,0),
            BackgroundTransparency=1, Text=string.upper(title), TextColor3=TH.TextSecondary,
            Font=Enum.Font.GothamBold, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left })
        table.insert(TabObject.Elements, { Name=title, Instance=Holder })
        return Holder
    end

    function TabObject.AddButton(text, callback)
        callback = callback or function() end
        local Btn = Utils.Create("TextButton", { Parent=Scroll, Size=UDim2.new(1,0,0,36),
            BackgroundColor3=TH.Container, Text=text, TextColor3=TH.TextPrimary,
            Font=Enum.Font.GothamMedium, TextSize=13, AutoButtonColor=false, BorderSizePixel=0,
        }, {
            Utils.Create("UICorner", { CornerRadius=UDim.new(0,8) }),
            Utils.Create("UIStroke", { Color=TH.Border, Thickness=1, Transparency=0.4 }),
        })
        Btn.MouseEnter:Connect(function() Utils.Tween(Btn, 0.15, { BackgroundColor3=TH.ElementHover }) end)
        Btn.MouseLeave:Connect(function() Utils.Tween(Btn, 0.15, { BackgroundColor3=TH.Container }) end)
        Btn.MouseButton1Click:Connect(function() pcall(callback) end)
        table.insert(TabObject.Elements, { Name=text, Instance=Btn })
        return Btn
    end

    function TabObject.AddToggle(text, default, callback)
        callback = callback or function() end
        local state = default or false
        Library.ConfigData[text] = state
        local Frame = Utils.Create("Frame", { Parent=Scroll, Size=UDim2.new(1,0,0,38),
            BackgroundColor3=TH.Container, BorderSizePixel=0,
        }, {
            Utils.Create("UICorner", { CornerRadius=UDim.new(0,8) }),
            Utils.Create("UIStroke", { Color=TH.Border, Thickness=1, Transparency=0.4 }),
            Utils.Create("TextLabel", { Position=UDim2.new(0,12,0,0), Size=UDim2.new(1,-70,1,0),
                BackgroundTransparency=1, Text=text, TextColor3=TH.TextPrimary,
                Font=Enum.Font.GothamMedium, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd }),
        })
        local Switch = Utils.Create("Frame", { Parent=Frame, AnchorPoint=Vector2.new(1,0.5),
            Position=UDim2.new(1,-12,0.5,0), Size=UDim2.new(0,40,0,22),
            BackgroundColor3=state and TH.Accent or TH.Element, BorderSizePixel=0,
        }, {
            Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }),
            Utils.Gradient(state and TH.Accent or TH.Element, state and TH.Accent2 or TH.ElementHover, 0),
        })
        local Knob = Utils.Create("Frame", { Parent=Switch, AnchorPoint=Vector2.new(0,0.5),
            Position=state and UDim2.new(1,-20,0.5,0) or UDim2.new(0,3,0.5,0),
            Size=UDim2.new(0,16,0,16), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0,
        }, { Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }) })
        local Click = Utils.Create("TextButton", { Parent=Frame, Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1, Text="" })

        local function Set(newState, silent)
            state = newState and true or false
            Library.ConfigData[text] = state
            Utils.Spring(Switch, 0.3, { BackgroundColor3=state and TH.Accent or TH.Element })
            if Switch.UIGradient then
                Switch.UIGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, state and TH.Accent or TH.Element),
                    ColorSequenceKeypoint.new(1, state and TH.Accent2 or TH.ElementHover),
                }
            end
            Utils.Spring(Knob, 0.3, { Position = state and UDim2.new(1,-20,0.5,0) or UDim2.new(0,3,0.5,0) })
            if not silent then pcall(callback, state) end
        end
        Click.MouseButton1Click:Connect(function() Set(not state) end)
        Library.Registry[text] = { Type="Toggle", Set=function(v) Set(v,true) end, Get=function() return state end }
        table.insert(TabObject.Elements, { Name=text, Instance=Frame })
        return { Frame=Frame, Set=Set, Get=function() return state end }
    end

    function TabObject.AddSlider(text, min, max, default, decimals, callback)
        callback = callback or function() end
        decimals = decimals or 0
        local value = math.clamp(default or min, min, max)
        Library.ConfigData[text] = value
        local Frame = Utils.Create("Frame", { Parent=Scroll, Size=UDim2.new(1,0,0,52),
            BackgroundColor3=TH.Container, BorderSizePixel=0,
        }, {
            Utils.Create("UICorner", { CornerRadius=UDim.new(0,8) }),
            Utils.Create("UIStroke", { Color=TH.Border, Thickness=1, Transparency=0.4 }),
            Utils.Create("TextLabel", { Position=UDim2.new(0,12,0,7), Size=UDim2.new(1,-90,0,18),
                BackgroundTransparency=1, Text=text, TextColor3=TH.TextPrimary,
                Font=Enum.Font.GothamMedium, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left }),
        })
        local ValueLabel = Utils.Create("TextLabel", { Parent=Frame, AnchorPoint=Vector2.new(1,0),
            Position=UDim2.new(1,-12,0,7), Size=UDim2.new(0,70,0,18), BackgroundTransparency=1,
            Text=tostring(value), TextColor3=TH.Accent, Font=Enum.Font.GothamBold,
            TextSize=12, TextXAlignment=Enum.TextXAlignment.Right })
        local Track = Utils.Create("Frame", { Parent=Frame, Position=UDim2.new(0,12,0,34),
            Size=UDim2.new(1,-24,0,5), BackgroundColor3=TH.Element, BorderSizePixel=0,
        }, { Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }) })
        local Fill = Utils.Create("Frame", { Parent=Track, Size=UDim2.new((value-min)/(max-min),0,1,0),
            BackgroundColor3=TH.Accent, BorderSizePixel=0,
        }, { Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }) })
        local Knob = Utils.Create("Frame", { Parent=Track, AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.new((value-min)/(max-min),0,0.5,0), Size=UDim2.new(0,13,0,13),
            BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0, ZIndex=2,
        }, {
            Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }),
            Utils.Create("UIStroke", { Color=TH.Accent, Thickness=2 }),
        })
        local Hitbox = Utils.Create("TextButton", { Parent=Frame, Position=UDim2.new(0,0,0,26),
            Size=UDim2.new(1,0,0,26), BackgroundTransparency=1, Text="" })
        local sliding = false
        local function Set(newValue, silent)
            value = math.clamp(newValue, min, max)
            if decimals == 0 then value = math.floor(value + 0.5)
            else value = tonumber(string.format("%."..decimals.."f", value)) or value end
            Library.ConfigData[text] = value
            ValueLabel.Text = tostring(value)
            local pct = (value-min)/(max-min)
            Utils.Tween(Fill, 0.08, { Size=UDim2.new(pct,0,1,0) })
            Utils.Tween(Knob, 0.08, { Position=UDim2.new(pct,0,0.5,0) })
            if not silent then pcall(callback, value) end
        end
        local function UpdateFromInput(pos)
            local pct = math.clamp((pos.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
            Set(min + (max-min) * pct)
        end
        Hitbox.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                Utils.Spring(Knob, 0.2, { Size=UDim2.new(0,16,0,16) })
                UpdateFromInput(input.Position)
            end
        end)
        AddConn(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if sliding then sliding = false; Utils.Spring(Knob, 0.2, { Size=UDim2.new(0,13,0,13) }) end
            end
        end))
        AddConn(UserInputService.InputChanged:Connect(function(input)
            if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                UpdateFromInput(input.Position)
            end
        end))
        Library.Registry[text] = { Type="Slider", Set=function(v) Set(tonumber(v) or min, true) end, Get=function() return value end }
        table.insert(TabObject.Elements, { Name=text, Instance=Frame })
        return { Frame=Frame, Set=Set, Get=function() return value end }
    end

    -- =========================================================================
    -- [FIX 1] AddDropdown — tambah method Refresh(newOptions)
    -- =========================================================================
    function TabObject.AddDropdown(text, options, default, callback)
        callback = callback or function() end
        options = options or {}
        local selected = default or options[1] or "None"
        Library.ConfigData[text] = selected

        local Frame = Utils.Create("Frame", { Parent=Scroll, Size=UDim2.new(1,0,0,38),
            BackgroundColor3=TH.Container, BorderSizePixel=0, ClipsDescendants=true,
        }, {
            Utils.Create("UICorner", { CornerRadius=UDim.new(0,8) }),
            Utils.Create("UIStroke", { Color=TH.Border, Thickness=1, Transparency=0.4 }),
            Utils.Create("TextLabel", { Position=UDim2.new(0,12,0,0), Size=UDim2.new(1,-160,0,38),
                BackgroundTransparency=1, Text=text, TextColor3=TH.TextPrimary,
                Font=Enum.Font.GothamMedium, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd }),
        })
        local Display = Utils.Create("TextLabel", { Parent=Frame, AnchorPoint=Vector2.new(1,0),
            Position=UDim2.new(1,-36,0,0), Size=UDim2.new(0,130,0,38), BackgroundTransparency=1,
            Text=selected, TextColor3=TH.Accent, Font=Enum.Font.GothamBold, TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Right, TextTruncate=Enum.TextTruncate.AtEnd })
        local Chevron = Utils.Create("TextLabel", { Parent=Frame, AnchorPoint=Vector2.new(1,0),
            Position=UDim2.new(1,-14,0,0), Size=UDim2.new(0,16,0,38), BackgroundTransparency=1,
            Text="▾", TextColor3=TH.TextSecondary, TextSize=13, Font=Enum.Font.GothamBold })

        local listH = math.min(#options, 5) * 28
        local ListScroll = Utils.Create("ScrollingFrame", { Parent=Frame, Position=UDim2.new(0,8,0,42),
            Size=UDim2.new(1,-16,0,listH), BackgroundTransparency=1, BorderSizePixel=0,
            ScrollBarThickness=2, ScrollBarImageColor3=TH.Border,
            CanvasSize=UDim2.new(0,0,0,#options*28), Visible=false,
        }, { Utils.Create("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,2) }) })

        local open = false
        -- [FIX 6] Tutup dropdown ini dan update global tracker
        local function SetOpen(s)
            -- Tutup dropdown lain yang sedang terbuka
            if s and ActiveDropdownClose and ActiveDropdownClose ~= SetOpen then
                ActiveDropdownClose(false)
            end
            open = s
            if s then ActiveDropdownClose = SetOpen end
            ListScroll.Visible = true
            Utils.Tween(Frame, 0.25, { Size = open and UDim2.new(1,0,0,46+listH) or UDim2.new(1,0,0,38) }, Enum.EasingStyle.Quint)
            Utils.Tween(Chevron, 0.25, { Rotation = open and 180 or 0 })
            if not open then
                task.delay(0.25, function() if not open then ListScroll.Visible = false end end)
                if ActiveDropdownClose == SetOpen then ActiveDropdownClose = nil end
            end
        end

        local Trigger = Utils.Create("TextButton", { Parent=Frame, Size=UDim2.new(1,0,0,38), BackgroundTransparency=1, Text="" })
        Trigger.MouseButton1Click:Connect(function() SetOpen(not open) end)

        local optionBtns = {}

        -- [FIX 1] Helper: buat satu option button (dipakai juga oleh Refresh)
        local function MakeOptionBtn(opt)
            local OptBtn = Utils.Create("TextButton", { Parent=ListScroll, Size=UDim2.new(1,0,0,26),
                BackgroundColor3=TH.Element, BackgroundTransparency=1, Text="", AutoButtonColor=false, BorderSizePixel=0,
            }, {
                Utils.Create("UICorner", { CornerRadius=UDim.new(0,6) }),
                Utils.Create("TextLabel", { Name="OptionLabel", Position=UDim2.new(0,10,0,0), Size=UDim2.new(1,-30,1,0),
                    BackgroundTransparency=1, Text=opt, TextColor3=TH.TextSecondary,
                    Font=Enum.Font.Gotham, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left,
                    TextTruncate=Enum.TextTruncate.AtEnd }),
                Utils.Create("TextLabel", { Name="Check", AnchorPoint=Vector2.new(1,0),
                    Position=UDim2.new(1,-8,0,0), Size=UDim2.new(0,16,1,0), BackgroundTransparency=1,
                    Text="✓", TextColor3=TH.Accent, TextSize=12, Font=Enum.Font.GothamBold, Visible=false }),
            })
            local lbl = OptBtn:FindFirstChild("OptionLabel")
            local chk = OptBtn:FindFirstChild("Check")
            OptBtn.MouseEnter:Connect(function() Utils.Tween(OptBtn, 0.12, { BackgroundTransparency=0 }) end)
            OptBtn.MouseLeave:Connect(function() Utils.Tween(OptBtn, 0.12, { BackgroundTransparency=1 }) end)
            OptBtn.MouseButton1Click:Connect(function()
                selected = opt
                Library.ConfigData[text] = selected
                Display.Text = selected
                for _, data in ipairs(optionBtns) do
                    if data.Check then data.Check.Visible = false end
                    if data.Label then data.Label.TextColor3 = TH.TextSecondary end
                end
                if chk then chk.Visible = true end
                if lbl then lbl.TextColor3 = TH.TextPrimary end
                SetOpen(false)
                pcall(callback, selected)
            end)
            return { Btn=OptBtn, Label=lbl, Check=chk, Value=opt }
        end

        for _, opt in ipairs(options) do
            optionBtns[#optionBtns+1] = MakeOptionBtn(opt)
        end

        -- Tandai default selected
        for _, d in ipairs(optionBtns) do
            if d.Value == selected then
                if d.Check then d.Check.Visible = true end
                if d.Label then d.Label.TextColor3 = TH.TextPrimary end
            end
        end

        local function Set(value, silent)
            selected = value; Library.ConfigData[text] = selected; Display.Text = tostring(selected)
            for _, d in ipairs(optionBtns) do
                local m = d.Value == selected
                if d.Check then d.Check.Visible = m end
                if d.Label then d.Label.TextColor3 = m and TH.TextPrimary or TH.TextSecondary end
            end
            if not silent then pcall(callback, selected) end
        end

        -- [FIX 1] Method Refresh: ganti opsi dropdown secara dinamis
        local function Refresh(newOptions)
            newOptions = newOptions or {}
            -- Tutup dulu kalau sedang terbuka
            if open then SetOpen(false) end
            -- Hapus semua button lama
            for _, d in ipairs(optionBtns) do
                if d.Btn and d.Btn.Parent then d.Btn:Destroy() end
            end
            optionBtns = {}
            options = newOptions
            -- Cek apakah selected masih ada di list baru
            local stillValid = false
            for _, opt in ipairs(options) do
                if opt == selected then stillValid = true; break end
            end
            if not stillValid then
                selected = options[1] or "None"
                Display.Text = selected
                Library.ConfigData[text] = selected
            end
            -- Update ukuran list
            listH = math.min(#options, 5) * 28
            ListScroll.Size = UDim2.new(1,-16,0,listH)
            ListScroll.CanvasSize = UDim2.new(0,0,0,#options*28)
            -- Buat ulang button
            for _, opt in ipairs(options) do
                optionBtns[#optionBtns+1] = MakeOptionBtn(opt)
            end
            -- Tandai selected
            for _, d in ipairs(optionBtns) do
                if d.Value == selected then
                    if d.Check then d.Check.Visible = true end
                    if d.Label then d.Label.TextColor3 = TH.TextPrimary end
                end
            end
        end

        Library.Registry[text] = { Type="Dropdown", Set=function(v) Set(tostring(v), true) end, Get=function() return selected end }
        table.insert(TabObject.Elements, { Name=text, Instance=Frame })
        -- [FIX 1] Return sekarang include Refresh
        return { Frame=Frame, Set=Set, Get=function() return selected end, Refresh=Refresh }
    end

    function TabObject.AddKeybind(text, defaultKey, callback)
        callback = callback or function() end
        local currentKey = defaultKey or Enum.KeyCode.E
        Library.ConfigData[text] = currentKey.Name
        local Frame = Utils.Create("Frame", { Parent=Scroll, Size=UDim2.new(1,0,0,38),
            BackgroundColor3=TH.Container, BorderSizePixel=0,
        }, {
            Utils.Create("UICorner", { CornerRadius=UDim.new(0,8) }),
            Utils.Create("UIStroke", { Color=TH.Border, Thickness=1, Transparency=0.4 }),
            Utils.Create("TextLabel", { Position=UDim2.new(0,12,0,0), Size=UDim2.new(1,-120,1,0),
                BackgroundTransparency=1, Text=text, TextColor3=TH.TextPrimary,
                Font=Enum.Font.GothamMedium, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left }),
        })
        local KeyBtn = Utils.Create("TextButton", { Parent=Frame, AnchorPoint=Vector2.new(1,0.5),
            Position=UDim2.new(1,-12,0.5,0), Size=UDim2.new(0,90,0,26), BackgroundColor3=TH.Element,
            Text=currentKey.Name, TextColor3=TH.TextSecondary, Font=Enum.Font.GothamBold,
            TextSize=11, AutoButtonColor=false, BorderSizePixel=0,
        }, { Utils.Create("UICorner", { CornerRadius=UDim.new(0,6) }) })
        local binding = false
        KeyBtn.MouseButton1Click:Connect(function()
            binding = true; KeyBtn.Text = "..."; KeyBtn.TextColor3 = TH.Accent
        end)
        AddConn(UserInputService.InputBegan:Connect(function(input, gp)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if binding then
                if input.KeyCode == Enum.KeyCode.Escape then
                    binding = false; KeyBtn.Text = currentKey.Name; KeyBtn.TextColor3 = TH.TextSecondary; return
                end
                binding = false; currentKey = input.KeyCode
                Library.ConfigData[text] = currentKey.Name
                KeyBtn.Text = currentKey.Name; KeyBtn.TextColor3 = TH.TextPrimary
                pcall(callback, currentKey)
            elseif not gp and input.KeyCode == currentKey then
                pcall(callback, currentKey)
            end
        end))
        local function Set(keyName, silent)
            local key = Enum.KeyCode[tostring(keyName)]; if not key then return end
            currentKey = key; Library.ConfigData[text] = currentKey.Name; KeyBtn.Text = currentKey.Name
            if not silent then pcall(callback, currentKey) end
        end
        Library.Registry[text] = { Type="Keybind", Set=function(v) Set(v,true) end, Get=function() return currentKey.Name end }
        table.insert(TabObject.Elements, { Name=text, Instance=Frame })
        return { Frame=Frame, Set=Set, Get=function() return currentKey end }
    end

    function TabObject.AddColorPicker(text, defaultColor, callback)
        callback = callback or function() end
        local color = defaultColor or TH.Accent
        Library.ConfigData[text] = { math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255) }
        local Frame = Utils.Create("Frame", { Parent=Scroll, Size=UDim2.new(1,0,0,38),
            BackgroundColor3=TH.Container, BorderSizePixel=0, ClipsDescendants=true,
        }, {
            Utils.Create("UICorner", { CornerRadius=UDim.new(0,8) }),
            Utils.Create("UIStroke", { Color=TH.Border, Thickness=1, Transparency=0.4 }),
            Utils.Create("TextLabel", { Position=UDim2.new(0,12,0,0), Size=UDim2.new(1,-70,0,38),
                BackgroundTransparency=1, Text=text, TextColor3=TH.TextPrimary,
                Font=Enum.Font.GothamMedium, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left }),
        })
        local Preview = Utils.Create("TextButton", { Parent=Frame, AnchorPoint=Vector2.new(1,0.5),
            Position=UDim2.new(1,-12,0.5,0), Size=UDim2.new(0,42,0,22), BackgroundColor3=color,
            Text="", AutoButtonColor=false, BorderSizePixel=0,
        }, {
            Utils.Create("UICorner", { CornerRadius=UDim.new(0,6) }),
            Utils.Create("UIStroke", { Color=TH.Border, Thickness=1 }),
        })
        local PANEL_H = 118
        local Panel = Utils.Create("Frame", { Parent=Frame, Position=UDim2.new(0,12,0,44),
            Size=UDim2.new(1,-24,0,PANEL_H), BackgroundTransparency=1, Visible=false })
        local SetColor, channelSliders = nil, {}
        for i, name in ipairs({"R","G","B"}) do
            local row = Utils.Create("Frame", { Parent=Panel, Position=UDim2.new(0,0,0,(i-1)*26),
                Size=UDim2.new(1,0,0,20), BackgroundTransparency=1 })
            Utils.Create("TextLabel", { Parent=row, Size=UDim2.new(0,18,1,0), BackgroundTransparency=1,
                Text=name, TextColor3=TH.TextSecondary, Font=Enum.Font.GothamBold, TextSize=11 })
            local track = Utils.Create("Frame", { Parent=row, Position=UDim2.new(0,24,0.5,-2),
                Size=UDim2.new(1,-78,0,4), BackgroundColor3=TH.Element, BorderSizePixel=0,
            }, { Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }) })
            local fill = Utils.Create("Frame", { Parent=track, Size=UDim2.new(color[name],0,1,0),
                BackgroundColor3=Color3.fromRGB(name=="R" and 255 or 80, name=="G" and 255 or 80, name=="B" and 255 or 80),
                BorderSizePixel=0 }, { Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }) })
            local vl = Utils.Create("TextLabel", { Parent=row, AnchorPoint=Vector2.new(1,0),
                Position=UDim2.new(1,0,0,0), Size=UDim2.new(0,44,1,0), BackgroundTransparency=1,
                Text=tostring(math.floor(color[name]*255)), TextColor3=TH.TextSecondary,
                Font=Enum.Font.GothamBold, TextSize=11, TextXAlignment=Enum.TextXAlignment.Right })
            local dragging = false
            local function apply(x)
                local pct = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local nc = Color3.new(color.R, color.G, color.B)
                if name == "R" then nc = Color3.new(pct, color.G, color.B)
                elseif name == "G" then nc = Color3.new(color.R, pct, color.B)
                else nc = Color3.new(color.R, color.G, pct) end
                if SetColor then SetColor(nc) end
            end
            local hit = Utils.Create("TextButton", { Parent=row, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="" })
            hit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true; apply(input.Position.X)
                end
            end)
            AddConn(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end))
            AddConn(UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    apply(input.Position.X)
                end
            end))
            channelSliders[name] = { Fill=fill, Label=vl }
        end
        local sw = Utils.Create("Frame", { Parent=Panel, Position=UDim2.new(0,0,0,82),
            Size=UDim2.new(1,0,0,24), BackgroundTransparency=1,
        }, { Utils.Create("UIListLayout", { FillDirection=Enum.FillDirection.Horizontal,
            Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder }) })
        for i, pc in ipairs({ Color3.fromRGB(96,118,255), Color3.fromRGB(168,96,255),
            Color3.fromRGB(255,96,122), Color3.fromRGB(52,211,153),
            Color3.fromRGB(251,191,36), Color3.fromRGB(244,244,250) }) do
            local s = Utils.Create("TextButton", { Parent=sw, Size=UDim2.new(0,24,0,24),
                BackgroundColor3=pc, Text="", AutoButtonColor=false, BorderSizePixel=0, LayoutOrder=i,
            }, {
                Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }),
                Utils.Create("UIStroke", { Color=TH.Border, Thickness=1 }),
            })
            s.MouseButton1Click:Connect(function() if SetColor then SetColor(pc) end end)
        end
        local open = false
        Preview.MouseButton1Click:Connect(function()
            open = not open; Panel.Visible = true
            Utils.Tween(Frame, 0.25, { Size = open and UDim2.new(1,0,0,44+PANEL_H+8) or UDim2.new(1,0,0,38) }, Enum.EasingStyle.Quint)
            if not open then task.delay(0.25, function() if not open then Panel.Visible = false end end) end
        end)
        SetColor = function(nc, silent)
            color = nc
            Library.ConfigData[text] = { math.floor(color.R*255+0.5), math.floor(color.G*255+0.5), math.floor(color.B*255+0.5) }
            Preview.BackgroundColor3 = color
            for name, data in pairs(channelSliders) do
                data.Fill.Size = UDim2.new(color[name], 0, 1, 0)
                data.Label.Text = tostring(math.floor(color[name]*255+0.5))
            end
            if not silent then pcall(callback, color) end
        end
        Library.Registry[text] = { Type="ColorPicker",
            Set=function(v) if type(v)=="table" and #v>=3 then SetColor(Color3.fromRGB(v[1],v[2],v[3]), true) end end,
            Get=function() return color end }
        table.insert(TabObject.Elements, { Name=text, Instance=Frame })
        return { Frame=Frame, Set=SetColor, Get=function() return color end }
    end

    return TabObject
end

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------
local function GetHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function GetHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function Notify(...) Library.Notify(...) end

--------------------------------------------------------------------------------
-- LAZY HOOK (dipasang hanya saat Magic Bullet ON)
--------------------------------------------------------------------------------
local function InstallMagicHook()
    if State._HookInstalled then return true end
    if not hasHookMeta then return false end
    local ok = pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            if not oldNamecall then return end
            local method = getnamecallmethod()
            if State.MagicBullet and State._SilentTarget
                and (method == "FireServer" or method == "InvokeServer") then
                local args = {...}
                for i, a in ipairs(args) do
                    if typeof(a) == "CFrame" then
                        args[i] = CFrame.new(Camera.CFrame.Position, State._SilentTarget.Position)
                    end
                end
                return oldNamecall(self, table.unpack(args))
            end
            return oldNamecall(self, ...)
        end)
    end)
    State._HookInstalled = ok
    return ok
end

--------------------------------------------------------------------------------
-- ANTI-AFK
--------------------------------------------------------------------------------
AddConn(LocalPlayer.Idled:Connect(function()
    if State.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end))

--------------------------------------------------------------------------------
-- AIMBOT (safe)
--------------------------------------------------------------------------------
AddConn(RunService.RenderStepped:Connect(function()
    if not State.Aimbot then return end
    Safe("Aimbot", function()
        local cam = Workspace.CurrentCamera; if not cam then return end
        local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
        local closest, closestDist = nil, State.AimbotFOV
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                if State.AimbotTeam and plr.Team and plr.Team == LocalPlayer.Team then continue end
                local target = plr.Character:FindFirstChild(State.AimbotBone) or plr.Character:FindFirstChild("Head")
                if target then
                    if State.AimbotVisible then
                        local params = RaycastParams.new()
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        params.FilterDescendantsInstances = { LocalPlayer.Character }
                        local ray = Workspace:Raycast(cam.CFrame.Position, target.Position - cam.CFrame.Position, params)
                        if ray and not ray.Instance:IsDescendantOf(plr.Character) then continue end
                    end
                    local pos, onScreen = cam:WorldToViewportPoint(target.Position)
                    if onScreen then
                        local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if mag < closestDist then closestDist = mag; closest = { part=target, plr=plr } end
                    end
                end
            end
        end
        if closest then
            local targetPos = closest.part.Position
            if State.AimbotPrediction then
                local hrp = closest.plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then targetPos = targetPos + hrp.AssemblyLinearVelocity * 0.15 end
            end
            local alpha = math.clamp(1 / math.max(State.AimbotSmooth, 1), 0, 1)
            cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, targetPos), alpha)
        end
    end)
end))

--------------------------------------------------------------------------------
-- SILENT AIM target search (safe)
--------------------------------------------------------------------------------
AddConn(RunService.RenderStepped:Connect(function()
    if not State.SilentAim then State._SilentTarget = nil; return end
    Safe("SilentAim", function()
        local cam = Workspace.CurrentCamera; if not cam then return end
        local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
        local closest, closestDist = nil, State.AimbotFOV
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local target = plr.Character:FindFirstChild(State.SilentBone) or plr.Character:FindFirstChild("Head")
                if target then
                    local pos = cam:WorldToViewportPoint(target.Position)
                    local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if mag < closestDist then closestDist = mag; closest = target end
                end
            end
        end
        State._SilentTarget = closest
    end)
end))

--------------------------------------------------------------------------------
-- TRIGGERBOT (safe)
--------------------------------------------------------------------------------
local lastTrigger = 0
AddConn(RunService.Heartbeat:Connect(function()
    if not State.Triggerbot then return end
    if tick() - lastTrigger < State.TriggerDelay/1000 then return end
    Safe("Triggerbot", function()
        local cam = Workspace.CurrentCamera; if not cam then return end
        local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local head = plr.Character:FindFirstChild("Head")
                if head then
                    local pos, onScreen = cam:WorldToViewportPoint(head.Position)
                    if onScreen and (Vector2.new(pos.X, pos.Y) - center).Magnitude < State.TriggerFOV then
                        lastTrigger = tick()
                        VirtualInput:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 1)
                        task.wait(0.03)
                        VirtualInput:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 1)
                        break
                    end
                end
            end
        end
    end)
end))

--------------------------------------------------------------------------------
-- AUTO CLICKER (safe)
--------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(0.05) do
        if State.AutoClicker then
            Safe("AutoClicker", function()
                local cps = math.max(State.AutoClickerCPS, 1)
                for _ = 1, cps do
                    if not State.AutoClicker then break end
                    VirtualInput:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 1)
                    VirtualInput:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 1)
                    task.wait(1/cps)
                end
            end)
        end
    end
end)

--------------------------------------------------------------------------------
-- HITBOX EXPANDER (safe)
--------------------------------------------------------------------------------
local OrigSizes = {}
AddConn(RunService.Heartbeat:Connect(function()
    if State.HitboxExpand then
        Safe("HitboxExpand", function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        if not OrigSizes[hrp] then OrigSizes[hrp] = hrp.Size end
                        hrp.Size = Vector3.new(State.HitboxSize, State.HitboxSize, State.HitboxSize)
                        hrp.CanCollide = false; hrp.Transparency = 0.7
                    end
                end
            end
        end)
    else
        for part, size in pairs(OrigSizes) do
            if part and part.Parent then pcall(function() part.Size = size; part.Transparency = 1 end) end
        end
        OrigSizes = {}
    end
end))

--------------------------------------------------------------------------------
-- ESP (safe)
--------------------------------------------------------------------------------
local ESPCache = {}
local function newDraw(t)
    if not hasDrawing then return nil end
    local ok, d = pcall(function() return Drawing.new(t) end)
    return ok and d or nil
end
local function CreateESPSet()
    if not hasDrawing then return nil end
    return {
        box=newDraw("Square"), outline=newDraw("Square"),
        nameTag=newDraw("Text"), distTag=newDraw("Text"),
        hpBar=newDraw("Square"), hpBarBg=newDraw("Square"),
        tracer=newDraw("Line"),
    }
end
local function RemoveESPSet(data)
    if not data then return end
    for _, d in pairs(data) do pcall(function() d:Remove() end) end
end
local function initESPVisual(esp)
    esp.box.Thickness=1; esp.box.Filled=false
    esp.outline.Thickness=3; esp.outline.Filled=false
    esp.nameTag.Size=14; esp.nameTag.Center=true; esp.nameTag.Outline=true
    esp.nameTag.Color=Color3.new(1,1,1); esp.nameTag.Font=2
    esp.distTag.Size=12; esp.distTag.Center=true; esp.distTag.Outline=true
    esp.hpBar.Filled=true; esp.hpBarBg.Filled=true
    esp.tracer.Thickness=1
end

AddConn(RunService.RenderStepped:Connect(function()
    if not hasDrawing then return end
    Safe("ESP", function()
        local cam = Workspace.CurrentCamera; if not cam then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                local head = plr.Character:FindFirstChild("Head")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hrp and head and hum then
                    if not ESPCache[plr] then
                        ESPCache[plr] = CreateESPSet()
                        if ESPCache[plr] then initESPVisual(ESPCache[plr]) end
                    end
                    local esp = ESPCache[plr]
                    if esp then
                        local hrpPos, on = cam:WorldToViewportPoint(hrp.Position)
                        local headPos = cam:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
                        local footPos = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0))
                        local dist = (cam.CFrame.Position - hrp.Position).Magnitude
                        if on then
                            local topY, botY = headPos.Y, footPos.Y
                            local h = math.abs(botY - topY)
                            local w = h * 0.5
                            local x = hrpPos.X - w/2
                            if State.BoxESP then
                                esp.outline.Visible=true; esp.outline.Size=Vector2.new(w,h)
                                esp.outline.Position=Vector2.new(x,topY); esp.outline.Color=Color3.new(0,0,0)
                                esp.box.Visible=true; esp.box.Size=Vector2.new(w,h)
                                esp.box.Position=Vector2.new(x,topY); esp.box.Color=State.ESPColor
                            else esp.box.Visible=false; esp.outline.Visible=false end
                            if State.NameESP then
                                esp.nameTag.Visible=true
                                esp.nameTag.Position=Vector2.new(hrpPos.X, topY-18)
                                esp.nameTag.Text=plr.Name
                            else esp.nameTag.Visible=false end
                            if State.DistESP then
                                esp.distTag.Visible=true
                                esp.distTag.Position=Vector2.new(hrpPos.X, botY+4)
                                esp.distTag.Text=string.format("[%d studs]", math.floor(dist))
                                esp.distTag.Color=State.ESPColor
                            else esp.distTag.Visible=false end
                            if State.HealthBarESP then
                                local hp = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
                                esp.hpBarBg.Visible=true
                                esp.hpBarBg.Size=Vector2.new(3,h)
                                esp.hpBarBg.Position=Vector2.new(x-6,topY)
                                esp.hpBarBg.Color=Color3.fromRGB(30,30,30)
                                esp.hpBar.Visible=true
                                esp.hpBar.Size=Vector2.new(3, h*hp)
                                esp.hpBar.Position=Vector2.new(x-6, botY - h*hp)
                                esp.hpBar.Color = hp > 0.5 and Color3.fromRGB(50,200,50)
                                    or hp > 0.25 and Color3.fromRGB(240,200,50)
                                    or Color3.fromRGB(220,50,50)
                            else esp.hpBar.Visible=false; esp.hpBarBg.Visible=false end
                            if State.TracerESP then
                                esp.tracer.Visible=true
                                local origin = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                                if State.TracerOrigin == "Center" then origin = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
                                elseif State.TracerOrigin == "Mouse" then origin = Vector2.new(Mouse.X, Mouse.Y) end
                                esp.tracer.From=origin
                                esp.tracer.To=Vector2.new(hrpPos.X, botY)
                                esp.tracer.Color=State.TracerColor
                            else esp.tracer.Visible=false end
                        else
                            esp.box.Visible=false; esp.outline.Visible=false; esp.nameTag.Visible=false
                            esp.distTag.Visible=false; esp.hpBar.Visible=false; esp.hpBarBg.Visible=false
                            esp.tracer.Visible=false
                        end
                    end
                end
            end
        end
        for plr, esp in pairs(ESPCache) do
            if not plr.Parent or not plr.Character then RemoveESPSet(esp); ESPCache[plr] = nil end
        end
    end)
end))

local Highlights = {}
AddConn(RunService.Heartbeat:Connect(function()
    Safe("HighlightESP", function()
        if State.HighlightESP then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    if not Highlights[plr] then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = State.ESPColor; hl.OutlineColor = Color3.new(1,1,1)
                        hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = plr.Character
                        Highlights[plr] = hl
                    end
                end
            end
        else
            for plr, hl in pairs(Highlights) do if hl then hl:Destroy() end Highlights[plr] = nil end
        end
    end)
end))

local WorldHighlights = {}
AddConn(RunService.Heartbeat:Connect(function()
    Safe("WorldESP", function()
        if not (State.ItemESP or State.VehicleESP or State.NPCESP) then
            for obj, hl in pairs(WorldHighlights) do if hl then hl:Destroy() end end
            WorldHighlights = {}
            return
        end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                if not WorldHighlights[obj] then
                    local isItem = State.ItemESP and (obj:IsA("Tool") or (obj.Name:lower():find("drop") or obj.Name:lower():find("item")))
                    local isVeh = State.VehicleESP and (obj:FindFirstChildOfClass("VehicleSeat") ~= nil)
                    local isNPC = State.NPCESP and obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid")
                        and not Players:GetPlayerFromCharacter(obj)
                    if isItem or isVeh or isNPC then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = isVeh and Color3.fromRGB(100,200,255)
                            or isItem and Color3.fromRGB(255,200,50)
                            or Color3.fromRGB(255,100,200)
                        hl.OutlineColor = Color3.new(1,1,1)
                        hl.FillTransparency = 0.6
                        pcall(function() hl.Parent = obj end)
                        WorldHighlights[obj] = hl
                    end
                end
            end
        end
    end)
end))

--------------------------------------------------------------------------------
-- FOV CIRCLE
--------------------------------------------------------------------------------
local FOVCircle
AddConn(RunService.RenderStepped:Connect(function()
    if not hasDrawing then return end
    Safe("FOVCircle", function()
        if State.FOVCircle or State.Aimbot or State.SilentAim then
            if not FOVCircle then
                FOVCircle = Drawing.new("Circle")
                FOVCircle.Thickness=1; FOVCircle.Filled=false
                FOVCircle.NumSides=60; FOVCircle.Transparency=0.7
            end
            FOVCircle.Visible=true
            FOVCircle.Radius=State.AimbotFOV
            FOVCircle.Position=Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            FOVCircle.Color=State.ESPColor
        elseif FOVCircle then FOVCircle.Visible=false end
    end)
end))

--------------------------------------------------------------------------------
-- SKELETON ESP
--------------------------------------------------------------------------------
local SkeletonLines = {}
local bones = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
AddConn(RunService.RenderStepped:Connect(function()
    if not hasDrawing then return end
    Safe("SkeletonESP", function()
        if not State.SkeletonESP then
            for _, line in pairs(SkeletonLines) do pcall(function() line:Remove() end) end
            SkeletonLines = {}; return
        end
        local cam = Workspace.CurrentCamera; if not cam then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                if not SkeletonLines[plr] then
                    SkeletonLines[plr] = {}
                    for _ = 1, #bones do
                        local l = Drawing.new("Line")
                        l.Thickness=1; l.Transparency=1; l.Color=State.ESPColor
                        table.insert(SkeletonLines[plr], l)
                    end
                end
                local lines = SkeletonLines[plr]
                for i, b in ipairs(bones) do
                    local p1 = plr.Character:FindFirstChild(b[1])
                    local p2 = plr.Character:FindFirstChild(b[2])
                    if p1 and p2 then
                        local v1, o1 = cam:WorldToViewportPoint(p1.Position)
                        local v2, o2 = cam:WorldToViewportPoint(p2.Position)
                        if o1 and o2 then
                            lines[i].Visible=true
                            lines[i].From=Vector2.new(v1.X,v1.Y)
                            lines[i].To=Vector2.new(v2.X,v2.Y)
                            lines[i].Color=State.ESPColor
                        else lines[i].Visible=false end
                    else lines[i].Visible=false end
                end
            end
        end
        for plr, lines in pairs(SkeletonLines) do
            if not plr.Parent or not plr.Character then
                for _, l in ipairs(lines) do pcall(function() l:Remove() end) end
                SkeletonLines[plr] = nil
            end
        end
    end)
end))

--------------------------------------------------------------------------------
-- OFFSCREEN ARROWS
--------------------------------------------------------------------------------
local OffArrows = {}
AddConn(RunService.RenderStepped:Connect(function()
    if not hasDrawing then return end
    Safe("OffscreenArrows", function()
        if not State.OffscreenArrows then
            for _, a in pairs(OffArrows) do pcall(function() a:Remove() end) end
            OffArrows = {}; return
        end
        local cam = Workspace.CurrentCamera; if not cam then return end
        local V = cam.ViewportSize
        local center = Vector2.new(V.X/2, V.Y/2)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pos, on = cam:WorldToViewportPoint(hrp.Position)
                    if not OffArrows[plr] then
                        local arrow = Drawing.new("Triangle")
                        arrow.Thickness=1; arrow.Filled=true; arrow.Transparency=1
                        OffArrows[plr] = arrow
                    end
                    local arrow = OffArrows[plr]
                    if arrow then
                        if on then arrow.Visible = false
                        else
                            arrow.Visible = true
                            local dir = (Vector2.new(pos.X, pos.Y) - center).Unit
                            local edge = center + dir * math.min(V.X, V.Y) * 0.4
                            local perp = Vector2.new(-dir.Y, dir.X)
                            arrow.PointA = edge + dir * 12
                            arrow.PointB = edge - perp * 8
                            arrow.PointC = edge + perp * 8
                            arrow.Color = State.ESPColor
                        end
                    end
                end
            end
        end
        for plr, a in pairs(OffArrows) do
            if not plr.Parent or not plr.Character then pcall(function() a:Remove() end); OffArrows[plr] = nil end
        end
    end)
end))

--------------------------------------------------------------------------------
-- RADAR
--------------------------------------------------------------------------------
local RadarFrame = Utils.Create("Frame", {
    Parent=ScreenGui, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-14,0,14),
    Size=UDim2.new(0,170,0,170), BackgroundColor3=TH.Background2, BorderSizePixel=0,
    Visible=false, ZIndex=90,
}, {
    Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }),
    Utils.Create("UIStroke", { Color=TH.Accent, Thickness=1, Transparency=0.3 }),
})
local RadarDots = {}
AddConn(RunService.RenderStepped:Connect(function()
    Safe("Radar", function()
        RadarFrame.Visible = State.Radar
        if not State.Radar then
            for _, d in pairs(RadarDots) do if d and d.Parent then d:Destroy() end end
            RadarDots = {}; return
        end
        RadarFrame.Size = UDim2.new(0, State.RadarSize, 0, State.RadarSize)
        local hrp = GetHRP()
        if not hrp then return end
        local myPos = hrp.Position
        local myLook = Camera.CFrame.LookVector
        local scale = (State.RadarSize / 2) / 150
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local thrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if thrp then
                    if not RadarDots[plr] then
                        RadarDots[plr] = Utils.Create("Frame", {
                            Parent=RadarFrame, Size=UDim2.new(0,6,0,6), AnchorPoint=Vector2.new(0.5,0.5),
                            BackgroundColor3=Color3.fromRGB(255,80,80), BorderSizePixel=0,
                        }, { Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }) })
                    end
                    local rel = thrp.Position - myPos
                    local rad = math.atan2(myLook.X, myLook.Z)
                    local x = rel.X * math.cos(-rad) - rel.Z * math.sin(-rad)
                    local z = rel.X * math.sin(-rad) + rel.Z * math.cos(-rad)
                    local cx = (State.RadarSize/2) + x * scale
                    local cy = (State.RadarSize/2) + z * scale
                    if (Vector2.new(cx, cy) - Vector2.new(State.RadarSize/2, State.RadarSize/2)).Magnitude < State.RadarSize/2 - 4 then
                        RadarDots[plr].Visible = true
                        RadarDots[plr].Position = UDim2.new(0, cx, 0, cy)
                    else RadarDots[plr].Visible = false end
                end
            end
        end
        if not RadarDots._self then
            RadarDots._self = Utils.Create("Frame", {
                Parent=RadarFrame, Size=UDim2.new(0,8,0,8), AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new(0.5,0,0.5,0), BackgroundColor3=Color3.fromRGB(80,200,255),
                BorderSizePixel=0,
            }, { Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }) })
        end
    end)
end))

--------------------------------------------------------------------------------
-- CROSSHAIR
--------------------------------------------------------------------------------
local crosshairHolder = Utils.Create("Frame", { Parent=ScreenGui, AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,0.5,0), Size=UDim2.new(0,30,0,30), BackgroundTransparency=1, Visible=false })
local CH1 = Utils.Create("Frame", { Parent=crosshairHolder, AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,0.5,0), Size=UDim2.new(0,14,0,2), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0 })
local CH2 = Utils.Create("Frame", { Parent=crosshairHolder, AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,0.5,0), Size=UDim2.new(0,2,0,14), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0 })
local CHDot = Utils.Create("Frame", { Parent=crosshairHolder, AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,0.5,0), Size=UDim2.new(0,3,0,3), BackgroundColor3=Color3.fromRGB(255,80,80),
    BorderSizePixel=0, Visible=false }, { Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }) })
AddConn(RunService.RenderStepped:Connect(function()
    Safe("Crosshair", function()
        crosshairHolder.Visible = State.Crosshair
        if not State.Crosshair then return end
        if State.CrosshairStyle == "Dot" then
            CH1.Visible=false; CH2.Visible=false; CHDot.Visible=true
        elseif State.CrosshairStyle == "Plus" then
            CH1.Visible=true; CH2.Visible=true; CHDot.Visible=false
            CH1.Size=UDim2.new(0,18,0,2); CH2.Size=UDim2.new(0,2,0,18)
        else
            CH1.Visible=true; CH2.Visible=true; CHDot.Visible=true
            CH1.Size=UDim2.new(0,14,0,2); CH2.Size=UDim2.new(0,2,0,14)
        end
    end)
end))

--------------------------------------------------------------------------------
-- CHINA HAT
--------------------------------------------------------------------------------
local ChinaHat = nil
AddConn(RunService.Heartbeat:Connect(function()
    Safe("ChinaHat", function()
        if State.ChinaHat and LocalPlayer.Character then
            if not ChinaHat or not ChinaHat.Parent then
                local head = LocalPlayer.Character:FindFirstChild("Head")
                if head then
                    local hat = Instance.new("Part")
                    hat.Name = "NovaHat"; hat.Shape = Enum.PartType.Cylinder
                    hat.Size = Vector3.new(0.1, 3, 3)
                    hat.Color = Color3.fromRGB(255, 40, 40)
                    hat.Material = Enum.Material.Neon
                    hat.CanCollide = false; hat.Massless = true
                    hat.CFrame = head.CFrame * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90))
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = head; weld.Part1 = hat; weld.Parent = hat
                    hat.Parent = LocalPlayer.Character
                    ChinaHat = hat
                end
            end
        elseif ChinaHat then ChinaHat:Destroy(); ChinaHat = nil end
    end)
end))

--------------------------------------------------------------------------------
-- FLY
--------------------------------------------------------------------------------
local FlyBV, FlyBG
AddConn(RunService.RenderStepped:Connect(function()
    Safe("Fly", function()
        if not State.Fly then
            if FlyBV then FlyBV:Destroy(); FlyBV = nil end
            if FlyBG then FlyBG:Destroy(); FlyBG = nil end
            local hum = GetHum(); if hum then hum.PlatformStand = false end
            return
        end
        local char = LocalPlayer.Character; if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if not FlyBV then
            FlyBV = Instance.new("BodyVelocity"); FlyBV.MaxForce = Vector3.new(9e9,9e9,9e9)
            FlyBV.Velocity = Vector3.zero; FlyBV.Parent = hrp
            FlyBG = Instance.new("BodyGyro"); FlyBG.MaxTorque = Vector3.new(9e9,9e9,9e9)
            FlyBG.P = 1000; FlyBG.Parent = hrp
        end
        local cam = Workspace.CurrentCamera
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
        if move.Magnitude > 0 then move = move.Unit end
        FlyBV.Velocity = move * State.FlySpeed
        FlyBG.CFrame = cam.CFrame
        hum.PlatformStand = true
    end)
end))

--------------------------------------------------------------------------------
-- SPEED / JUMP
--------------------------------------------------------------------------------
AddConn(RunService.Heartbeat:Connect(function()
    Safe("SpeedJump", function()
        local hum = GetHum(); if not hum then return end
        if State.SpeedHack then hum.WalkSpeed = State.WalkSpeed end
        if State.JumpMod then hum.UseJumpPower = true; hum.JumpPower = State.JumpPower end
    end)
end))
AddConn(UserInputService.JumpRequest:Connect(function()
    Safe("InfJump", function()
        if State.InfJump then local hum = GetHum(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end
    end)
end))
AddConn(RunService.Heartbeat:Connect(function()
    Safe("BHop", function()
        if State.BHop then
            local hum = GetHum()
            if hum and hum.MoveDirection.Magnitude > 0 then hum.Jump = true end
        end
        if State.AutoJump then
            local hum = GetHum()
            if hum and hum.FloorMaterial ~= Enum.Material.Air then hum.Jump = true end
        end
    end)
end))

--------------------------------------------------------------------------------
-- NOCLIP
--------------------------------------------------------------------------------
AddConn(RunService.Stepped:Connect(function()
    Safe("Noclip", function()
        if State.Noclip then
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                end
            end
        end
        if State.VehicleNoclip then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.SeatPart then
                local seat = hum.SeatPart
                local veh = seat:FindFirstAncestorOfClass("Model")
                if veh then
                    for _, p in ipairs(veh:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end
        end
    end)
end))

--------------------------------------------------------------------------------
-- SPIDER / WALLHOP / LONG JUMP / DASH
--------------------------------------------------------------------------------
AddConn(RunService.Heartbeat:Connect(function()
    Safe("Spider", function()
        if State.Spider then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = { char }
                params.FilterType = Enum.RaycastFilterType.Exclude
                local ray = Workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 3, params)
                if ray then hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 40, hrp.AssemblyLinearVelocity.Z) end
            end
        end
    end)
end))

AddConn(UserInputService.JumpRequest:Connect(function()
    Safe("Wallhop", function()
        if State.Wallhop then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = { char }
                params.FilterType = Enum.RaycastFilterType.Exclude
                local look = hrp.CFrame.LookVector
                for _, dir in ipairs({ look, -look, hrp.CFrame.RightVector, -hrp.CFrame.RightVector }) do
                    local ray = Workspace:Raycast(hrp.Position, dir * 2.5, params)
                    if ray then
                        hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + Vector3.new(0, 45, 0) + dir * 20
                        break
                    end
                end
            end
        end
    end)
end))

AddConn(UserInputService.JumpRequest:Connect(function()
    Safe("LongJump", function()
        if State.LongJump then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.FloorMaterial ~= Enum.Material.Air then
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0 then
                    hrp.AssemblyLinearVelocity = moveDir * 150 + Vector3.new(0, 60, 0)
                end
            end
        end
    end)
end))

local dashRequested = false
AddConn(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if State.Dash and input.KeyCode == State.DashKey then dashRequested = true end
end))
AddConn(RunService.Heartbeat:Connect(function()
    if not dashRequested then return end
    dashRequested = false
    Safe("Dash", function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            local dir = hum.MoveDirection
            if dir.Magnitude == 0 then dir = hrp.CFrame.LookVector end
            hrp.CFrame = hrp.CFrame + dir * 30
        end
    end)
end))

--------------------------------------------------------------------------------
-- AIRWALK
--------------------------------------------------------------------------------
local AirwalkPart = nil
AddConn(RunService.Stepped:Connect(function()
    Safe("Airwalk", function()
        if State.Airwalk then
            local hrp = GetHRP()
            if hrp then
                if not AirwalkPart then
                    AirwalkPart = Instance.new("Part")
                    AirwalkPart.Name = "NovaAirwalk"; AirwalkPart.Size = Vector3.new(6, 1, 6)
                    AirwalkPart.Anchored = true; AirwalkPart.CanCollide = true
                    AirwalkPart.Transparency = 0.7; AirwalkPart.Color = Color3.fromRGB(96,118,255)
                    AirwalkPart.Material = Enum.Material.ForceField
                    AirwalkPart.Parent = Workspace
                end
                AirwalkPart.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 3.5, 0))
            end
        elseif AirwalkPart then AirwalkPart:Destroy(); AirwalkPart = nil end
    end)
end))

--------------------------------------------------------------------------------
-- FREEZE POS / GRAVITY / NO FALL
--------------------------------------------------------------------------------
AddConn(RunService.Heartbeat:Connect(function()
    Safe("Physics", function()
        if State.FreezePos then
            local hrp = GetHRP()
            if hrp then hrp.Anchored = true end
        end
        Workspace.Gravity = State.Gravity
        if State.NoFall then
            local hum = GetHum()
            if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        end
    end)
end))

--------------------------------------------------------------------------------
-- GODMODE / ANTI VOID / ANTI RAGDOLL
--------------------------------------------------------------------------------
AddConn(RunService.Heartbeat:Connect(function()
    Safe("Protections", function()
        if State.Godmode then
            local hum = GetHum()
            if hum and hum.Health > 0 then hum.MaxHealth = math.huge; hum.Health = math.huge end
        end
        if State.AntiVoid then
            local hrp = GetHRP()
            if hrp and hrp.Position.Y < -50 then hrp.CFrame = CFrame.new(0, 50, 0) end
        end
        if State.AntiRagdoll or State.AntiStun then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                local state = hum:GetState()
                if state == Enum.HumanoidStateType.Physics
                    or state == Enum.HumanoidStateType.Ragdoll
                    or state == Enum.HumanoidStateType.FallingDown then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
        if State.AntiFling then
            local hrp = GetHRP()
            if hrp then
                local vel = hrp.AssemblyLinearVelocity
                if vel.Magnitude > 200 then hrp.AssemblyLinearVelocity = vel.Unit * 50 end
            end
        end
    end)
end))

--------------------------------------------------------------------------------
-- SPINBOT / FAKE LAG
--------------------------------------------------------------------------------
AddConn(RunService.RenderStepped:Connect(function()
    Safe("Spinbot", function()
        if State.Spinbot then
            local hrp = GetHRP()
            if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(State.SpinbotSpeed), 0) end
        end
    end)
end))
AddConn(RunService.Heartbeat:Connect(function()
    Safe("FakeLag", function()
        if State.FakeLag then
            local hrp = GetHRP()
            if hrp then
                local c = hrp.CFrame
                hrp.CFrame = c + Vector3.new(0.001, 0, 0.001)
                hrp.CFrame = c
            end
        end
    end)
end))

--------------------------------------------------------------------------------
-- HEADLESS / KORBLOX
--------------------------------------------------------------------------------
AddConn(RunService.Heartbeat:Connect(function()
    Safe("Headless", function()
        local char = LocalPlayer.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if head then head.Transparency = State.Headless and 1 or 0 end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Decal") and obj.Name == "face" then
                obj.Transparency = State.Headless and 1 or 0
            end
        end
        local rleg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightUpperLeg")
        if rleg and rleg:IsA("BasePart") then
            rleg.Color = State.Korblox and Color3.fromRGB(40,40,40) or Color3.fromRGB(255,204,153)
        end
    end)
end))

--------------------------------------------------------------------------------
-- LIGHTING
--------------------------------------------------------------------------------
local origTrans = {}
local XRayOn = false
AddConn(RunService.Heartbeat:Connect(function()
    Safe("Lighting", function()
        if State.Fullbright then
            Lighting.Ambient = Color3.new(1,1,1); Lighting.Brightness = 3
            Lighting.OutdoorAmbient = Color3.new(1,1,1); Lighting.GlobalShadows = false
        else
            Lighting.Ambient = Color3.fromRGB(70,70,70); Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128); Lighting.GlobalShadows = true
        end
        Lighting.FogEnd = State.NoFog and 9e9 or 500
        Lighting.ClockTime = State.TimeOfDay
        if State.XRay and not XRayOn then
            XRayOn = true
            for _, p in ipairs(Workspace:GetDescendants()) do
                if p:IsA("BasePart") and (not LocalPlayer.Character or not p:IsDescendantOf(LocalPlayer.Character)) then
                    origTrans[p] = p.LocalTransparencyModifier
                    p.LocalTransparencyModifier = 0.7
                end
            end
        elseif not State.XRay and XRayOn then
            XRayOn = false
            for p, t in pairs(origTrans) do if p and p.Parent then p.LocalTransparencyModifier = t end end
            origTrans = {}
        end
    end)
end))

--------------------------------------------------------------------------------
-- REMOVE TEXTURES
--------------------------------------------------------------------------------
local RemovedTex = {}
AddConn(RunService.Heartbeat:Connect(function()
    Safe("RemoveTex", function()
        if State.RemoveTextures then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Decal") or obj:IsA("Texture") then
                    if not RemovedTex[obj] then RemovedTex[obj] = obj.Transparency; obj.Transparency = 1 end
                end
            end
        else
            for obj, t in pairs(RemovedTex) do if obj and obj.Parent then obj.Transparency = t end end
            RemovedTex = {}
        end
    end)
end))

--------------------------------------------------------------------------------
-- SPECTATE
--------------------------------------------------------------------------------
AddConn(RunService.RenderStepped:Connect(function()
    Safe("Spectate", function()
        -- [FIX 5] Cek targetPlayer masih valid
        if State.Spectate and State.SpectateTarget and State.SpectateTarget.Parent and State.SpectateTarget.Character then
            local head = State.SpectateTarget.Character:FindFirstChild("Head")
            if head and Camera then Camera.CameraSubject = head end
        elseif LocalPlayer.Character and Camera then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then Camera.CameraSubject = hum end
        end
    end)
end))

--------------------------------------------------------------------------------
-- AUTO COLLECT / INTERACT
--------------------------------------------------------------------------------
AddConn(RunService.Heartbeat:Connect(function()
    Safe("AutoCollect", function()
        if State.AutoCollect and hasFireTouch then
            local hrp = GetHRP()
            if hrp then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.CanTouch then
                        if (obj.Position - hrp.Position).Magnitude < 20 then
                            pcall(function() firetouchinterest(hrp, obj, 0); firetouchinterest(hrp, obj, 1) end)
                        end
                    end
                end
            end
        end
        if State.InstantInteract and hasFirePrompt then
            local hrp = GetHRP()
            if hrp then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and obj.Enabled then
                        local parent = obj.Parent
                        if parent and parent:IsA("BasePart") then
                            if (parent.Position - hrp.Position).Magnitude < obj.MaxActivationDistance then
                                pcall(function() fireproximityprompt(obj) end)
                            end
                        end
                    end
                end
            end
        end
    end)
end))

--------------------------------------------------------------------------------
-- CHAT SPY
--------------------------------------------------------------------------------
local ChatSpyGui = Utils.Create("Frame", {
    Parent=ScreenGui, AnchorPoint=Vector2.new(1,1), Position=UDim2.new(1,-14,1,-14),
    Size=UDim2.new(0,300,0,180), BackgroundColor3=TH.Background2, BorderSizePixel=0, Visible=false,
}, {
    Utils.Create("UICorner", { CornerRadius=UDim.new(0,8) }),
    Utils.Create("UIStroke", { Color=TH.Border, Thickness=1 }),
})
local ChatSpyScroll = Utils.Create("ScrollingFrame", {
    Parent=ChatSpyGui, Position=UDim2.new(0,5,0,5), Size=UDim2.new(1,-10,1,-10),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=2, CanvasSize=UDim2.new(0,0,0,0),
}, { Utils.Create("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,2) }) })
ChatSpyScroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ChatSpyScroll.CanvasSize = UDim2.new(0,0,0, ChatSpyScroll.UIListLayout.AbsoluteContentSize.Y + 5)
end)
local function hookChat(plr)
    pcall(function()
        plr.Chatted:Connect(function(msg)
            if State.ChatSpy then
                Utils.Create("TextLabel", { Parent=ChatSpyScroll, Size=UDim2.new(1,0,0,18),
                    BackgroundTransparency=1, Text=plr.Name..": "..msg, TextColor3=TH.TextPrimary,
                    TextSize=12, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
                    TextTruncate=Enum.TextTruncate.AtEnd })
            end
        end)
    end)
end
for _, p in ipairs(Players:GetPlayers()) do hookChat(p) end
Players.PlayerAdded:Connect(hookChat)
AddConn(RunService.Heartbeat:Connect(function()
    ChatSpyGui.Visible = State.ChatSpy
end))

--------------------------------------------------------------------------------
-- ADMIN ALERT
--------------------------------------------------------------------------------
task.spawn(function()
    local adminKw = { "admin", "owner", "mod", "staff", "roblox" }
    local alerted = {}
    while task.wait(5) do
        if State.AdminAlert then
            Safe("AdminAlert", function()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and not alerted[plr] then
                        for _, kw in ipairs(adminKw) do
                            if string.find(string.lower(plr.Name), kw) or string.find(string.lower(plr.DisplayName), kw) then
                                alerted[plr] = true
                                Notify("Admin Alert", "Mungkin admin: "..plr.Name, 5, "Warning")
                                break
                            end
                        end
                    end
                end
            end)
        end
    end
end)

--------------------------------------------------------------------------------
-- CHAT SPAM
--------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(2) do
        if State.ChatSpam then
            pcall(function()
                game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(State.ChatSpamMsg, "All")
            end)
        end
    end
end)

--------------------------------------------------------------------------------
-- FPS BOOSTER
--------------------------------------------------------------------------------
local origQuality = nil
AddConn(RunService.Heartbeat:Connect(function()
    Safe("FPSBooster", function()
        if State.FPSBooster then
            if not origQuality then pcall(function() origQuality = settings().Rendering.QualityLevel end) end
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
            Lighting.GlobalShadows = false
        elseif origQuality then
            pcall(function() settings().Rendering.QualityLevel = origQuality end)
            origQuality = nil
        end
    end)
end))

--------------------------------------------------------------------------------
-- POPULASI TAB
--------------------------------------------------------------------------------

local CombatTab = Library.CreateTab("Combat", "⚔")
CombatTab.AddSection("Aimbot")
CombatTab.AddToggle("Aimbot Enabled", false, function(s) State.Aimbot = s end)
CombatTab.AddSlider("Aimbot Smoothness", 1, 10, 3, 1, function(v) State.AimbotSmooth = v end)
CombatTab.AddSlider("Aimbot FOV", 30, 500, 150, 0, function(v) State.AimbotFOV = v end)
CombatTab.AddDropdown("Aimbot Bone", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, "Head", function(sel) State.AimbotBone = sel end)
CombatTab.AddToggle("Team Check", false, function(s) State.AimbotTeam = s end)
CombatTab.AddToggle("Visible Check", false, function(s) State.AimbotVisible = s end)
CombatTab.AddToggle("Movement Prediction", false, function(s) State.AimbotPrediction = s end)
CombatTab.AddToggle("Draw FOV Circle", false, function(s) State.FOVCircle = s end)

CombatTab.AddSection("Silent Aim / Magic Bullet")
CombatTab.AddToggle("Silent Aim", false, function(s) State.SilentAim = s end)
CombatTab.AddDropdown("Silent Target Bone", {"Head", "HumanoidRootPart", "UpperTorso"}, "Head", function(sel) State.SilentBone = sel end)
CombatTab.AddToggle("Magic Bullet (Hook __namecall)", false, function(s)
    State.MagicBullet = s
    if s then
        if not hasHookMeta then
            Notify("Magic Bullet", "Executor tidak support hookmetamethod", 4, "Danger")
            State.MagicBullet = false
        else
            local ok = InstallMagicHook()
            if ok then Notify("Magic Bullet", "Hook terpasang!", 3, "Success")
            else Notify("Magic Bullet", "Hook gagal dipasang", 4, "Danger"); State.MagicBullet = false end
        end
    end
end)

CombatTab.AddSection("Triggerbot & Auto")
CombatTab.AddToggle("Triggerbot", false, function(s) State.Triggerbot = s end)
CombatTab.AddSlider("Triggerbot Delay (ms)", 0, 300, 20, 0, function(v) State.TriggerDelay = v end)
CombatTab.AddSlider("Triggerbot FOV", 2, 50, 10, 0, function(v) State.TriggerFOV = v end)
CombatTab.AddToggle("Auto Clicker", false, function(s) State.AutoClicker = s end)
CombatTab.AddSlider("Auto Clicker CPS", 1, 60, 15, 0, function(v) State.AutoClickerCPS = v end)

CombatTab.AddSection("Weapon")
CombatTab.AddToggle("Hitbox Expander", false, function(s) State.HitboxExpand = s end)
CombatTab.AddSlider("Hitbox Size", 2, 30, 5, 1, function(v) State.HitboxSize = v end)

local VisualsTab = Library.CreateTab("Visuals", "👁")
VisualsTab.AddSection("Player ESP")
VisualsTab.AddToggle("Box ESP", false, function(s) State.BoxESP = s end)
VisualsTab.AddToggle("Name ESP", false, function(s) State.NameESP = s end)
VisualsTab.AddToggle("Distance ESP", false, function(s) State.DistESP = s end)
VisualsTab.AddToggle("Health Bar ESP", false, function(s) State.HealthBarESP = s end)
VisualsTab.AddToggle("Tracer ESP", false, function(s) State.TracerESP = s end)
VisualsTab.AddDropdown("Tracer Origin", {"Bottom", "Center", "Mouse"}, "Bottom", function(sel) State.TracerOrigin = sel end)
VisualsTab.AddToggle("Skeleton ESP", false, function(s) State.SkeletonESP = s end)
VisualsTab.AddToggle("Highlight ESP", false, function(s) State.HighlightESP = s end)
VisualsTab.AddToggle("Offscreen Arrows", false, function(s) State.OffscreenArrows = s end)
VisualsTab.AddColorPicker("ESP Color", Color3.fromRGB(96,118,255), function(c) State.ESPColor = c end)
VisualsTab.AddColorPicker("Tracer Color", Color3.fromRGB(255,80,80), function(c) State.TracerColor = c end)

VisualsTab.AddSection("World ESP")
VisualsTab.AddToggle("Item / Drop ESP", false, function(s) State.ItemESP = s end)
VisualsTab.AddToggle("Vehicle ESP", false, function(s) State.VehicleESP = s end)
VisualsTab.AddToggle("NPC ESP", false, function(s) State.NPCESP = s end)

VisualsTab.AddSection("Overlay")
VisualsTab.AddToggle("Custom Crosshair", false, function(s) State.Crosshair = s end)
VisualsTab.AddDropdown("Crosshair Style", {"Cross", "Plus", "Dot"}, "Cross", function(sel) State.CrosshairStyle = sel end)
VisualsTab.AddToggle("Radar / Minimap", false, function(s) State.Radar = s end)
VisualsTab.AddSlider("Radar Size", 100, 300, 170, 0, function(v) State.RadarSize = v end)
VisualsTab.AddToggle("China Hat", false, function(s) State.ChinaHat = s end)

local MoveTab = Library.CreateTab("Movement", "🏃")
MoveTab.AddSection("Flight & Speed")
MoveTab.AddToggle("Fly Mode", false, function(s) State.Fly = s end)
MoveTab.AddSlider("Fly Speed", 10, 300, 50, 0, function(v) State.FlySpeed = v end)
MoveTab.AddToggle("Speed Hack", false, function(s) State.SpeedHack = s end)
MoveTab.AddSlider("WalkSpeed", 16, 500, 100, 0, function(v) State.WalkSpeed = v end)
MoveTab.AddToggle("Jump Modifier", false, function(s) State.JumpMod = s end)
MoveTab.AddSlider("JumpPower", 50, 600, 120, 0, function(v) State.JumpPower = v end)
MoveTab.AddToggle("Infinite Jump", false, function(s) State.InfJump = s end)

MoveTab.AddSection("Advanced Movement")
MoveTab.AddToggle("Long Jump", false, function(s) State.LongJump = s end)
MoveTab.AddToggle("Wall Hop", false, function(s) State.Wallhop = s end)
MoveTab.AddToggle("Bunny Hop", false, function(s) State.BHop = s end)
MoveTab.AddToggle("Auto Jump", false, function(s) State.AutoJump = s end)
MoveTab.AddToggle("Spider / Wall Climb", false, function(s) State.Spider = s end)
MoveTab.AddToggle("Airwalk", false, function(s) State.Airwalk = s end)
MoveTab.AddToggle("Dash", false, function(s) State.Dash = s end)
MoveTab.AddKeybind("Dash Key", Enum.KeyCode.Q, function(k) State.DashKey = k end)
MoveTab.AddToggle("Freeze Position", false, function(s) State.FreezePos = s end)

MoveTab.AddSection("Physics")
MoveTab.AddToggle("Noclip", false, function(s) State.Noclip = s end)
MoveTab.AddToggle("Vehicle Noclip", false, function(s) State.VehicleNoclip = s end)
MoveTab.AddSlider("Gravity", 0, 300, 196, 0, function(v) State.Gravity = v end)
MoveTab.AddToggle("No Fall Damage", false, function(s) State.NoFall = s end)

local PlayerTab = Library.CreateTab("Player", "🧍")
PlayerTab.AddSection("Protections")
PlayerTab.AddToggle("Godmode", false, function(s) State.Godmode = s end)
PlayerTab.AddToggle("Anti Void", false, function(s) State.AntiVoid = s end)
PlayerTab.AddToggle("Anti Ragdoll", false, function(s) State.AntiRagdoll = s end)
PlayerTab.AddToggle("Anti Stun", false, function(s) State.AntiStun = s end)
PlayerTab.AddToggle("Anti Fling", false, function(s) State.AntiFling = s end)

PlayerTab.AddSection("Character")
PlayerTab.AddToggle("Headless (Local)", false, function(s) State.Headless = s end)
PlayerTab.AddToggle("Korblox Leg (Local)", false, function(s) State.Korblox = s end)
PlayerTab.AddToggle("Fake Lag", false, function(s) State.FakeLag = s end)
PlayerTab.AddToggle("Spinbot", false, function(s) State.Spinbot = s end)
PlayerTab.AddSlider("Spinbot Speed", 10, 200, 50, 0, function(v) State.SpinbotSpeed = v end)

PlayerTab.AddSection("Actions")
PlayerTab.AddButton("Force Reset Character", function()
    if LocalPlayer.Character then LocalPlayer.Character:BreakJoints() end
    Notify("Player", "Karakter di-reset", 2, "Success")
end)

-- ============================================================================
-- [FIX 2] TAB TELEPORT — Select Player sekarang DINAMIS
-- ============================================================================
local TpTab = Library.CreateTab("Teleport", "🌐")
TpTab.AddSection("Player Actions")

local targetPlayer = nil

-- [FIX 2] Helper untuk ambil list player terkini
local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    if #list == 0 then
        return { "(Tidak ada player)" }
    end
    return list
end

-- Buat dropdown dengan list awal
local playerDropdown = TpTab.AddDropdown("Select Player", getPlayerList(), nil, function(sel)
    -- [FIX 2] Cari player berdasarkan nama yang dipilih
    targetPlayer = nil
    if sel ~= "(Tidak ada player)" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == sel then
                targetPlayer = p
                break
            end
        end
    end
end)

-- [FIX 3] Tombol refresh manual
TpTab.AddButton("🔄 Refresh Daftar Player", function()
    local list = getPlayerList()
    playerDropdown.Refresh(list)
    -- Reset targetPlayer jika sudah tidak ada di game
    if targetPlayer and not targetPlayer.Parent then
        targetPlayer = nil
    end
    Notify("Players", "Daftar player diperbarui ("..tostring(#list).." player)", 2, "Success")
end)

-- [FIX 2] Auto-refresh saat player join / keluar
Players.PlayerAdded:Connect(function(plr)
    task.wait(0.5) -- tunggu sebentar agar player selesai load
    local list = getPlayerList()
    playerDropdown.Refresh(list)
    hookChat(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
    -- [FIX 4] Reset targetPlayer kalau player yang keluar adalah target
    if targetPlayer == plr then
        targetPlayer = nil
        Notify("Teleport", plr.Name.." keluar dari game", 3, "Warning")
    end
    -- [FIX 5] Matikan spectate jika target keluar
    if State.SpectateTarget == plr then
        State.Spectate = false
        State.SpectateTarget = nil
    end
    task.wait(0.1)
    local list = getPlayerList()
    playerDropdown.Refresh(list)
end)

TpTab.AddButton("Teleport to Selected Player", function()
    -- [FIX 4] Validasi lengkap sebelum teleport
    if not targetPlayer then
        Notify("Teleport", "Pilih player dulu dari dropdown", 4, "Warning")
        return
    end
    if not targetPlayer.Parent then
        Notify("Teleport", "Player sudah keluar dari game", 4, "Warning")
        targetPlayer = nil
        return
    end
    if not targetPlayer.Character then
        Notify("Teleport", "Character player belum siap", 4, "Warning")
        return
    end
    if not LocalPlayer.Character then
        Notify("Teleport", "Character kamu belum siap", 4, "Warning")
        return
    end
    local thrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myhrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if thrp and myhrp then
        myhrp.CFrame = thrp.CFrame * CFrame.new(0, 0, 3)
        Notify("Teleport", "Teleport ke "..targetPlayer.Name, 2, "Success")
    else
        Notify("Teleport", "HumanoidRootPart tidak ditemukan", 4, "Warning")
    end
end)

TpTab.AddToggle("Spectate Selected Player", false, function(s)
    State.Spectate = s
    if s then
        if not targetPlayer or not targetPlayer.Parent then
            Notify("Spectate", "Pilih player yang valid dulu", 4, "Warning")
            State.Spectate = false
        else
            State.SpectateTarget = targetPlayer
            Notify("Spectate", "Spectate: "..targetPlayer.Name, 3, "Success")
        end
    else
        State.SpectateTarget = nil
    end
end)

TpTab.AddButton("Goto Random Player", function()
    local plrs = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Parent then
            table.insert(plrs, p)
        end
    end
    if #plrs == 0 then
        Notify("Teleport", "Tidak ada player lain di server", 4, "Warning")
        return
    end
    local t = plrs[math.random(1, #plrs)]
    local myhrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local thrp = t.Character and t.Character:FindFirstChild("HumanoidRootPart")
    if thrp and myhrp then
        myhrp.CFrame = thrp.CFrame * CFrame.new(0, 0, 3)
        Notify("Teleport", "Goto: "..t.Name, 2, "Success")
    end
end)

TpTab.AddSection("Position")
TpTab.AddButton("Teleport Up (100 studs)", function()
    local hrp = GetHRP()
    if hrp then hrp.CFrame = hrp.CFrame + Vector3.new(0, 100, 0) end
end)
TpTab.AddButton("Teleport Down (100 studs)", function()
    local hrp = GetHRP()
    if hrp then hrp.CFrame = hrp.CFrame - Vector3.new(0, 100, 0) end
end)
TpTab.AddButton("Teleport to Mouse", function()
    local hrp = GetHRP()
    if hrp then
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { LocalPlayer.Character }
        params.FilterType = Enum.RaycastFilterType.Exclude
        local unit = Workspace.CurrentCamera:ViewportPointToRay(Mouse.X, Mouse.Y)
        local hit = Workspace:Raycast(unit.Origin, unit.Direction * 1000, params)
        if hit then hrp.CFrame = CFrame.new(hit.Position + Vector3.new(0,4,0)) end
    end
end)
TpTab.AddButton("Safe Place Base TP", function()
    local hrp = GetHRP()
    if hrp then hrp.CFrame = CFrame.new(0, 500, 0) end
end)

TpTab.AddSection("Server")
TpTab.AddButton("Rejoin Server", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)
TpTab.AddButton("Server Hop", function()
    if not hasHttpGet then Notify("Server Hop", "Executor tidak support HttpGet", 3, "Danger"); return end
    task.spawn(function()
        local ok = pcall(function()
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            local resp = HttpService:JSONDecode(game:HttpGet(url))
            for _, srv in ipairs(resp.data) do
                if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer) end)
                    return
                end
            end
            Notify("Server Hop", "Server tidak tersedia", 3, "Warning")
        end)
        if not ok then Notify("Server Hop", "HTTP request gagal", 3, "Danger") end
    end)
end)
TpTab.AddButton("Copy JobId", function()
    if setclipboard then setclipboard(tostring(game.JobId)); Notify("Clipboard", "JobId disalin", 2, "Success") end
end)
TpTab.AddButton("Copy PlaceId", function()
    if setclipboard then setclipboard(tostring(game.PlaceId)); Notify("Clipboard", "PlaceId disalin", 2, "Success") end
end)

local WorldTab = Library.CreateTab("World", "🌍")
WorldTab.AddSection("Lighting")
WorldTab.AddToggle("Fullbright", false, function(s) State.Fullbright = s end)
WorldTab.AddToggle("No Fog", false, function(s) State.NoFog = s end)
WorldTab.AddToggle("X-Ray Transparency", false, function(s) State.XRay = s end)
WorldTab.AddSlider("Time of Day", 0, 24, 14, 1, function(v) State.TimeOfDay = v end)
WorldTab.AddToggle("Remove Textures", false, function(s) State.RemoveTextures = s end)

WorldTab.AddSection("Automation")
WorldTab.AddToggle("FPS Booster", false, function(s) State.FPSBooster = s end)
WorldTab.AddToggle("Anti-AFK", true, function(s) State.AntiAFK = s end)
WorldTab.AddToggle("Auto Collect Drops", false, function(s) State.AutoCollect = s end)
WorldTab.AddToggle("Instant Proximity Interact", false, function(s) State.InstantInteract = s end)

WorldTab.AddSection("Monitoring")
WorldTab.AddToggle("Chat Spy", false, function(s) State.ChatSpy = s end)
WorldTab.AddToggle("Admin Detection Alert", true, function(s) State.AdminAlert = s end)
WorldTab.AddToggle("Chat Spammer", false, function(s) State.ChatSpam = s end)
do
    local tb = Utils.Create("TextBox", { Parent=WorldTab.Scroll, Size=UDim2.new(1,0,0,34),
        BackgroundColor3=TH.Container, PlaceholderText="Pesan chat spam...", Text=State.ChatSpamMsg,
        TextColor3=TH.TextPrimary, PlaceholderColor3=TH.TextSecondary, Font=Enum.Font.Gotham,
        TextSize=12, BorderSizePixel=0, ClearTextOnFocus=false }, {
        Utils.Create("UICorner", { CornerRadius=UDim.new(0,8) }),
        Utils.Create("UIStroke", { Color=TH.Border, Thickness=1, Transparency=0.4 }),
    })
    tb.FocusLost:Connect(function() State.ChatSpamMsg = tb.Text end)
    table.insert(WorldTab.Elements, { Name="Chat Spam Text", Instance=tb })
end

local SettingsTab = Library.CreateTab("Settings", "⚙")
SettingsTab.AddSection("UI")
SettingsTab.AddKeybind("UI Toggle Key", Enum.KeyCode.RightControl, function(key)
    Library.ToggleKey = key
    Notify("Keybind", "UI toggle: "..key.Name, 3, "Success")
end)
SettingsTab.AddToggle("Watermark", true, function(s) Library.Watermark = s; Watermark.Visible = s end)
SettingsTab.AddToggle("Notifications", true, function(s) Library.Notifications = s end)

SettingsTab.AddSection("Config")
SettingsTab.AddButton("Save Config", function()
    State.WatermarkPos = { X = Watermark.Position.X.Offset, Y = Watermark.Position.Y.Offset }
    Library.ConfigData["WatermarkPos"] = State.WatermarkPos
    if not hasWriteFile then Notify("Config", "Executor tidak support writefile", 3, "Danger"); return end
    local json = HttpService:JSONEncode(Library.ConfigData)
    local ok = pcall(function() writefile("NovaUI_Config.json", json) end)
    if ok then Notify("Config", "Disimpan!", 3, "Success")
    else Notify("Config", "Gagal menyimpan file", 3, "Danger") end
end)
SettingsTab.AddButton("Load Config", function()
    if not (hasReadFile and hasIsFile) then Notify("Config", "Executor tidak support readfile", 3, "Danger"); return end
    if not isfile("NovaUI_Config.json") then Notify("Config", "File tidak ditemukan", 3, "Warning"); return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile("NovaUI_Config.json")) end)
    if ok and type(data) == "table" then
        Library.ConfigData = data
        for name, value in pairs(data) do
            if name == "WatermarkPos" and type(value) == "table" then
                State.WatermarkPos = value
                Watermark.Position = UDim2.new(0, value.X or 14, 0, value.Y or 14)
            else
                local el = Library.Registry[name]
                if el then pcall(el.Set, value) end
            end
        end
        Notify("Config", "Dimuat & diterapkan!", 3, "Success")
    else Notify("Config", "File corrupt", 3, "Danger") end
end)
SettingsTab.AddButton("Reset Watermark Position", function()
    State.WatermarkPos = { X = 14, Y = 14 }
    Watermark.Position = UDim2.new(0, 14, 0, 14)
    Notify("Watermark", "Posisi direset", 2, "Success")
end)
SettingsTab.AddButton("Unload UI", function() Unload() end)

--------------------------------------------------------------------------------
-- GLOBAL TOGGLE
--------------------------------------------------------------------------------
AddConn(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Library.ToggleKey then
        MainWindow.Visible = not MainWindow.Visible
    end
end))

--------------------------------------------------------------------------------
-- FLOATING BUTTON (mobile)
--------------------------------------------------------------------------------
if IsMobile then
    local FloatBtn = Utils.Create("TextButton", {
        Parent=ScreenGui, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0,60,0.5,0),
        Size=UDim2.new(0,46,0,46), BackgroundColor3=TH.Accent, Text="N",
        TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=18,
        AutoButtonColor=false, BorderSizePixel=0, ZIndex=150,
    }, {
        Utils.Create("UICorner", { CornerRadius=UDim.new(1,0) }),
        Utils.Gradient(TH.Accent, TH.Accent2, 45),
    })
    local dragging, moved, startPos, startInput
    FloatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            startPos = FloatBtn.Position; startInput = input.Position
        end
    end)
    FloatBtn.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - startInput
            if d.Magnitude > 10 then moved = true end
            FloatBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    FloatBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            if not moved then MainWindow.Visible = not MainWindow.Visible end
        end
    end)
end

--------------------------------------------------------------------------------
-- OPEN ANIMATION
--------------------------------------------------------------------------------
task.delay(0.1, function()
    if not MainWindow.Parent then return end
    Utils.Tween(MainWindow, 0.4, { Size = UDim2.new(0,WIN_W,0,WIN_H) }, Enum.EasingStyle.Quint)
end)

Notify("Nova UI "..Library.Version,
    "Loaded. Tekan "..Library.ToggleKey.Name.." untuk toggle UI. Fitur: "..
    (hasDrawing and "ESP ✓ " or "ESP ✗ ")..
    (hasHookMeta and "Hook ✓" or "Hook ✗"),
    6, "Success")
