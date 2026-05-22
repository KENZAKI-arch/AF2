local Model = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local shopEvent = ReplicatedStorage:WaitForChild("Events", 9e9):WaitForChild("Shop", 9e9)
local buyableItems = workspace:WaitForChild("BuyableItems", 9e9)
local sellEvent = ReplicatedStorage:WaitForChild("FishingShopRemote", 9e9)
local statsFolder = ReplicatedStorage:WaitForChild("Stats" .. player.Name, 9e9)
local inventoryObj = statsFolder:WaitForChild("Inventory", 9e9):WaitForChild("Inventory", 9e9)
local Remote = ReplicatedStorage:WaitForChild("Fishing", 9e9):WaitForChild("Remotes", 9e9):WaitForChild("Action", 9e9)

-- Constants
local BAIT_NAME = "Common Fish Bait"
local MIN_BAIT = 10
local BUY_AMOUNT = 290
local BAIT_SEARCH_RADIUS = 25
local THROW_ANIMATION_ID = "rbxassetid://140322334422224"
local THROW_ANIMATION_TIME = 0.8
local FISH_WAIT_TIME = 9
local REEL_ANIMATION_ID = "rbxassetid://136623058564703"
local REEL_ANIMATION_TIME = 1.2

local fishToSell = {
    "Crimson Snapper", "Exotic Tigerfin", "Fangfish", 
    "Zebra Ribbon Angelfish", "Blue-Lip Grouper", 
    "Tigerfin", "Crimson Polka Puffer"
}

-- State Data
Model.State = {
    isFishing = false,
    autoBuy = false,
    autoSell = false,
    isBuying = false
}

-- Helper Functions
local function getItemPosition(item)
    if item:IsA("BasePart") then return item.Position end
    if item:IsA("Model") then return item:GetPivot().Position end
    local part = item:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local function playAnimation(animationId)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    
    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
    local anim = Instance.new("Animation")
    anim.AnimationId = animationId
    local track = animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action
    track:Play(0.1)
    return track
end

-- Core Logic Functions
function Model.BuyNearestBait()
    if Model.State.isBuying then return end
    Model.State.isBuying = true

    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local nearestBait = nil
    local nearestDistance = BAIT_SEARCH_RADIUS

    for _, item in ipairs(buyableItems:GetChildren()) do
        if string.find(string.lower(item.Name), "bait") then
            local itemPos = getItemPosition(item)
            if itemPos then
                local distance = (rootPart.Position - itemPos).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestBait = item
                end
            end
        end
    end

    if nearestBait then
        pcall(function()
            if shopEvent:IsA("RemoteFunction") then
                shopEvent:InvokeServer(nearestBait, BUY_AMOUNT)
            else
                shopEvent:FireServer(nearestBait, BUY_AMOUNT)
            end
        end)
    end
    task.wait(0.5)
    Model.State.isBuying = false
end

function Model.CheckInventory()
    local success, inventoryData = pcall(function()
        return HttpService:JSONDecode(inventoryObj.Value)
    end)
    if not success or not inventoryData then return end

    -- Check Bait
    if Model.State.autoBuy and not Model.State.isBuying then
        local count = inventoryData[BAIT_NAME] or 0
        if count < MIN_BAIT then Model.BuyNearestBait() end
    end

    -- Check Fish
    if Model.State.autoSell then
        for _, fishName in ipairs(fishToSell) do
            local count = inventoryData[fishName] or 0
            if count >= 40 then
                pcall(function()
                    sellEvent:InvokeServer({Fish = fishName, All = true, Method = "SellFish"})
                end)
            end
        end
    end
end

function Model.DoFishingCycle()
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local throwGoal = rootPart.Position + (rootPart.CFrame.LookVector * 20) + Vector3.new(0, -5, 0)

    pcall(function()
        Remote:InvokeServer({Bait = BAIT_NAME, Action = "Throw", Goal = throwGoal})
    end)

    local throwTrack = playAnimation(THROW_ANIMATION_ID)
    if throwTrack then
        task.delay(THROW_ANIMATION_TIME, function() throwTrack:Stop(0.15) end)
    end

    task.wait(FISH_WAIT_TIME)

    local reelTrack = playAnimation(REEL_ANIMATION_ID)
    task.wait(REEL_ANIMATION_TIME)

    pcall(function() Remote:InvokeServer({ Action = "Reel" }) end)
    if reelTrack then reelTrack:Stop(0.2) end
    task.wait(0.2)
    pcall(function() Remote:InvokeServer({ Action = "Cancel" }) end)
end

function Model.ListenToInventoryChanges(callback)
    inventoryObj:GetPropertyChangedSignal("Value"):Connect(callback)
end

return Model