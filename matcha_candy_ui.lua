local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- Matcha InputBegan returns integer key codes. Letters use lowercase ASCII.
local KEY_VISIBILITY = 104 -- H
local KEY_BIND = 98 -- B
local KEY_UNLOAD = 117 -- U
local KEY_Z = 122
local KEY_X = 120
local DEFAULT_TOGGLE_KEY = 107 -- K
local FAST_DELAY = 0.4
local SLOW_DELAY = 3.0
local CONFIG_PATH = "matcha_candy_toggle_key.txt"

local function loadToggleKey()
    if isfile(CONFIG_PATH) then
        local saved = tonumber(readfile(CONFIG_PATH))
        if saved and saved > 0 and saved ~= KEY_VISIBILITY then
            return saved
        end
    end
    return DEFAULT_TOGGLE_KEY
end

local function keyName(key)
    if key >= 97 and key <= 122 then
        return string.upper(string.char(key))
    elseif key >= 48 and key <= 57 then
        return string.char(key)
    end

    local names = {
        [8] = "BACKSPACE",
        [9] = "TAB",
        [13] = "ENTER",
        [27] = "ESC",
        [32] = "SPACE",
        [277] = "INSERT",
        [280] = "PAGE UP",
        [281] = "PAGE DOWN",
    }
    return names[key] or ("KEY " .. tostring(key))
end

if _G.MatchaCandyUI and _G.MatchaCandyUI.unload then
    _G.MatchaCandyUI.unload()
end

local state = {
    alive = true,
    running = false,
    visible = true,
    delay = FAST_DELAY,
    speedMode = "FAST",
    collected = 0,
    available = 0,
    binding = false,
    toggleKey = loadToggleKey(),
}

local drawings = {}

