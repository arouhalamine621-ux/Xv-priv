-- ================================================================
-- MM2 FREEZE + FORCE ACCEPT — MOBILE
-- Language: Lua | Executor: Delta mobile / any UNC
-- Two floating buttons: FREEZE and FORCE
-- ================================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local LP = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui")

-- ----------------------------------------------------------------
-- CONFIG
-- ----------------------------------------------------------------
local CFG = {
    DelayBeforeForce = 0.2,  -- seconds after FORCE pressed before packet fires
}

-- ----------------------------------------------------------------
-- STATE
-- ----------------------------------------------------------------
local _frozen    = false
local _triggered = false
local _victimItems = {}

-- ----------------------------------------------------------------
-- FIND REMOTES
-- ----------------------------------------------------------------
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if not Remotes then warn("[MM2] Remotes not found") return end

local function findRemote(...)
    for _, v in ipairs(Remotes:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            for _, p in ipairs({...}) do
                if v.Name:lower():find(p:lower()) then return v end
            end
        end
    end
    return nil
end

local TradeUpdate  = findRemote("tradeupdate",  "trade_update",  "updatetrade")
local TradeAdd     = findRemote("tradeadd",     "trade_add",     "additem")
local TradeConfirm = findRemote("tradeconfirm", "trade_confirm", "confirmtrade")
local TradeAccept  = findRemote("tradeaccept",  "trade_accept",  "accepttrade")
local AcceptRemote = TradeAccept or TradeConfirm

if not AcceptRemote then
    warn("[MM2] accept remote not found — dumping all remotes:")
    for _, v in ipairs(Remotes:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            warn("  " .. v:GetFullName())
        end
    end
    return
end

-- ----------------------------------------------------------------
-- MOBILE UI
-- ----------------------------------------------------------------
local function makeUI()
    local old = PGui:FindFirstChild("MM2FreezeUI")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name            = "MM2FreezeUI"
    sg.ResetOnSpawn    = false
    sg.IgnoreGuiInset  = true
    sg.DisplayOrder    = 99999
    sg.Parent          = PGui

    local function makeBtn(text, color, posY)
        local btn = Instance.new("TextButton")
        btn.Size                = UDim2.fromOffset(130, 52)
        btn.Position            = UDim2.new(1, -145, 0.5, posY)
        btn.AnchorPoint         = Vector2.new(0, 0.5)
        btn.BackgroundColor3    = color
        btn.BorderSizePixel     = 0
        btn.Text                = text
        btn.TextColor3          = Color3.new(1, 1, 1)
        btn.Font                = Enum.Font.GothamBold
        btn.TextSize            = 15
        btn.AutoButtonColor     = false
        btn.Parent              = sg
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

        local shadow = Instance.new("Frame")
        shadow.Size              = UDim2.new(1, 4, 1, 4)
        shadow.Position          = UDim2.fromOffset(-2, 3)
        shadow.BackgroundColor3  = Color3.new(0, 0, 0)
        shadow.BackgroundTransparency = 0.7
        shadow.BorderSizePixel   = 0
        shadow.ZIndex            = btn.ZIndex - 1
        shadow.Parent            = btn
        Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 12)

        return btn
    end

    local freezeBtn = makeBtn("🔒 FREEZE", Color3.fromRGB(220, 60, 60),  -35)
    local forceBtn  = makeBtn("✅ FORCE",  Color3.fromRGB(40, 180, 80),   35)

    local status = Instance.new("TextLabel")
    status.Size               = UDim2.fromOffset(130, 24)
    status.Position           = UDim2.new(1, -145, 0.5, -68)
    status.AnchorPoint        = Vector2.new(0, 0.5)
    status.BackgroundColor3   = Color3.fromRGB(15, 15, 18)
    status.BackgroundTransparency = 0.3
    status.BorderSizePixel    = 0
    status.Text               = "READY"
    status.TextColor3         = Color3.fromRGB(160, 160, 160)
    status.Font               = Enum.Font.GothamMedium
    status.TextSize           = 12
    status.Parent             = sg
    Instance.new("UICorner", status).CornerRadius = UDim.new(0, 8)

    local function setStatus(txt, col)
        status.Text       = txt
        status.TextColor3 = col or Color3.fromRGB(160, 160, 160)
    end

    -- FREEZE button
    freezeBtn.MouseButton1Click:Connect(function()
        _frozen = not _frozen
        _triggered = false
        if _frozen then
            freezeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 30)
            freezeBtn.Text = "🔓 UNFREEZE"
            setStatus("FROZEN", Color3.fromRGB(255, 100, 30))
        else
            freezeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
            freezeBtn.Text = "🔒 FREEZE"
            setStatus("READY", Color3.fromRGB(160, 160, 160))
        end
    end)

    -- FORCE button
    forceBtn.MouseButton1Click:Connect(function()
        if not _frozen then
            setStatus("FREEZE FIRST", Color3.fromRGB(255, 60, 60))
            task.delay(1.5, function() setStatus("READY") end)
            return
        end
        if _triggered then
            setStatus("ALREADY FIRED", Color3.fromRGB(255, 200, 0))
            task.delay(1.5, function() setStatus("FROZEN", Color3.fromRGB(255, 100, 30)) end)
            return
        end

        _triggered = true
        forceBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        setStatus("FIRING...", Color3.fromRGB(255, 220, 0))

        task.delay(CFG.DelayBeforeForce, function()
            pcall(function() AcceptRemote:FireServer(true) end)
            pcall(function() AcceptRemote:FireServer(1, true) end)
            pcall(function() AcceptRemote:FireServer() end)

            setStatus("✓ DONE", Color3.fromRGB(40, 220, 80))
            task.delay(2, function()
                _frozen    = false
                _triggered = false
                freezeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
                freezeBtn.Text = "🔒 FREEZE"
                forceBtn.BackgroundColor3  = Color3.fromRGB(40, 180, 80)
                setStatus("READY")
            end)
        end)
    end)

    return sg
end

makeUI()
-- ================================================================
-- END MM2 FREEZE + FORCE ACCEPT MOBILE
-- ================================================================
