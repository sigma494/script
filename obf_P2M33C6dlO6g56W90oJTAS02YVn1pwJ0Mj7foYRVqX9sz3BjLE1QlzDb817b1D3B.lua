-- ==========================================
-- USER WHITELIST SETTINGS
-- ==========================================
local AllowedUsers = {
    "Structure_block12354",
    "metro_king1",
    "thething1289",
    "build_asPremium2",
}

-- Default values
local MechScale = 1 
local GroundHeightOffset = 6 

-- ==========================================
-- SYSTEM INITIALIZATION & CORE SERVICES
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local isWhitelisted = false
for _, username in ipairs(AllowedUsers) do
    if lp.Name == username then
        isWhitelisted = true
        break
    end
end

if not isWhitelisted then
    warn("Execution halted: You are not whitelisted to use this script.")
    return
end

local mouse = lp:GetMouse()
local isAssembled = false
local awaitingPart = nil 
local currentRigMode = "R6" 
local isMinimized = false

local mechParts = {
    Head = nil, Torso = nil, LeftArm = nil, RightArm = nil, LeftLeg = nil, RightLeg = nil,
    UpperTorso = nil, LowerTorso = nil,
    LeftUpperArm = nil, LeftLowerArm = nil, LeftHand = nil,
    RightUpperArm = nil, RightLowerArm = nil, RightHand = nil,
    LeftUpperLeg = nil, LeftLowerLeg = nil, LeftFoot = nil,
    RightUpperLeg = nil, RightLowerLeg = nil, RightFoot = nil
}

local r6Limbs = {"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}
local r15Limbs = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}

local function getTargetFolder()
    local blocks = workspace:FindFirstChild("Blocks")
    if blocks then
        local userFolder = blocks:FindFirstChild(lp.Name)
        if userFolder then return userFolder end
    end
    return nil
end

-- ==========================================
-- ISOLATED NETWORK BYPASS
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        settings().Physics.AllowSleep = false
        settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
        
        if sethiddenproperty then
            sethiddenproperty(lp, "SimulationRadius", math.huge)
            sethiddenproperty(lp, "MaxSimulationRadius", math.huge)
        end
        
        pcall(function()
            if lp.Character and lp.Character.PrimaryPart then
                lp.Character.PrimaryPart.CanCollide = true
            end
        end)
        
        -- ONLY loop through bound mech parts, and ONLY strip collisions if assembled
        if isAssembled then
            for _, block in pairs(mechParts) do
                if block and block:IsA("BasePart") then
                    pcall(function()
                        block.CanCollide = false 
                        if sethiddenproperty then
                            sethiddenproperty(block, "NetworkOwner", lp)
                        end
                    end)
                end
            end
        end
    end
end)

-- ==========================================
-- GUI SETUP (DRAGGABLE)
-- ==========================================
local cg = game:GetService("CoreGui")
if cg:FindFirstChild("MechBuilderUI") then cg.MechBuilderUI:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "MechBuilderUI"
sg.ResetOnSpawn = false
sg.Parent = cg

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 260, 0, 410) 
Main.Position = UDim2.new(0.5, -130, 0.5, -205) 
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = sg
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(100, 255, 100)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🤖 MECH BUILDER"
Title.TextColor3 = Color3.fromRGB(100, 255, 100)
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextSize = 14
Title.Parent = Main

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, 0, 0, 20)
StatusLbl.Position = UDim2.new(0, 0, 0, 30)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = "Select Rig Type, bind parts, then Assemble"
StatusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLbl.Font = Enum.Font.Gotham
StatusLbl.TextSize = 10
StatusLbl.Parent = Main

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 25, 0, 20)
MinimizeBtn.Position = UDim2.new(1, -35, 0, 5)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 12
MinimizeBtn.Parent = Main
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 4)

local ModeToggleBtn = Instance.new("TextButton")
ModeToggleBtn.Size = UDim2.new(1, -20, 0, 25)
ModeToggleBtn.Position = UDim2.new(0, 10, 0, 55)
ModeToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
ModeToggleBtn.Text = "RIG TYPE: R6"
ModeToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeToggleBtn.Font = Enum.Font.GothamBold
ModeToggleBtn.TextSize = 11
ModeToggleBtn.Parent = Main
Instance.new("UICorner", ModeToggleBtn).CornerRadius = UDim.new(0, 4)

local ButtonContainer = Instance.new("ScrollingFrame")
ButtonContainer.Size = UDim2.new(1, -20, 0, 180)
ButtonContainer.Position = UDim2.new(0, 10, 0, 90)
ButtonContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
ButtonContainer.BorderSizePixel = 0
ButtonContainer.ScrollBarThickness = 4
ButtonContainer.Parent = Main
Instance.new("UICorner", ButtonContainer).CornerRadius = UDim.new(0, 6)

