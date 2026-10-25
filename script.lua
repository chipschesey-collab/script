-- bss_toolkit.lua
-- ESP, Teleport, Aimbot, Fling, Hitbox, Fun, Utility.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ============ PALETTE ============
local COL_BG        = Color3.fromRGB(24, 24, 28)
local COL_PANEL     = Color3.fromRGB(34, 34, 40)
local COL_PANEL_ALT = Color3.fromRGB(30, 30, 36)
local COL_STROKE    = Color3.fromRGB(60, 60, 70)
local COL_TEXT      = Color3.fromRGB(230, 230, 240)
local COL_TEXT_DIM  = Color3.fromRGB(170, 170, 185)
local COL_ACCENT    = Color3.fromRGB(60, 130, 220)
local COL_OK        = Color3.fromRGB(150, 200, 150)
local COL_BAD       = Color3.fromRGB(220, 130, 130)
local COL_DANGER    = Color3.fromRGB(150, 60, 60)

-- ============ STATE ============
local state = {
    esp_enabled = false,
    esp_box = true,
    esp_name = true,
    esp_distance = true,
    esp_tracers = false,
    esp_skeleton = false,
    esp_color = Color3.fromRGB(255, 80, 80),
    esp_team_color = false,
    esp_range = 500,
    fov_enabled = false,
    fov_value = 70,
    saved_spots = {},
    aimbot_enabled = false,
    aimbot_fov = 150,
    aimbot_smooth = 0.35,
    aimbot_part = "Head",
    aimbot_teamcheck = true,
    aimbot_range = 500,
    aimbot_prediction = 0.05,
    fling_return = true,
    hitbox_enabled = false,
    hitbox_part = "HumanoidRootPart",
    hitbox_size = 6,
    hitbox_transparency = 0.5,
    object_name = "",
    object_esp_enabled = false,
    object_aimbot_enabled = false,
    object_box = true,
    object_name_lbl = true,
    object_range = 500,
    fly_enabled = false,
    fly_speed = 60,
    vehiclefly_enabled = false,
    jb_fly_enabled = false,
    -- UTILITY / FUN
    spinbot = false,
    mask_enabled = false,
    mask_display = "",
    noclip = false,
    cf_speed = false,
    cf_speed_val = 50,
    anti_afk = false,
    fullbright = false,
    click_tp = false,
    anti_fling = false,
}

local keybinds = {
    aimbot = {input = Enum.UserInputType.Keyboard, key = Enum.KeyCode.E},
    fling = {input = Enum.UserInputType.Keyboard, key = Enum.KeyCode.F},
    hide = {input = Enum.UserInputType.Keyboard, key = Enum.KeyCode.RightShift},
    fly = {input = Enum.UserInputType.Keyboard, key = Enum.KeyCode.G},
}
local key_state = {aimbot = false, fling = false, fly = false}

local fling_active = false
local fling_target = nil
local fling_return_cf = nil
local fling_conn = nil

local fly_conn = nil
local fly_velocity = nil
local fly_gyro = nil

local hitbox_originals = {}
local obj_esp_objs = {}
local troll_conn = nil
local spin_vel = nil
local noclip_conn = nil
local cf_speed_conn = nil
local anti_afk_conn = nil
local anti_fling_conn = nil

-- Fullbright originals
local orig_lighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
}

-- ============ TEARDOWN ============
local old = CoreGui:FindFirstChild("BSSToolkit")
if old then old:Destroy() end
if _G._bss_fling_conn then _G._bss_fling_conn:Disconnect(); _G._bss_fling_conn = nil end
if _G._bss_fling_weld then pcall(function() _G._bss_fling_weld:Destroy() end); _G._bss_fling_weld = nil end
if _G._bss_inf_jump then _G._bss_inf_jump:Disconnect(); _G._bss_inf_jump = nil end
if _G._bss_fly_conn then _G._bss_fly_conn:Disconnect(); _G._bss_fly_conn = nil end
if _G._bss_fly_vel then pcall(function() _G._bss_fly_vel:Destroy() end); _G._bss_fly_vel = nil end
if _G._bss_fly_gyro then pcall(function() _G._bss_fly_gyro:Destroy() end); _G._bss_fly_gyro = nil end

-- ============ HELPERS ============
local function make(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function corner(inst, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 6)}, inst)
    return inst
end

local function stroke(inst, color, thickness)
    make("UIStroke", {Color = color or COL_STROKE, Thickness = thickness or 1}, inst)
    return inst
end

local function get_root(p)
    p = p or player
    local char = p.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function parse_cframe(text)
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    local inner = text:match("CFrame%.new%s*%((.*)%)%s*$") or text
    local nums = {}
    for n in inner:gmatch("-?%d+%.?%d*[eE]?[-+]?%d*") do
        local v = tonumber(n)
        if v then table.insert(nums, v) end
    end
    if #nums == 3 then return CFrame.new(nums[1], nums[2], nums[3]) end
    if #nums == 12 then return CFrame.new(table.unpack(nums)) end
    return nil
end

local function same_team(a, b)
    if not a.Team or not b.Team then return false end
    return a.Team == b.Team
end

local function player_in_game(p)
    local char = p.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end
    if hum.Health <= 0 then return false end
    return true
end

