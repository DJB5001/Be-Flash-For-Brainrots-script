-- bf_tab_minigame.lua
return function(Window, Rayfield, Utils)
    local Players           = game:GetService("Players")
    local RunService        = game:GetService("RunService")
    local LocalPlayer       = Players.LocalPlayer

    local MinigameTab = Window:CreateTab("Minigame", nil)

    local function log(msg)
        print("[DJ HUB | Minigame] " .. tostring(msg))
    end
    local function warn2(msg)
        warn("[DJ HUB | Minigame] ⚠ " .. tostring(msg))
    end

    -- ================================================================
    -- CHARGEZONE
    -- ================================================================
    local chargeZoneCache = nil
    local function findChargeZone()
        if chargeZoneCache and chargeZoneCache.Parent then return chargeZoneCache end
        log("Searching for ChargeZone...")
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
            else
                local ok, piv = pcall(function() return cz:GetPivot() end)
                if ok then cf = piv
                else
                    local p = cz:FindFirstChildWhichIsA("BasePart", true)
                    if p then cf = p.CFrame end
                end
            end
        end
        if not cf then warn2("Could not get CFrame") return false end
        hrp.CFrame = cf + Vector3.new(0, 4, 0)
        log("Teleported to: " .. tostring(cf.Position))
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
            log("Found: " .. btn:GetFullName())
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

        log("Holding ChargeButton for " .. holdTime .. "s...")
        log("Visible: " .. tostring(btn.Visible))

        -- Das Spiel nutzt InputBegan — wir feuern die Connections direkt
        local ok1, conns1 = pcall(function() return getconnections(btn.InputBegan) end)
        if ok1 and conns1 then
            log("InputBegan connections: " .. #conns1)
            -- Fake InputObject bauen
            local fakeInput = {
                UserInputType  = Enum.UserInputType.MouseButton1,
                UserInputState = Enum.UserInputState.Begin,
                KeyCode        = Enum.KeyCode.Unknown,
                Position       = Vector3.new(
                    btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2,
                    btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2,
                    0
                ),
                Delta = Vector3.new(0, 0, 0),
            }
            for _, c in ipairs(conns1) do
                pcall(function() c:Fire(fakeInput, false) end)
            end
            log("InputBegan connections fired ✅")
        else
            warn2("getconnections InputBegan failed")
        end

        -- Halten
        task.wait(holdTime)

        -- InputEnded feuern
        local ok2, conns2 = pcall(function() return getconnections(btn.InputEnded) end)
        if ok2 and conns2 then
            local fakeEnd = {
                UserInputType  = Enum.UserInputType.MouseButton1,
                UserInputState = Enum.UserInputState.End,
                KeyCode        = Enum.KeyCode.Unknown,
                Position       = Vector3.new(
                    btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2,
                    btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2,
                    0
                ),
                Delta = Vector3.new(0, 0, 0),
            }
            log("InputEnded connections: " .. #conns2)
            for _, c in ipairs(conns2) do
                pcall(function() c:Fire(fakeEnd, false) end)
            end
            log("InputEnded connections fired ✅")
        end

        -- Fallback: auch MouseButton1Down/Up Connections feuern
        pcall(function()
            local c = getconnections(btn.MouseButton1Down)
            for _, conn in ipairs(c) do pcall(function() conn:Fire() end) end
        end)

        log("Released after " .. holdTime .. "s")
        return true
    end

    -- ================================================================
    -- AUTO CHARGE LOOP
    -- ================================================================
    local autoChargeEnabled = false

    local function runChargeLoop()
        log("=== Auto Charge loop started ===")
        local cycleCount = 0

        while autoChargeEnabled do
            cycleCount += 1
            log("── Cycle #" .. cycleCount .. " ──")

            -- 1) TP zur ChargeZone
            log("Step 1: Teleporting to ChargeZone...")
            local tpOk = tpToChargeZone()
            if not tpOk then
                warn2("Teleport failed — retrying in 2s")
                task.wait(2)
                continue
            end

            -- 2) 1s warten
            log("Step 2: Waiting 1s...")
            task.wait(1)
            if not autoChargeEnabled then break end

            -- 3) ChargeButton 3s halten
            log("Step 3: Holding ChargeButton for 3s...")
            holdChargeButton(3)
            if not autoChargeEnabled then break end

            log("Cycle #" .. cycleCount .. " complete!")

            -- 4) 20s warten
            log("Step 4: Waiting 20s for next cycle...")
            for i = 20, 1, -1 do
                if not autoChargeEnabled then break end
                log("Next cycle in " .. i .. "s...")
                task.wait(1)
            end
        end

        log("=== Auto Charge loop stopped after " .. cycleCount .. " cycle(s) ===")
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
                .."4. Waits 20 seconds\n"
                .."5. Repeats automatically\n"
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
                local czOk  = findChargeZone()  ~= nil
                local btnOk = findChargeButton() ~= nil
                log("ChargeZone:   " .. (czOk  and "✅ Found" or "❌ Not found"))
                log("ChargeButton: " .. (btnOk and "✅ Found" or "❌ Not found"))
                Rayfield:Notify({
                    Title   = "Auto Charge",
                    Content = (czOk and btnOk)
                        and "Started! Check F9 for debug logs."
                        or  "⚠ Setup issue — check F9!",
                    Duration = 3,
                })
                task.spawn(runChargeLoop)
            else
                log("=== Auto Charge DISABLED ===")
                Rayfield:Notify({ Title = "Auto Charge", Content = "Stopped.", Duration = 3 })
            end
        end,
    })

    -- ================================================================
    -- DEBUG
    -- ================================================================
    MinigameTab:CreateSection("Debug")

    MinigameTab:CreateButton({
        Name     = "Test: Find ChargeZone",
        Callback = function()
            chargeZoneCache = nil
            local cz = findChargeZone()
            Rayfield:Notify({
                Title   = "Debug",
                Content = cz and ("✅ " .. cz:GetFullName()) or "❌ Not found — check F9",
                Duration = 4,
            })
        end
    })

    MinigameTab:CreateButton({
        Name     = "Test: Find ChargeButton",
        Callback = function()
            chargeButtonCache = nil
            local btn = findChargeButton()
            if btn then
                -- Connection-Info loggen
                local ok, c = pcall(function() return getconnections(btn.InputBegan) end)
                log("InputBegan connections: " .. (ok and #c or "N/A"))
                local ok2, c2 = pcall(function() return getconnections(btn.MouseButton1Down) end)
                log("MouseButton1Down connections: " .. (ok2 and #c2 or "N/A"))
            end
            Rayfield:Notify({
                Title   = "Debug",
                Content = btn and ("✅ " .. btn:GetFullName()) or "❌ Not found — check F9",
                Duration = 4,
            })
        end
    })

    MinigameTab:CreateButton({
        Name     = "Test: Teleport to ChargeZone",
        Callback = function()
            local ok = tpToChargeZone()
            Rayfield:Notify({
                Title   = "Debug",
                Content = ok and "✅ Teleported!" or "❌ Failed — check F9",
                Duration = 3,
            })
        end
    })

    MinigameTab:CreateButton({
        Name     = "Test: Hold ChargeButton (3s)",
        Callback = function()
            log("Manual test: Hold ChargeButton 3s")
            local ok = holdChargeButton(3)
            Rayfield:Notify({
                Title   = "Debug",
                Content = ok and "✅ Hold complete!" or "❌ Failed — check F9",
                Duration = 3,
            })
        end
    })

    print("[MINIGAME] Tab loaded")
end
