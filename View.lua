local View = {}

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FishingMenu"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 320)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 180, 255)
stroke.Thickness = 1.5
stroke.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0.5, 0)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Auto Fisher"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -70, 0, 6)
minBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 0)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.TextSize = 18
minBtn.Font = Enum.Font.GothamBold
minBtn.BorderSizePixel = 0
minBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -40)
content.Position = UDim2.new(0, 0, 0, 40)
content.BackgroundTransparency = 1
content.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = content

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.Parent = content

local function makeToggle(labelText, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 220, 0, 52)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Parent = content

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(50, 50, 65)
    btnStroke.Thickness = 1
    btnStroke.Parent = btn

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(210, 210, 220)
    label.TextSize = 13
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = btn

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 42, 0, 22)
    pill.Position = UDim2.new(1, -54, 0.5, -11)
    pill.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    pill.BorderSizePixel = 0
    pill.Parent = btn

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(1, 0)
    pillCorner.Parent = pill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(180, 180, 190)
    knob.BorderSizePixel = 0
    knob.Parent = pill

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local function setState(on)
        if on then
            pill.BackgroundColor3 = color
            knob.Position = UDim2.new(1, -19, 0.5, -8)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            btnStroke.Color = color
        else
            pill.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
            knob.Position = UDim2.new(0, 3, 0.5, -8)
            knob.BackgroundColor3 = Color3.fromRGB(180, 180, 190)
            btnStroke.Color = Color3.fromRGB(50, 50, 65)
        end
    end

    return btn, setState
end

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 220, 0, 24)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = content

-- Build toggles
local fishBtn, setFish = makeToggle("Auto Fish\nLovestruck Rod", Color3.fromRGB(0, 180, 255))
local buyBtn, setBuy = makeToggle("Auto Buy Bait\nBelow 10 -> Buy 290", Color3.fromRGB(80, 200, 80))
local sellBtn, setSell = makeToggle("Auto Sell Fish\nFish count >= 40", Color3.fromRGB(255, 160, 0))

-- Expose to Controller
View.fishBtn = fishBtn
View.setFish = setFish
View.buyBtn = buyBtn
View.setBuy = setBuy
View.sellBtn = sellBtn
View.setSell = setSell
View.minBtn = minBtn
View.closeBtn = closeBtn
View.screenGui = screenGui
View.mainFrame = mainFrame
View.content = content

function View.updateStatus(isFishing, autoBuyEnabled, autoSellEnabled)
    local parts = {}
    if isFishing then table.insert(parts, "Fishing") end
    if autoBuyEnabled then table.insert(parts, "Buying") end
    if autoSellEnabled then table.insert(parts, "Selling") end
    statusLabel.Text = #parts > 0 and ("Active: " .. table.concat(parts, "  ")) or "Status: Idle"
end

function View.startStatusLoop(getState)
    task.spawn(function()
        while task.wait(1) do
            local state = getState()
            View.updateStatus(state.isFishing, state.autoBuyEnabled, state.autoSellEnabled)
        end
    end)
end

return View