-- base64
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64encode(data)
    return ((data:gsub('.', function(x)
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
        return b64chars:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end
local function b64decode(data)
    data = data:gsub('[^' .. b64chars .. '=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b64chars:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

-- ============ GUI SHELL ============
local gui = make("ScreenGui", {
    Name = "BSSToolkit",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
}, CoreGui)

local main = make("Frame", {
    Size = UDim2.new(0, 660, 0, 560),
    Position = UDim2.new(0.5, -330, 0.5, -280),
    BackgroundColor3 = COL_BG,
    BorderSizePixel = 0,
    Active = false,
}, gui)
corner(main, 10)
stroke(main)

local titleBar = make("Frame", {
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = COL_PANEL,
    BorderSizePixel = 0,
}, main)
corner(titleBar, 10)
make("TextLabel", {
    Size = UDim2.new(1, -140, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
    Text = "BSSToolkit",
    TextColor3 = COL_TEXT,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
}, titleBar)

local keybindLabel = make("TextLabel", {
    Size = UDim2.new(0, 130, 1, 0),
    Position = UDim2.new(1, -170, 0, 0),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = COL_TEXT_DIM,
    TextXAlignment = Enum.TextXAlignment.Right,
    Font = Enum.Font.Code,
    TextSize = 10,
}, titleBar)

local closeBtn = make("TextButton", {
    Size = UDim2.new(0, 28, 0, 22),
    Position = UDim2.new(1, -36, 0, 7),
    BackgroundColor3 = COL_DANGER,
    BorderSizePixel = 0,
    Text = "x",
    TextColor3 = Color3.fromRGB(240, 200, 200),
    Font = Enum.Font.GothamBold,
    TextSize = 13,
}, titleBar)
corner(closeBtn, 5)
closeBtn.MouseButton1Click:Connect(function()
    if state.fov_enabled then camera.FieldOfView = 70 end
    gui:Destroy()
end)

local dragging = false
local drag_start = nil
local drag_start_pos = nil
titleBar.InputBegan:Connect(function(io)
    if io.UserInputType == Enum.UserInputType.MouseButton1
        or io.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        drag_start = io.Position
        drag_start_pos = main.Position
        io:CaptureFocus()
    end
end)
UserInputService.InputChanged:Connect(function(io)
    if not dragging then return end
    if io.UserInputType == Enum.UserInputType.MouseMovement
        or io.UserInputType == Enum.UserInputType.Touch then
        local delta = io.Position - drag_start
        main.Position = UDim2.new(
            drag_start_pos.X.Scale, drag_start_pos.X.Offset + delta.X,
            drag_start_pos.Y.Scale, drag_start_pos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(io)
    if io.UserInputType == Enum.UserInputType.MouseButton1
        or io.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local tabs = {"ESP", "Teleport", "Aimbot", "Fling", "Hitbox", "Fun", "Utility"}
local tabBar = make("Frame", {
    Size = UDim2.new(1, 0, 0, 34),
    Position = UDim2.new(0, 0, 0, 36),
    BackgroundColor3 = COL_BG,
    BorderSizePixel = 0,
}, main)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, tabBar)

local tabButtons = {}
local tabPages = {}
for i, name in ipairs(tabs) do
    local btn = make("TextButton", {
        Size = UDim2.new(1 / #tabs, 0, 1, 0),
        BackgroundColor3 = COL_PANEL_ALT,
        BorderSizePixel = 0,
        Text = name,
        TextColor3 = COL_TEXT_DIM,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        LayoutOrder = i,
    }, tabBar)
    tabButtons[name] = btn
    local page = make("Frame", {
        Size = UDim2.new(1, -24, 1, -96),
        Position = UDim2.new(0, 12, 0, 82),
        BackgroundTransparency = 1,
        Visible = false,
    }, main)
    tabPages[name] = page
end

local function switch_tab(name)
    for n, btn in pairs(tabButtons) do
        if n == name then
            btn.BackgroundColor3 = COL_ACCENT
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabPages[n].Visible = true
        else
            btn.BackgroundColor3 = COL_PANEL_ALT
            btn.TextColor3 = COL_TEXT_DIM
            tabPages[n].Visible = false
        end
    end
end
for n, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function() switch_tab(n) end)
end
switch_tab("ESP")

-- ============ WIDGETS ============
local function section(parent, text, order)
    return make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = COL_TEXT,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        LayoutOrder = order or 0,
    }, parent)
end

local function toggle(parent, text, initial, callback, order)
    local row = make("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = COL_PANEL_ALT,
        BorderSizePixel = 0,
        LayoutOrder = order or 0,
    }, parent)
    corner(row, 5)
    make("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = COL_TEXT,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
        TextSize = 12,
    }, row)
    local track = make("Frame", {
        Size = UDim2.new(0, 36, 0, 18),
        Position = UDim2.new(1, -46, 0.5, -9),
        BackgroundColor3 = initial and COL_ACCENT or COL_PANEL,
        BorderSizePixel = 0,
    }, row)
    corner(track, 9); stroke(track)
    local knob = make("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = initial and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
        BackgroundColor3 = COL_TEXT,
        BorderSizePixel = 0,
    }, track)
    corner(knob, 7)
    local on = initial
    local hit = make("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    }, row)
    hit.MouseButton1Click:Connect(function()
        on = not on
        track.BackgroundColor3 = on and COL_ACCENT or COL_PANEL
        knob.Position = on and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        callback(on)
    end)
    return row
end

local function slider(parent, text, minv, maxv, initial, callback, order)
    local row = make("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = COL_PANEL_ALT,
        BorderSizePixel = 0,
        LayoutOrder = order or 0,
    }, parent)
    corner(row, 5)
    local label = make("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 10, 0, 4),
        BackgroundTransparency = 1,
        Text = text .. "  (" .. string.format("%.2f", initial) .. ")",
        TextColor3 = COL_TEXT,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
        TextSize = 12,
    }, row)
    local track = make("Frame", {
        Size = UDim2.new(1, -20, 0, 4),
        Position = UDim2.new(0, 10, 0, 30),
        BackgroundColor3 = COL_PANEL,
        BorderSizePixel = 0,
    }, row)
    corner(track, 2)
    local fill = make("Frame", {
        Size = UDim2.new((initial - minv) / (maxv - minv), 0, 1, 0),
        BackgroundColor3 = COL_ACCENT,
        BorderSizePixel = 0,
    }, track)
    corner(fill, 2)
    local thumb = make("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new((initial - minv) / (maxv - minv), -6, 0.5, -6),
        BackgroundColor3 = COL_TEXT,
        BorderSizePixel = 0,
    }, track)
    corner(thumb, 6)
    local grabbing = false
    local function set_from_x(px)
        local rel = math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = minv + rel * (maxv - minv)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        thumb.Position = UDim2.new(rel, -6, 0.5, -6)
        label.Text = text .. "  (" .. string.format("%.2f", val) .. ")"
        callback(val)
    end
    thumb.InputBegan:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 then
            grabbing = true; io:CaptureFocus()
        end
    end)
    UserInputService.InputChanged:Connect(function(io)
        if grabbing and io.UserInputType == Enum.UserInputType.MouseMovement then
            set_from_x(io.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 then grabbing = false end
    end)
    return row
end

local function button(parent, text, color, callback, order)
    local b = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = color or COL_PANEL_ALT,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = COL_TEXT,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        LayoutOrder = order or 0,
    }, parent)
    corner(b, 5)
    b.MouseButton1Click:Connect(callback)
    return b
end

local function textbox(parent, placeholder, order, initial)
    local t = make("TextBox", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = COL_PANEL,
        BorderSizePixel = 0,
        TextColor3 = COL_TEXT,
        PlaceholderText = placeholder,
        PlaceholderColor3 = COL_TEXT_DIM,
        Text = initial or "",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        ClearTextOnFocus = false,
        LayoutOrder = order or 0,
    }, parent)
    corner(t, 6)
    return t
end

