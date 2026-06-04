-- === 1. KILL SWITCH: DESTROY OLD VERSIONS ===
if _G.AF2_Running then
    _G.AF2_Running = false -- Tells all old loops to stop dead in their tracks
    
    -- Disconnect old background events
    if _G.AF2_Connections then
        for _, conn in pairs(_G.AF2_Connections) do
            pcall(function() conn:Disconnect() end)
        end
    end
    
    -- Destroy old menu if it exists
    local oldMenu = game.Players.LocalPlayer.PlayerGui:FindFirstChild("FishingMenu")
    if oldMenu then oldMenu:Destroy() end
    
    task.wait(0.5) -- Give the game half a second to clear out the ghosts
end

-- Start fresh for the new version
_G.AF2_Running = true
_G.AF2_Connections = {}
-- ============================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Model = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/AF2/refs/heads/main/Model.lua"))()
local View = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/AF2/refs/heads/main/View.lua"))()

-- AFK Timer Variables
local isAFKModeActive = false
local secondsSinceLastInput = 0

-- Reset the stopwatch whenever the player moves their mouse or types
-- We save these connections so the kill switch can delete them later!
table.insert(_G.AF2_Connections, UserInputService.InputBegan:Connect(function() secondsSinceLastInput = 0 end))
table.insert(_G.AF2_Connections, UserInputService.InputChanged:Connect(function() secondsSinceLastInput = 0 end))

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

-- =======================================
-- THE AFK STOPWATCH LOOP
-- =======================================
task.spawn(function()
    while task.wait(1) do
        if not _G.AF2_Running then break end -- Kill Switch: Stops old version

        if isAFKModeActive then
            secondsSinceLastInput = secondsSinceLastInput + 1
            
            if secondsSinceLastInput == 20 then
                uiHandle.ForceTogglesOn()
                Model.State.waitingForArrivalToFish = true
            end
        end
    end
end)

-- Travel Loop & Noclip
table.insert(_G.AF2_Connections, RunService.Stepped:Connect(function()
    if Model.State.isAutoTraveling then
        local char = Players.LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end))

table.insert(_G.AF2_Connections, RunService.Heartbeat:Connect(function(deltaTime)
    if Model.State.isAutoTraveling then
        Model.HandleMovement(deltaTime)
    end
end))

Model.ListenToInventoryChanges(function()
    Model.CheckInventory()
end)

task.spawn(function()
    while task.wait(2) do
        if not _G.AF2_Running then break end -- Kill Switch
        if Model.State.autoBuy then
            Model.CheckInventory()
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if not _G.AF2_Running then break end -- Kill Switch
        if Model.State.isFishing then
            Model.DoFishingCycle()
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if not _G.AF2_Running then break end -- Kill Switch

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