local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local orig_fov = camera.FieldOfView
local COL_BG = Color3.fromRGB(14, 14, 20)
local COL_PANEL = Color3.fromRGB(22, 22, 32)
local COL_PANEL_ALT = Color3.fromRGB(30, 30, 44)
local COL_PANEL_HOVER = Color3.fromRGB(42, 42, 60)
local COL_STROKE = Color3.fromRGB(55, 55, 80)
local COL_TEXT = Color3.fromRGB(235, 235, 250)
local COL_TEXT_DIM = Color3.fromRGB(140, 140, 165)
local COL_ACCENT = Color3.fromRGB(90, 170, 255)
local COL_OK = Color3.fromRGB(120, 220, 160)
local COL_BAD = Color3.fromRGB(255, 120, 130)
local COL_DANGER = Color3.fromRGB(220, 70, 90)
local COL_DANGER_HOVER = Color3.fromRGB(255, 90, 110)
local config_file = "BSSToolkit_Config.json"
local downloads_config = "Downloads/BSSToolkit_Config.json"

-- ==========================================
-- LOADING SCREEN
-- ==========================================
local loadingGui = Instance.new("ScreenGui")
loadingGui.Name = "BSS_Loading"
loadingGui.ResetOnSpawn = false
loadingGui.IgnoreGuiInset = true
loadingGui.DisplayOrder = 9999
loadingGui.Parent = CoreGui

local bg = Instance.new("Frame", loadingGui)
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
bg.BorderSizePixel = 0

local title = Instance.new("TextLabel", bg)
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0.4, 0)
title.BackgroundTransparency = 1
title.Text = "BSSToolkit"
title.TextColor3 = COL_ACCENT
title.Font = Enum.Font.GothamBlack
title.TextSize = 28

local status = Instance.new("TextLabel", bg)
status.Size = UDim2.new(1, 0, 0, 20)
status.Position = UDim2.new(0, 0, 0.45, 10)
status.BackgroundTransparency = 1
status.Text = "Starting..."
status.TextColor3 = COL_TEXT
status.Font = Enum.Font.Gotham
status.TextSize = 14

local barBg = Instance.new("Frame", bg)
barBg.Size = UDim2.new(0, 300, 0, 6)
barBg.Position = UDim2.new(0.5, -150, 0.5, 15)
barBg.BackgroundColor3 = COL_PANEL_ALT
barBg.BorderSizePixel = 0
local cornerBar = Instance.new("UICorner", barBg)
cornerBar.CornerRadius = UDim.new(1, 0)

local barFill = Instance.new("Frame", barBg)
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = COL_ACCENT
barFill.BorderSizePixel = 0
local cornerFill = Instance.new("UICorner", barFill)
cornerFill.CornerRadius = UDim.new(1, 0)

local function update_loading(text, pct)
    status.Text = text .. " (" .. tostring(pct) .. "%)"
    TweenService:Create(barFill, TweenInfo.new(0.3), {Size = UDim2.new(pct/100, 0, 1, 0)}):Play()
    task.wait(0.1)
end

-- ==========================================
-- MAIN SCRIPT VARIABLES
-- ==========================================
update_loading("Initializing variables", 5)

local top_conns = {}
local hit_sound_conns = {}
local function track(c)
    table.insert(top_conns, c)
    return c
end
local function tween(inst, props, time, style, dir)
    local ti = TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(inst, ti, props)
    t:Play()
    return t
end
local function lighten(c, amt)
    amt = amt or 25
    return Color3.fromRGB(
        math.min(255, c.R * 255 + amt),
        math.min(255, c.G * 255 + amt),
        math.min(255, c.B * 255 + amt)
    )
end

local state = {
    esp_enabled = false, esp_box = true, esp_name = true, esp_distance = true, esp_tracers = false, esp_skeleton = false, esp_color = Color3.fromRGB(255, 80, 80), esp_team_color = false, esp_range = 500,
    fov_enabled = false, fov_value = 70, saved_spots = {}, aimbot_enabled = false, aimbot_fov = 150, aimbot_smooth = 0.35, aimbot_part = "Head", aimbot_teamcheck = true, aimbot_range = 500, aimbot_prediction = 0.05, aimbot_snap = false, wallbang = false,
    triggerbot = false, hit_sound = false, fling_return = true, use_walkfling = false, hitbox_enabled = false, hitbox_part = "HumanoidRootPart", hitbox_look = "Box", hitbox_size = 6, hitbox_transparency = 0.5,
    object_name = "", object_esp_enabled = false, object_aimbot_enabled = false, object_box = true, object_name_lbl = true, object_range = 500, fly_enabled = false, fly_speed = 60, fly_mode = "Velocity",
    vehiclefly_enabled = false, vehicle_noclip = false, jb_fly_enabled = false, spinbot = false, spinbot_speed = 50, mask_enabled = false, mask_display = "", noclip = false, cf_speed = false, cf_speed_val = 50,
    anti_afk = false, fullbright = false, click_tp = false, anti_fling = false, float = false, swim = false, under_map = false, auto_farm = false, safe_fly = false, mm2_auto_shoot = false, mm2_auto_grab = false, grabbing_gun = false,
    rapid_fire = false, rapid_fire_delay = 0.1,
    xray_enabled = false, chams_enabled = false, rainbow_enabled = false, forcefield_enabled = false,
    jb_auto_rob = false, jb_auto_arrest = false, inf_jump = false, config_filename = "BSSToolkit_Config.json"
}

local ui_refs = { toggles = {}, sliders = {}, textboxes = {} }

local locked_target = nil
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
local hitbox_expanded = {}
local obj_esp_objs = {}
local troll_conn = nil
local spin_vel = nil
local noclip_conn = nil
local cf_speed_conn = nil
local anti_afk_conn = nil
local anti_fling_conn = nil
local float_conn = nil
local swim_conn = nil
local vehicle_noclip_conn = nil
local under_map_conn = nil
local auto_farm_conn = nil
local rapid_fire_task = nil
local main_render_conn = nil
local loop_tp_conn = nil
local xray_originals = {}
local chams_highlights = {}
local rainbow_task = nil
local rainbow_originals = {}
local orig_lighting = {
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, GlobalShadows = Lighting.GlobalShadows, FogEnd = Lighting.FogEnd,
}
local is_mm2 = game.PlaceId == 142823291

local function import_config(code)
    local ok, data = pcall(function() return HttpService:JSONDecode(code) end)
    if not ok then return false end
    for k, v in pairs(data) do
        if type(v) == "table" then
            if v.__color then
                state[k] = Color3.new(v.r, v.g, v.b)
            elseif v.__keybind then
                if keybinds[k] then
                    if v.keyName == "None" then
                        keybinds[k].key = nil
                    else
                        keybinds[k].key = Enum.KeyCode[v.keyName] or Enum.KeyCode.E
                    end
                    keybinds[k].input = Enum.UserInputType[v.inputName] or Enum.UserInputType.Keyboard
                end
            end
        elseif state[k] ~= nil then
            state[k] = v
        end
    end

    for _, item in ipairs(ui_refs.toggles) do
        if item.key and state[item.key] ~= nil then item.set(state[item.key]) end
    end
    for _, item in ipairs(ui_refs.sliders) do
        if item.key and state[item.key] ~= nil then item.set(state[item.key]) end
    end
    for _, item in ipairs(ui_refs.textboxes) do
        if item.key and state[item.key] ~= nil then item.set(state[item.key]) end
    end

    return true
end

-- Auto-load from Downloads or standard workspace
if isfile then
    local file_to_load = nil
    if isfile(downloads_config) then
        file_to_load = downloads_config
    elseif isfile(config_file) then
        file_to_load = config_file
    end
    
    if file_to_load then
        local ok, savedData = pcall(function() return readfile(file_to_load) end)
        if ok and savedData then
            import_config(savedData)
        end
    end
end

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
local function stroke(inst, color, thickness, transparency)
    make("UIStroke", {Color = color or COL_STROKE, Thickness = thickness or 1, Transparency = transparency or 0}, inst)
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
local function play_hit_sound()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://131094575"
    s.Volume = 0.6
    s.Parent = camera
    s:Play()
    task.delay(1, function() s:Destroy() end)