local function scroll_col(parent)
    local s = make("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, parent)
    make("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, s)
    return s
end

local function split_two(parent)
    local left = make("Frame", {
        Size = UDim2.new(0.5, -6, 1, 0),
        BackgroundTransparency = 1,
    }, parent)
    local ls = scroll_col(left)
    local right = make("Frame", {
        Size = UDim2.new(0.5, -6, 1, 0),
        Position = UDim2.new(0.5, 6, 0, 0),
        BackgroundTransparency = 1,
    }, parent)
    local rs = scroll_col(right)
    return ls, rs
end

-- ============ DRAW LAYER ============
local draw_holder = make("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Active = false,
    ClipsDescendants = false,
}, gui)

local fovCircle = make("Frame", {
    Size = UDim2.new(0, state.aimbot_fov * 2, 0, state.aimbot_fov * 2),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 5,
}, draw_holder)
make("UICorner", {CornerRadius = UDim.new(1, 0)}, fovCircle)
make("UIStroke", {
    Color = COL_ACCENT, Thickness = 1.5, Transparency = 0.3,
}, fovCircle)

local function update_fov_circle()
    local d = state.aimbot_fov * 2
    fovCircle.Size = UDim2.new(0, d, 0, d)
    fovCircle.Visible = state.aimbot_enabled or state.object_aimbot_enabled
end
update_fov_circle()

-- ============ ESP ============
local esp_objects = {}

local function make_esp_for(p)
    local frame = make("Frame", {BackgroundTransparency = 1, Visible = false}, draw_holder)
    local box = make("Frame", {BackgroundTransparency = 1, Visible = false}, frame)
    local box_stroke = make("UIStroke", {Color = state.esp_color, Thickness = 1}, box)
    local nameLbl = make("TextLabel", {
        BackgroundTransparency = 1, TextColor3 = state.esp_color,
        Font = Enum.Font.GothamBold, TextSize = 12, TextStrokeTransparency = 0.4,
    }, frame)
    local distLbl = make("TextLabel", {
        BackgroundTransparency = 1, TextColor3 = state.esp_color,
        Font = Enum.Font.Gotham, TextSize = 11, TextStrokeTransparency = 0.4,
    }, frame)
    local tracer = make("Frame", {
        BackgroundColor3 = state.esp_color, BorderSizePixel = 0, Visible = false,
    }, frame)
    local skel = {}
    for i = 1, 16 do
        skel[i] = make("Frame", {
            BackgroundColor3 = Color3.fromRGB(200, 200, 210),
            BorderSizePixel = 0,
            Visible = false,
        }, frame)
    end
    esp_objects[p] = {
        root = frame, box = box, box_stroke = box_stroke,
        name = nameLbl, dist = distLbl,
        tracer = tracer, skel = skel,
    }
end

local function remove_esp_for(p)
    local o = esp_objects[p]
    if o and o.root then o.root:Destroy() end
    esp_objects[p] = nil
end

local function world_to_screen(pos)
    local sp, on = camera:WorldToViewportPoint(pos)
    if not on then return nil end
    return Vector2.new(sp.X, sp.Y), sp.Z
end

local function char_bounds(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hrp or not head then return nil end
    local pos_hrp, dist = world_to_screen(hrp.Position)
    local pos_head = world_to_screen(head.Position)
    if not pos_hrp or not pos_head then return nil end
    local top = pos_head.Y
    local bottom = pos_hrp.Y + (pos_hrp.Y - top) * 0.4
    local h = bottom - top
    local w = h * 0.5
    local cx = pos_hrp.X
    return Vector2.new(cx, (top + bottom) / 2), w, h, dist
end

local SKEL_R6 = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}
local SKEL_R15 = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}

local function draw_skeleton(o, char)
    local pairs_list = char:FindFirstChild("UpperTorso") and SKEL_R15 or SKEL_R6
    local idx = 0
    for _, pair in ipairs(pairs_list) do
        local a = char:FindFirstChild(pair[1])
        local b = char:FindFirstChild(pair[2])
        if a and b then
            local pa = world_to_screen(a.Position)
            local pb = world_to_screen(b.Position)
            if pa and pb then
                idx = idx + 1
                local line = o.skel[idx]
                if line then
                    local delta = pb - pa
                    local length = delta.Magnitude
                    line.Visible = true
                    line.Size = UDim2.new(0, length, 0, 1)
                    line.Position = UDim2.new(0, pa.X, 0, pa.Y)
                    line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
                end
            end
        end
    end
    for i = idx + 1, #o.skel do o.skel[i].Visible = false end
end

local function update_esp()
    for p, _ in pairs(esp_objects) do
        if not p.Parent or not p.Character then remove_esp_for(p) end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            if not esp_objects[p] then make_esp_for(p) end
            local o = esp_objects[p]
            local char = p.Character
            local use_color = state.esp_color
            if state.esp_team_color and p.Team then
                use_color = p.Team.TeamColor.Color
            end
            o.box_stroke.Color = use_color
            o.name.TextColor3 = use_color
            o.dist.TextColor3 = use_color
            o.tracer.BackgroundColor3 = use_color
            if state.esp_enabled and char and player_in_game(p) then
                local pos, w, h, dist = char_bounds(char)
                if pos and dist and dist <= state.esp_range then
                    o.root.Visible = true
                    if state.esp_box then
                        o.box.Visible = true
                        o.box.Size = UDim2.new(0, w, 0, h)
                        o.box.Position = UDim2.new(0, pos.X - w/2, 0, pos.Y - h/2)
                    else o.box.Visible = false end
                    if state.esp_name then
                        o.name.Visible = true
                        o.name.Text = p.Name
                        o.name.Size = UDim2.new(0, w * 2, 0, 14)
                        o.name.Position = UDim2.new(0, pos.X - w, 0, pos.Y - h/2 - 16)
                    else o.name.Visible = false end
                    if state.esp_distance then
                        o.dist.Visible = true
                        o.dist.Text = string.format("%d studs", dist)
                        o.dist.Size = UDim2.new(0, w * 2, 0, 12)
                        o.dist.Position = UDim2.new(0, pos.X - w, 0, pos.Y + h/2 + 2)
                    else o.dist.Visible = false end
                    if state.esp_tracers then
                        o.tracer.Visible = true
                        local vp = camera.ViewportSize
                        local startV = Vector2.new(vp.X/2, vp.Y)
                        local endV = Vector2.new(pos.X, pos.Y + h/2)
                        local delta = endV - startV
                        local length = delta.Magnitude
                        o.tracer.Size = UDim2.new(0, length, 0, 1)
                        o.tracer.Position = UDim2.new(0, startV.X, 0, startV.Y)
                        o.tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
                    else o.tracer.Visible = false end
                    if state.esp_skeleton then
                        draw_skeleton(o, char)
                    else
                        for _, line in ipairs(o.skel) do line.Visible = false end
                    end
                else
                    o.root.Visible = false
                end
            else
                o.root.Visible = false
            end
        end
    end
