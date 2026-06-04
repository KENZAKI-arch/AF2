local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Make sure your GitHub files are updated first, or this will download the old code!
local Model = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/AF2/refs/heads/main/Model.lua"))()
local View = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/AF2/refs/heads/main/View.lua"))()

local isAFKModeActive = false
local secondsSinceLastInput = 0

UserInputService.InputBegan:Connect(function() secondsSinceLastInput = 0 end)
UserInputService.InputChanged:Connect(function() secondsSinceLastInput = 0 end)

local uiHandle = View.Build({
    OnFishToggle = function(isOn)
        Model.State.isFishing = isOn
    end,
    OnBuyToggle = function(isOn)
        Model.State.autoBuy = isOn
        if isOn then Model.CheckInventory() end
    end,
    OnSellToggle = function(isOn)
        Model.State.autoSell = isOn
        if isOn then Model.CheckInventory() end
    end,
    OnTravelToggle = function(isOn)
        Model.State.isAutoTraveling = isOn
        if isOn then
            local pos = Model.GetFreeBaitPosition()
            if pos then
                Model.State.targetPos = pos
                Model.State.travelMessage = "Traveling..."
                Model.EnableFlight()
            else
                Model.State.isAutoTraveling = false
                Model.State.travelMessage = "All Baits Full"
            end
        else
            Model.DisableFlight()
            Model.State.targetPos = nil
            Model.State.travelMessage = ""
        end
    end,
    OnAFKToggle = function(isOn)
        isAFKModeActive = isOn
        secondsSinceLastInput = 0 
    end,
    OnClose = function()
        Model.State.isFishing = false
        Model.State.autoBuy = false
        Model.State.autoSell = false
        Model.State.isAutoTraveling = false
        isAFKModeActive = false
        Model.DisableFlight()
    end
})

task.spawn(function()
    while task.wait(1) do
        if isAFKModeActive then
            secondsSinceLastInput = secondsSinceLastInput + 1
            if secondsSinceLastInput == 20 then
                uiHandle.ForceTogglesOn()
                Model.State.waitingForArrivalToFish = true
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    if Model.State.isAutoTraveling then
        local char = Players.LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function(deltaTime)
    if Model.State.isAutoTraveling then
        Model.HandleMovement(deltaTime)
    end
end)

Model.ListenToInventoryChanges(function()
    Model.CheckInventory()
end)

task.spawn(function()
    while task.wait(2) do
        if Model.State.autoBuy then
            Model.CheckInventory()
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if Model.State.isFishing then
            Model.DoFishingCycle()
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        local parts = {}
        if Model.State.isFishing then table.insert(parts, "Fishing") end
        if Model.State.autoBuy then table.insert(parts, "Buying") end
        if Model.State.autoSell then table.insert(parts, "Selling") end
        if isAFKModeActive then table.insert(parts, "[AFK ON]") end
        
        if Model.State.isAutoTraveling or Model.State.travelMessage ~= "" then
            uiHandle.UpdateStatus("Status: " .. Model.State.travelMessage)
            if Model.State.travelMessage == "Arrived at Bait" or Model.State.travelMessage == "All Baits Full" then
                if Model.State.travelMessage == "Arrived at Bait" and Model.State.waitingForArrivalToFish then
                    Model.State.waitingForArrivalToFish = false
                    uiHandle.ForceFishOn()
                end
                task.delay(3, function() Model.State.travelMessage = "" end)
            end
        else
            local statusText = #parts > 0 and ("Active: " .. table.concat(parts, " ")) or "Status: Idle"
            uiHandle.UpdateStatus(statusText)
        end
    end
end)

Model.CheckInventory()