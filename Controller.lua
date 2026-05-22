-- Fetch the modules directly from your GitHub
local Model = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/AF2/refs/heads/main/Model.lua"))()
local View = loadstring(game:HttpGet("https://raw.githubusercontent.com/KENZAKI-arch/AF2/refs/heads/main/View.lua"))()

-- Connect the View (UI) to the Model (Logic)
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

-- Listen for inventory changes on the client
Model.ListenToInventoryChanges(function()
    Model.CheckInventory()
end)

-- The background checking loop for buying bait
task.spawn(function()
    while task.wait(2) do
        if Model.State.autoBuy then
            Model.CheckInventory()
        end
    end
end)

-- The fishing loop engine
task.spawn(function()
    while true do
        task.wait()
        if Model.State.isFishing then
            Model.DoFishingCycle()
        end
    end
end)

-- Status text loop (shows what is currently active)
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

-- Run a quick check right away
Model.CheckInventory()