end

-- object esp
local function clear_object_esp()
    for inst, o in pairs(obj_esp_objs) do
        if o.frame then o.frame:Destroy() end
    end
    obj_esp_objs = {}
end

local function update_object_esp()
    if not state.object_esp_enabled or state.object_name == "" then
        clear_object_esp()
        return
    end
    local name = state.object_name
    local seen = {}
    local my_pos = get_root() and get_root().Position or Vector3.zero
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == name and obj:IsA("BasePart") then
            local dist = (obj.Position - my_pos).Magnitude
            if dist <= state.object_range then
                seen[obj] = true
                if not obj_esp_objs[obj] then
                    local frame = make("Frame", {BackgroundTransparency = 1, Visible = false}, draw_holder)
                    local box = make("Frame", {BackgroundTransparency = 1}, frame)
                    stroke(box, Color3.fromRGB(80, 200, 255), 1)
                    local label = make("TextLabel", {
                        BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(140, 220, 255),
                        Font = Enum.Font.GothamBold, TextSize = 11, TextStrokeTransparency = 0.4,
                    }, frame)
                    obj_esp_objs[obj] = {frame = frame, box = box, label = label}
                end
                local o = obj_esp_objs[obj]
                local pos, sdist = world_to_screen(obj.Position)
                if pos and sdist then
                    local scale = 800 / math.max(sdist, 1)
                    local h = math.clamp(scale, 8, 300)
                    local w = h
                    o.frame.Visible = true
                    o.box.Visible = state.object_box
                    o.box.Size = UDim2.new(0, w, 0, h)
                    o.box.Position = UDim2.new(0, pos.X - w/2, 0, pos.Y - h/2)
                    o.label.Visible = state.object_name_lbl
                    o.label.Text = obj.Name
                    o.label.Size = UDim2.new(0, w * 3, 0, 14)
                    o.label.Position = UDim2.new(0, pos.X - w*1.5, 0, pos.Y - h/2 - 16)
                else
                    o.frame.Visible = false
                end
            end
        end
    end
    for inst, o in pairs(obj_esp_objs) do
        if not seen[inst] then
            if o.frame then o.frame:Destroy() end
            obj_esp_objs[inst] = nil
        end
    end
end

-- ============ ESP TAB ============
local espLeft, espRight = split_two(tabPages["ESP"])
section(espLeft, "Player ESP", 1)
toggle(espLeft, "Enable ESP", false, function(on) state.esp_enabled = on end, 2)
toggle(espLeft, "Box", true, function(on) state.esp_box = on end, 3)
toggle(espLeft, "Name", true, function(on) state.esp_name = on end, 4)
toggle(espLeft, "Distance", true, function(on) state.esp_distance = on end, 5)
toggle(espLeft, "Tracers", false, function(on) state.esp_tracers = on end, 6)
toggle(espLeft, "Skeleton", false, function(on) state.esp_skeleton = on end, 7)
slider(espLeft, "Max range", 50, 2000, 500, function(v) state.esp_range = v end, 8)
toggle(espLeft, "Team color", false, function(on) state.esp_team_color = on end, 9)
section(espLeft, "Color", 10)
slider(espLeft, "Red", 0, 255, 255, function(v)
    state.esp_color = Color3.fromRGB(v, state.esp_color.G * 255, state.esp_color.B * 255)
end, 11)
slider(espLeft, "Green", 0, 255, 80, function(v)
    state.esp_color = Color3.fromRGB(state.esp_color.R * 255, v, state.esp_color.B * 255)
end, 12)
slider(espLeft, "Blue", 0, 255, 80, function(v)
    state.esp_color = Color3.fromRGB(state.esp_color.R * 255, state.esp_color.G * 255, v)
end, 13)
section(espLeft, "Camera", 20)
toggle(espLeft, "Enable FOV override", false, function(on) state.fov_enabled = on end, 21)
slider(espLeft, "FOV", 30, 120, 70, function(v) state.fov_value = v end, 22)

section(espRight, "Object ESP", 1)
toggle(espRight, "Enable object ESP", false, function(on)
    state.object_esp_enabled = on
    if not on then clear_object_esp() end
end, 2)
local obj_name_box = textbox(espRight, "object name (exact match)", 3, "")
obj_name_box:GetPropertyChangedSignal("Text"):Connect(function()
    state.object_name = obj_name_box.Text
end)
slider(espRight, "Object range", 50, 2000, 500, function(v) state.object_range = v end, 4)
toggle(espRight, "Object box", true, function(on) state.object_box = on end, 5)
toggle(espRight, "Object name label", true, function(on) state.object_name_lbl = on end, 6)

-- ============ TELEPORT TAB ============
local tpLeft, tpRight = split_two(tabPages["Teleport"])
section(tpLeft, "Players", 1)
local playerListFrame = make("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.Y,
    LayoutOrder = 2,
}, tpLeft)
make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, playerListFrame)

local function refresh_player_list()
    for _, c in ipairs(playerListFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for i, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            button(playerListFrame, p.Name, COL_PANEL_ALT, function()
                local root, target = get_root(), get_root(p)
                if root and target then root.CFrame = target.CFrame end
            end, i)
        end
    end
end
Players.PlayerAdded:Connect(refresh_player_list)
Players.PlayerRemoving:Connect(refresh_player_list)
refresh_player_list()

section(tpRight, "CFrame warp", 1)
local cfBox = make("TextBox", {
    Size = UDim2.new(1, 0, 0, 80),
    BackgroundColor3 = COL_PANEL,
    BorderSizePixel = 0,
    TextColor3 = COL_TEXT,
    PlaceholderText = "CFrame.new(...) or 3/12 numbers",
    PlaceholderColor3 = COL_TEXT_DIM,
    Text = "",
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Font = Enum.Font.Code,
    TextSize = 12,
    ClearTextOnFocus = false,
    LayoutOrder = 2,
}, tpRight)
corner(cfBox, 6)
make("UIPadding", {
    PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
    PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
}, cfBox)

local tpStatus = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = COL_OK,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    LayoutOrder = 3,
}, tpRight)

local function set_status(msg, ok)
    tpStatus.Text = msg
    tpStatus.TextColor3 = ok and COL_OK or COL_BAD
    task.delay(2.5, function() if tpStatus.Text == msg then tpStatus.Text = "" end end)
end

button(tpRight, "Teleport to CFrame", COL_ACCENT, function()
    local cf = parse_cframe(cfBox.Text)
    if not cf then set_status("couldn't parse cframe", false); return end
    local root = get_root()
    if not root then set_status("no character", false); return end
    root.CFrame = cf
    set_status("teleported", true)
end, 4)