end
local function monitor_health(p)
    if p == player then return end
    if hit_sound_conns[p] then hit_sound_conns[p]:Disconnect() end
    local function bind_char(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hit_sound_conns[p] = hum.HealthChanged:Connect(function(newHealth)
                if state.hit_sound and newHealth < hum.MaxHealth then play_hit_sound() end
            end)
        end
    end
    if p.Character then bind_char(p.Character) end
    track(p.CharacterAdded:Connect(bind_char))
end
track(Players.PlayerAdded:Connect(monitor_health))
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= player then monitor_health(p) end
end

local function full_cleanup()
    pcall(function() RunService:UnbindFromRenderStep("BSSToolkitAim") end)
    if main_render_conn then main_render_conn:Disconnect(); main_render_conn = nil end
    if fling_conn then fling_conn:Disconnect(); fling_conn = nil end
    if fly_conn then fly_conn:Disconnect(); fly_conn = nil end
    if troll_conn then troll_conn:Disconnect(); troll_conn = nil end
    if noclip_conn then noclip_conn:Disconnect(); noclip_conn = nil end
    if cf_speed_conn then cf_speed_conn:Disconnect(); cf_speed_conn = nil end
    if anti_afk_conn then anti_afk_conn:Disconnect(); anti_afk_conn = nil end
    if anti_fling_conn then anti_fling_conn:Disconnect(); anti_fling_conn = nil end
    if float_conn then float_conn:Disconnect(); float_conn = nil end
    if swim_conn then swim_conn:Disconnect(); swim_conn = nil end
    if vehicle_noclip_conn then vehicle_noclip_conn:Disconnect(); vehicle_noclip_conn = nil end
    if under_map_conn then under_map_conn:Disconnect(); under_map_conn = nil end
    if auto_farm_conn then pcall(function() task.cancel(auto_farm_conn) end); auto_farm_conn = nil end
    if rapid_fire_task then pcall(function() task.cancel(rapid_fire_task) end); rapid_fire_task = nil end
    if loop_tp_conn then loop_tp_conn:Disconnect(); loop_tp_conn = nil end
    if rainbow_task then pcall(function() task.cancel(rainbow_task) end); rainbow_task = nil end
    for obj, orig in pairs(xray_originals) do if obj and obj.Parent then obj.Transparency = orig end end
    xray_originals = {}
    for p, hl in pairs(chams_highlights) do if hl and hl.Parent then pcall(function() hl:Destroy() end) end end
    chams_highlights = {}
    for part, orig in pairs(rainbow_originals) do if part and part.Parent then part.Color = orig end end
    rainbow_originals = {}
    for _, conn in pairs(hit_sound_conns) do conn:Disconnect() end
    hit_sound_conns = {}
    if spin_vel then spin_vel:Destroy(); spin_vel = nil end
    if fly_velocity then fly_velocity:Destroy(); fly_velocity = nil end
    if fly_gyro then fly_gyro:Destroy(); fly_gyro = nil end
    if _G._bss_fling_weld then pcall(function() _G._bss_fling_weld:Destroy() end); _G._bss_fling_weld = nil end
    if _G._bss_inf_jump then _G._bss_inf_jump:Disconnect(); _G._bss_inf_jump = nil end
    camera.FieldOfView = orig_fov
    Lighting.Brightness = orig_lighting.Brightness
    Lighting.ClockTime = orig_lighting.ClockTime
    Lighting.GlobalShadows = orig_lighting.GlobalShadows
    Lighting.FogEnd = orig_lighting.FogEnd
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.AutoRotate = true
        hum.PlatformStand = false
        hum.WalkSpeed = 16
    end
    local root = get_root()
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        local bv = root:FindFirstChild("FloatBV")
        if bv then bv:Destroy() end
    end
    for _, hb in pairs(hitbox_expanded) do if hb then hb:Destroy() end end
    hitbox_expanded = {}
    for _, o in pairs(esp_objects or {}) do if o and o.root then o.root:Destroy() end end
    for _, o in pairs(obj_esp_objs) do if o.frame then o.frame:Destroy() end end
    obj_esp_objs = {}
    if _G._bss_aim_debug_lbl then pcall(function() _G._bss_aim_debug_lbl:Destroy() end); _G._bss_aim_debug_lbl = nil end
    for _, c in ipairs(top_conns) do pcall(function() c:Disconnect() end) end
    top_conns = {}
    key_state.aimbot = false
    key_state.fling = false
    key_state.fly = false
    fling_active = false
end

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
    for k, v in pairs(keybinds) do
        data[k] = {keyName = v.key and v.key.Name or "None", inputName = v.input.Name, __keybind = true}
    end
    return HttpService:JSONEncode(data)
end

-- ==========================================
-- WALLBANG HOOK
-- ==========================================
local hooked_raycast = false
local function hook_wallbang()
    if hooked_raycast or not hookfunction then return end
    hooked_raycast = true
    local old_raycast = Workspace.Raycast
    hookfunction(old_raycast, newcclosure(function(self, origin, direction, params)
        if state.wallbang then
            local targets = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    table.insert(targets, p.Character)
                end
            end
            local new_params = RaycastParams.new()
            new_params.FilterType = Enum.RaycastFilterType.Include
            new_params.FilterDescendantsInstances = targets
            new_params.IgnoreWater = true
            return old_raycast(self, origin, direction, new_params)
        end
        return old_raycast(self, origin, direction, params)
    end))
end

-- ==========================================
-- UI CREATION
-- ==========================================
update_loading("Building main window", 25)

local gui = make("ScreenGui", {Name = "BSSToolkit", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true}, CoreGui)
local shadow = make("Frame", {Size = UDim2.new(0, 660, 0, 560), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 3, 0.5, 5), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.55, BorderSizePixel = 0}, gui)
corner(shadow, 12)
local main = make("Frame", {Size = UDim2.new(0, 660, 0, 560), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = COL_BG, BorderSizePixel = 0, Active = false, ClipsDescendants = true, Visible = false}, gui)
corner(main, 10)
stroke(main, COL_STROKE, 1.5)
local main_scale = make("UIScale", {Scale = 0.85}, main)

local titleBar = make("Frame", {Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = COL_PANEL, BorderSizePixel = 0}, main)
corner(titleBar, 10)
make("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = COL_ACCENT, BorderSizePixel = 0, BackgroundTransparency = 0.4}, titleBar)
local titleText = make("TextLabel", {Size = UDim2.new(1, -140, 1, 0), Position = UDim2.new(0, 16, 0, 0), BackgroundTransparency = 1, Text = "BSSToolkit", TextColor3 = COL_TEXT, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBlack, TextSize = 15}, titleBar)
make("UIStroke", {Color = COL_ACCENT, Thickness = 1, Transparency = 0.7}, titleText)
local keybindLabel = make("TextLabel", {Size = UDim2.new(0, 130, 1, 0), Position = UDim2.new(1, -170, 0, 0), BackgroundTransparency = 1, Text = "", TextColor3 = COL_TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.Code, TextSize = 10}, titleBar)
local closeBtn = make("TextButton", {Size = UDim2.new(0, 28, 0, 22), Position = UDim2.new(1, -36, 0, 8), BackgroundColor3 = COL_DANGER, BorderSizePixel = 0, Text = "x", TextColor3 = Color3.fromRGB(255, 220, 220), Font = Enum.Font.GothamBold, TextSize = 13}, titleBar)
corner(closeBtn, 5)
closeBtn.MouseEnter:Connect(function() tween(closeBtn, {BackgroundColor3 = COL_DANGER_HOVER}, 0.12) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, {BackgroundColor3 = COL_DANGER}, 0.12) end)
closeBtn.MouseButton1Click:Connect(function()
    tween(main_scale, {Scale = 0.85}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    tween(shadow, {BackgroundTransparency = 1}, 0.15)
    task.delay(0.15, function()
        full_cleanup()
        gui:Destroy()
    end)
end)
local dragging = false
local drag_start = nil
local drag_start_pos = nil
titleBar.InputBegan:Connect(function(io)
    if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        drag_start = io.Position
        drag_start_pos = main.Position
        io:CaptureFocus()
    end
end)
track(UserInputService.InputChanged:Connect(function(io)
    if not dragging then return end
    if io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch then
        local delta = io.Position - drag_start
        local newPos = UDim2.new(drag_start_pos.X.Scale, drag_start_pos.X.Offset + delta.X, drag_start_pos.Y.Scale, drag_start_pos.Y.Offset + delta.Y)
        main.Position = newPos
        shadow.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset + 3, newPos.Y.Scale, newPos.Y.Offset + 5)
    end
end))
track(UserInputService.InputEnded:Connect(function(io)
    if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then dragging = false end
end))

-- ==========================================
-- TAB BAR & HELPERS
-- ==========================================
update_loading("Building tabs", 35)

