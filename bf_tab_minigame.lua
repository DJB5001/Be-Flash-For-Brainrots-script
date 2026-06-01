-- bf_tab_minigame.lua
return function(Window, Rayfield, Utils)
    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local MinigameTab = Window:CreateTab("Minigame", nil)

    local function log(msg)
        print("[DJ HUB | Minigame] " .. tostring(msg))
    end
    local function warn2(msg)
        warn("[DJ HUB | Minigame] ⚠ " .. tostring(msg))
    end

    local UIS      = game:GetService("UserInputService")
    local vim      = game:GetService("VirtualInputManager")
    local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

    -- ================================================================
    -- ZONE NAMEN (von links nach rechts wie im Bild)
    -- ================================================================
    local ZONE_NAMES = {
        "Common", "Uncommon", "Rare", "Epic",
        "Legendary", "Mythic", "Secret", "Cosmic", "Celestial"
    }

    -- ================================================================
    -- CHARGEZONE
    -- ================================================================
    local chargeZoneCache = nil
    local function findChargeZone()
        if chargeZoneCache and chargeZoneCache.Parent then return chargeZoneCache end
        local plot = workspace:FindFirstChild("Plot")
        if plot then
            local czg = plot:FindFirstChild("ChargeZoneGroup")
            if czg then
                local cz = czg:FindFirstChild("ChargeZone")
                if cz then chargeZoneCache = cz return cz end
            end
        end
        local cz = workspace:FindFirstChild("ChargeZone", true)
        if cz then chargeZoneCache = cz return cz end
        return nil
    end

    local function getChargeZonePos()
        local cz = findChargeZone()
        if not cz then return nil end
        if cz:IsA("BasePart") then return cz.Position end
        if cz:IsA("Model") then
            if cz.PrimaryPart then return cz.PrimaryPart.Position end
            local ok, piv = pcall(function() return cz:GetPivot() end)
            if ok and piv then return piv.Position end
            local p = cz:FindFirstChildWhichIsA("BasePart", true)
            if p then return p.Position end
        end
        return nil
    end

    local function walkToChargeZone(stopFn)
        local czPos = getChargeZonePos()
        if not czPos then warn2("ChargeZone not found") return false end
        log("Walking to ChargeZone at " .. tostring(czPos))

        -- Erst nah rantp (20 Studs davor), dann das letzte Stück laufen
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then warn2("HumanoidRootPart not found") return false end

        local dir    = (hrp.Position - czPos)
        local dirXZ  = Vector3.new(dir.X, 0, dir.Z)
        local offset = dirXZ.Magnitude > 0 and (dirXZ.Unit * 20) or Vector3.new(0, 0, 20)
        local nearPos = czPos + offset + Vector3.new(0, 3, 0)
        hrp.CFrame = CFrame.new(nearPos)
        log("TP'd to 20 studs before ChargeZone ✅")
        task.wait(0.3)

        -- Laufe das letzte Stück
        local maxTime   = 15
        local start     = tick()
        local lastPos2  = nil
        local stuckTime = 0

        while tick() - start < maxTime do
            if stopFn and stopFn() then return false end

            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not humanoid then task.wait(0.3) continue end

            local freshPos = getChargeZonePos()
            if freshPos then czPos = freshPos end

            local dist = (hrp.Position - czPos).Magnitude
            log("Distance to ChargeZone: " .. string.format("%.1f", dist))

            if dist < 6 then
                log("Arrived at ChargeZone ✅")
                return true
            end

            -- Stuck-Detection
            if lastPos2 then
                local moved = (hrp.Position - lastPos2).Magnitude
                stuckTime = moved < 0.5 and stuckTime + 0.4 or 0
            end
            lastPos2 = hrp.Position

            if stuckTime >= 1.2 then
                log("Stuck — jumping!")
                humanoid.Jump = true
                pcall(function()
                    vim:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
                    task.wait(0.15)
                    vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                end)
                stuckTime = 0
            end

            humanoid:MoveTo(czPos)
            task.wait(0.4)
        end

        warn2("Could not reach ChargeZone in time")
        return false
    end

    -- ================================================================
    -- CHARGEBUTTON / SHIFT HOLD
    -- ================================================================
    local chargeButtonCache = nil
    local function findChargeButton()
        if chargeButtonCache and chargeButtonCache.Parent then return chargeButtonCache end
        local ok, btn = pcall(function()
            return LocalPlayer
                :WaitForChild("PlayerGui", 5)
                :WaitForChild("DashInterface", 5)
                :WaitForChild("ChargeButton", 5)
        end)
        if ok and btn then chargeButtonCache = btn return btn end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local b = pg:FindFirstChild("ChargeButton", true)
            if b then chargeButtonCache = b return b end
        end
        return nil
    end

    local function holdShift(holdTime)
        holdTime = holdTime or 3
        log("Holding Shift for " .. holdTime .. "s...")
        pcall(function() vim:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game) end)
        pcall(function() vim:SendKeyEvent(true, Enum.KeyCode.RightShift, false, game) end)
        if isMobile then
            local btn = findChargeButton()
            if btn then
                local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
                pcall(function() vim:SendTouchEvent(0, pos, Enum.UserInputState.Begin, game) end)
            end
        end
        local holdStart = tick()
        local loopConn
        loopConn = RunService.Heartbeat:Connect(function()
            if tick() - holdStart >= holdTime then loopConn:Disconnect() return end
            pcall(function() vim:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game) end)
        end)
        task.wait(holdTime)
        if loopConn then pcall(function() loopConn:Disconnect() end) end
        pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game) end)
        pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.RightShift, false, game) end)
        if isMobile then
            local btn = findChargeButton()
            if btn then
                local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
                pcall(function() vim:SendTouchEvent(0, pos, Enum.UserInputState.End, game) end)
            end
        end
        log("Shift released ✅")
    end

    -- ================================================================
    -- ZONES HELPER
    -- ================================================================
    local function getZone(name)
        local zones = workspace:FindFirstChild("Zones")
        if not zones then return nil end
        return zones:FindFirstChild(name)
    end

    local function getZoneCenter(zoneName)
        local zone = getZone(zoneName)
        if not zone then return nil end
        if zone:IsA("BasePart") then return zone.Position end
        if zone:IsA("Model") then
            if zone.PrimaryPart then return zone.PrimaryPart.Position end
            local ok, piv = pcall(function() return zone:GetPivot() end)
            if ok and piv then return piv.Position end
            local p = zone:FindFirstChildWhichIsA("BasePart", true)
            if p then return p.Position end
        end
        return nil
    end

    local function isPlayerInZones()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        local zones = workspace:FindFirstChild("Zones")
        if not zones then return false end
        local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
        for _, zone in pairs(zones:GetChildren()) do
            local pos
            if zone:IsA("BasePart") then pos = zone.Position
            elseif zone:IsA("Model") then
                local ok, piv = pcall(function() return zone:GetPivot() end)
                if ok and piv then pos = piv.Position end
            end
            if pos then
                minX = math.min(minX, pos.X)
                maxX = math.max(maxX, pos.X)
                minZ = math.min(minZ, pos.Z)
                maxZ = math.max(maxZ, pos.Z)
            end
        end
        local margin = 40
        local p = hrp.Position
        return p.X > minX - margin and p.X < maxX + margin
           and p.Z > minZ - margin and p.Z < maxZ + margin
    end

    -- ================================================================
    -- QTE AUTO CLICKER
    -- ================================================================
    local qteEnabled    = false
    local qteConnection = nil

    local lastQTEClick = {}
    local function startQTE()
        if qteConnection then return end
        log("QTE Auto-Clicker started")
        qteConnection = RunService.Heartbeat:Connect(function()
            if not qteEnabled then return end
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if not pg then return end
            for _, obj in ipairs(pg:GetDescendants()) do
                if not obj:IsA("ImageButton") then continue end
                if not obj.Visible then continue end
                if obj.ImageTransparency >= 0.5 then continue end
                local sizeX = obj.AbsoluteSize.X
                local sizeY = obj.AbsoluteSize.Y
                if sizeX < 50 or sizeY < 50 then continue end
                local fullName = obj:GetFullName()
                if not (fullName:find("QTE") or fullName:find("Paradox")
                     or fullName:find("Bifrost") or fullName:find("Mutation")) then continue end

                -- Cooldown pro Button: max 1x pro 0.5s klicken
                local now = tick()
                if lastQTEClick[obj] and now - lastQTEClick[obj] < 0.5 then continue end
                lastQTEClick[obj] = now

                log("QTE Button found & clicking: " .. fullName)
                local center = obj.AbsolutePosition + obj.AbsoluteSize / 2

                -- Methode 1: getconnections MouseButton1Down
                pcall(function()
                    local conns = getconnections(obj.MouseButton1Down)
                    for _, c in ipairs(conns) do c:Fire(center.X, center.Y) end
                end)
                -- Methode 2: firesignal
                pcall(function() firesignal(obj.MouseButton1Down, center.X, center.Y) end)
                -- Methode 3: VirtualInputManager
                pcall(function()
                    if isMobile then
                        vim:SendTouchEvent(0, Vector2.new(center.X, center.Y), Enum.UserInputState.Begin, game)
                        task.wait(0.05)
                        vim:SendTouchEvent(0, Vector2.new(center.X, center.Y), Enum.UserInputState.End, game)
                    else
                        vim:SendMouseButtonEvent(center.X, center.Y, 0, true,  game, 0)
                        task.wait(0.05)
                        vim:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
                    end
                end)
            end
        end)
    end

    local function stopQTE()
        if qteConnection then
            qteConnection:Disconnect()
            qteConnection = nil
        end
        log("QTE Auto-Clicker stopped")
    end

    -- ================================================================
    -- ZONE NAVIGATION mit A/D Keys
    -- ================================================================
    local FIXED_X = 205  -- X-Mitte der Zonen-Reihe

    local function navigateZones(stopFn)
        log("Starting zone navigation (A/D key method)...")

        -- Warte bis Spieler in Zones ist
        local waitStart = tick()
        while tick() - waitStart < 10 do
            if stopFn and stopFn() then return end
            if isPlayerInZones() then
                log("Player is in zones ✅")
                break
            end
            task.wait(0.3)
        end

        if not isPlayerInZones() then
            warn2("Player not in zones after 10s")
            return
        end

        -- Sammle alle Zone-Z-Positionen und sortiere
        local zonePositions = {}
        for _, zoneName in ipairs(ZONE_NAMES) do
            local pos = getZoneCenter(zoneName)
            if pos then
                table.insert(zonePositions, {
                    name = zoneName,
                    x    = pos.X,
                    y    = pos.Y,
                    z    = pos.Z,
                })
            else
                warn2("Zone not found: " .. zoneName)
            end
        end

        -- Sortiere nach X-Position (links nach rechts)
        table.sort(zonePositions, function(a, b) return a.x < b.x end)

        log("Zone order (left→right by X):")
        for i, z in ipairs(zonePositions) do
            log("  " .. i .. ". " .. z.name .. " X=" .. string.format("%.1f", z.x) .. " Z=" .. string.format("%.1f", z.z))
        end

        -- Navigiere durch jede Zone mit A/D Keys
        for _, zoneData in ipairs(zonePositions) do
            if stopFn and stopFn() then
                log("Navigation stopped")
                return
            end

            if not isPlayerInZones() then
                log("Player left zones — done!")
                return
            end

            local char     = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            local hrp      = char and char:FindFirstChild("HumanoidRootPart")
            if not humanoid or not hrp then
                warn2("Character lost")
                return
            end

            -- Ziel: echte X/Z der Zone, Y vom Spieler
            local targetPos = Vector3.new(zoneData.x, hrp.Position.Y, zoneData.z)
            log("→ " .. zoneData.name .. " (X=" .. string.format("%.1f", zoneData.x) .. " Z=" .. string.format("%.1f", zoneData.z) .. ")")

            -- Bestimme ob wir nach links (A) oder rechts (D) müssen
            local moveStart = tick()
            while tick() - moveStart < 20 do
                -- stopFn sofort checken — kein Delay
                if stopFn and stopFn() then
                    log("Navigation aborted!")
                    -- Alle Keys loslassen
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.A, false, game) end)
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.D, false, game) end)
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.W, false, game) end)
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.S, false, game) end)
                    return
                end

                char     = LocalPlayer.Character
                humanoid = char and char:FindFirstChildOfClass("Humanoid")
                hrp      = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp or not humanoid then break end

                if not isPlayerInZones() then
                    log("Player left zones during navigation!")
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.A, false, game) end)
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.D, false, game) end)
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.W, false, game) end)
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.S, false, game) end)
                    return
                end

                local dx = zoneData.x - hrp.Position.X
                local dz = zoneData.z - hrp.Position.Z
                local dist = math.sqrt(dx*dx + dz*dz)

                if dist < 8 then
                    log("✅ Reached " .. zoneData.name)
                    -- Kurz Key loslassen
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.A, false, game) end)
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.D, false, game) end)
                    break
                end

                -- A/D drücken je nach X-Differenz
                -- Zusätzlich W/S für Z-Achse
                if dx < -3 then
                    -- Links
                    pcall(function() vim:SendKeyEvent(true,  Enum.KeyCode.A, false, game) end)
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.D, false, game) end)
                elseif dx > 3 then
                    -- Rechts
                    pcall(function() vim:SendKeyEvent(true,  Enum.KeyCode.D, false, game) end)
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.A, false, game) end)
                else
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.A, false, game) end)
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.D, false, game) end)
                end

                -- W/S für Z-Achse
                if dz < -3 then
                    pcall(function() vim:SendKeyEvent(true,  Enum.KeyCode.S, false, game) end)
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.W, false, game) end)
                elseif dz > 3 then
                    pcall(function() vim:SendKeyEvent(true,  Enum.KeyCode.W, false, game) end)
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.S, false, game) end)
                else
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.W, false, game) end)
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.S, false, game) end)
                end

                task.wait(0.1)
            end

            -- Alle Keys loslassen zwischen Zonen
            pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.A, false, game) end)
            pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.D, false, game) end)
            pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.W, false, game) end)
            pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.S, false, game) end)
            task.wait(0.1)
        end

        -- Alle Keys sicher loslassen am Ende
        pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.A, false, game) end)
        pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.D, false, game) end)
        pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.W, false, game) end)
        pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.S, false, game) end)
        log("Zone navigation complete ✅")
    end

    -- ================================================================
    -- HAUPT LOOP
    -- ================================================================
    local autoChargeEnabled = false

    local function runChargeLoop()
        log("=== Auto Charge loop started ===")
        local cycleCount = 0

        while autoChargeEnabled do
            cycleCount += 1
            log("── Cycle #" .. cycleCount .. " ──")

            -- SCHRITT 1: Zur ChargeZone laufen
            log("Step 1: Walking to ChargeZone...")
            local tpOk = walkToChargeZone(function() return not autoChargeEnabled end)
            if not tpOk then
                warn2("Could not reach ChargeZone — retrying in 2s")
                task.wait(2)
                continue
            end

            -- SCHRITT 2: 1s warten
            log("Step 2: Waiting 1s...")
            task.wait(1)
            if not autoChargeEnabled then break end

            -- SCHRITT 3: Shift 3s halten
            log("Step 3: Charging (Shift 3s)...")
            holdShift(3)
            if not autoChargeEnabled then break end

            -- SCHRITT 4: Warten bis Game uns in Zones TP'd
            log("Step 4: Waiting for game to TP into zones (max 8s)...")
            local tpWait = tick()
            while tick() - tpWait < 8 do
                if not autoChargeEnabled then break end
                if isPlayerInZones() then
                    log("In zones! ✅")
                    break
                end
                task.wait(0.3)
            end
            if not autoChargeEnabled then break end

            -- SCHRITT 5: QTE Clicker starten + Zones navigieren
            if isPlayerInZones() then
                log("Step 5: Starting QTE clicker + navigating zones...")
                qteEnabled = true
                startQTE()

                navigateZones(function() return not autoChargeEnabled end)

                -- SCHRITT 6: Warten bis Game uns raus-TP'd
                log("Step 6: Waiting for game to remove player from zones (max 15s)...")
                local exitWait = tick()
                while tick() - exitWait < 15 do
                    if not autoChargeEnabled then break end
                    if not isPlayerInZones() then
                        log("Player left zones ✅")
                        break
                    end
                    task.wait(0.3)
                end

                -- QTE stoppen
                qteEnabled = false
                stopQTE()
            else
                warn2("Not in zones after 8s — skipping")
            end

            if not autoChargeEnabled then break end

            -- SCHRITT 7: 3s warten
            log("Step 7: Waiting 3s before next cycle...")
            for i = 3, 1, -1 do
                if not autoChargeEnabled then break end
                log("Next cycle in " .. i .. "s...")
                task.wait(1)
            end

            log("Cycle #" .. cycleCount .. " complete!")
        end

        -- Cleanup
        qteEnabled = false
        stopQTE()
        pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.A, false, game) end)
        pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.D, false, game) end)
        pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.W, false, game) end)
        pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.S, false, game) end)
        log("=== Auto Charge loop stopped after " .. cycleCount .. " cycle(s) ===")
    end

    -- ================================================================
    -- UI
    -- ================================================================
    MinigameTab:CreateSection("Auto Charge")

    MinigameTab:CreateParagraph({
        Title   = "How it works",
        Content = "1. Walks to ChargeZone (jumps over obstacles)\n"
                .."2. Waits 1s → Holds Shift 3s (Charge)\n"
                .."3. Waits for game to TP into zones\n"
                .."4. Navigates zones with A/D keys (Common → Celestial)\n"
                .."5. Auto-clicks QTE/Mutation buttons\n"
                .."6. Detects exit → waits 3s → repeats\n"
                .."Open F9 for debug logs."
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
                local czOk = findChargeZone() ~= nil
                log("ChargeZone: " .. (czOk and "✅ Found" or "❌ Not found"))
                log("Walking mode: player will walk to ChargeZone")
                Rayfield:Notify({
                    Title   = "Auto Charge",
                    Content = czOk
                        and "Started! Check F9 for debug logs."
                        or  "⚠ ChargeZone not found!",
                    Duration = 3,
                })
                task.spawn(runChargeLoop)
            else
                log("=== Auto Charge DISABLED ===")
                qteEnabled = false
                stopQTE()
                pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.A, false, game) end)
                pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.D, false, game) end)
                pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.W, false, game) end)
                pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.S, false, game) end)
                Rayfield:Notify({ Title = "Auto Charge", Content = "Stopped.", Duration = 3 })
            end
        end,
    })

    print("[MINIGAME] Tab loaded")
end