local saveBox = textbox(tpRight, "name this spot...", 5, "")
local savedFrame = make("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.Y,
    LayoutOrder = 7,
}, tpRight)
make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, savedFrame)

local function rebuild_saved()
    for _, c in ipairs(savedFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for i, entry in ipairs(state.saved_spots) do
        local row = make("Frame", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = COL_PANEL_ALT,
            BorderSizePixel = 0,
            LayoutOrder = i,
        }, savedFrame)
        corner(row, 4)
        local nb = make("TextButton", {
            Size = UDim2.new(1, -36, 1, 0),
            BackgroundTransparency = 1,
            Text = "  " .. entry.name,
            TextColor3 = COL_TEXT,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.Gotham,
            TextSize = 12,
        }, row)
        nb.MouseButton1Click:Connect(function()
            local root = get_root()
            if root then root.CFrame = entry.cf; set_status("teleported to " .. entry.name, true) end
        end)
        local del = make("TextButton", {
            Size = UDim2.new(0, 28, 0, 22),
            Position = UDim2.new(1, -32, 0, 3),
            BackgroundColor3 = COL_DANGER,
            BorderSizePixel = 0,
            Text = "x",
            TextColor3 = Color3.fromRGB(230, 180, 180),
            Font = Enum.Font.GothamBold,
            TextSize = 12,
        }, row)
        corner(del, 4)
        del.MouseButton1Click:Connect(function()
            table.remove(state.saved_spots, i)
            rebuild_saved()
        end)
    end
end

button(tpRight, "Save spot", COL_PANEL_ALT, function()
    local cf = parse_cframe(cfBox.Text)
    if not cf then set_status("couldn't parse cframe", false); return end
    local name = saveBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then name = "spot " .. (#state.saved_spots + 1) end
    table.insert(state.saved_spots, {name = name, cf = cf})
    saveBox.Text = ""
    rebuild_saved()
    set_status("saved: " .. name, true)
end, 6)
rebuild_saved()

-- ============ AIMBOT TAB ============
local aimLeft, aimRight = split_two(tabPages["Aimbot"])
section(aimLeft, "Player aimbot", 1)
toggle(aimLeft, "Enable aimbot", false, function(on)
    state.aimbot_enabled = on
    update_fov_circle()
end, 2)
slider(aimLeft, "FOV (px)", 20, 500, 150, function(v)
    state.aimbot_fov = v
    update_fov_circle()
end, 3)
slider(aimLeft, "Max range", 50, 2000, 500, function(v) state.aimbot_range = v end, 4)
slider(aimLeft, "Smoothness", 0, 1, 0.35, function(v) state.aimbot_smooth = v end, 5)
slider(aimLeft, "Prediction", 0, 0.3, 0.05, function(v) state.aimbot_prediction = v end, 6)
toggle(aimLeft, "Team check", true, function(on) state.aimbot_teamcheck = on end, 7)
section(aimLeft, "Target part", 10)
toggle(aimLeft, "Head", true, function(on) state.aimbot_part = "Head" end, 11)
toggle(aimLeft, "HumanoidRootPart", false, function(on) state.aimbot_part = "HumanoidRootPart" end, 12)

section(aimRight, "Keybinds", 1)
local keybindButtons = {}
local function bind_label(b)
    local bind = keybinds[b]
    return bind.key.Name or bind.input.Name
end
local function keybind_button(parent, label, slot, order)
    local b = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = COL_PANEL_ALT,
        BorderSizePixel = 0,
        Text = label .. ":  " .. bind_label(slot),
        TextColor3 = COL_TEXT,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        LayoutOrder = order or 0,
    }, parent)
    corner(b, 5)
    keybindButtons[slot] = b
    b.MouseButton1Click:Connect(function()
        b.Text = label .. ":  ..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(io, gp)
            if gp then return end
            if io.UserInputType == Enum.UserInputType.Keyboard then
                keybinds[slot] = {input = Enum.UserInputType.Keyboard, key = io.KeyCode}
                b.Text = label .. ":  " .. io.KeyCode.Name
                conn:Disconnect(); update_keybind_label()
            elseif io.UserInputType == Enum.UserInputType.MouseButton1
                or io.UserInputType == Enum.UserInputType.MouseButton2 then
                keybinds[slot] = {input = io.UserInputType, key = io.KeyCode}
                b.Text = label .. ":  " .. io.UserInputType.Name
                conn:Disconnect(); update_keybind_label()
            end
        end)
    end)
    return b
end
function update_keybind_label()
    keybindLabel.Text = "aim:" .. bind_label("aimbot") .. "  fling:" .. bind_label("fling")
end
keybind_button(aimRight, "Aimbot hold", "aimbot", 2)
keybind_button(aimRight, "Fling hold", "fling", 3)
keybind_button(aimRight, "Fly toggle", "fly", 4)
update_keybind_label()

section(aimRight, "Object aimbot", 10)
toggle(aimRight, "Enable object aimbot", false, function(on)
    state.object_aimbot_enabled = on
    update_fov_circle()
end, 11)
local obj_aim_name = textbox(aimRight, "object name (exact match)", 12, "")
obj_aim_name:GetPropertyChangedSignal("Text"):Connect(function()
    state.object_name = obj_aim_name.Text
end)

local function nearest_target()
    local best, best_dist = nil, state.aimbot_fov
    local my_pos = get_root() and get_root().Position or Vector3.zero
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and not (state.aimbot_teamcheck and same_team(player, p)) and player_in_game(p) then
            local char = p.Character
            if char then
                local part = char:FindFirstChild(state.aimbot_part)
                if part then
                    local world_dist = (part.Position - my_pos).Magnitude
                    if world_dist <= state.aimbot_range then
                        local sp, onscreen = camera:WorldToViewportPoint(part.Position)
                        if onscreen and sp.Z > 0 then
                            local vp = camera.ViewportSize
                            local center = Vector2.new(vp.X/2, vp.Y/2)
                            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if d < best_dist then best_dist = d; best = part end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function nearest_object()
    if state.object_name == "" then return nil end
    local best, best_dist = nil, state.aimbot_fov
    local my_pos = get_root() and get_root().Position or Vector3.zero
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == state.object_name and obj:IsA("BasePart") then
            local world_dist = (obj.Position - my_pos).Magnitude
            if world_dist <= state.object_range then
                local sp, onscreen = camera:WorldToViewportPoint(obj.Position)
                if onscreen and sp.Z > 0 then
                    local vp = camera.ViewportSize
                    local center = Vector2.new(vp.X/2, vp.Y/2)
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < best_dist then best_dist = d; best = obj end
                end
            end
        end
    end
    return best
end

