local View = {}
local Players = game:GetService("Players")

local function createToggle(parent, labelText, activeColor, onToggleCallback, startOn)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 220, 0, 52)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    btn.Text = ""
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(50, 50, 65)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(210, 210, 220)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = btn

    local pill = Instance.new("Frame")
    pill.Size, pill.Position = UDim2.new(0, 42, 0, 22), UDim2.new(1, -54, 0.5, -11)
    pill.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    pill.Parent = btn
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size, knob.Position = UDim2.new(0, 16, 0, 16), UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(180, 180, 190)
    knob.Parent = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local isOn = false
    
    local function setToggleState(newState, triggerCallback)
        if isOn == newState then return end 
        isOn = newState
        
        pill.BackgroundColor3 = isOn and activeColor or Color3.fromRGB(60, 60, 75)
        knob.Position = isOn and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        knob.BackgroundColor3 = isOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 190)
        btnStroke.Color = isOn and activeColor or Color3.fromRGB(50, 50, 65)
        
        if triggerCallback then
            onToggleCallback(isOn)
        end
    end

    btn.MouseButton1Click:Connect(function()
        setToggleState(not isOn, true)
    end)
    
    if startOn then
        setToggleState(true, true)
    end
    
    return setToggleState
end

function View.Build(callbacks)
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name, screenGui.ResetOnSpawn, screenGui.Parent = "FishingMenu", false, playerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size, mainFrame.Position = UDim2.new(0, 260, 0, 440), UDim2.new(0.5, -130, 0.5, -220)
    mainFrame.BackgroundColor3, mainFrame.Active, mainFrame.Draggable = Color3.fromRGB(18, 18, 24), true, true
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
    
    local titleBar = Instance.new("Frame")
    titleBar.Size, titleBar.BackgroundColor3 = UDim2.new(1, 0, 0, 40), Color3.fromRGB(0, 120, 200)
    titleBar.Parent = mainFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size, titleLabel.Position = UDim2.new(1, -40, 1, 0), UDim2.new(0, 12, 0, 0)
    titleLabel.BackgroundTransparency, titleLabel.Text, titleLabel.TextColor3 = 1, "Auto Fisher", Color3.fromRGB(255, 255, 255)
    titleLabel.Font, titleLabel.TextSize = Enum.Font.GothamBold, 16
    titleLabel.TextXAlignment, titleLabel.Parent = Enum.TextXAlignment.Left, titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size, closeBtn.Position = UDim2.new(0, 28, 0, 28), UDim2.new(1, -36, 0, 6)
    closeBtn.BackgroundColor3, closeBtn.Text, closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80), "X", Color3.fromRGB(255, 255, 255)
    closeBtn.Font, closeBtn.Parent = Enum.Font.GothamBold, titleBar
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

    local content = Instance.new("Frame")
    content.Size, content.Position, content.BackgroundTransparency = UDim2.new(1, 0, 1, -40), UDim2.new(0, 0, 0, 40), 1
    content.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding, listLayout.HorizontalAlignment = UDim.new(0, 10), Enum.HorizontalAlignment.Center
    listLayout.Parent = content

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 12)
    padding.Parent = content

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size, statusLabel.BackgroundTransparency, statusLabel.Text = UDim2.new(0, 220, 0, 24), 1, "Status: Idle"
    statusLabel.TextColor3, statusLabel.Font, statusLabel.TextSize = Color3.fromRGB(120, 120, 140), Enum.Font.Gotham, 12
    statusLabel.Parent = content

    local toggleUpdaters = {}
    
    toggleUpdaters.Fish = createToggle(content, "Auto Fish\nLovestruck Rod", Color3.fromRGB(0, 180, 255), callbacks.OnFishToggle, false)
    toggleUpdaters.Buy = createToggle(content, "Auto Buy Bait\nBelow 10 -> Buy 290", Color3.fromRGB(80, 200, 80), callbacks.OnBuyToggle, false)
    toggleUpdaters.Sell = createToggle(content, "Auto Sell Fish\nFish count >= 40", Color3.fromRGB(255, 160, 0), callbacks.OnSellToggle, false)
    toggleUpdaters.Travel = createToggle(content, "Travel to Bait\nFinds empty spot", Color3.fromRGB(150, 80, 200), callbacks.OnTravelToggle, false)
    toggleUpdaters.AFK = createToggle(content, "AFK Mode\nAuto-start after 20s", Color3.fromRGB(255, 60, 100), callbacks.OnAFKToggle, true)

    closeBtn.MouseButton1Click:Connect(function()
        callbacks.OnClose()
        screenGui:Destroy()
    end)

    return {
        UpdateStatus = function(text)
            statusLabel.Text = text
        end,
        ForceTogglesOn = function()
            toggleUpdaters.Buy(true, true)
            toggleUpdaters.Sell(true, true)
            toggleUpdaters.Travel(true, true)
        end,
        ForceFishOn = function()
            toggleUpdaters.Fish(true, true)
        end
    }
end

return View