local tabs = {"ESP", "Teleport", "Aimbot", "Fling", "Hitbox", "Exploits", "Fun", "Utility"}
if is_mm2 then table.insert(tabs, "MM2") end
local tabBar = make("Frame", {Size = UDim2.new(1, -20, 0, 34), Position = UDim2.new(0, 10, 0, 38), BackgroundColor3 = COL_BG, BorderSizePixel = 0}, main)
make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)}, tabBar)
local tabButtons = {}
local tabPages = {}
for i, name in ipairs(tabs) do
    local btn = make("TextButton", {Size = UDim2.new(1 / #tabs, -4, 1, -6), Position = UDim2.new(0, 0, 0, 3), BackgroundColor3 = COL_PANEL_ALT, BorderSizePixel = 0, Text = name, TextColor3 = COL_TEXT_DIM, Font = Enum.Font.GothamBold, TextSize = 11, LayoutOrder = i, AutoButtonColor = false}, tabBar)
    corner(btn, 6)
    tabButtons[name] = btn
    local page = make("Frame", {Size = UDim2.new(1, -24, 1, -96), Position = UDim2.new(0, 12, 0, 82), BackgroundTransparency = 1, Visible = false}, main)
    tabPages[name] = page
    btn.MouseEnter:Connect(function() if not page.Visible then tween(btn, {BackgroundColor3 = COL_PANEL_HOVER}, 0.12) end end)
    btn.MouseLeave:Connect(function() if not page.Visible then tween(btn, {BackgroundColor3 = COL_PANEL_ALT}, 0.12) end end)
end
local function switch_tab(name)
    for n, btn in pairs(tabButtons) do
        local active = (n == name)
        tween(btn, {BackgroundColor3 = active and COL_ACCENT or COL_PANEL_ALT}, 0.18)
        tween(btn, {TextColor3 = active and Color3.fromRGB(255, 255, 255) or COL_TEXT_DIM}, 0.18)
        tabPages[n].Visible = active
    end
end
for n, btn in pairs(tabButtons) do btn.MouseButton1Click:Connect(function() switch_tab(n) end) end
switch_tab("ESP")

local function section(parent, text, order)
    local row = make("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = order or 0}, parent)
    local bar = make("Frame", {Size = UDim2.new(0, 3, 0, 14), Position = UDim2.new(0, 0, 0.5, -7), BackgroundColor3 = COL_ACCENT, BorderSizePixel = 0}, row)
    corner(bar, 2)
    make("TextLabel", {Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = COL_TEXT, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 12}, row)
    return row
end

local function toggle(parent, text, initial, callback, order, state_key)
    local actual_initial = initial
    if state_key and state[state_key] ~= nil then actual_initial = state[state_key] end
    local row = make("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = COL_PANEL_ALT, BorderSizePixel = 0, LayoutOrder = order or 0}, parent)
    corner(row, 6)
    make("TextLabel", {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = COL_TEXT, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 12}, row)
    local track_ui = make("Frame", {Size = UDim2.new(0, 36, 0, 18), Position = UDim2.new(1, -46, 0.5, -9), BackgroundColor3 = actual_initial and COL_ACCENT or COL_PANEL, BorderSizePixel = 0}, row)
    corner(track_ui, 9)
    stroke(track_ui, COL_STROKE, 1)
    local knob = make("Frame", {Size = UDim2.new(0, 14, 0, 14), Position = actual_initial and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = COL_TEXT, BorderSizePixel = 0}, track_ui)
    corner(knob, 7)
    local state_on = actual_initial
    local function set_val(val)
        state_on = val
        tween(track_ui, {BackgroundColor3 = state_on and COL_ACCENT or COL_PANEL}, 0.2)
        tween(knob, {Position = state_on and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}, 0.2, Enum.EasingStyle.Quad)
        callback(val)
    end
    local hit = make("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false}, row)
    hit.MouseEnter:Connect(function() tween(row, {BackgroundColor3 = COL_PANEL_HOVER}, 0.12) end)
    hit.MouseLeave:Connect(function() tween(row, {BackgroundColor3 = COL_PANEL_ALT}, 0.12) end)
    hit.MouseButton1Click:Connect(function() set_val(not state_on) end)
    if state_key then table.insert(ui_refs.toggles, {key = state_key, set = set_val}) end
    return row
end

local function slider(parent, text, minv, maxv, initial, callback, order, state_key)
    local actual_initial = initial
    if state_key and state[state_key] ~= nil then actual_initial = state[state_key] end
    local row = make("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = COL_PANEL_ALT, BorderSizePixel = 0, LayoutOrder = order or 0}, parent)
    corner(row, 6)
    local label = make("TextLabel", {Size = UDim2.new(1, -20, 0, 18), Position = UDim2.new(0, 12, 0, 5), BackgroundTransparency = 1, Text = text .. "  (" .. string.format("%.2f", actual_initial) .. ")", TextColor3 = COL_TEXT, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 12}, row)
    local track_ui = make("Frame", {Size = UDim2.new(1, -24, 0, 4), Position = UDim2.new(0, 12, 0, 32), BackgroundColor3 = COL_PANEL, BorderSizePixel = 0}, row)
    corner(track_ui, 2)
    local fill = make("Frame", {Size = UDim2.new((actual_initial - minv) / (maxv - minv), 0, 1, 0), BackgroundColor3 = COL_ACCENT, BorderSizePixel = 0}, track_ui)
    corner(fill, 2)
    local thumb = make("Frame", {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new((actual_initial - minv) / (maxv - minv), -7, 0.5, -7), BackgroundColor3 = COL_TEXT, BorderSizePixel = 0}, track_ui)
    corner(thumb, 7)
    local thumb_stroke = make("UIStroke", {Color = COL_ACCENT, Thickness = 1.5, Transparency = 0.5}, thumb)
    local grabbing = false
    local function set_val(val)
        local rel = math.clamp((val - minv) / (maxv - minv), 0, 1)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        thumb.Position = UDim2.new(rel, -7, 0.5, -7)
        label.Text = text .. "  (" .. string.format("%.2f", val) .. ")"
        callback(val)
    end
    local function set_from_x(px)
        local rel = math.clamp((px - track_ui.AbsolutePosition.X) / track_ui.AbsoluteSize.X, 0, 1)
        set_val(minv + rel * (maxv - minv))
    end
    thumb.InputBegan:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 then
            grabbing = true
            tween(thumb_stroke, {Transparency = 0}, 0.12)
            tween(thumb, {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(thumb.Position.X.Scale, -8, 0.5, -8)}, 0.12)
            io:CaptureFocus()
        end
    end)
    track(UserInputService.InputChanged:Connect(function(io)
        if grabbing and io.UserInputType == Enum.UserInputType.MouseMovement then set_from_x(io.Position.X) end
    end))
    track(UserInputService.InputEnded:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 then
            grabbing = false
            tween(thumb_stroke, {Transparency = 0.5}, 0.12)
            tween(thumb, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(thumb.Position.X.Scale, -7, 0.5, -7)}, 0.12)
        end
    end))
    if state_key then table.insert(ui_refs.sliders, {key = state_key, set = set_val}) end
    return row
end

local function button(parent, text, color, callback, order)
    local base = color or COL_PANEL_ALT
    local hover = lighten(base, 22)
    local b = make("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = base, BorderSizePixel = 0, Text = text, TextColor3 = COL_TEXT, Font = Enum.Font.GothamBold, TextSize = 12, LayoutOrder = order or 0, AutoButtonColor = false}, parent)
    corner(b, 6)
    b.MouseEnter:Connect(function() tween(b, {BackgroundColor3 = hover}, 0.12) end)
    b.MouseLeave:Connect(function() tween(b, {BackgroundColor3 = base}, 0.12) end)
    b.MouseButton1Click:Connect(function()
        tween(b, {BackgroundColor3 = lighten(base, 45)}, 0.05)
        task.delay(0.08, function() tween(b, {BackgroundColor3 = hover}, 0.12) end)
        callback()
    end)
    return b
end

local function textbox(parent, placeholder, order, initial, state_key)
    local actual_initial = initial
    if state_key and state[state_key] ~= nil then actual_initial = state[state_key] end
    local t = make("TextBox", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = COL_PANEL, BorderSizePixel = 0, TextColor3 = COL_TEXT, PlaceholderText = placeholder, PlaceholderColor3 = COL_TEXT_DIM, Text = actual_initial or "", Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false, LayoutOrder = order or 0}, parent)
    corner(t, 6)
    local s = make("UIStroke", {Color = COL_STROKE, Thickness = 1, Transparency = 0.3}, t)
    t.Focused:Connect(function() tween(s, {Color = COL_ACCENT, Transparency = 0}, 0.15) end)
    t.FocusLost:Connect(function() tween(s, {Color = COL_STROKE, Transparency = 0.3}, 0.15) end)
    if state_key then table.insert(ui_refs.textboxes, {key = state_key, set = function(val) t.Text = val end}) end
    return t
end

local function scroll_col(parent)
    local s = make("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarImageColor3 = COL_ACCENT}, parent)
    make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, s)
    return s
end
local function split_two(parent)
    local left = make("Frame", {Size = UDim2.new(0.5, -6, 1, 0), BackgroundTransparency = 1}, parent)
    local ls = scroll_col(left)
    local right = make("Frame", {Size = UDim2.new(0.5, -6, 1, 0), Position = UDim2.new(0.5, 6, 0, 0), BackgroundTransparency = 1}, parent)
    local rs = scroll_col(right)
    return ls, rs
end

-- ==========================================
-- ESP & DRAWING
-- ==========================================
update_loading("Building ESP elements", 50)

local draw_holder = make("Frame", {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, Active = false, ClipsDescendants = false}, gui)
local fovCircle = make("Frame", {Size = UDim2.new(0, state.aimbot_fov * 2, 0, state.aimbot_fov * 2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 5}, draw_holder)
make("UICorner", {CornerRadius = UDim.new(1, 0)}, fovCircle)
make("UIStroke", {Color = COL_ACCENT, Thickness = 1.5, Transparency = 0.35}, fovCircle)
local function update_fov_circle()
    local d = state.aimbot_fov * 2
    fovCircle.Size = UDim2.new(0, d, 0, d)
    fovCircle.Visible = state.aimbot_enabled or state.object_aimbot_enabled
end
update_fov_circle()
local esp_objects = {}
local function make_esp_for(p)
    local frame = make("Frame", {BackgroundTransparency = 1, Visible = false}, draw_holder)
    local box = make("Frame", {BackgroundTransparency = 1, Visible = false, AnchorPoint = Vector2.new(0.5, 0.5)}, frame)
    local box_stroke = make("UIStroke", {Color = state.esp_color, Thickness = 1}, box)
    local nameLbl = make("TextLabel", {BackgroundTransparency = 1, TextColor3 = state.esp_color, Font = Enum.Font.GothamBold, TextSize = 12, TextStrokeTransparency = 0.4, AnchorPoint = Vector2.new(0.5, 0.5)}, frame)
    local distLbl = make("TextLabel", {BackgroundTransparency = 1, TextColor3 = state.esp_color, Font = Enum.Font.Gotham, TextSize = 11, TextStrokeTransparency = 0.4, AnchorPoint = Vector2.new(0.5, 0.5)}, frame)
    local tracer = make("Frame", {BackgroundColor3 = state.esp_color, BorderSizePixel = 0, Visible = false, AnchorPoint = Vector2.new(0, 0.5)}, frame)
    local skel = {}
    for i = 1, 16 do
        skel[i] = make("Frame", {BackgroundColor3 = Color3.fromRGB(200, 200, 210), BorderSizePixel = 0, Visible = false, AnchorPoint = Vector2.new(0, 0.5)}, frame)
    end
    esp_objects[p] = {root = frame, box = box, box_stroke = box_stroke, name = nameLbl, dist = distLbl, tracer = tracer, skel = skel}
end
local function remove_esp_for(p)
    local o = esp_objects[p]
    if o and o.root then o.root:Destroy() end
    esp_objects[p] = nil
end
local function char_bounds(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local cam = Workspace.CurrentCamera
    local sp, onscreen = cam:WorldToViewportPoint(hrp.Position)
    if not onscreen or sp.Z <= 0 then return nil end
    local dist = (cam.CFrame.Position - hrp.Position).Magnitude
    local h = 1200 / math.max(dist, 1)
    local w = h * 0.6
    return Vector2.new(sp.X, sp.Y), w, h, dist
end
local SKEL_R6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}
local SKEL_R15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local function draw_skeleton(o, char)
    local pairs_list = char:FindFirstChild("UpperTorso") and SKEL_R15 or SKEL_R6
    local idx = 0
    for _, pair in ipairs(pairs_list) do
        local a = char:FindFirstChild(pair[1])
        local b = char:FindFirstChild(pair[2])
        if a and b then
            local cam = Workspace.CurrentCamera
            local sp_a, on_a = cam:WorldToViewportPoint(a.Position)
            local sp_b, on_b = cam:WorldToViewportPoint(b.Position)
            if on_a and on_b then
                idx = idx + 1
                local line = o.skel[idx]
                if line then
                    local pa = Vector2.new(sp_a.X, sp_a.Y)
                    local pb = Vector2.new(sp_b.X, sp_b.Y)
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
            if state.esp_team_color and p.Team then use_color = p.Team.TeamColor.Color end
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
                        o.box.Position = UDim2.new(0, pos.X, 0, pos.Y)
                    else o.box.Visible = false end
                    if state.esp_name then
                        o.name.Visible = true
                        o.name.Text = p.Name
                        o.name.Size = UDim2.new(0, 200, 0, 14)
                        o.name.Position = UDim2.new(0, pos.X, 0, pos.Y - h/2 - 10)
                    else o.name.Visible = false end
                    if state.esp_distance then
                        o.dist.Visible = true
                        o.dist.Text = string.format("%d studs", dist)
                        o.dist.Size = UDim2.new(0, 200, 0, 12)
                        o.dist.Position = UDim2.new(0, pos.X, 0, pos.Y + h/2 + 10)
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
local function clear_object_esp()
    for inst, o in pairs(obj_esp_objs) do if o.frame then o.frame:Destroy() end end
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
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == name and obj:IsA("BasePart") then
            local dist = (obj.Position - my_pos).Magnitude
            if dist <= state.object_range then
                seen[obj] = true
                if not obj_esp_objs[obj] then
                    local frame = make("Frame", {BackgroundTransparency = 1, Visible = false}, draw_holder)
                    local box = make("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5)}, frame)
                    stroke(box, Color3.fromRGB(80, 200, 255), 1)
                    local label = make("TextLabel", {BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(140, 220, 255), Font = Enum.Font.GothamBold, TextSize = 11, TextStrokeTransparency = 0.4, AnchorPoint = Vector2.new(0.5, 0.5)}, frame)
                    obj_esp_objs[obj] = {frame = frame, box = box, label = label}
                end
                local o = obj_esp_objs[obj]
                local cam = Workspace.CurrentCamera
                local sp, onscreen = cam:WorldToViewportPoint(obj.Position)
                if onscreen then
                    local scale = 800 / math.max(dist, 1)
                    local h = math.clamp(scale, 8, 300)
                    local w = h
                    o.frame.Visible = true
                    o.box.Visible = state.object_box
                    o.box.Size = UDim2.new(0, w, 0, h)
                    o.box.Position = UDim2.new(0, sp.X, 0, sp.Y)
                    o.label.Visible = state.object_name_lbl
                    o.label.Text = obj.Name
                    o.label.Size = UDim2.new(0, 150, 0, 14)
                    o.label.Position = UDim2.new(0, sp.X, 0, sp.Y - h/2 - 10)
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

-- ==========================================
-- TAB BUILDER: ESP & TELEPORT
-- ==========================================
update_loading("Building ESP UI", 60)

local espLeft, espRight = split_two(tabPages["ESP"])
section(espLeft, "Player ESP", 1)
toggle(espLeft, "Enable ESP", false, function(on) state.esp_enabled = on end, 2, "esp_enabled")
toggle(espLeft, "Box", true, function(on) state.esp_box = on end, 3, "esp_box")
toggle(espLeft, "Name", true, function(on) state.esp_name = on end, 4, "esp_name")
toggle(espLeft, "Distance", true, function(on) state.esp_distance = on end, 5, "esp_distance")
toggle(espLeft, "Tracers", false, function(on) state.esp_tracers = on end, 6, "esp_tracers")
toggle(espLeft, "Skeleton", false, function(on) state.esp_skeleton = on end, 7, "esp_skeleton")
slider(espLeft, "Max range", 50, 2000, 500, function(v) state.esp_range = v end, 8, "esp_range")
toggle(espLeft, "Team color", false, function(on) state.esp_team_color = on end, 9, "esp_team_color")
section(espLeft, "Color", 10)
slider(espLeft, "Red", 0, 255, 255, function(v) state.esp_color = Color3.fromRGB(v, state.esp_color.G * 255, state.esp_color.B * 255) end, 11)
slider(espLeft, "Green", 0, 255, 80, function(v) state.esp_color = Color3.fromRGB(state.esp_color.R * 255, v, state.esp_color.B * 255) end, 12)
slider(espLeft, "Blue", 0, 255, 80, function(v) state.esp_color = Color3.fromRGB(state.esp_color.R * 255, state.esp_color.G * 255, v) end, 13)
section(espLeft, "Camera", 20)
toggle(espLeft, "Enable FOV override", false, function(on) state.fov_enabled = on end, 21, "fov_enabled")
slider(espLeft, "FOV", 30, 120, 70, function(v) state.fov_value = v end, 22, "fov_value")
section(espRight, "Object ESP", 1)
toggle(espRight, "Enable object ESP", false, function(on)
    state.object_esp_enabled = on
    if not on then clear_object_esp() end
end, 2, "object_esp_enabled")
local obj_name_box = textbox(espRight, "object name (exact match)", 3, "", "object_name")
obj_name_box:GetPropertyChangedSignal("Text"):Connect(function() state.object_name = obj_name_box.Text end)
slider(espRight, "Object range", 50, 2000, 500, function(v) state.object_range = v end, 4, "object_range")
toggle(espRight, "Object box", true, function(on) state.object_box = on end, 5, "object_box")
toggle(espRight, "Object name label", true, function(on) state.object_name_lbl = on end, 6, "object_name_lbl")

local tpLeft, tpRight = split_two(tabPages["Teleport"])
section(tpLeft, "Players", 1)
local playerListFrame = make("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2}, tpLeft)
make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, playerListFrame)
local function refresh_player_list()
    for _, c in ipairs(playerListFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for i, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            button(playerListFrame, p.Name, COL_PANEL_ALT, function()
                local root, target = get_root(), get_root(p)
                if root and target then root.CFrame = target.CFrame end
            end, i)
        end
    end
end
track(Players.PlayerAdded:Connect(refresh_player_list))
track(Players.PlayerRemoving:Connect(refresh_player_list))
refresh_player_list()
section(tpRight, "CFrame warp", 1)
local cfBox = make("TextBox", {Size = UDim2.new(1, 0, 0, 80), BackgroundColor3 = COL_PANEL, BorderSizePixel = 0, TextColor3 = COL_TEXT, PlaceholderText = "CFrame.new(...) or 3/12 numbers", PlaceholderColor3 = COL_TEXT_DIM, Text = "", TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Code, TextSize = 12, ClearTextOnFocus = false, LayoutOrder = 2}, tpRight)
corner(cfBox, 6)
make("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, cfBox)
local tpStatus = make("TextLabel", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "", TextColor3 = COL_OK, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 12, LayoutOrder = 3}, tpRight)
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
local savedFrame = make("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 7}, tpRight)
make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, savedFrame)
local function rebuild_saved()
    for _, c in ipairs(savedFrame:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for i, entry in ipairs(state.saved_spots) do
        local row = make("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = COL_PANEL_ALT, BorderSizePixel = 0, LayoutOrder = i}, savedFrame)
        corner(row, 5)
        local nb = make("TextButton", {Size = UDim2.new(1, -36, 1, 0), BackgroundTransparency = 1, Text = "  " .. entry.name, TextColor3 = COL_TEXT, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 12, AutoButtonColor = false}, row)
        nb.MouseButton1Click:Connect(function()
            local root = get_root()
            if root then root.CFrame = entry.cf; set_status("teleported to " .. entry.name, true) end
        end)
        local del = make("TextButton", {Size = UDim2.new(0, 28, 0, 22), Position = UDim2.new(1, -32, 0, 4), BackgroundColor3 = COL_DANGER, BorderSizePixel = 0, Text = "x", TextColor3 = Color3.fromRGB(255, 220, 220), Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false}, row)
        corner(del, 4)
        del.MouseEnter:Connect(function() tween(del, {BackgroundColor3 = COL_DANGER_HOVER}, 0.12) end)
        del.MouseLeave:Connect(function() tween(del, {BackgroundColor3 = COL_DANGER}, 0.12) end)
        del.MouseButton1Click:Connect(function()
            table.remove(state.saved_spots, i)
            rebuild_saved()
        end)
    end
end
button(tpRight, "Save spot (Named)", COL_PANEL_ALT, function()
    local cf = parse_cframe(cfBox.Text)
    if not cf then set_status("couldn't parse cframe", false); return end
    local name = saveBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then name = "spot " .. (#state.saved_spots + 1) end
    table.insert(state.saved_spots, {name = name, cf = cf})
    saveBox.Text = ""
    rebuild_saved()
    set_status("saved: " .. name, true)
end, 6)
section(tpRight, "Auto-Waypoints", 8)
button(tpRight, "Save Current Position", COL_ACCENT, function()
    local root = get_root()
    if root then
        local name = "Position " .. (#state.saved_spots + 1)
        table.insert(state.saved_spots, {name = name, cf = root.CFrame})
        rebuild_saved()
        set_status("saved: " .. name, true)
    else set_status("no character", false) end
end, 9)
button(tpRight, "Clear All Waypoints", COL_DANGER, function()
    state.saved_spots = {}
    rebuild_saved()
    set_status("cleared all waypoints", true)
end, 10)
rebuild_saved()

-- ==========================================
-- TAB BUILDER: AIMBOT
-- ==========================================
update_loading("Building Aimbot", 70)

local aimLeft, aimRight = split_two(tabPages["Aimbot"])
section(aimLeft, "Player aimbot", 1)
toggle(aimLeft, "Enable aimbot", false, function(on)
    state.aimbot_enabled = on
    update_fov_circle()
end, 2, "aimbot_enabled")
slider(aimLeft, "FOV (px)", 20, 500, 150, function(v) state.aimbot_fov = v; update_fov_circle() end, 3, "aimbot_fov")
slider(aimLeft, "Max range", 50, 2000, 500, function(v) state.aimbot_range = v end, 4, "aimbot_range")
slider(aimLeft, "Smoothness", 0, 1, 0.35, function(v) state.aimbot_smooth = v end, 5, "aimbot_smooth")
slider(aimLeft, "Prediction", 0, 0.3, 0.05, function(v) state.aimbot_prediction = v end, 6, "aimbot_prediction")
toggle(aimLeft, "Team check", true, function(on) state.aimbot_teamcheck = on end, 7, "aimbot_teamcheck")
toggle(aimLeft, "Triggerbot", false, function(on) state.triggerbot = on end, 8, "triggerbot")
toggle(aimLeft, "Instant Snap (Lock-on)", false, function(on) state.aimbot_snap = on end, 9, "aimbot_snap")

-- NEW WALLBANG TOGGLE
toggle(aimLeft, "Wallbang (Shoot Through Walls)", false, function(on) 
    state.wallbang = on 
    if on then hook_wallbang() end
end, 10, "wallbang")

section(aimLeft, "Target part", 11)
toggle(aimLeft, "Head", true, function(on) state.aimbot_part = "Head" end, 12)
toggle(aimLeft, "HumanoidRootPart", false, function(on) state.aimbot_part = "HumanoidRootPart" end, 13)

section(aimLeft, "Exploits", 20)
toggle(aimLeft, "Rapid Fire (Remote)", false, function(on)
    state.rapid_fire = on
    if on and not rapid_fire_task then
        rapid_fire_task = task.spawn(function()
            local rs = game:GetService("ReplicatedStorage")
            local remotes = rs:WaitForChild("Remotes", 5)
            local replication = remotes and remotes:WaitForChild("Replication", 5)
            local fighter = replication and replication:WaitForChild("Fighter", 5)
            local shoot_remote = fighter and fighter:WaitForChild("UseItem", 5)
            while state.rapid_fire do
                task.wait(state.rapid_fire_delay)
                local char = player.Character
                local tool = char and char:FindFirstChildOfClass("Tool")
                if tool and shoot_remote then pcall(function() shoot_remote:FireServer(tool) end) end
            end
            rapid_fire_task = nil
        end)
    end
end, 21, "rapid_fire")
slider(aimLeft, "Rapid Fire Delay", 0.01, 0.5, 0.1, function(v) state.rapid_fire_delay = v end, 22, "rapid_fire_delay")

section(aimRight, "Keybinds", 1)
local keybindButtons = {}
local function bind_label(b)
    local bind = keybinds[b]
    if not bind.key then return "none" end
    if bind.input == Enum.UserInputType.Keyboard then return bind.key.Name else return bind.input.Name end
end
local function keybind_button(parent, label, slot, order)
    local b = make("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = COL_PANEL_ALT, BorderSizePixel = 0, Text = label .. ":  " .. bind_label(slot), TextColor3 = COL_TEXT, Font = Enum.Font.Gotham, TextSize = 12, LayoutOrder = order or 0, AutoButtonColor = false}, parent)
    corner(b, 5)
    keybindButtons[slot] = b
    b.MouseEnter:Connect(function() tween(b, {BackgroundColor3 = COL_PANEL_HOVER}, 0.12) end)
    b.MouseLeave:Connect(function() tween(b, {BackgroundColor3 = COL_PANEL_ALT}, 0.12) end)
    b.MouseButton1Click:Connect(function()
        b.Text = label .. ":  ..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(io, gp)
            if io.KeyCode == Enum.KeyCode.Escape then
                b.Text = label .. ":  " .. bind_label(slot)
                conn:Disconnect()
                return
            end
            if gp then return end
            if io.KeyCode == Enum.KeyCode.Backspace or io.KeyCode == Enum.KeyCode.Delete then
                keybinds[slot] = {input = Enum.UserInputType.Keyboard, key = nil}
                b.Text = label .. ":  none"
                conn:Disconnect(); update_keybind_label()
                return
            end
            if io.UserInputType == Enum.UserInputType.Keyboard then
                keybinds[slot] = {input = Enum.UserInputType.Keyboard, key = io.KeyCode}
                b.Text = label .. ":  " .. io.KeyCode.Name
                conn:Disconnect(); update_keybind_label()
            elseif io.UserInputType.Name:find("MouseButton") then
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
toggle(aimRight, "Enable object aimbot", false, function(on) state.object_aimbot_enabled = on; update_fov_circle() end, 11, "object_aimbot_enabled")
local obj_aim_name = textbox(aimRight, "object name (exact match)", 12, "", "object_name")
obj_aim_name:GetPropertyChangedSignal("Text"):Connect(function() state.object_name = obj_aim_name.Text end)

local function nearest_target()
    local cam = Workspace.CurrentCamera
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
                        local sp, onscreen = cam:WorldToViewportPoint(part.Position)
                        if onscreen and sp.Z > 0 then
                            local vp = cam.ViewportSize
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
    local cam = Workspace.CurrentCamera
    if state.object_name == "" then return nil end
    local best, best_dist = nil, state.aimbot_fov
    local my_pos = get_root() and get_root().Position or Vector3.zero
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == state.object_name and obj:IsA("BasePart") then
            local world_dist = (obj.Position - my_pos).Magnitude
            if world_dist <= state.object_range then
                local sp, onscreen = cam:WorldToViewportPoint(obj.Position)
                if onscreen and sp.Z > 0 then
                    local vp = cam.ViewportSize
                    local center = Vector2.new(vp.X/2, vp.Y/2)
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < best_dist then best_dist = d; best = obj end
                end
            end
        end
    end
    return best
end

-- ==========================================
-- TAB BUILDER: FLING & HITBOX
-- ==========================================
update_loading("Building Fling & Hitbox", 80)

local flLeft, flRight = split_two(tabPages["Fling"])
section(flLeft, "Fling target", 1)
local flingListFrame = make("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2}, flLeft)
make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, flingListFrame)
local function stop_fling()
    if fling_conn then fling_conn:Disconnect(); fling_conn = nil end
    if _G._bss_fling_weld then pcall(function() _G._bss_fling_weld:Destroy() end); _G._bss_fling_weld = nil end
    fling_active = false
    local root = get_root()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if root then root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end
    if hum then hum.PlatformStand = false end
    if state.fling_return and fling_return_cf then
        local r2 = get_root()
        if r2 then r2.CFrame = fling_return_cf end
    end
    fling_return_cf = nil; fling_target = nil
end
local function start_fling(target_player)
    if fling_active then stop_fling() end
    local root = get_root()
    local target_root = get_root(target_player)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not target_root or not hum then return end
    fling_target = target_player
    fling_return_cf = root.CFrame
    fling_active = true
    pcall(function() target_root:SetNetworkOwner(player) end)
    root.CFrame = target_root.CFrame * CFrame.new(0, 0, 2)
    task.wait(0.15)
    if state.use_walkfling then hum.PlatformStand = true end
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = target_root; weld.Part1 = root; weld.Parent = target_root
    _G._bss_fling_weld = weld
    local t = 0
    fling_conn = RunService.Heartbeat:Connect(function(dt)
        t = t + dt
        local r = get_root(); local tr = get_root(target_player)
        if not r or not tr or not fling_active then stop_fling(); return end
        if state.use_walkfling then
            local speed = 1000000; local direction = tr.CFrame.LookVector
            r.AssemblyLinearVelocity = direction * speed
            r.AssemblyAngularVelocity = Vector3.new(0, 50000, 0)
        else
            r.CFrame = tr.CFrame * CFrame.Angles(0, t * 2000, 0)
        end
    end)
    task.delay(2.5, function() if fling_active and fling_target == target_player then stop_fling() end end)
end
local function refresh_fling_list()
    for _, c in ipairs(flingListFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for i, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            button(flingListFrame, "Fling " .. p.Name, COL_PANEL_ALT, function() start_fling(p) end, i)
        end
    end
end
track(Players.PlayerAdded:Connect(refresh_fling_list))
track(Players.PlayerRemoving:Connect(refresh_fling_list))
refresh_fling_list()
section(flRight, "Options", 1)
toggle(flRight, "Return to start after fling", true, function(on) state.fling_return = on end, 2, "fling_return")
toggle(flRight, "Walkfling method", false, function(on) state.use_walkfling = on end, 3, "use_walkfling")
button(flRight, "Stop fling", COL_DANGER, function() stop_fling() end, 4)

local hbLeft, hbRight = split_two(tabPages["Hitbox"])
section(hbLeft, "Hitbox Expander", 1)
local function remove_hitbox(p)
    if hitbox_expanded[p] then hitbox_expanded[p]:Destroy(); hitbox_expanded[p] = nil end
end
toggle(hbLeft, "Enabled", false, function(on)
    state.hitbox_enabled = on
    if not on then for p, _ in pairs(hitbox_expanded) do remove_hitbox(p) end end
end, 2, "hitbox_enabled")
local partRow = make("Frame", {Size = UDim2.new(1,0,0,34), BackgroundColor3 = COL_PANEL_ALT, LayoutOrder = 3}, hbLeft)
corner(partRow, 5)
make("TextLabel", {Size = UDim2.new(1,-160,1,0), Position = UDim2.new(0,12,0,0), BackgroundTransparency = 1, Text = "Part", TextColor3 = COL_TEXT, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, partRow)
local hrpBtn = make("TextButton", {Size = UDim2.new(0, 80, 0, 24), Position = UDim2.new(1, -160, 0.5, -12), BackgroundColor3 = state.hitbox_part == "HumanoidRootPart" and COL_ACCENT or COL_PANEL, Text = "HumanoidRootPart", TextColor3 = COL_TEXT, Font = Enum.Font.GothamBold, TextSize = 10, TextScaled = true, AutoButtonColor = false}, partRow)
corner(hrpBtn, 4)
local headBtn = make("TextButton", {Size = UDim2.new(0, 60, 0, 24), Position = UDim2.new(1, -75, 0.5, -12), BackgroundColor3 = state.hitbox_part == "Head" and COL_ACCENT or COL_PANEL, Text = "Head", TextColor3 = COL_TEXT, Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false}, partRow)
corner(headBtn, 4)
hrpBtn.MouseButton1Click:Connect(function()
    state.hitbox_part = "HumanoidRootPart"; tween(hrpBtn, {BackgroundColor3 = COL_ACCENT}, 0.15); tween(headBtn, {BackgroundColor3 = COL_PANEL}, 0.15)
    for p, _ in pairs(hitbox_expanded) do remove_hitbox(p) end
end)
headBtn.MouseButton1Click:Connect(function()
    state.hitbox_part = "Head"; tween(hrpBtn, {BackgroundColor3 = COL_PANEL}, 0.15); tween(headBtn, {BackgroundColor3 = COL_ACCENT}, 0.15)
    for p, _ in pairs(hitbox_expanded) do remove_hitbox(p) end
end)
local lookRow = make("Frame", {Size = UDim2.new(1,0,0,34), BackgroundColor3 = COL_PANEL_ALT, LayoutOrder = 4}, hbLeft)
corner(lookRow, 5)
make("TextLabel", {Size = UDim2.new(1,-210,1,0), Position = UDim2.new(0,12,0,0), BackgroundTransparency = 1, Text = "Hitbox Look", TextColor3 = COL_TEXT, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, lookRow)
local boxBtn = make("TextButton", {Size = UDim2.new(0, 60, 0, 24), Position = UDim2.new(1, -210, 0.5, -12), BackgroundColor3 = state.hitbox_look == "Box" and COL_ACCENT or COL_PANEL, Text = "Box", TextColor3 = COL_TEXT, Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false}, lookRow)
corner(boxBtn, 4)
local wireBtn = make("TextButton", {Size = UDim2.new(0, 60, 0, 24), Position = UDim2.new(1, -145, 0.5, -12), BackgroundColor3 = state.hitbox_look == "Wireframe" and COL_ACCENT or COL_PANEL, Text = "Wireframe", TextColor3 = COL_TEXT, Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false}, lookRow)
corner(wireBtn, 4)
local invBtn = make("TextButton", {Size = UDim2.new(0, 60, 0, 24), Position = UDim2.new(1, -80, 0.5, -12), BackgroundColor3 = state.hitbox_look == "Invisible" and COL_ACCENT or COL_PANEL, Text = "Invisible", TextColor3 = COL_TEXT, Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false}, lookRow)
corner(invBtn, 4)
boxBtn.MouseButton1Click:Connect(function() state.hitbox_look = "Box"; tween(boxBtn, {BackgroundColor3 = COL_ACCENT}, 0.15); tween(wireBtn, {BackgroundColor3 = COL_PANEL}, 0.15); tween(invBtn, {BackgroundColor3 = COL_PANEL}, 0.15) end)
wireBtn.MouseButton1Click:Connect(function() state.hitbox_look = "Wireframe"; tween(boxBtn, {BackgroundColor3 = COL_PANEL}, 0.15); tween(wireBtn, {BackgroundColor3 = COL_ACCENT}, 0.15); tween(invBtn, {BackgroundColor3 = COL_PANEL}, 0.15) end)
invBtn.MouseButton1Click:Connect(function() state.hitbox_look = "Invisible"; tween(boxBtn, {BackgroundColor3 = COL_PANEL}, 0.15); tween(wireBtn, {BackgroundColor3 = COL_PANEL}, 0.15); tween(invBtn, {BackgroundColor3 = COL_ACCENT}, 0.15) end)
slider(hbLeft, "Size", 1, 50, 6, function(v) state.hitbox_size = v end, 5, "hitbox_size")
slider(hbLeft, "Transparency", 0, 1, 0.7, function(v) state.hitbox_transparency = v end, 6, "hitbox_transparency")
local function apply_hitbox_to(p)
    if not state.hitbox_enabled then
        if hitbox_expanded[p] then remove_hitbox(p) end
        return
    end
    local char = p.Character
    local hrp = char and char:FindFirstChild(state.hitbox_part)
    if not hrp then
        if hitbox_expanded[p] then remove_hitbox(p) end
        return
    end
    if not hitbox_expanded[p] then
        local hitbox = Instance.new("Part")
        hitbox.Name = "BSS_Hitbox"
        hitbox.Size = Vector3.new(state.hitbox_size, state.hitbox_size, state.hitbox_size)
        hitbox.CanCollide = false; hitbox.Massless = true; hitbox.Anchored = true
        hitbox.Color = Color3.fromRGB(0, 255, 255); hitbox.Material = Enum.Material.ForceField
        if state.hitbox_look == "Box" then hitbox.Transparency = 0.5
        elseif state.hitbox_look == "Wireframe" then
            hitbox.Transparency = 1
            local sel = Instance.new("SelectionBox"); sel.Adornee = hitbox; sel.Color3 = Color3.fromRGB(0, 255, 255); sel.LineThickness = 0.05; sel.Parent = hitbox
        else hitbox.Transparency = 1 end
        hitbox.Parent = Workspace
        hitbox_expanded[p] = hitbox
    else
        local hitbox = hitbox_expanded[p]
        hitbox.Size = Vector3.new(state.hitbox_size, state.hitbox_size, state.hitbox_size)
        hitbox.CFrame = hrp.CFrame
        if state.hitbox_look == "Box" then
            hitbox.Transparency = 0.5
            local sel = hitbox:FindFirstChildOfClass("SelectionBox")
            if sel then sel:Destroy() end
        elseif state.hitbox_look == "Wireframe" then
            hitbox.Transparency = 1
            if not hitbox:FindFirstChildOfClass("SelectionBox") then
                local sel = Instance.new("SelectionBox"); sel.Adornee = hitbox; sel.Color3 = Color3.fromRGB(0, 255, 255); sel.LineThickness = 0.05; sel.Parent = hitbox
            end
        else
            hitbox.Transparency = 1
            local sel = hitbox:FindFirstChildOfClass("SelectionBox")
            if sel then sel:Destroy() end
        end
    end
end
track(Players.PlayerRemoving:Connect(function(p) remove_hitbox(p) end))

-- ==========================================
-- TAB BUILDER: EXPLOITS & FUN
-- ==========================================
update_loading("Building Exploits", 90)

local exLeft, exRight = split_two(tabPages["Exploits"])
section(exLeft, "Targeted Exploits", 1)
local exTargetBox = textbox(exLeft, "target player name...", 2, "")

local function fly_to_position(target_pos, speed)
    local hrp = get_root()
    if not hrp then return end
    
    local bv = Instance.new("BodyVelocity")
    bv.Name = "BSS_AutoMove"
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = hrp
    
    local timeout = tick() + 10
    while (hrp.Position - target_pos).Magnitude > 8 and tick() < timeout do
        if not hrp or not hrp.Parent then 
            bv:Destroy() 
            return 
        end
        local dir = (target_pos - hrp.Position).Unit
        bv.Velocity = dir * speed
        task.wait(0.05)
    end
    
    if bv then bv.Velocity = Vector3.zero; task.wait(0.1); bv:Destroy() end
end

local DIAMOND_CFRAME = CFrame.new(111.998154, 17.5156422, 1294.89917, 0.173624337, -0, -0.984811902, 0, 1, -0, 0.984811902, 0, 0.173624337)
local DROPOFF_CFRAME = CFrame.new(-300.185577, 20.6801224, 1594.45862, -0.29079634, 6.13783641e-06, -0.956784964, 0.00014125774, 1, -3.65175038e-05, 0.956784964, -0.000145772443, -0.29079634)

toggle(exLeft, "Auto Rob Jewelry (Speed 300)", false, function(on)
    state.jb_auto_rob = on
    if on then
        task.spawn(function()
            while state.jb_auto_rob do
                local hrp = get_root()
                if not hrp then break end
                
                fly_to_position(DIAMOND_CFRAME.Position, 300)
                
                local vim = game:GetService("VirtualInputManager")
                for i = 1, 20 do
                    if not state.jb_auto_rob then break end
                    vim:SendMouseButtonEvent(camera.ViewportSize.X/2, camera.ViewportSize.Y/2, 0, true, game, 0)
                    vim:SendMouseButtonEvent(camera.ViewportSize.X/2, camera.ViewportSize.Y/2, 0, false, game, 0)
                    task.wait(0.05)
                end
                
                fly_to_position(DROPOFF_CFRAME.Position, 300)
                task.wait(2)
            end
        end)
    end
end, 3, "jb_auto_rob")

toggle(exLeft, "Auto Arrest (Speed 300)", false, function(on)
    state.jb_auto_arrest = on
    if on then
        task.spawn(function()
            while state.jb_auto_arrest do
                local hrp = get_root()
                local char = player.Character
                if not hrp or not char then break end
                
                local target = nil
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= player and p.Character then
                        local wanted = p:FindFirstChild("Wanted")
                        if wanted and wanted.Value > 0 then
                            target = p
                            break
                        end
                    end
                end
                
                if target and target.Character then
                    local t_hrp = target.Character:FindFirstChild("HumanoidRootPart")
                    if t_hrp then
                        fly_to_position(t_hrp.Position, 300)
                        
                        local backpack = player:FindFirstChild("Backpack")
                        local cuffs = backpack and (backpack:FindFirstChild("Handcuffs") or backpack:FindFirstChild("Arrest"))
                        if cuffs then
                            cuffs.Parent = char
                            task.wait(0.1)
                            local vim = game:GetService("VirtualInputManager")
                            vim:SendMouseButtonEvent(camera.ViewportSize.X/2, camera.ViewportSize.Y/2, 0, true, game, 0)
                            vim:SendMouseButtonEvent(camera.ViewportSize.X/2, camera.ViewportSize.Y/2, 0, false, game, 0)
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end
end, 5, "jb_auto_arrest")

local loop_tp_target = nil
toggle(exLeft, "Loop Teleport to Target", false, function(on)
    if on then
        local targetName = exTargetBox.Text
        if targetName == "" then return end
        local target = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():find(targetName:lower()) then target = p break end
        end
        if target then
            loop_tp_target = target
            if loop_tp_conn then loop_tp_conn:Disconnect() end
            loop_tp_conn = RunService.Heartbeat:Connect(function()
                local hrp = get_root()
                local t_hrp = get_root(loop_tp_target)
                if hrp and t_hrp then
                    hrp.CFrame = t_hrp.CFrame * CFrame.new(0, 0, 2)
                end
            end)
        end
    else
        if loop_tp_conn then loop_tp_conn:Disconnect(); loop_tp_conn = nil end
        loop_tp_target = nil
    end
end, 4)

button(exLeft, "Invalid Avatar Rig Break", COL_DANGER, function()
    local targetName = exTargetBox.Text
    if targetName == "" then return end
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(targetName:lower()) then target = p break end
    end
    if target and target ~= player then
        local t_char = target.Character
        local t_hrp = t_char and t_char:FindFirstChild("HumanoidRootPart")
        local hrp = get_root()
        if t_hrp and hrp then
            hrp.CFrame = t_hrp.CFrame
            local breaker = Instance.new("Part")
            breaker.Size = Vector3.new(10, 10, 10)
            breaker.Position = t_hrp.Position
            breaker.CanCollide = true
            breaker.Transparency = 1
            breaker.Massless = false
            breaker.Parent = Workspace
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = breaker
            weld.Part1 = t_hrp
            weld.Parent = breaker
            local bav = Instance.new("BodyAngularVelocity")
            bav.AngularVelocity = Vector3.new(999999, 999999, 999999)
            bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bav.Parent = breaker
            task.delay(1.5, function() if breaker then breaker:Destroy() end end)
        end
    end
end, 6)

section(exLeft, "Rage Visuals", 10)
toggle(exLeft, "Wall Transparency (X-Ray)", false, function(on)
    state.xray_enabled = on
    if on then
        local char_parts = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                for _, desc in ipairs(p.Character:GetDescendants()) do
                    if desc:IsA("BasePart") then char_parts[desc] = true end
                end
            end
        end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not char_parts[obj] then
                if not xray_originals[obj] then xray_originals[obj] = obj.Transparency end
                obj.Transparency = 0.85
            end
        end
    else
        for obj, orig in pairs(xray_originals) do
            if obj and obj.Parent then obj.Transparency = orig end
        end
        xray_originals = {}
    end
end, 11, "xray_enabled")

local function apply_chams(p)
    if p == player then return end
    local char = p.Character
    if not char then return end
    if chams_highlights[p] and chams_highlights[p].Parent then return end
    local hl = Instance.new("Highlight")
    hl.Name = "BSS_Chams"
    hl.Adornee = char
    hl.FillColor = Color3.fromRGB(255, 40, 90)
    hl.FillTransparency = 0.35
    hl.OutlineColor = Color3.fromRGB(255, 120, 150)
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char
    chams_highlights[p] = hl
end

toggle(exLeft, "Enemy Chams (Through Walls)", false, function(on)
    state.chams_enabled = on
    if on then
        for _, p in ipairs(Players:GetPlayers()) do if p ~= player then apply_chams(p) end end
    else
        for p, hl in pairs(chams_highlights) do if hl and hl.Parent then pcall(function() hl:Destroy() end) end end
        chams_highlights = {}
    end
end, 12, "chams_enabled")

toggle(exLeft, "Rainbow Character", false, function(on)
    state.rainbow_enabled = on
    if on then
        local char = player.Character
        if char then
            rainbow_originals = {}
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then rainbow_originals[part] = part.Color end
            end
        end
        if not rainbow_task then
            rainbow_task = task.spawn(function()
                local t = 0
                while state.rainbow_enabled do
                    t = t + 0.02
                    local c = Color3.fromHSV((t * 0.3) % 1, 1, 1)
                    local char = player.Character
                    if char then
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then part.Color = c end
                        end
                    end
                    task.wait(0.05)
                end
                rainbow_task = nil
            end)
        end
    else
        if rainbow_task then task.cancel(rainbow_task); rainbow_task = nil end
        for part, orig in pairs(rainbow_originals) do
            if part and part.Parent then part.Color = orig end
        end
        rainbow_originals = {}
    end
end, 13, "rainbow_enabled")

toggle(exLeft, "Forcefield Aura (Enemies)", false, function(on)
    state.forcefield_enabled = on
    if on then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp and not hrp:FindFirstChild("BSS_FF") then
                    local ff = Instance.new("ForceField")
                    ff.Name = "BSS_FF"
                    ff.Visible = true
                    ff.Parent = hrp
                end
            end
        end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                for _, desc in ipairs(p.Character:GetDescendants()) do
                    if desc.Name == "BSS_FF" then desc:Destroy() end
                end
            end
        end
    end
end, 14, "forcefield_enabled")

section(exRight, "Server Exploits", 1)
button(exRight, "Global Server Fling (Mass Parts)", COL_DANGER, function()
    local hrp = get_root()
    if not hrp then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local t_hrp = get_root(p)
            if t_hrp then
                for i = 1, 15 do
                    local mass = Instance.new("Part")
                    mass.Size = Vector3.new(5, 5, 5)
                    mass.Position = t_hrp.Position
                    mass.CanCollide = true
                    mass.Transparency = 1
                    mass.Massless = false
                    mass.Parent = Workspace
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = mass
                    weld.Part1 = t_hrp
                    weld.Parent = mass
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = Vector3.new(math.random(-9999, 9999), 9999, math.random(-9999, 9999))
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.Parent = mass
                    task.delay(1, function() if mass then mass:Destroy() end end)
                end
            end
        end
    end
end, 2)

button(exRight, "Spawn Lag Parts (Crash Server)", COL_DANGER, function()
    local char = player.Character
    local hrp = get_root()
    if hrp then
        for i = 1, 300 do
            local part = Instance.new("Part")
            part.Size = Vector3.new(50, 50, 50)
            part.Position = hrp.Position + Vector3.new(math.random(-50, 50), math.random(10, 50), math.random(-50, 50))
            part.Anchored = false
            part.CanCollide = true
            part.Transparency = 0.5
            part.Color = Color3.fromRGB(255, 0, 0)
            part.Parent = Workspace
            task.delay(3, function() part:Destroy() end)
        end
    end
end, 3)

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
            anim.AnimationId = "rbxassetid://507770818"
            local track_anim = animator:LoadAnimation(anim)
            track_anim:Play()
            task.delay(5, function() track_anim:Stop() end)
        end
    end
end, 2)

-- ==========================================
-- TAB BUILDER: UTILITY & FLY
-- ==========================================
update_loading("Building Utility", 95)

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
            if state.fly_mode == "CFrame" then
                for _, part in ipairs(vehicle:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Anchored = false
                    elseif part:IsA("BodyPosition") or part:IsA("BodyVelocity") or part:IsA("BodyGyro") or part:IsA("BodyForce") or part:IsA("AlignPosition") or part:IsA("AlignOrientation") then
                        part:Destroy()
                    end
                end
            end
            pcall(function() root:SetNetworkOwner(player) end)
        end
    end
    if not root then root = get_root() end
    if not root then return end
    if state.fly_mode == "CFrame" then
        fly_conn = RunService.RenderStepped:Connect(function(dt)
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
            local move = Vector3.zero
            local cam = camera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
            local speed = state.fly_speed
            if state.safe_fly then speed = math.min(speed, 50) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 2.5 end
            if move.Magnitude > 0 then r.CFrame = r.CFrame + (move.Unit * speed * dt) end
        end)
    else
        fly_velocity = Instance.new("BodyVelocity")
        fly_velocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        fly_velocity.Velocity = Vector3.zero
        fly_velocity.Parent = root
        fly_gyro = Instance.new("BodyGyro")
        fly_gyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
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
            if state.safe_fly then speed = math.min(speed, 50) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 2.5 end
            fly_velocity.Velocity = move.Magnitude > 0 and move.Unit * speed or Vector3.zero
        end)
    end
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
    fly_velocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    fly_velocity.Velocity = Vector3.zero
    fly_velocity.Parent = root
    fly_gyro = Instance.new("BodyGyro")
    fly_gyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
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
        if state.safe_fly then speed = math.min(speed, 50) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 2.5 end
        fly_velocity.Velocity = move.Magnitude > 0 and move.Unit * speed or Vector3.zero
    end)
end

local uScroll = scroll_col(tabPages["Utility"])
section(uScroll, "Movement", 1)
slider(uScroll, "WalkSpeed", 16, 200, 16, function(v)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end, 2)
toggle(uScroll, "Infinite Jump", false, function(on)
    state.inf_jump = on
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
end, 3, "inf_jump")
toggle(uScroll, "Spinbot", false, function(on)
    state.spinbot = on
    if on then
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = false end
            spin_vel = Instance.new("BodyAngularVelocity")
            spin_vel.AngularVelocity = Vector3.new(0, state.spinbot_speed, 0)
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
end, 4, "spinbot")
slider(uScroll, "Spinbot Speed", 10, 500, 50, function(v)
    state.spinbot_speed = v
    if spin_vel then spin_vel.AngularVelocity = Vector3.new(0, state.spinbot_speed, 0) end
end, 5, "spinbot_speed")
toggle(uScroll, "Noclip", false, function(on)
    state.noclip = on
    if on then
        if noclip_conn then noclip_conn:Disconnect() end
        noclip_conn = RunService.Stepped:Connect(function()
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() hrp:SetNetworkOwner(player) end) end
                
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.CanQuery = false
                    end
                end
            end
        end)
    else
        if noclip_conn then noclip_conn:Disconnect(); noclip_conn = nil end
    end
end, 6, "noclip")
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
                if move.Magnitude > 0 then hrp.CFrame = hrp.CFrame + move.Unit * (state.cf_speed_val * dt) end
            end
        end)
    else
        if cf_speed_conn then cf_speed_conn:Disconnect(); cf_speed_conn = nil end
    end
end, 7, "cf_speed")
slider(uScroll, "CFrame Speed Value", 10, 300, 50, function(v) state.cf_speed_val = v end, 8, "cf_speed_val")
toggle(uScroll, "Float (Q/E to move)", false, function(on)
    state.float = on
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = get_root()
    if on then
        if hum then hum.PlatformStand = true; hum:ChangeState(Enum.HumanoidStateType.Physics) end
        if root then
            local bv = Instance.new("BodyVelocity")
            bv.Name = "FloatBV"; bv.MaxForce = Vector3.new(0, math.huge, 0); bv.Velocity = Vector3.zero; bv.Parent = root
        end
        if float_conn then float_conn:Disconnect() end
        float_conn = RunService.RenderStepped:Connect(function()
            local r = get_root()
            local bv = r and r:FindFirstChild("FloatBV")
            if bv then
                local y_vel = 0
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then y_vel = 50 end
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then y_vel = -50 end
                bv.Velocity = Vector3.new(0, y_vel, 0)
            end
        end)
    else
        if float_conn then float_conn:Disconnect(); float_conn = nil end
        if hum then hum.PlatformStand = false; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        if root then
            local bv = root:FindFirstChild("FloatBV")
            if bv then bv:Destroy() end
        end
    end
end, 9, "float")
toggle(uScroll, "Swim in Air", false, function(on)
    state.swim = on
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if on then
        if hum then hum.PlatformStand = true end
        if swim_conn then swim_conn:Disconnect() end
        swim_conn = RunService.RenderStepped:Connect(function(dt)
            local r = get_root()
            if r then
                local move = Vector3.zero
                local cam = camera.CFrame
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
                r.AssemblyLinearVelocity = move.Magnitude > 0 and move.Unit * 50 or Vector3.new(0,0,0)
            end
        end)
    else
        if swim_conn then swim_conn:Disconnect(); swim_conn = nil end
        if hum then hum.PlatformStand = false end
    end
end, 10, "swim")
section(uScroll, "Fly", 20)
toggle(uScroll, "Enable fly", false, function(on)
    state.fly_enabled = on
    if on then start_fly(false) else stop_fly() end
end, 21, "fly_enabled")
slider(uScroll, "Fly speed", 10, 300, 60, function(v) state.fly_speed = v end, 22, "fly_speed")
local modeRow = make("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = COL_PANEL_ALT, LayoutOrder = 23}, uScroll)
corner(modeRow, 5)
make("TextLabel", {Size = UDim2.new(1, -150, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = "Fly Mode", TextColor3 = COL_TEXT, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, modeRow)
local velBtn = make("TextButton", {Size = UDim2.new(0, 60, 1, -8), Position = UDim2.new(1, -130, 0, 4), BackgroundColor3 = state.fly_mode == "Velocity" and COL_ACCENT or COL_PANEL, BorderSizePixel = 0, Text = "Velocity", TextColor3 = COL_TEXT, Font = Enum.Font.GothamBold, TextSize = 11, AutoButtonColor = false}, modeRow)
corner(velBtn, 4)
local cfBtn = make("TextButton", {Size = UDim2.new(0, 60, 1, -8), Position = UDim2.new(1, -66, 0, 4), BackgroundColor3 = state.fly_mode == "CFrame" and COL_ACCENT or COL_PANEL, BorderSizePixel = 0, Text = "CFrame", TextColor3 = COL_TEXT, Font = Enum.Font.GothamBold, TextSize = 11, AutoButtonColor = false}, modeRow)
corner(cfBtn, 4)
velBtn.MouseButton1Click:Connect(function()
    state.fly_mode = "Velocity"; tween(velBtn, {BackgroundColor3 = COL_ACCENT}, 0.15); tween(cfBtn, {BackgroundColor3 = COL_PANEL}, 0.15)
    if state.fly_enabled then start_fly(false) end
    if state.vehiclefly_enabled then start_fly(true) end
end)
cfBtn.MouseButton1Click:Connect(function()
    state.fly_mode = "CFrame"; tween(velBtn, {BackgroundColor3 = COL_PANEL}, 0.15); tween(cfBtn, {BackgroundColor3 = COL_ACCENT}, 0.15)
    if state.fly_enabled then start_fly(false) end
    if state.vehiclefly_enabled then start_fly(true) end
end)
toggle(uScroll, "Enable vehicle fly", false, function(on)
    state.vehiclefly_enabled = on
    if on then start_fly(true) else stop_fly() end
end, 24, "vehiclefly_enabled")
toggle(uScroll, "Jailbreak fly (unsits)", false, function(on)
    state.jb_fly_enabled = on
    if on then start_jb_fly() else stop_fly() end
end, 25, "jb_fly_enabled")
toggle(uScroll, "Vehicle Noclip", false, function(on)
    state.vehicle_noclip = on
    if on then
        if vehicle_noclip_conn then vehicle_noclip_conn:Disconnect() end
        vehicle_noclip_conn = RunService.Heartbeat:Connect(function()
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local seat = hum and hum.SeatPart
            if seat then
                local vehicle = seat.Parent
                if vehicle then
                    local primary = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
                    if primary then pcall(function() primary:SetNetworkOwner(player) end) end
                    for _, part in ipairs(vehicle:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                            part.CanQuery = false
                        end
                    end
                end
            end
        end)
    else
        if vehicle_noclip_conn then vehicle_noclip_conn:Disconnect(); vehicle_noclip_conn = nil end
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        if seat and seat.Parent then
            for _, part in ipairs(seat.Parent:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true; part.CanQuery = true end
            end
        end
    end
end, 26, "vehicle_noclip")
section(uScroll, "Farm & Bypass", 30)
toggle(uScroll, "Under Map (Immortal)", false, function(on)
    state.under_map = on
    if on then
        if under_map_conn then under_map_conn:Disconnect() end
        under_map_conn = RunService.RenderStepped:Connect(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if hrp.Position.Y > -50 then
                    hrp.CFrame = CFrame.new(hrp.Position.X, -50, hrp.Position.Z)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end)
    else
        if under_map_conn then under_map_conn:Disconnect(); under_map_conn = nil end
    end
end, 31, "under_map")
toggle(uScroll, "Safe Fly (Anti-Kick)", false, function(on) state.safe_fly = on end, 32, "safe_fly")
section(uScroll, "Misc", 40)
toggle(uScroll, "Hit Sounds", false, function(on) state.hit_sound = on end, 41, "hit_sound")
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
end, 42, "anti_afk")
toggle(uScroll, "Fullbright", false, function(on)
    state.fullbright = on
    if on then
        Lighting.Brightness = 2; Lighting.ClockTime = 12; Lighting.GlobalShadows = false; Lighting.FogEnd = 100000
    else
        Lighting.Brightness = orig_lighting.Brightness; Lighting.ClockTime = orig_lighting.ClockTime; Lighting.GlobalShadows = orig_lighting.GlobalShadows; Lighting.FogEnd = orig_lighting.FogEnd
    end
end, 43, "fullbright")
toggle(uScroll, "Click Teleport (L-Alt + Click)", false, function(on) state.click_tp = on end, 44, "click_tp")
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
                    local part0 = child.Part0; local part1 = child.Part1
                    if (part0 and part0.Parent ~= char and part0.Parent ~= nil) or (part1 and part1.Parent ~= char and part1.Parent ~= nil) then child:Destroy() end
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
end, 45, "anti_fling")

section(uScroll, "Config", 50)
local configStatus = make("TextLabel", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "", TextColor3 = COL_OK, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 12, LayoutOrder = 51}, uScroll)
local function set_config_status(msg, is_success)
    configStatus.Text = msg
    configStatus.TextColor3 = is_success and COL_OK or COL_BAD
    task.delay(3, function() if configStatus.Text == msg then configStatus.Text = "" end end)
end

local configNameBox = textbox(uScroll, "filename... (e.g. myconfig.json)", 52, "BSSToolkit_Config.json", "config_filename")

button(uScroll, "Save Config", COL_ACCENT, function()
    local code = export_config()
    local fname = configNameBox.Text
    if fname == "" then fname = "BSSToolkit_Config.json" end
    if writefile then
        local success = pcall(function() writefile("Downloads/" .. fname, code) end)
        if success then
            set_config_status("Saved to Downloads/" .. fname, true)
        else
            local fallback_success = pcall(function() writefile(fname, code) end)
            if fallback_success then
                set_config_status("Saved to workspace root", true)
            else
                set_config_status("Failed to save config", false)
            end
        end
    else
        set_config_status("Executor doesn't support saving", false)
    end
end, 53)

button(uScroll, "Load Config", COL_PANEL_ALT, function()
    local fname = configNameBox.Text
    if fname == "" then fname = "BSSToolkit_Config.json" end
    if isfile and readfile then
        local code
        if isfile("Downloads/" .. fname) then
            code = readfile("Downloads/" .. fname)
        elseif isfile(fname) then
            code = readfile(fname)
        end

        if code then
            local ok = import_config(code)
            if ok then
                set_config_status("Config loaded and applied!", true)
            else
                set_config_status("Config file is corrupt", false)
            end
        else
            set_config_status("No config file found: " .. fname, false)
        end
    else
        set_config_status("Executor doesn't support loading", false)
    end
end, 54)

section(uScroll, "Character", 60)
button(uScroll, "Reset character", COL_PANEL_ALT, function()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
end, 61)
button(uScroll, "Rejoin server", COL_DANGER, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, player)
end, 62)
section(uScroll, "External Tools", 70)
button(uScroll, "Launch Infinite Yield", COL_ACCENT, function()
    pcall(function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end)
end, 71)
button(uScroll, "Launch Dex", COL_ACCENT, function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Balakeuse/Dex/main/Dex.lua"))()
    end)
end, 72)

-- ==========================================
-- FINAL INITIALIZATION
-- ==========================================
update_loading("Starting services", 98)

track(UserInputService.InputBegan:Connect(function(io, gp)
    if gp then return end
    if UserInputService:GetFocusedTextBox() then return end
    
    if state.click_tp and io.KeyCode == Enum.KeyCode.LeftAlt and io.UserInputType == Enum.UserInputType.Keyboard then
        local mouse = player:GetMouse()
        if mouse.Target then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) end
        end
    end
    local aim_bind = keybinds.aimbot; local fling_bind = keybinds.fling; local fly_bind = keybinds.fly; local hide_bind = keybinds.hide
    if aim_bind.key and io.UserInputType == aim_bind.input and io.KeyCode == aim_bind.key then
        key_state.aimbot = true
    elseif fling_bind.key and io.UserInputType == fling_bind.input and io.KeyCode == fling_bind.key then
        key_state.fling = true
        local tgt = nearest_target()
        if not tgt and state.object_aimbot_enabled then
            local obj = nearest_object()
            if obj then local tp = Players:GetPlayerFromCharacter(obj.Parent); if tp then start_fling(tp) end end
        elseif tgt then
            local tp = Players:GetPlayerFromCharacter(tgt.Parent); if tp then start_fling(tp) end
        end
    elseif fly_bind.key and io.UserInputType == fly_bind.input and io.KeyCode == fly_bind.key then
        key_state.fly = not key_state.fly
        if key_state.fly then start_fly(false) else stop_fly() end
    elseif hide_bind.key and io.UserInputType == hide_bind.input and io.KeyCode == hide_bind.key then
        main.Visible = not main.Visible
        shadow.Visible = main.Visible
    end
end))

track(UserInputService.InputEnded:Connect(function(io)
    local aim_bind = keybinds.aimbot; local fling_bind = keybinds.fling
    if aim_bind.key and io.UserInputType == aim_bind.input and io.KeyCode == aim_bind.key then key_state.aimbot = false end
    if fling_bind.key and io.UserInputType == fling_bind.input and io.KeyCode == fling_bind.key then key_state.fling = false end
end))

track(UserInputService.WindowFocusReleased:Connect(function()
    key_state.aimbot = false
    key_state.fling = false
    key_state.fly = false
end))

-- MAIN LOOP
main_render_conn = RunService.Heartbeat:Connect(function(dt)
    pcall(function()
        camera = Workspace.CurrentCamera
        if not gui.Parent then return end
        
        if state.chams_enabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player then apply_chams(p) end
            end
        end
        if state.forcefield_enabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and not hrp:FindFirstChild("BSS_FF") then
                        local ff = Instance.new("ForceField")
                        ff.Name = "BSS_FF"
                        ff.Visible = true
                        ff.Parent = hrp
                    end
                end
            end
        end
        
        update_esp()
        update_object_esp()
        
        if state.hitbox_enabled then
            for _, p in ipairs(Players:GetPlayers()) do if p ~= player then apply_hitbox_to(p) end end
        end
    end)
end)

-- AIMBOT BIND
RunService:BindToRenderStep("BSSToolkitAim", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local cam = Workspace.CurrentCamera
    if not gui.Parent then return end
    if state.fov_enabled then cam.FieldOfView = state.fov_value end
    if not key_state.aimbot then
        locked_target = nil
        return
    end

    if locked_target then
        local char = locked_target.Parent
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            locked_target = nil
        end
    end

    if not locked_target then
        if state.aimbot_enabled then locked_target = nearest_target() end
        if not locked_target and state.object_aimbot_enabled then locked_target = nearest_object() end
    end

    if not locked_target then return end

    local aim_pos = locked_target.Position
    if locked_target.Parent and locked_target.Parent:IsA("Model") then
        local hrp = locked_target.Parent:FindFirstChild("HumanoidRootPart")
        if hrp then aim_pos = aim_pos + hrp.AssemblyLinearVelocity * state.aimbot_prediction end
    end
    local sp, onscreen = cam:WorldToViewportPoint(aim_pos)
    if not onscreen or sp.Z <= 0 then return end
    
    if state.aimbot_snap then
        local cam_pos = cam.CFrame.Position
        local target_cf = CFrame.lookAt(cam_pos, aim_pos)
        cam.CFrame = target_cf
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local look = Vector3.new(aim_pos.X, hrp.Position.Y, aim_pos.Z)
            hrp.CFrame = CFrame.lookAt(hrp.Position, look)
        end
    else
        local vp = cam.ViewportSize
        local dx = sp.X - vp.X * 0.5
        local dy = sp.Y - vp.Y * 0.5
        local strength = 1 - state.aimbot_smooth * 0.9
        if type(mousemoverel) == "function" then
            mousemoverel(dx * strength, dy * strength)
        else
            local cam_pos = cam.CFrame.Position
            local target_cf = CFrame.lookAt(cam_pos, aim_pos)
            if state.aimbot_smooth <= 0.01 then
                cam.CFrame = target_cf
            else
                local alpha = 1 - (0.001 ^ (dt * 60))
                cam.CFrame = cam.CFrame:Lerp(target_cf, alpha * (1 - state.aimbot_smooth * 0.7))
            end
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local look = Vector3.new(aim_pos.X, hrp.Position.Y, aim_pos.Z)
                hrp.CFrame = CFrame.lookAt(hrp.Position, look)
            end
        end
    end
end)

-- TRIGGERBOT BIND
RunService.Heartbeat:Connect(function()
    if not state.triggerbot then return end
    local mouse = player:GetMouse()
    if mouse.Target then
        local target_p = Players:GetPlayerFromCharacter(mouse.Target.Parent)
        if not target_p and mouse.Target.Name == "BSS_Hitbox" then
            for p, hb in pairs(hitbox_expanded) do
                if hb == mouse.Target then target_p = p; break end
            end
        end
        if target_p and target_p ~= player and player_in_game(target_p) then
            if not (state.aimbot_teamcheck and same_team(player, target_p)) then
                local vim = game:GetService("VirtualInputManager")
                vim:SendMouseButtonEvent(camera.ViewportSize.X/2, camera.ViewportSize.Y/2, 0, true, game, 0)
                vim:SendMouseButtonEvent(camera.ViewportSize.X/2, camera.ViewportSize.Y/2, 0, false, game, 0)
            end
        end
    end
end)

-- FINISH LOADING
task.wait(0.3)
update_loading("Finished!", 100)
task.wait(0.2)
loadingGui:Destroy()
main.Visible = true
tween(main_scale, {Scale = 1}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