local function aim_step(dt)
    if not key_state.aimbot then return end
    local target
    if state.aimbot_enabled then
        target = nearest_target()
    end
    if not target and state.object_aimbot_enabled then
        target = nearest_object()
    end
    if not target then return end
    local aim_pos = target.Position
    if target.Parent and target.Parent:IsA("Model") then
        local hrp = target.Parent:FindFirstChild("HumanoidRootPart")
        if hrp then
            aim_pos = aim_pos + hrp.AssemblyLinearVelocity * state.aimbot_prediction
        end
    end
    local cam_pos = camera.CFrame.Position
    local target_cf = CFrame.lookAt(cam_pos, aim_pos)
    local current = camera.CFrame
    if state.aimbot_smooth <= 0.01 then
        camera.CFrame = target_cf
    else
        local alpha = 1 - (0.001 ^ (dt * 60))
        camera.CFrame = current:Lerp(target_cf, alpha * (1 - state.aimbot_smooth * 0.7))
    end
end

-- ============ FLING TAB ============
local flLeft, flRight = split_two(tabPages["Fling"])
section(flLeft, "Fling target", 1)
local flingListFrame = make("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.Y,
    LayoutOrder = 2,
}, flLeft)
make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, flingListFrame)

local function stop_fling()
    if fling_conn then fling_conn:Disconnect(); fling_conn = nil end
    if _G._bss_fling_weld then
        pcall(function() _G._bss_fling_weld:Destroy() end)
        _G._bss_fling_weld = nil
    end
    fling_active = false
    local root = get_root()
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    if state.fling_return and fling_return_cf then
        local r2 = get_root()
        if r2 then r2.CFrame = fling_return_cf end
    end
    fling_return_cf = nil
    fling_target = nil
end

local function start_fling(target_player)
    if fling_active then stop_fling() end
    local root = get_root()
    local target_root = get_root(target_player)
    if not root or not target_root then return end
    fling_target = target_player
    fling_return_cf = root.CFrame
    fling_active = true
    root.CFrame = target_root.CFrame
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = target_root
    weld.Parent = root
    _G._bss_fling_weld = weld
    local t = 0
    fling_conn = RunService.Heartbeat:Connect(function(dt)
        t = t + dt
        local r = get_root()
        local tr = get_root(target_player)
        if not r or not tr or not fling_active then
            stop_fling(); return
        end
        r.CFrame = tr.CFrame
        r.AssemblyAngularVelocity = Vector3.new(0, 15000, 0)
        r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end)
    task.delay(2.5, function() if fling_active and fling_target == target_player then stop_fling() end end)
end

