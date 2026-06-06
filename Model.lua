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

-- The list of valid rods to look for
local VALID_RODS = {
    "Devil Fruit Rod", 
    "Merchants Banana Rod", 
    "Lovestruck Rod", 
    "Fishing Rod"
}

-- State Data
Model.State = {
    isFishing = false,
    autoBuy = false,
    autoSell = false,
    isBuying = false,
    isAutoTraveling = false,
    targetPos = nil,
    travelMessage = ""
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

-- ========================================== --
-- AUTO EQUIP LOGIC
-- ========================================== --
function Model.EquipRod()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and table.find(VALID_RODS, tool.Name) then
            return -- Already equipped
        end
    end

    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and table.find(VALID_RODS, tool.Name) then
                print("[AutoFisher] Equipping rod:", tool.Name)
                humanoid:EquipTool(tool)
                task.wait(0.2) 
                return
            end
        end
    end
end

-- ========================================== --
-- TRAVEL AND PHYSICS LOGIC
-- ========================================== --
function Model.EnableFlight()
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if rootPart and humanoid then
        print("[AutoFisher] Enabling flight to travel to bait...")
        humanoid.PlatformStand = true 
        local bg = rootPart:FindFirstChild("AutoTravel_Gyro") or Instance.new("BodyGyro")
        bg.Name, bg.P, bg.MaxTorque, bg.CFrame, bg.Parent = "AutoTravel_Gyro", 9e4, Vector3.new(9e9, 9e9, 9e9), rootPart.CFrame, rootPart
        
        local bv = rootPart:FindFirstChild("AutoTravel_Velocity") or Instance.new("BodyVelocity")
        bv.Name, bv.Velocity, bv.MaxForce, bv.Parent = "AutoTravel_Velocity", Vector3.new(0, 0, 0), Vector3.new(9e9, 9e9, 9e9), rootPart
    end
end

function Model.DisableFlight()
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if rootPart then
        local bg = rootPart:FindFirstChild("AutoTravel_Gyro")
        if bg then bg:Destroy() end
        local bv = rootPart:FindFirstChild("AutoTravel_Velocity")
        if bv then bv:Destroy() end
    end
    if humanoid then 
        humanoid.PlatformStand = false 
        print("[AutoFisher] Flight disabled.")
    end
end

function Model.GetFreeBaitPosition()
    if not buyableItems then return nil end
    
    -- Hub Fence: Find the exact center of the Fishing Hub Island
    local islandsFolder = workspace:FindFirstChild("Islands")
    local fishingHub = islandsFolder and islandsFolder:FindFirstChild("Fishing Hub")
    local hubCenterPos = nil
    
    if fishingHub then
        local hubPart = fishingHub:IsA("Model") and fishingHub.PrimaryPart or fishingHub:FindFirstChildWhichIsA("BasePart", true)
        if hubPart then
            hubCenterPos = hubPart.Position
        end
    end

    for _, item in pairs(buyableItems:GetChildren()) do
        if item.Name == BAIT_NAME then
            local baitCFrame = item:IsA("Model") and item.PrimaryPart.CFrame or item.CFrame
            local baitPosition = baitCFrame.Position
            
            local isLocalBait = true
            
            -- CHECK: Is it too far from the hub? (Prevents flying to other islands)
            if hubCenterPos and (baitPosition - hubCenterPos).Magnitude > 1000 then
                isLocalBait = false
            end
            
            if isLocalBait then
                -- THE PEDESTAL TARGET: Calculates a safe spot exactly 4 studs ABOVE the bait
                local safeSpot = baitPosition + Vector3.new(0, 4, 0)
                local isOccupied = false

                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= player and plr.Character then
                        local root = plr.Character:FindFirstChild("HumanoidRootPart")
                        if root and (root.Position - baitPosition).Magnitude < 12 then
                            isOccupied = true
                            break
                        end
                    end
                end
                
                if not isOccupied then 
                    print("[AutoFisher] Found a free bait pedestal at:", safeSpot)
                    return safeSpot 
                end
            end
        end
    end
    
    print("[AutoFisher] Could not find any free bait pedestals.")
    return nil
end

function Model.HandleMovement(deltaTime)
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart or not Model.State.targetPos then return end

    local currentPos = rootPart.Position
    local target = Model.State.targetPos
    local nextPoint
    
    -- Simple Straight-Line Lerp Logic (X -> Z -> Y)
    if math.abs(currentPos.X - target.X) > 1 then
        nextPoint = Vector3.new(target.X, currentPos.Y, currentPos.Z)
        
    elseif math.abs(currentPos.Z - target.Z) > 1 then
        nextPoint = Vector3.new(target.X, currentPos.Y, target.Z)
        
    elseif math.abs(currentPos.Y - target.Y) > 1 then
        nextPoint = Vector3.new(target.X, target.Y, target.Z)
        
    else
        -- Arrived exactly on the pedestal!
        print("[AutoFisher] Arrived at bait pedestal successfully!")
        Model.State.isAutoTraveling = false
        Model.DisableFlight()
        Model.State.travelMessage = "Arrived at Bait"
        return
    end

    local distance = (currentPos - nextPoint).Magnitude
    if distance > 0 then
        local alpha = math.clamp((90 * deltaTime) / distance, 0, 1)
        rootPart.CFrame = rootPart.CFrame:Lerp(CFrame.new(nextPoint), alpha)
    end
    
    rootPart.Velocity = Vector3.new(0, 0, 0)
    rootPart.RotVelocity = Vector3.new(0, 0, 0)
end

-- ========================================== --
-- CORE FISHING LOGIC
-- ========================================== --
function Model.BuyNearestBait()
    if Model.State.isBuying then return end
    Model.State.isBuying = true

    print("[AutoFisher] Bait is low! Attempting to buy more...")

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
        print("[AutoFisher] Buying 290 bait from nearest shop...")
        pcall(function()
            if shopEvent:IsA("RemoteFunction") then shopEvent:InvokeServer(nearestBait, BUY_AMOUNT)
            else shopEvent:FireServer(nearestBait, BUY_AMOUNT) end
        end)
    else
        print("[AutoFisher] Could not find a bait shop nearby.")
    end
    
    task.wait(0.5)
    Model.State.isBuying = false
end

function Model.CheckInventory()
    local success, inventoryData = pcall(function() return HttpService:JSONDecode(inventoryObj.Value) end)
    if not success or not inventoryData then return end

    if Model.State.autoBuy and not Model.State.isBuying then
        local count = inventoryData[BAIT_NAME] or 0
        if count < MIN_BAIT then 
            Model.BuyNearestBait() 
        end
    end

    if Model.State.autoSell then
        for _, fishName in ipairs(fishToSell) do
            local count = inventoryData[fishName] or 0
            if count >= 40 then
                print("[AutoFisher] Fish limit reached! Selling all:", fishName)
                pcall(function() sellEvent:InvokeServer({Fish = fishName, All = true, Method = "SellFish"}) end)
            end
        end
    end
end

function Model.DoFishingCycle()
    local character = player.Character
    if not character then return end
    
    Model.EquipRod()
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- 1. Calculate where to throw and send the command
    local throwGoal = rootPart.Position + (rootPart.CFrame.LookVector * 20) + Vector3.new(0, -5, 0)
    print("[AutoFisher] Casting line out...")
    pcall(function() Remote:InvokeServer({Bait = BAIT_NAME, Action = "Throw", Goal = throwGoal}) end)

    local throwTrack = playAnimation(THROW_ANIMATION_ID)
    if throwTrack then task.delay(THROW_ANIMATION_TIME, function() throwTrack:Stop(0.15) end) end

    -- Wait just a split second to give the server time to spawn the hook into the world
    task.wait(0.5) 

    -- 2. Find your specific hook in the workspace
    local hookName = player.Name .. "'s hook"
    local hook = workspace.Effects:FindFirstChild(hookName)
    
    -- 3. The Smart Stopwatch Logic
    if hook then
        print("[AutoFisher] Bobber detected in water. Waiting for a bite...")
        local maxWaitTime = 5
        local timeWaited = 0
        local caught = false
        
        -- Check the hook every 0.1 seconds
        while timeWaited < maxWaitTime do
            -- If the 'Caught' attribute turns true, a fish bit! Break the loop instantly.
            if hook:GetAttribute("Caught") then
                print("[AutoFisher] A FISH BIT THE HOOK! Reeling in instantly!")
                caught = true
                break 
            end
            
            -- Add 0.1 to our stopwatch and wait before checking again
            timeWaited = timeWaited + task.wait(0.1)
        end
        
        if not caught then
            print("[AutoFisher] Waited 5 seconds with no bite. Reeling in to try again.")
        end
    else
        -- Fallback: If for some reason the script couldn't find the hook, just wait 5 seconds.
        print("[AutoFisher] WARNING: Could not find bobber in workspace. Waiting 5 seconds default.")
        task.wait(5)
    end

    -- 4. Reel it in
    local reelTrack = playAnimation(REEL_ANIMATION_ID)
    task.wait(REEL_ANIMATION_TIME)

    print("[AutoFisher] Reeling finished. Ending cycle.")
    pcall(function() Remote:InvokeServer({ Action = "Reel" }) end)
    if reelTrack then reelTrack:Stop(0.2) end
    
    task.wait(0.2)
    pcall(function() Remote:InvokeServer({ Action = "Cancel" }) end)
end

function Model.ListenToInventoryChanges(callback)
    inventoryObj:GetPropertyChangedSignal("Value"):Connect(callback)
end

return Model