local UIGridLayout = Instance.new("UIGridLayout")
UIGridLayout.CellSize = UDim2.new(0, 72, 0, 32)
UIGridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIGridLayout.Parent = ButtonContainer

local function createInput(name, yPos, defaultVal, callback)
    local lbl = Instance.new("TextLabel", Main)
    lbl.Size = UDim2.new(0, 100, 0, 25)
    lbl.Position = UDim2.new(0, 10, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextSize = 11
    
    local box = Instance.new("TextBox", Main)
    box.Size = UDim2.new(1, -120, 0, 25)
    box.Position = UDim2.new(0, 110, 0, yPos)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    box.Text = tostring(defaultVal)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 12
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    
    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then 
            callback(val) 
            StatusLbl.Text = name .. " updated to " .. tostring(val)
        else
            box.Text = "Invalid"
        end
    end)
    return lbl, box
end

local ScaleLbl, ScaleInput = createInput("MECH SCALE:", 280, MechScale, function(v) MechScale = v end)
local OffsetLbl, OffsetInput = createInput("GROUND OFFSET:", 315, GroundHeightOffset, function(v) GroundHeightOffset = v end)

local AssembleBtn = Instance.new("TextButton")
AssembleBtn.Size = UDim2.new(1, -20, 0, 35)
AssembleBtn.Position = UDim2.new(0, 10, 0, 355)
AssembleBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
AssembleBtn.Text = "ASSEMBLE MECH"
AssembleBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
AssembleBtn.Font = Enum.Font.GothamBold
AssembleBtn.TextSize = 14
AssembleBtn.Parent = Main
Instance.new("UICorner", AssembleBtn).CornerRadius = UDim.new(0, 6)

local function makeDraggable(frame)
    local dragToggle, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragToggle = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragToggle then
            local Delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
        end
    end)
end
makeDraggable(Main)

MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        ModeToggleBtn.Visible = false
        ButtonContainer.Visible = false
        AssembleBtn.Visible = false
        StatusLbl.Visible = false
        ScaleLbl.Visible = false
        ScaleInput.Visible = false
        OffsetLbl.Visible = false
        OffsetInput.Visible = false
        Main.Size = UDim2.new(0, 260, 0, 30)
        MinimizeBtn.Text = "+"
    else
        ModeToggleBtn.Visible = true
        ButtonContainer.Visible = true
        AssembleBtn.Visible = true
        StatusLbl.Visible = true
        ScaleLbl.Visible = true
        ScaleInput.Visible = true
        OffsetLbl.Visible = true
        OffsetInput.Visible = true
        Main.Size = UDim2.new(0, 260, 0, 410)
        MinimizeBtn.Text = "—"
    end
end)

local activeButtons = {}

local function updateLimbButtons()
    for _, btn in pairs(activeButtons) do
        btn:Destroy()
    end
    activeButtons = {}
    awaitingPart = nil
    
    local targets = (currentRigMode == "R6") and r6Limbs or r15Limbs
    for i, name in ipairs(targets) do
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.BackgroundColor3 = mechParts[name] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(60, 60, 60)
        btn.Text = mechParts[name] and "BOUND" or name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 8
        btn.Parent = ButtonContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        activeButtons[name] = btn

        btn.MouseButton1Click:Connect(function()
            if isAssembled then return end
            awaitingPart = name
            StatusLbl.Text = "Selecting: " .. name .. " (Click a block)"
            btn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
        end)
    end
    
    ButtonContainer.CanvasSize = UDim2.new(0, 0, 0, UIGridLayout.AbsoluteContentSize.Y + 10)
end

ModeToggleBtn.MouseButton1Click:Connect(function()
    if isAssembled then return end
    if currentRigMode == "R6" then
        currentRigMode = "R15"
    else
        currentRigMode = "R6"
    end
    ModeToggleBtn.Text = "RIG TYPE: " .. currentRigMode
    
    for k, v in pairs(mechParts) do 
        if v and v:FindFirstChild("MechHighlight") then
            v.MechHighlight:Destroy()
        end
        mechParts[k] = nil 
    end
    AssembleBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    updateLimbButtons()
end)

updateLimbButtons()

mouse.Button1Down:Connect(function()
    if not awaitingPart then return end
    
    local target = mouse.Target
    local tFolder = getTargetFolder()

    if target and target:IsA("BasePart") then
        if tFolder and target:IsDescendantOf(tFolder) then
            target.Anchored = false
            mechParts[awaitingPart] = target
            activeButtons[awaitingPart].BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            activeButtons[awaitingPart].Text = "BOUND"
            
            local highlight = target:FindFirstChild("MechHighlight") or Instance.new("SelectionBox")
            highlight.Name = "MechHighlight"
            highlight.Color3 = Color3.fromRGB(100, 255, 100)
            highlight.LineThickness = 0.05
            highlight.Adornee = target
            highlight.Parent = target
            
            StatusLbl.Text = awaitingPart .. " secured!"
            awaitingPart = nil
            
            local allBound = true
            local activeLimbs = (currentRigMode == "R6") and r6Limbs or r15Limbs
            for _, limbName in ipairs(activeLimbs) do
                if mechParts[limbName] == nil then allBound = false end
            end
            
            if allBound then
                AssembleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                StatusLbl.Text = "All systems go. Ready to assemble."
            end
        else
            StatusLbl.Text = "Error: Part must be in " .. lp.Name .. "!"
        end
    end
end)

