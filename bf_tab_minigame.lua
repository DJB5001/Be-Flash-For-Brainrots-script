-- bf_tab_minigame.lua
return function(Window, Rayfield, Utils)
    local Players           = game:GetService("Players")
    local RunService        = game:GetService("RunService")
    local LocalPlayer       = Players.LocalPlayer

    local MinigameTab = Window:CreateTab("Minigame", nil)

    -- ================================================================
    -- HELPERS
    -- ================================================================
    local function log(msg)
        print("[DJ HUB | Minigame] " .. tostring(msg))
    end

    local function warn2(msg)
        warn("[DJ HUB | Minigame] ⚠ " .. tostring(msg))
    end

    -- ================================================================
    -- CHARGEZONE FINDER
    -- ================================================================
    local chargeZoneCache = nil
    local function findChargeZone()
        if chargeZoneCache and chargeZoneCache.Parent then
            return chargeZoneCache
        end
        log("Searching for ChargeZone...")

        -- Methode 1: Plot > ChargeZoneGroup > ChargeZone
        local plot = workspace:FindFirstChild("Plot")
        if plot then
            local czg = plot:FindFirstChild("ChargeZoneGroup")
            if czg then
                local cz = czg:FindFirstChild("ChargeZone")
                if cz then
                    log("Found: Plot > ChargeZoneGroup > ChargeZone")
                    chargeZoneCache = cz
                    return cz
                end
            end
        end

        -- Methode 2: Rekursiv im Workspace
        local cz = workspace:FindFirstChild("ChargeZone", true)
        if cz then
            log("Found via recursive search: " .. cz:GetFullName())
            chargeZoneCache = cz
            return cz
        end

        warn2("ChargeZone NOT found!")
        return nil
    end

    local function getChargeZoneCFrame()
        local cz = findChargeZone()
        if not cz then return nil end
        if cz:IsA("BasePart") then return cz.CFrame end
        if cz:IsA("Model") then
            if cz.PrimaryPart then return cz.PrimaryPart.CFrame end
            local ok, piv = pcall(function() return cz:GetPivot() end)
            if ok and piv then return piv end
            local p = cz:FindFirstChildWhichIsA("BasePart", true)
            if p then return p.CFrame end
        end
        warn2("Could not get CFrame from: " .. cz.ClassName)
        return nil
    end

    local function tpToChargeZone()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            warn2("HumanoidRootPart not found")
            return false
        end
        local cf = getChargeZoneCFrame()
        if not cf then return false end
        hrp.CFrame = cf + Vector3.new(0, 4, 0)
        log("Teleported to ChargeZone at " .. tostring(cf.Position))
        return true
    end

    -- ================================================================
    -- CHARGEBUTTON FINDER & HOLD
    -- ================================================================
    local chargeButtonCache = nil
    local function findChargeButton()
        if chargeButtonCache and chargeButtonCache.Parent then
            return chargeButtonCache
        end
        log("Looking for ChargeButton...")

        -- Methode 1: PlayerGui > DashInterface > ChargeButton
        local ok, btn = pcall(function()
            return LocalPlayer
                :WaitForChild("PlayerGui", 10)
                :WaitForChild("DashInterface", 10)
                :WaitForChild("ChargeButton", 10)
        end)
        if ok and btn then
            log("ChargeButton found: " .. btn:GetFullName())
            chargeButtonCache = btn
            return btn
        end

        -- Methode 2: Rekursiv in PlayerGui
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local btn2 = pg:FindFirstChild("ChargeButton", true)
            if btn2 then
                log("ChargeButton found via recursive: " .. btn2:GetFullName())
                chargeButtonCache = btn2
                return btn2
            end
        end

        warn2("ChargeButton NOT found in PlayerGui!")
        return nil
    end

    local function holdChargeButton(holdTime)
        holdTime = holdTime or 3
        local btn = findChargeButton()
        if not btn then
            warn2("Cannot hold — ChargeButton not found")
            return false
        end

        log("Attempting to press ChargeButton for " .. holdTime .. "s...")
        log("Button class: " .. btn.ClassName)

        local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
        log("Button AbsolutePosition: " .. tostring(btn.AbsolutePosition))
        log("Button AbsoluteSize: " .. tostring(btn.AbsoluteSize))
        log("Click position: " .. tostring(pos))

        -- Methode 1: fireSignal / firesignal (Synapse / Executor)
        local method1 = pcall(function()
            firesignal(btn.MouseButton1Down)
        end)
        log("Method 1 (firesignal MouseButton1Down): " .. (method1 and "✅ OK" or "❌ Failed"))

        -- Methode 2: fireclickdetector Fallback
        local method2 = false
        if not method1 then
            method2 = pcall(function()
                local cd = btn:FindFirstChildOfClass("ClickDetector")
                if cd then fireclickdetector(cd) end
            end)
            log("Method 2 (fireclickdetector): " .. (method2 and "✅ OK" or "❌ N/A"))
        end

        -- Methode 3: VirtualInputManager mit echten Screen-Koordinaten
        local method3 = false
        if not method1 and not method2 then
            method3 = pcall(function()
                local vim = game:GetService("VirtualInputManager")
                vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            end)
            log("Method 3 (VirtualInputManager MouseDown): " .. (method3 and "✅ OK" or "❌ Failed"))
        end

        -- Halten
        task.wait(holdTime)

        -- Mouse Up — alle Methoden
        pcall(function() firesignal(btn.MouseButton1Up) end)
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end)

        log("Hold released after " .. holdTime .. "s")
        return method1 or method2 or method3
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

            -- 1) Teleport zur ChargeZone
            log("Step 1: Teleporting to ChargeZone...")
            local tpOk = tpToChargeZone()
            if not tpOk then
                warn2("Teleport failed — retrying in 2s")
                task.wait(2)
                continue
            end

            -- 2) 1 Sekunde warten
            log("Step 2: Waiting 1s...")
            task.wait(1)
            if not autoChargeEnabled then break end

            -- 3) ChargeButton 3 Sekunden halten
            log("Step 3: Holding ChargeButton for 3s...")
            holdChargeButton(3)
            if not autoChargeEnabled then break end

            log("Cycle #" .. cycleCount .. " complete!")

            -- 4) 20 Sekunden warten vor nächstem Cycle
            log("Step 4: Waiting 20s for next cycle...")
            for i = 20, 1, -1 do
                if not autoChargeEnabled then break end
                log("Next cycle in " .. i .. "s...")
                task.wait(1)
            end
        end

        log("=== Auto Charge loop stopped after " .. (cycleCount) .. " cycle(s) ===")
    end

    -- ================================================================
    -- UI — AUTO CHARGE
    -- ================================================================
    MinigameTab:CreateSection("Auto Charge")

    MinigameTab:CreateParagraph({
        Title   = "How it works",
        Content = "1. Teleports to ChargeZone\n"
                .."2. Waits 1 second\n"
                .."3. Holds ChargeButton for 3 seconds\n"
                .."4. Waits 20 seconds\n"
                .."5. Repeats automatically\n"
                .."Open F9 console for detailed debug logs."
    })

    MinigameTab:CreateToggle({
        Name         = "Auto Charge Minigame",
        CurrentValue = false,
        Flag         = "MinigameAutoCharge",
        Callback     = function(value)
            autoChargeEnabled = value
            if value then
                log("=== Auto Charge ENABLED ===")

                -- Pre-Check
                chargeZoneCache  = nil
                chargeButtonCache = nil
                local czOk  = findChargeZone()  ~= nil
                local btnOk = findChargeButton() ~= nil

                log("ChargeZone:   " .. (czOk  and "✅ Found" or "❌ Not found"))
                log("ChargeButton: " .. (btnOk and "✅ Found" or "❌ Not found"))

                if not czOk or not btnOk then
                    Rayfield:Notify({
                        Title   = "Auto Charge",
                        Content = "⚠ Setup issue!\n"
                                .. (czOk  and "" or "• ChargeZone not found\n")
                                .. (btnOk and "" or "• ChargeButton not found\n")
                                .. "Check F9 for details.",
                        Duration = 6,
                    })
                else
                    Rayfield:Notify({
                        Title   = "Auto Charge",
                        Content = "Started!\nCheck F9 for debug logs.",
                        Duration = 3,
                    })
                end

                task.spawn(runChargeLoop)
            else
                log("=== Auto Charge DISABLED ===")
                Rayfield:Notify({
                    Title   = "Auto Charge",
                    Content = "Stopped.",
                    Duration = 3,
                })
            end
        end,
    })

    -- ================================================================
    -- UI — DEBUG
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
