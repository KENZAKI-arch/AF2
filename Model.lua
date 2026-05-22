_G.Model = {}
local Model = _G.Model

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local buyableItems = workspace:WaitForChild("BuyableItems", 9e9)
local shopEvent = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("Shop", 9e9)
local sellEvent = ReplicatedStorage:WaitForChild("FishingShopRemote", 9e9)
local statsFolder = ReplicatedStorage:WaitForChild("Stats" .. player.Name, 9e9)
local Remote = ReplicatedStorage:WaitForChild("Fishing", 9e9):WaitForChild("Remotes", 9e9):WaitForChild("Action", 9e9)

Model.inventoryObj = statsFolder:WaitForChild("Inventory", 9e9):WaitForChild("Inventory", 9e9)

Model.BAIT_NAME = "Common Fish Bait"
Model.MIN_BAIT = 10
Model.BUY_AMOUNT = 290
Model.BAIT_SEARCH_RADIUS = 25
Model.THROW_ANIMATION_ID = "rbxassetid://140322334422224"
Model.THROW_ANIMATION_TIME = 0.8
Model.FISH_WAIT_TIME = 9
Model.REEL_ANIMATION_ID = "rbxassetid://136623058564703"
Model.REEL_ANIMATION_TIME = 1.2

Model.isFishing = false
Model.autoBuyEnabled = false
Model.autoSellEnabled = false
Model.isBuying = false

Model.fishToSell = {
    "Crimson Snapper",
    "Exotic Tigerfin",
    "Fangfish",
    "Zebra Ribbon Angelfish",
    "Blue-Lip Grouper",
    "Tigerfin",
    "Crimson Polka Puffer",
}

function Model.getItemPosition(item)
    if item:IsA("BasePart") then return item.Position end
    if item:IsA("Model") then return item:GetPivot().Position end
    local part = item:FindFirstChildWhichIsA("BasePart", true)
    if part then return part.Position end
    return nil
end

function Model.getNearestBait(maxDistance)
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local nearestBait = nil
    local nearestDistance = maxDistance or math.huge
    for _, item in ipairs(buyableItems:GetChildren()) do
        if string.find(string.lower(item.Name), "bait") then
            local itemPos = Model.getItemPosition(item)
            if itemPos then
                local distance = (rootPart.Position - itemPos).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestBait = item
                end
            end
        end
    end
    return nearestBait, nearestDistance
end

function Model.buyNearestBait(amount)
    if Model.isBuying then return end
    Model.isBuying = true
    local nearestBait, distance = Model.getNearestBait(Model.BAIT_SEARCH_RADIUS)
    if nearestBait then
        print("Nearest bait:", nearestBait.Name, "Distance:", distance)
        pcall(function()
            if shopEvent:IsA("RemoteFunction") then
                shopEvent:InvokeServer(nearestBait, amount)
            elseif shopEvent:IsA("RemoteEvent") then
                shopEvent:FireServer(nearestBait, amount)
            end
        end)
        print("Bought", amount, "bait.")
    else
        warn("No bait found near you.")
    end
    task.wait(0.5)
    Model.isBuying = false
end

function Model.checkBaitInventory()
    if not Model.autoBuyEnabled or Model.isBuying then return end
    local success, inventoryData = pcall(function()
        return HttpService:JSONDecode(Model.inventoryObj.Value)
    end)
    if success and inventoryData then
        local count = inventoryData[Model.BAIT_NAME] or 0
        if count < Model.MIN_BAIT then
            print("Bait below", Model.MIN_BAIT, "current:", count, "buying", Model.BUY_AMOUNT)
            Model.buyNearestBait(Model.BUY_AMOUNT)
        end
    end
end

function Model.sellFish(fishName)
    pcall(function()
        sellEvent:InvokeServer({
            Fish = fishName,
            All = true,
            Method = "SellFish"
        })
    end)
end

function Model.checkInventory()
    if not Model.autoSellEnabled then return end
    local success, inventoryData = pcall(function()
        return HttpService:JSONDecode(Model.inventoryObj.Value)
    end)
    if success and inventoryData then
        for _, fishName in ipairs(Model.fishToSell) do
            local count = inventoryData[fishName] or 0
            if count >= 40 then
                Model.sellFish(fishName)
            end
        end
    end
end

function Model.getAnimator()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    return animator
end

function Model.playAnimation(animationId, looped)
    local animator = Model.getAnimator()
    if not animator then return nil end
    local anim = Instance.new("Animation")
    anim.AnimationId = animationId
    local track = animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action
    track.Looped = looped == true
    track:Play(0.1)
    return track
end

function Model.doFishingCycle()
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local throwGoal = rootPart.Position + (rootPart.CFrame.LookVector * 20) + Vector3.new(0, -5, 0)

    local throwOk, throwErr = pcall(function()
        Remote:InvokeServer({
            Bait = Model.BAIT_NAME,
            Action = "Throw",
            Goal = throwGoal,
        })
    end)

    if not throwOk then
        warn("Throw failed:", throwErr)
        return
    end

    local throwTrack = Model.playAnimation(Model.THROW_ANIMATION_ID, false)
    if throwTrack then
        task.delay(Model.THROW_ANIMATION_TIME, function()
            if throwTrack and throwTrack.IsPlaying then
                throwTrack:Stop(0.15)
            end
        end)
    end

    task.wait(Model.FISH_WAIT_TIME)

    local reelTrack = Model.playAnimation(Model.REEL_ANIMATION_ID, false)
    task.wait(Model.REEL_ANIMATION_TIME)

    pcall(function()
        Remote:InvokeServer({ Action = "Reel" })
    end)

    if reelTrack then reelTrack:Stop(0.2) end
    task.wait(0.2)

    pcall(function()
        Remote:InvokeServer({ Action = "Cancel" })
    end)
end

function Model.startLoops()
    task.spawn(function()
        while true do
            task.wait()
            if Model.isFishing then
                local ok, err = pcall(Model.doFishingCycle)
                if not ok then warn("Cycle error:", err) end
            end
        end
    end)

    task.spawn(function()
        while task.wait(2) do
            Model.checkBaitInventory()
        end
    end)

    Model.inventoryObj:GetPropertyChangedSignal("Value"):Connect(function()
        Model.checkBaitInventory()
        Model.checkInventory()
    end)
end