AssembleBtn.MouseButton1Click:Connect(function()
    if isAssembled then
        isAssembled = false
        AssembleBtn.Text = "ASSEMBLE MECH"
        AssembleBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
        StatusLbl.Text = "Mech broken! Blocks fell apart."
        
        -- Clean up constraints and RESTORE collisions when disassembled
        local activeLimbs = (currentRigMode == "R6") and r6Limbs or r15Limbs
        for _, limbName in ipairs(activeLimbs) do
            local block = mechParts[limbName]
            if block then
                if block:FindFirstChild("MechHighlight") then block.MechHighlight:Destroy() end
                if block:FindFirstChild("MechAttachment") then block.MechAttachment:Destroy() end
                if block:FindFirstChild("MechAlignPos") then block.MechAlignPos:Destroy() end
                if block:FindFirstChild("MechAlignOri") then block.MechAlignOri:Destroy() end
                
                -- Restores normal physical interactions so the blocks drop safely
                pcall(function()
                    block.CanCollide = true
                end)
            end
        end
        return
    end

    local allBound = true
    local activeLimbs = (currentRigMode == "R6") and r6Limbs or r15Limbs
    for _, limbName in ipairs(activeLimbs) do
        if mechParts[limbName] == nil then allBound = false end
    end
    
    if allBound then
        isAssembled = true
        AssembleBtn.Text = "DISASSEMBLE MECH"
        AssembleBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        StatusLbl.Text = "Mimic sequence initiated."
    else
        StatusLbl.Text = "Cannot assemble: Missing limbs!"
    end
end)

-- ==========================================
-- RENDER LOOP (PHYSICS CONSTRAINTS FOR GLOBAL SYNC)
-- ==========================================
local function getCharacterLimb(limbName)
    local char = lp.Character
    if not char then return nil end
    if currentRigMode == "R6" then
        if limbName == "Head" then return char:FindFirstChild("Head") end
        if limbName == "Torso" then return char:FindFirstChild("Torso") end
        if limbName == "LeftArm" then return char:FindFirstChild("Left Arm") end
        if limbName == "RightArm" then return char:FindFirstChild("Right Arm") end
        if limbName == "LeftLeg" then return char:FindFirstChild("Left Leg") end
        if limbName == "RightLeg" then return char:FindFirstChild("Right Leg") end
    else
        return char:FindFirstChild(limbName)
    end
    return nil
end

RunService.Heartbeat:Connect(function()
    if not isAssembled then return end
    
    local root = lp.Character and (lp.Character:FindFirstChild("HumanoidRootPart") or lp.Character:FindFirstChild("Torso"))
    if not root then return end
    
    local cloneRootCF = root.CFrame * CFrame.new(8 + (MechScale * 2), GroundHeightOffset, 0) 
    local activeLimbs = (currentRigMode == "R6") and r6Limbs or r15Limbs
    
    for _, limbName in ipairs(activeLimbs) do
        local block = mechParts[limbName]
        if block and block.Parent then
            local charLimb = getCharacterLimb(limbName)
            if charLimb then
                -- Calculate Target Positions
                local localCF = root.CFrame:ToObjectSpace(charLimb.CFrame)
                local scaledPos = localCF.Position * MechScale
                local scaledLocalCF = CFrame.new(scaledPos) * localCF.Rotation
                local targetCF = cloneRootCF * scaledLocalCF
                
                -- Create/Update Physics Constraints
                local attach = block:FindFirstChild("MechAttachment") or Instance.new("Attachment", block)
                attach.Name = "MechAttachment"
                
                local alignPos = block:FindFirstChild("MechAlignPos") or Instance.new("AlignPosition", block)
                alignPos.Name = "MechAlignPos"
                alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
                alignPos.Attachment0 = attach
                alignPos.MaxForce = 10000000 
                alignPos.Responsiveness = 200 
                alignPos.Position = targetCF.Position
                
                local alignOri = block:FindFirstChild("MechAlignOri") or Instance.new("AlignOrientation", block)
                alignOri.Name = "MechAlignOri"
                alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
                alignOri.Attachment0 = attach
                alignOri.MaxTorque = 10000000
                alignOri.Responsiveness = 200
                alignOri.CFrame = targetCF
            end
        end
    end
end)