local function refresh_fling_list()
    for _, c in ipairs(flingListFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for i, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            button(flingListFrame, "Fling " .. p.Name, COL_PANEL_ALT, function()
                start_fling(p)
            end, i)
        end
    end
end
Players.PlayerAdded:Connect(refresh_fling_list)
Players.PlayerRemoving:Connect(refresh_fling_list)
refresh_fling_list()

section(flRight, "Options", 1)
toggle(flRight, "Return to start after fling", true, function(on) state.fling_return = on end, 2)
button(flRight, "Stop fling", COL_DANGER, function() stop_fling() end, 3)

-- ============ HITBOX TAB ============
local hbLeft, hbRight = split_two(tabPages["Hitbox"])
section(hbLeft, "Hitbox expander", 1)
toggle(hbLeft, "Enable hitbox expander", false, function(on)
    state.hitbox_enabled = on
    if not on then
        for p, orig in pairs(hitbox_originals) do
            local char = p.Character
            if char then
                local part = char:FindFirstChild(orig.part)
                if part then
                    part.Size = orig.size
                    part.Transparency = orig.transparency
                    part.CanCollide = orig.cancollide
                end
            end
        end
        hitbox_originals = {}
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local char = p.Character
                if char then
                    local part = char:FindFirstChild(state.hitbox_part)
                    if part then
                        hitbox_originals[p] = {
                            part = state.hitbox_part,
                            size = part.Size,
                            transparency = part.Transparency,
                            cancollide = part.CanCollide,
                        }
                    end
                end
            end
        end
    end
end, 2)
toggle(hbLeft, "HumanoidRootPart", true, function(on)
    if on then state.hitbox_part = "HumanoidRootPart" end
end, 3)
toggle(hbLeft, "Head", false, function(on)
    if on then state.hitbox_part = "Head" end
end, 4)
slider(hbLeft, "Size", 1, 20, 6, function(v) state.hitbox_size = v end, 5)
slider(hbLeft, "Transparency", 0, 1, 0.5, function(v) state.hitbox_transparency = v end, 6)

local function apply_hitbox_to(p)
    local char = p.Character
    if not char then return end
    local part = char:FindFirstChild(state.hitbox_part)
    if not part then return end
    if not hitbox_originals[p] then
        hitbox_originals[p] = {
            part = state.hitbox_part,
            size = part.Size,
            transparency = part.Transparency,
            cancollide = part.CanCollide,
        }
    end
    local target_size = Vector3.new(state.hitbox_size, state.hitbox_size, state.hitbox_size)
    if part.Size ~= target_size then
        part.Size = target_size
        part.Transparency = state.hitbox_transparency
        part.CanCollide = false
    end
end

-- ============ FUN TAB ============
local funLeft, funRight = split_two(tabPages["Fun"])

section(funLeft, "Troll", 1)
local bangTarget = textbox(funLeft, "target player name...", 2, "")
button(funLeft, "Bang Target (Back n Forth)", COL_PANEL_ALT, function()
    local targetName = bangTarget.Text
    if targetName == "" then return end
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(targetName:lower()) then target = p break end
    end
    if target then
        local char = player.Character
        local t_char = target.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local t_root = t_char and t_char:FindFirstChild("HumanoidRootPart")
        if root and t_root then
            if troll_conn then troll_conn:Disconnect() end
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://131094575"
            sound.Volume = 2
            sound.Parent = t_root
            sound:Play()
            task.delay(2, function() sound:Destroy() end)
            
            local start_cf = root.CFrame
            troll_conn = RunService.RenderStepped:Connect(function()
                local r = get_root()
                local tr = get_root(target)
                if not r or not tr then 
                    if troll_conn then troll_conn:Disconnect(); troll_conn = nil end
                    if get_root() then get_root().CFrame = start_cf end
                    return 
                end
                local t = tick()
                local bang = math.sin(t * 20) * 3
                r.CFrame = tr.CFrame * CFrame.new(0, 0, 2) * CFrame.new(0, 0, bang)
            end)
            task.delay(3, function()
                if troll_conn then troll_conn:Disconnect(); troll_conn = nil end
                local r = get_root()
                if r then r.CFrame = start_cf end
            end)
        end
    end
end, 3)

section(funRight, "Dance", 1)
button(funRight, "Force Dance", COL_ACCENT, function()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://507770818" -- default dance
            local track = animator:LoadAnimation(anim)
            track:Play()
            task.delay(5, function() track:Stop() end)
        end
    end
end, 2)

section(funRight, "Mask (Display Name)", 10)
local dispBox = textbox(funRight, "fake display name...", 11, "")
toggle(funRight, "Enable Mask", false, function(on)
    state.mask_enabled = on
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if on and dispBox.Text ~= "" then
            state.mask_display = dispBox.Text
            hum.DisplayName = state.mask_display
            if not hum:FindFirstChild("MaskTag") then
                local tag = Instance.new("BillboardGui")
                tag.Name = "MaskTag"
                tag.Size = UDim2.new(0, 200, 0, 50)
                tag.StudsOffset = Vector3.new(0, 2.5, 0)
                tag.AlwaysOnTop = true
                tag.Parent = hum
                local text = Instance.new("TextLabel")
                text.Size = UDim2.new(1, 0, 1, 0)
                text.BackgroundTransparency = 1
                text.Text = state.mask_display
                text.TextColor3 = Color3.new(1, 1, 1)
                text.TextStrokeTransparency = 0
                text.Font = Enum.Font.GothamBold
                text.TextSize = 14
                text.Parent = tag
            end
        else
            hum.DisplayName = player.DisplayName
            local tag = hum:FindFirstChild("MaskTag")
            if tag then tag:Destroy() end
        end
    end
end, 12)

-- ============ FLY ============
local function stop_fly()
    if fly_conn then fly_conn:Disconnect(); fly_conn = nil end
    if fly_velocity then fly_velocity:Destroy(); fly_velocity = nil end
    if fly_gyro then fly_gyro:Destroy(); fly_gyro = nil end
end

local function start_fly(on_vehicle)
    stop_fly()
    local root
    if on_vehicle then
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        if seat then
            local vehicle = seat.Parent
            root = vehicle.PrimaryPart or vehicle:FindFirstChild("HumanoidRootPart") or vehicle:FindFirstChild("Base") or seat
        end
    end
    if not root then root = get_root() end
    if not root then return end
    fly_velocity = Instance.new("BodyVelocity")
    fly_velocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    fly_velocity.Velocity = Vector3.zero
    fly_velocity.Parent = root
    fly_gyro = Instance.new("BodyGyro")
    fly_gyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    fly_gyro.P = 1000
    fly_gyro.D = 50
    fly_gyro.Parent = root
    fly_conn = RunService.RenderStepped:Connect(function()
        local r = root
        if on_vehicle then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local seat = hum and hum.SeatPart
            if not seat then stop_fly(); return end
            local vehicle = seat.Parent
            r = vehicle.PrimaryPart or vehicle:FindFirstChild("HumanoidRootPart") or vehicle:FindFirstChild("Base") or seat
        else
            r = get_root()
        end
        if not r then stop_fly(); return end
        fly_gyro.CFrame = camera.CFrame
        local move = Vector3.zero
        local cam = camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
        local speed = state.fly_speed
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 2.5 end
        fly_velocity.Velocity = move.Magnitude > 0 and move.Unit * speed or Vector3.zero
    end)
end

local function start_jb_fly()
    stop_fly()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = false end
    task.wait(0.1)
    local root = get_root()
    if not root then return end
    fly_velocity = Instance.new("BodyVelocity")
    fly_velocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    fly_velocity.Velocity = Vector3.zero
    fly_velocity.Parent = root
    fly_gyro = Instance.new("BodyGyro")
    fly_gyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    fly_gyro.P = 1000
    fly_gyro.D = 50
    fly_gyro.Parent = root
    fly_conn = RunService.RenderStepped:Connect(function()
        local r = get_root()
        if not r then stop_fly(); return end
        fly_gyro.CFrame = camera.CFrame
        local move = Vector3.zero
        local cam = camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
        local speed = state.fly_speed
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 2.5 end
        fly_velocity.Velocity = move.Magnitude > 0 and move.Unit * speed or Vector3.zero
    end)
end

-- ============ CONFIG ============
local function export_config()
    local data = {}
    for k, v in pairs(state) do
        if k ~= "saved_spots" then
            if typeof(v) == "Color3" then
                data[k] = {r = v.R, g = v.G, b = v.B, __color = true}
            else
                data[k] = v
            end
        end
    end
    local json = HttpService:JSONEncode(data)
    return b64encode(json)
end

local function import_config(code)
    local ok, json = pcall(function() return b64decode(code) end)
    if not ok then return false, "decode failed" end
    local ok2, data = pcall(function() return HttpService:JSONDecode(json) end)
    if not ok2 then return false, "json failed" end
    for k, v in pairs(data) do
        if type(v) == "table" and v.__color then
            state[k] = Color3.new(v.r, v.g, v.b)
        elseif state[k] ~= nil then
            state[k] = v
        end
    end
    return true
end

-- ============ UTILITY TAB ============
local uScroll = scroll_col(tabPages["Utility"])
section(uScroll, "Movement", 1)
slider(uScroll, "WalkSpeed", 16, 200, 16, function(v)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end, 2)
toggle(uScroll, "Infinite Jump", false, function(on)
    if on then
        local conn
        conn = UserInputService.JumpRequest:Connect(function()
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
        _G._bss_inf_jump = conn
    else
        if _G._bss_inf_jump then _G._bss_inf_jump:Disconnect(); _G._bss_inf_jump = nil end
    end
end, 3)
toggle(uScroll, "Spinbot", false, function(on)
    state.spinbot = on
    if on then
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = false end
            spin_vel = Instance.new("BodyAngularVelocity")
            spin_vel.AngularVelocity = Vector3.new(0, 50, 0)
            spin_vel.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            spin_vel.P = 1000
            spin_vel.Parent = hrp
        end
    else
        if spin_vel then spin_vel:Destroy(); spin_vel = nil end
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
    end
end, 4)

toggle(uScroll, "Noclip", false, function(on)
    state.noclip = on
    if on then
        if noclip_conn then noclip_conn:Disconnect() end
        noclip_conn = RunService.Stepped:Connect(function()
            local char = player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclip_conn then noclip_conn:Disconnect(); noclip_conn = nil end
    end
end, 5)

toggle(uScroll, "CFrame Speed", false, function(on)
    state.cf_speed = on
    if on then
        if cf_speed_conn then cf_speed_conn:Disconnect() end
        cf_speed_conn = RunService.RenderStepped:Connect(function(dt)
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local move = Vector3.zero
                local cam = camera.CFrame
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.RightVector end
                if move.Magnitude > 0 then
                    hrp.CFrame = hrp.CFrame + move.Unit * (state.cf_speed_val * dt)
                end
            end
        end)
    else
        if cf_speed_conn then cf_speed_conn:Disconnect(); cf_speed_conn = nil end
    end
end, 6)
slider(uScroll, "CFrame Speed Value", 10, 300, 50, function(v) state.cf_speed_val = v end, 7)

section(uScroll, "Fly", 10)
toggle(uScroll, "Enable fly", false, function(on)
    state.fly_enabled = on
    if on then start_fly(false) else stop_fly() end
end, 11)
slider(uScroll, "Fly speed", 10, 300, 60, function(v) state.fly_speed = v end, 12)
toggle(uScroll, "Enable vehicle fly", false, function(on)
    state.vehiclefly_enabled = on
    if on then start_fly(true) else stop_fly() end
end, 13)
toggle(uScroll, "Jailbreak fly (unsits)", false, function(on)
    state.jb_fly_enabled = on
    if on then start_jb_fly() else stop_fly() end
end, 14)

section(uScroll, "Misc", 20)
toggle(uScroll, "Anti-AFK", false, function(on)
    state.anti_afk = on
    if on then
        if anti_afk_conn then anti_afk_conn:Disconnect() end
        anti_afk_conn = player.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    else
        if anti_afk_conn then anti_afk_conn:Disconnect(); anti_afk_conn = nil end
    end
end, 21)

toggle(uScroll, "Fullbright", false, function(on)
    state.fullbright = on
    if on then
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    else
        Lighting.Brightness = orig_lighting.Brightness
        Lighting.ClockTime = orig_lighting.ClockTime
        Lighting.GlobalShadows = orig_lighting.GlobalShadows
        Lighting.FogEnd = orig_lighting.FogEnd
    end
end, 22)

toggle(uScroll, "Click Teleport (L-Alt + Click)", false, function(on)
    state.click_tp = on
end, 23)

toggle(uScroll, "Anti-Fling", false, function(on)
    state.anti_fling = on
    if on then
        if anti_fling_conn then anti_fling_conn:Disconnect() end
        anti_fling_conn = RunService.Heartbeat:Connect(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, child in ipairs(hrp:GetChildren()) do
                if child:IsA("WeldConstraint") or child:IsA("Weld") then
                    local part0 = child.Part0
                    local part1 = child.Part1
                    if (part0 and part0.Parent ~= char and part0.Parent ~= nil) or 
                       (part1 and part1.Parent ~= char and part1.Parent ~= nil) then
                        child:Destroy()
                    end
                end
            end
            local vel = hrp.AssemblyLinearVelocity
            if vel.Magnitude > 100 then hrp.AssemblyLinearVelocity = Vector3.zero end
            local ang_vel = hrp.AssemblyAngularVelocity
            if ang_vel.Magnitude > 50 then hrp.AssemblyAngularVelocity = Vector3.zero end
        end)
    else
        if anti_fling_conn then anti_fling_conn:Disconnect(); anti_fling_conn = nil end
    end
end, 24)

section(uScroll, "Config", 30)
local configOut = make("TextBox", {
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundColor3 = COL_PANEL,
    BorderSizePixel = 0,
    TextColor3 = COL_TEXT,
    PlaceholderText = "config code appears here...",
    PlaceholderColor3 = COL_TEXT_DIM,
    Text = "",
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Font = Enum.Font.Code,
    TextSize = 10,
    ClearTextOnFocus = false,
    LayoutOrder = 31,
}, uScroll)
corner(configOut, 6)

button(uScroll, "Export config", COL_ACCENT, function()
    local code = export_config()
    configOut.Text = code
    if setclipboard then setclipboard(code) end
end, 32)

local configIn = textbox(uScroll, "paste config code here...", 33, "")
button(uScroll, "Import config", COL_PANEL_ALT, function()
    local ok, err = import_config(configIn.Text)
    if ok then
        configOut.Text = "imported. re-execute or toggle things to apply."
    else
        configOut.Text = "import failed: " .. tostring(err)
    end
end, 34)

section(uScroll, "Character", 40)
button(uScroll, "Reset character", COL_PANEL_ALT, function()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
end, 41)
button(uScroll, "Rejoin server", COL_DANGER, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, player)
end, 42)

-- ============ KEYBINDS ============
UserInputService.InputBegan:Connect(function(io, gp)
    if gp then return end
    
    if state.click_tp and io.KeyCode == Enum.KeyCode.LeftAlt and io.UserInputType == Enum.UserInputType.Keyboard then
        local mouse = player:GetMouse()
        if mouse.Target then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
            end
        end
    end

    local aim_bind = keybinds.aimbot
    local fling_bind = keybinds.fling
    local fly_bind = keybinds.fly
    local hide_bind = keybinds.hide
    if io.UserInputType == aim_bind.input and (io.KeyCode == aim_bind.key or aim_bind.input ~= Enum.UserInputType.Keyboard) then
        key_state.aimbot = true
    elseif io.UserInputType == fling_bind.input and (io.KeyCode == fling_bind.key or fling_bind.input ~= Enum.UserInputType.Keyboard) then
        key_state.fling = true
        local tgt = nearest_target()
        if not tgt and state.object_aimbot_enabled then
            local obj = nearest_object()
            if obj then
                local tp = Players:GetPlayerFromCharacter(obj.Parent)
                if tp then start_fling(tp) end
            end
        elseif tgt then
            local tp = Players:GetPlayerFromCharacter(tgt.Parent)
            if tp then start_fling(tp) end
        end
    elseif io.UserInputType == fly_bind.input and (io.KeyCode == fly_bind.key or fly_bind.input ~= Enum.UserInputType.Keyboard) then
        key_state.fly = not key_state.fly
        if key_state.fly then start_fly(false) else stop_fly() end
    elseif io.UserInputType == hide_bind.input and (io.KeyCode == hide_bind.key or hide_bind.input ~= Enum.UserInputType.Keyboard) then
        main.Visible = not main.Visible
    end
end)

UserInputService.InputEnded:Connect(function(io)
    local aim_bind = keybinds.aimbot
    local fling_bind = keybinds.fling
    if io.UserInputType == aim_bind.input and (io.KeyCode == aim_bind.key or aim_bind.input ~= Enum.UserInputType.Keyboard) then
        key_state.aimbot = false
    end
    if io.UserInputType == fling_bind.input and (io.KeyCode == fling_bind.key or fling_bind.input ~= Enum.UserInputType.Keyboard) then
        key_state.fling = false
    end
end)

-- ============ LOOPS ============
RunService.RenderStepped:Connect(function(dt)
    if state.fov_enabled then camera.FieldOfView = state.fov_value end
    update_esp()
    update_object_esp()
    update_fov_circle()
    aim_step(dt)
    if state.hitbox_enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then apply_hitbox_to(p) end
        end
    end
end)