local function addDrawing(kind)
    local item = Drawing.new(kind)
    drawings[#drawings + 1] = item
    return item
end

local panel = addDrawing("Square")
panel.Position = Vector2.new(24, 210)
panel.Size = Vector2.new(350, 214)
panel.Color = Color3.fromRGB(20, 23, 30)
panel.Transparency = 0.12
panel.Filled = true
panel.Thickness = 1
panel.Visible = true

local accent = addDrawing("Square")
accent.Position = Vector2.new(24, 210)
accent.Size = Vector2.new(5, 214)
accent.Color = Color3.fromRGB(255, 145, 30)
accent.Transparency = 0
accent.Filled = true
accent.Visible = true

local title = addDrawing("Text")
title.Position = Vector2.new(42, 224)
title.Size = 18
title.Text = "MATCHA RESELLER 7679"
title.Color = Color3.fromRGB(255, 190, 70)
title.Outline = true
title.Visible = true

local statusText = addDrawing("Text")
statusText.Position = Vector2.new(42, 255)
statusText.Size = 15
statusText.Color = Color3.fromRGB(235, 235, 240)
statusText.Outline = true
statusText.Visible = true

local countText = addDrawing("Text")
countText.Position = Vector2.new(42, 280)
countText.Size = 14
countText.Color = Color3.fromRGB(205, 210, 220)
countText.Outline = true
countText.Visible = true

local speedText = addDrawing("Text")
speedText.Position = Vector2.new(42, 305)
speedText.Size = 13
speedText.Color = Color3.fromRGB(205, 210, 220)
speedText.Outline = true
speedText.Visible = true

local bindText = addDrawing("Text")
bindText.Position = Vector2.new(42, 330)
bindText.Size = 13
bindText.Color = Color3.fromRGB(255, 205, 105)
bindText.Outline = true
bindText.Visible = true

local helpText = addDrawing("Text")
helpText.Size = 13
helpText.Position = Vector2.new(42, 354)
helpText.Text = "H: Show or Hide | U: Unload\nZ: Slowest | X: Fastest"
helpText.Color = Color3.fromRGB(170, 180, 195)
helpText.Outline = true
helpText.Visible = true

local function refreshUI()
    statusText.Text = "Status: " .. (state.running and "RUNNING" or "STOPPED")
        .. " | Speed: " .. state.speedMode
    statusText.Color = state.running
        and Color3.fromRGB(90, 235, 135)
        or Color3.fromRGB(255, 115, 115)
    countText.Text = "Available: " .. tostring(state.available)
        .. " | Teleports: " .. tostring(state.collected)
    speedText.Text = "Z = SLOWEST (3.0s)   |   X = FASTEST (0.4s)"
    speedText.Color = state.speedMode == "FAST"
        and Color3.fromRGB(90, 235, 135)
        or Color3.fromRGB(255, 205, 105)
    if state.binding then
        bindText.Text = "Toggle key: PRESS A KEY... (H reserved)"
        bindText.Color = Color3.fromRGB(255, 145, 30)
    else
        bindText.Text = "Toggle key: " .. keyName(state.toggleKey) .. " | B: Rebind"
        bindText.Color = Color3.fromRGB(255, 205, 105)
    end
end

local function setVisible(visible)
    state.visible = visible
    if not visible then
        state.binding = false
    end
    for _, item in ipairs(drawings) do
        item.Visible = visible
    end
end

local inputConnection

local function unload()
    if not state.alive then
        return
    end

    state.running = false
    state.alive = false

    if inputConnection then
        inputConnection:Disconnect()
    end

    for _, item in ipairs(drawings) do
        item:Remove()
    end

    _G.MatchaCandyUI = nil
    print("Candy UI unloaded")
end

_G.MatchaCandyUI = {
    start = function()
        state.running = true
        refreshUI()
    end,
    stop = function()
        state.running = false
        refreshUI()
    end,
    setToggleKey = function(key)
        if type(key) == "number" and key > 0
            and key ~= KEY_VISIBILITY then
            state.toggleKey = key
            writefile(CONFIG_PATH, tostring(key))
            refreshUI()
        end
    end,
    unload = unload,
}

inputConnection = UserInputService.InputBegan:Connect(function(input)
    local key = input.KeyCode

    if key == KEY_VISIBILITY then
        setVisible(not state.visible)
        return
    end

    if state.binding then
        if key ~= KEY_BIND then
            state.toggleKey = key
            state.binding = false
            writefile(CONFIG_PATH, tostring(key))
            refreshUI()
            print("Candy toggle key saved: " .. keyName(key))
        end
        return
    end

    if key == KEY_BIND and state.visible then
        state.binding = true
        refreshUI()
        print("Press a new key for Candy start/stop")
    elseif key == state.toggleKey then
        state.running = not state.running
        refreshUI()
        print(state.running and "Candy collector started" or "Candy collector stopped")
    elseif key == KEY_X then
        state.delay = FAST_DELAY
        state.speedMode = "FAST"
        refreshUI()
    elseif key == KEY_Z then
        state.delay = SLOW_DELAY
        state.speedMode = "SLOW"
        refreshUI()
    elseif key == KEY_UNLOAD then
        unload()
    end
end)

refreshUI()
print("Candy UI loaded - toggle key: " .. keyName(state.toggleKey))
print("H shows/hides the panel; B changes the toggle key")

task.spawn(function()
    while state.alive do
        if not state.running then
            task.wait(0.15)
        else
            local folder = Workspace:FindFirstChild("CandyCorns")
            local candies = folder and folder:GetChildren() or {}
            local moved = 0

            state.available = #candies
            refreshUI()

            for _, candy in ipairs(candies) do
                if not state.alive or not state.running then
                    break
                end

                if candy.ClassName == "Part"
                    or candy.ClassName == "MeshPart"
                    or candy.ClassName == "UnionOperation" then
                    local player = Players.LocalPlayer
                    local character = player and player.Character
                    local root = character
                        and character:FindFirstChild("HumanoidRootPart")
                    local position = candy.Position

                    if root and position then
                        root.CFrame = CFrame.new(
                            position.X,
                            position.Y + 2.2,
                            position.Z
                        )

                        moved = moved + 1
                        state.collected = state.collected + 1
                        refreshUI()
                        task.wait(state.delay)
                    end
                end
            end

            if moved == 0 then
                task.wait(1.5)
            else
                task.wait(0.8)
            end
        end
    end
end)
