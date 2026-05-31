-- bf_tab_minigame.lua
return function(Window, Rayfield, Utils)
    local Players    = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local MinigameTab = Window:CreateTab("Minigame", nil)

    local function log(msg)  print("[DJ HUB | Minigame] " .. tostring(msg)) end
    local function warn2(msg) warn("[DJ HUB | Minigame] ⚠ " .. tostring(msg)) end

    -- ================================================================
    -- CHARGEZONE
    -- ================================================================
    local chargeZoneCache = nil
    local function findChargeZone()
        if chargeZoneCache and chargeZoneCache.Parent then return chargeZoneCache end
        log("Searching ChargeZone...")
        local plot = workspace:FindFirstChild("Plot")
        if plot then
            local czg = plot:FindFirstChild("ChargeZoneGroup")
            if czg then
                local cz = czg:FindFirstChild("ChargeZone")
                if cz then log("Found: " .. cz:GetFullName()) chargeZoneCache = cz return cz end
            end
        end
        local cz = workspace:FindFirstChild("ChargeZone", true)
        if cz then log("Found recursive: " .. cz:GetFullName()) chargeZoneCache = cz return cz end
        warn2("ChargeZone NOT found!")
        return nil
    end

    local function tpToChargeZone()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then warn2("HumanoidRootPart not found") return false end
        local cz = findChargeZone()
        if not cz then return false end
        local cf
        if cz:IsA("BasePart") then cf = cz.CFrame
        elseif cz:IsA("Model") then
            if cz.PrimaryPart then cf = cz.PrimaryPart.CFrame
            else local ok, p = pcall(function() return cz:GetPivot() end) if ok then cf = p end end
        end
        if not cf then warn2("No CFrame from ChargeZone") return false end
        hrp.CFrame = cf + Vector3.new(0, 4, 0)
        log("Teleported to " .. tostring(cf.Position))
        return true
    end

    -- ================================================================
    -- CHARGEBUTTON
    -- ================================================================
    local chargeButtonCache = nil
    local function findChargeButton()
        if chargeButtonCache and chargeButtonCache.Parent then return chargeButtonCache end
        log("Looking for ChargeButton...")
        local ok, btn = pcall(function()
            return LocalPlayer
                :WaitForChild("PlayerGui", 10)
                :WaitForChild("DashInterface", 10)
                :WaitForChild("ChargeButton", 10)
        end)
        if ok and btn then
            log("Found: " .. btn:GetFullName() .. " [" .. btn.ClassName .. "]")
            chargeButtonCache = btn
            return btn
        end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local b = pg:FindFirstChild("ChargeButton", true)
            if b then log("Found recursive: " .. b:GetFullName()) chargeButtonCache = b return b end
        end
        warn2("ChargeButton NOT found!")
        return nil
    end

    local function holdChargeButton(holdTime)
        holdTime = holdTime or 3
        local btn = findChargeButton()
        if not btn then warn2("Cannot hold — not found") return false end

        log("Button: " .. btn:GetFullName() .. " | " .. btn.ClassName)
        log("Visible: " .. tostring(btn.Visible))

        -- Methode 1: getconnections + :Fire() — zuverlässigste Methode
        local m1down = pcall(function()
            local conns = getconnections(btn.MouseButton1Down)
            log("MouseButton1Down connections: " .. #conns)
            for _, c in ipairs(conns) do c:Fire() end
        end)
        log("M1 getconnections MouseButton1Down: " .. (m1down and "✅" or "❌"))

        -- Methode 2: firesignal
        local m2 = pcall(function() firesignal(btn.MouseButton1Down) end)
        log("M2 firesignal MouseButton1Down: " .. (m2 and "✅" or "❌"))

        -- Methode 3: InputBegan via firesignal
        local m3 = pcall(function()
            local inp = Instance.new("InputObject")
            inp.UserInputType  = Enum.UserInputType.MouseButton1
            inp.UserInputState = Enum.UserInputState.Begin
            firesignal(btn.InputBegan, inp, false)
        end)
        log("M3 firesignal InputBegan: " .. (m3 and "✅" or "❌"))

        -- Methode 4: UIS InputBegan
        local m4 = pcall(function()
            local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
            local inp = Instance.new("InputObject")
            inp.UserInputType  = Enum.UserInputType.MouseButton1
            inp.UserInputState = Enum.UserInputState.Begin
            inp.Position       = Vector3.new(pos.X, pos.Y, 0)
            firesignal(game:GetService("UserInputService").InputBegan, inp, false)
        end)
        log("M4 UIS.InputBegan: " .. (m4 and "✅" or "❌"))

        -- Halten
        log("Holding for " .. holdTime .. "s...")
        task.wait(holdTime)

        -- Release alle Methoden
        pcall(function()
            local conns = getconnections(btn.MouseButton1Up)
            for _, c in ipairs(conns) do c:Fire() end
        end)
        pcall(function() firesignal(btn.MouseButton1Up) end)
        pcall(function()
            local inp = Instance.new("InputObject")
            inp.UserInputType  = Enum.UserInputType.MouseButton1
            inp.UserInputState = Enum.UserInputState.End
            firesignal(btn.InputEnded, inp, false)
        end)

        log("Released after " .. holdTime .. "s")
        return true
    end

    -- ================================================================
    -- DEBUG BUTTON INFO
    -- ================================================================
    local function debugButtonInfo()
        local btn = findChargeButton()
        if not btn then return end
        log("=== ChargeButton Debug ===")
        log("Class:    " .. btn.ClassName)
        log("Path:     " .. btn:GetFullName())
        log("Visible:  " .. tostring(btn.Visible))
        log("AbsPos:   " .. tostring(btn.AbsolutePosition))
        log("AbsSize:  " .. tostring(btn.AbsoluteSize))
        log("Children:")
        for _, c in pairs(btn:GetChildren()) do
            log("  " .. c.Name .. " [" .. c.ClassName .. "]")
        end
        local ok1, c1 = pcall(function() return getconnections(btn.MouseButton1Down) end)
        if ok1 then log("MouseButton1Down connections: " .. #c1)
        else log("getconnections not supported") end
        local ok2, c2 = pcall(function() return getconnections(btn.MouseButton1Up) end)
        if ok2 then log("MouseButton1Up connections: " .. #c2) end
        local ok3, c3 = pcall(function() return getconnections(btn.InputBegan) end)
        if ok3 then log("InputBegan connections: " .. #c3) end
    end

    -- ================================================================
    -- AUTO CHARGE LOOP
    -- ================================================================
    local autoChargeEnabled = false

    local function runChargeLoop()
        log("=== Loop started ===")
        local cycle = 0
        while autoChargeEnabled do
            cycle += 1
            log("── Cycle #" .. cycle .. " ──")

            log("Step 1: TP to ChargeZone")
            if not tpToChargeZone() then
                warn2("TP failed — retry in 2s")
                task.wait(2)
                continue
            end

            log("Step 2: Wait 1s")
            task.wait(1)
            if not autoChargeEnabled then break end

            log("Step 3: Hold ChargeButton 3s")
            holdChargeButton(3)
            if not autoChargeEnabled then break end

            log("Cycle #" .. cycle .. " done — waiting 20s...")
            for i = 20, 1, -1 do
                if not autoChargeEnabled then break end
                if i % 5 == 0 then log("Next cycle in " .. i .. "s...") end
                task.wait(1)
            end
        end
        log("=== Loop stopped after " .. cycle .. " cycle(s) ===")
    end

    -- ================================================================
    -- UI
    -- ================================================================
    MinigameTab:CreateSection("Auto Charge")

    MinigameTab:CreateParagraph({
        Title   = "How it works",
        Content = "1. Teleports to ChargeZone\n"
                .."2. Waits 1 second\n"
                .."3. Holds ChargeButton for 3 seconds\n"
                .."4. Waits 20 seconds → repeats\n"
                .."Open F9 for detailed debug logs."
    })

    MinigameTab:CreateToggle({
        Name         = "Auto Charge Minigame",
        CurrentValue = false,
        Flag         = "MinigameAutoCharge",
        Callback     = function(value)
            autoChargeEnabled = value
            if value then
                log("=== Auto Charge ENABLED ===")
                chargeZoneCache   = nil
                chargeButtonCache = nil
                local czOk  = findChargeZone()   ~= nil
                local btnOk = findChargeButton()  ~= nil
                debugButtonInfo()
                log("ChargeZone:   " .. (czOk  and "✅" or "❌"))
                log("ChargeButton: " .. (btnOk and "✅" or "❌"))
                Rayfield:Notify({
                    Title   = "Auto Charge",
                    Content = (czOk and btnOk)
                        and "Started! Check F9 for logs."
                        or  "⚠ Issue detected — check F9!",
                    Duration = 4,
                })
                task.spawn(runChargeLoop)
            else
                log("=== Auto Charge DISABLED ===")
                Rayfield:Notify({ Title = "Auto Charge", Content = "Stopped.", Duration = 3 })
            end
        end,
    })

    MinigameTab:CreateSection("Debug")

    MinigameTab:CreateButton({
        Name = "Debug: Print Button Info (F9)",
        Callback = function()
            chargeButtonCache = nil
            debugButtonInfo()
            Rayfield:Notify({ Title = "Debug", Content = "Check F9 for button info.", Duration = 3 })
        end
    })

    MinigameTab:CreateButton({
        Name = "Test: Teleport to ChargeZone",
        Callback = function()
            local ok = tpToChargeZone()
            Rayfield:Notify({ Title = "Debug", Content = ok and "✅ Teleported!" or "❌ Failed — check F9", Duration = 3 })
        end
    })

    MinigameTab:CreateButton({
        Name = "Test: Hold ChargeButton (3s)",
        Callback = function()
            log("Manual hold test")
            holdChargeButton(3)
            Rayfield:Notify({ Title = "Debug", Content = "Done — check F9 for which method worked.", Duration = 3 })
        end
    })

    print("[MINIGAME] Tab loaded")
end
