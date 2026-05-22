-- Require the modules (Assumes they are children of this script)
local Model = require(script:WaitForChild("Model"))
local View = require(script:WaitForChild("View"))

-- 1. Setup the UI and provide instructions (callbacks) on what to do when buttons are clicked
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
    OnClose = function()
        Model.State.isFishing = false
        Model.State.autoBuy = false
        Model.State.autoSell = false
    end
})

-- 2. Hook up Model Events
Model.ListenToInventoryChanges(function()
    Model.CheckInventory()
end)

-- 3. Run Background Loops
-- Bait checking loop
task.spawn(function()
    while task.wait(2) do
        if Model.State.autoBuy then
            Model.CheckInventory()
        end
    end
end)

-- Fishing engine loop
task.spawn(function()
    while true do
        task.wait()
        if Model.State.isFishing then
            Model.DoFishingCycle()
        end
    end
end)

-- Status updating loop (Tells the View what text to display)
task.spawn(function()
    while task.wait(1) do
        local parts = {}
        if Model.State.isFishing then table.insert(parts, "Fishing") end
        if Model.State.autoBuy then table.insert(parts, "Buying") end
        if Model.State.autoSell then table.insert(parts, "Selling") end
        
        local statusText = #parts > 0 and ("Active: " .. table.concat(parts, "  ")) or "Status: Idle"
        uiHandle.UpdateStatus(statusText)
    end
end)

-- Initial check
Model.CheckInventory()