--==============================================================
-- Fazium.xyz - Key Gate
--==============================================================

repeat
    task.wait(0.25)
until game:IsLoaded()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local ALLOWED_PLACE_ID = 90086669327265
local VALID_KEY = "JZHP-M52U-2RQ1-36FX"
local KEY_URL = "https://work.ink/2Rw/fazium-is-here"
local KEY_SAVE_FILE = "fazium_key.txt"
DISCORD_INVITE = "https://discord.gg/NydUzyKX6S"

if game.PlaceId ~= ALLOWED_PLACE_ID then
    return
end

-- Reset stale gate state when the script is executed again.
getgenv().FaziumKeyGateRunning = false

-- If an old execution left a stale loaded flag but no Fazium UI exists,
-- allow the script to start again.
local ExistingFaziumUI = false

pcall(function()
    for _, Gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if tostring(Gui.Name):lower():find("fluent", 1, true)
            or tostring(Gui.Name):lower():find("fazium", 1, true)
        then
            ExistingFaziumUI = true
            break
        end
    end
end)

if getgenv().FaziumLoaded == true and ExistingFaziumUI then
    return
end

getgenv().FaziumLoaded = false
getgenv().FaziumKeyGateRunning = true

local function GetRequest()
    return
        http_request
        or (syn and syn.request)
        or request
end

local function CleanKey(Value)
    return tostring(Value or "")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
end

local function SaveKey(Key)
    if not writefile then
        return
    end

    pcall(function()
        writefile(KEY_SAVE_FILE, CleanKey(Key))
    end)
end

local function LoadSavedKey()
    if not (isfile and readfile) then
        return ""
    end

    if not isfile(KEY_SAVE_FILE) then
        return ""
    end

    local Success, Value = pcall(function()
        return readfile(KEY_SAVE_FILE)
    end)

    if not Success then
        return ""
    end

    return CleanKey(Value)
end

local function ClearSavedKey()
    if delfile and isfile and isfile(KEY_SAVE_FILE) then
        pcall(function()
            delfile(KEY_SAVE_FILE)
        end)
    end
end

local function OpenDiscordInvite()
    -- Always copy the invite if possible.
    if setclipboard then
        pcall(function()
            setclipboard(DISCORD_INVITE)
        end)
    end

    local InviteCode =
        DISCORD_INVITE:match("discord%.gg/([%w%-_]+)")
        or DISCORD_INVITE:match("discord%.com/invite/([%w%-_]+)")

    if not InviteCode then
        return
    end

    local HttpRequest = GetRequest()

    if not HttpRequest then
        return
    end

    pcall(function()
        HttpRequest({
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Origin"] = "https://discord.com",
            },
            Body = HttpService:JSONEncode({
                cmd = "INVITE_BROWSER",
                nonce = HttpService:GenerateGUID(false),
                args = {
                    code = InviteCode,
                },
            }),
        })
    end)
end

local function OpenKeyLink()
    if setclipboard then
        pcall(function()
            setclipboard(KEY_URL)
        end)
    end

    if openurl then
        pcall(function()
            openurl(KEY_URL)
        end)
    end
end

-- Open/copy Discord automatically on key screen launch.
task.spawn(OpenDiscordInvite)

--==============================================================
-- Fluent Key UI
--==============================================================

local KeyFluent = loadstring(
    game:HttpGetAsync(
        "https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"
    )
)()

local KeyWindow = KeyFluent:CreateWindow({
    Title = "Fazium.xyz",
    SubTitle = "Made by drazox1732",
    TabWidth = 150,
    Size = UDim2.fromOffset(500, 360),
    Resize = false,
    Acrylic = false,
    Theme = "Vynixu",
    MinimizeKey = "LeftControl",
})

local KeyTab = KeyWindow:CreateTab({
    Title = "Key",
    Icon = "key-round",
})

KeyTab:CreateSection("Access")

KeyTab:CreateParagraph("KeyInfo", {
    Title = "Fazium.xyz",
    Content =
        "1. Get your key\n"
        .. "2. Paste it below\n"
        .. "3. Press Check Key",
})

local CurrentKey = LoadSavedKey()
local Authorized = false
local Checking = false

local KeyInput = KeyTab:CreateInput("FaziumKeyInput", {
    Title = "Key",
    Default = CurrentKey,
    Placeholder = "Paste your key here",
    Numeric = false,
    Finished = false,

    Callback = function(Value)
        CurrentKey = CleanKey(Value)
    end,
})

KeyTab:CreateButton({
    Title = "Get Key",
    Description = "Open the official key page.",

    Callback = function()
        OpenKeyLink()

        KeyFluent:Notify({
            Title = "Get Key",
            Content = "Link copied.",
            Duration = 3,
        })
    end,
})

KeyTab:CreateButton({
    Title = "Join Discord",
    Description = "Open the Fazium.xyz Discord.",

    Callback = function()
        OpenDiscordInvite()

        KeyFluent:Notify({
            Title = "Discord",
            Content = "Invite copied.",
            Duration = 3,
        })
    end,
})

local GateEvent = Instance.new("BindableEvent")

KeyTab:CreateButton({
    Title = "Check Key",
    Description = "Check your key.",

    Callback = function()
        if Checking or Authorized then
            return
        end

        Checking = true

        task.wait(0.15)

        if CurrentKey == VALID_KEY then
            Authorized = true
            SaveKey(CurrentKey)

            KeyFluent:Notify({
                Title = "Fazium.xyz",
                Content = "Key accepted.",
                Duration = 2,
            })

            task.wait(0.25)

            pcall(function()
                KeyWindow:Destroy()
            end)

            GateEvent:Fire(true)
        else
            Checking = false
            ClearSavedKey()

            KeyFluent:Notify({
                Title = "Fazium.xyz",
                Content = "Invalid key.",
                Duration = 3,
            })
        end
    end,
})

KeyWindow:SelectTab(1)

local Passed = false

-- Auto-check saved key BEFORE waiting on the button event.
if CurrentKey ~= "" then
    Checking = true
    task.wait(0.15)

    if CurrentKey == VALID_KEY then
        Authorized = true
        Passed = true
        SaveKey(CurrentKey)

        pcall(function()
            KeyWindow:Destroy()
        end)
    else
        Checking = false
        ClearSavedKey()
        CurrentKey = ""

        pcall(function()
            KeyInput:SetValue("")
        end)

        KeyFluent:Notify({
            Title = "Fazium.xyz",
            Content = "Saved key invalid.",
            Duration = 3,
        })
    end
end

-- Only wait for the Check Key button if auto-check did not pass.
if not Passed then
    Passed = GateEvent.Event:Wait()
end

GateEvent:Destroy()

if Passed ~= true or Authorized ~= true then
    return
end

-- Lightweight client-side anti-bypass marker.
-- This only makes casual bypassing harder; the real protection would be server-side.
local ACCESS_TOKEN = HttpService:GenerateGUID(false)
getgenv().FaziumAccessToken = ACCESS_TOKEN

local function HasValidAccess()
    return
        Authorized == true
        and getgenv().FaziumAccessToken == ACCESS_TOKEN
end

if not HasValidAccess() then
    getgenv().FaziumKeyGateRunning = nil
    return
end

getgenv().FaziumKeyGateRunning = nil
getgenv().FaziumLoaded = true

--==============================================================
-- MAIN SCRIPT
--==============================================================

--==============================================================
-- Fazium Hub
-- Clean / readable version
-- Original logic reorganized into clear sections
--==============================================================


--==============================================================
-- 2. MOBILE GUI BUTTON
--==============================================================

task.spawn(function()
    if getgenv().LoadedMobileUI == true then
        return
    end

    getgenv().LoadedMobileUI = true

    local OpenUI = Instance.new("ScreenGui")
    local ImageButton = Instance.new("ImageButton")
    local UICorner = Instance.new("UICorner")

    OpenUI.Name = "OpenUI"
    OpenUI.Parent = game:GetService("CoreGui")
    OpenUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    ImageButton.Parent = OpenUI
    ImageButton.BackgroundColor3 = Color3.fromRGB(105, 105, 105)
    ImageButton.BackgroundTransparency = 0.8
    ImageButton.Position = UDim2.new(0.9, 0, 0.1, 0)
    ImageButton.Size = UDim2.new(0, 50, 0, 50)
    ImageButton.Image = "http://www.roblox.com/asset/?id=113082318257088"
    ImageButton.Draggable = true

    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = ImageButton

    ImageButton.MouseButton1Click:Connect(function()
        game:GetService("VirtualInputManager"):SendKeyEvent(
            true,
            "LeftControl",
            false,
            game
        )
    end)
end)


--==============================================================
-- 3. ANTI AFK
--==============================================================

-- Reserved for Anti-AFK logic.

--==============================================================
-- 4. EXECUTOR DETECTOR
--==============================================================

local executor = ""

if syn then
    executor = "Synapse X"
elseif is_sirhurt_closure then
    executor = "SirHurt"
elseif secure_load then
    executor = "Sentinel"
elseif KRNL_LOADED then
    executor = "KRNL"
elseif getexecutorname then
    executor = getexecutorname()
elseif isvm then
    executor = "Protosmasher"
elseif identifyexecutor then
    executor = identifyexecutor()
elseif wavy then
    executor = "Wave"
elseif delta then
    executor = "Delta"
elseif solarus or is_solarus then
    executor = "Solara"
elseif is_codex or CodexLoaded then
    executor = "Codex"
elseif is_arceus or ArceusX then
    executor = "Arceus X"
else
    executor = "Unknown"
end



--==============================================================
-- 5. SERVICES / CONSTANTS
--==============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
HttpService = game:GetService("HttpService")

--==============================================================
-- 6. VARIABLES
--==============================================================

local Flags = {AutoClicker = false, AutoSellALL = false, SelectFarmingZone = "-- Select Zone --", AutoTeleportZone = false, SelectFarmingZoneDropdownValues = {}, RemoveGrassLine = false, AutoRebirth = false, AutoBuyBestCutter = false, AutoBuyBestAura = false}


task.spawn(function()
    while task.wait(2) do
        if not HasValidAccess() then
            if Flags then
                for Key, Value in pairs(Flags) do
                    if type(Value) == "boolean" then
                        Flags[Key] = false
                    end
                end
            end
            return
        end
    end
end)

--==============================================================
-- 10. LIBRARIES
--==============================================================

local Fluent = loadstring(
    game:HttpGetAsync(
        "https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"
    )
)()

local SuppressNotifications = true

local function Notify(Data)
    if SuppressNotifications then
        return
    end

    Fluent:Notify(Data)
end


local SaveManager = loadstring(
    game:HttpGetAsync(
        "https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"
    )
)()

local InterfaceManager = loadstring(
    game:HttpGetAsync(
        "https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"
    )
)()


--==============================================================
-- 11. WINDOW
--==============================================================

local ScriptVersion = "1.0"
local ScriptAuthor = "drazox1732"

-- Put your permanent Discord invite here.
DISCORD_INVITE = "https://discord.gg/NydUzyKX6S"

local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

local Window = Fluent:CreateWindow({
    Title = "Fazium.xyz "
        .. ScriptVersion
        .. " | "
        .. GameName
        .. " | "
        .. executor,

    SubTitle = "Made by " .. ScriptAuthor,
    TabWidth = 160,

    Size = UDim2.fromOffset(580, 460),
    Resize = false,
    MinSize = Vector2.new(470, 380),

    Acrylic = false,
    Theme = "Vynixu",
    MinimizeKey = "LeftControl",
})


--==============================================================
-- 12. TABS
--==============================================================

local Tabs = {
    ScriptInfos = Window:CreateTab({
        Title = "Info",
        Icon = "badge-info",
    }),

    Main = Window:CreateTab({
        Title = "Main",
        Icon = "zap",
    }),

    Teleport = Window:CreateTab({
        Title = "Teleport",
        Icon = "map-pin",
    }),

    Webhook = Window:CreateTab({
        Title = "Webhook",
        Icon = "webhook",
    }),

    Settings = Window:CreateTab({
        Title = "Settings",
        Icon = "settings",
    }),
}

local Options = Fluent.Options

Notify({
    Title = "Fazium.xyz",
    Content = "Loading the script for " .. GameName,
    Duration = 6,
})

--==============================================================
-- 13. SCRIPT INFOS TAB
--==============================================================

Tabs.ScriptInfos:CreateSection("Overview")

Tabs.ScriptInfos:CreateParagraph("ScriptAbout", {
    Title = "Fazium.xyz",
    Content =
        "Cut Grass Adventure utility hub"
        .. "\nVersion " .. ScriptVersion
        .. "  •  Made by " .. ScriptAuthor,
})

Tabs.ScriptInfos:CreateParagraph("GameDetails", {
    Title = "Current Game",
    Content =
        GameName
        .. "\nPlace ID: " .. tostring(game.PlaceId),
})

Tabs.ScriptInfos:CreateSection("Session")

local TimeInGame = Tabs.ScriptInfos:CreateParagraph("TimeInGame", {
    Title = "Time Elapsed",
    Content = "00h 00m 00s",
})

Tabs.ScriptInfos:CreateSection("What's Included")

Tabs.ScriptInfos:CreateParagraph("FeaturesInfo", {
    Title = "Features",
    Content =
        "• Auto farming"
        .. "\n• Smart cutter & aura upgrades"
        .. "\n• Auto sell & auto rebirth"
        .. "\n• Zone & world teleport"
        .. "\n• Discord status webhook",
})

Tabs.ScriptInfos:CreateSection("Latest Update")

Tabs.ScriptInfos:CreateParagraph("UpdatesInfos", {
    Title = "Release " .. ScriptVersion,
    Content =
        "• Improved farming flow"
        .. "\n• Smarter upgrade detection"
        .. "\n• Dynamic zone handling"
        .. "\n• Cleaner interface",
})

Tabs.ScriptInfos:CreateSection("Community")

Tabs.ScriptInfos:CreateParagraph("CommunityInfo", {
    Title = "Fazium Community",
    Content = "Updates, support and new releases.",
})

local function OpenDiscordInvite()
    -- Always copy the invite first.
    if setclipboard then
        pcall(function()
            setclipboard(DISCORD_INVITE)
        end)
    end

    local InviteCode =
        DISCORD_INVITE:match("discord%.gg/([%w%-_]+)")
        or DISCORD_INVITE:match("discord%.com/invite/([%w%-_]+)")

    if not InviteCode then
        Notify({
            Title = "Discord",
            Content = "Invalid invite link.",
            Duration = 4,
        })
        return
    end

    local HttpRequest =
        http_request
        or (syn and syn.request)
        or request

    local Opened = false

    -- Try Discord desktop RPC first.
    if HttpRequest then
        local Success = pcall(function()
            local Response = HttpRequest({
                Url = "http://127.0.0.1:6463/rpc?v=1",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Origin"] = "https://discord.com",
                },
                Body = HttpService:JSONEncode({
                    cmd = "INVITE_BROWSER",
                    nonce = HttpService:GenerateGUID(false),
                    args = {
                        code = InviteCode,
                    },
                }),
            })

            if Response then
                local Status =
                    Response.StatusCode
                    or Response.Status
                    or 0

                if Status >= 200 and Status < 500 then
                    Opened = true
                end
            end
        end)

        if not Success then
            Opened = false
        end
    end

    if Opened then
        Notify({
            Title = "Discord",
            Content = "Opening Discord. Invite copied.",
            Duration = 4,
        })
        return
    end

    -- Discord RPC unavailable; the invite was already copied above.
    if setclipboard then
        Notify({
            Title = "Discord",
            Content = "Invite copied.",
            Duration = 4,
        })
    else
        Notify({
            Title = "Discord",
            Content = DISCORD_INVITE,
            Duration = 8,
        })
    end
end

Tabs.ScriptInfos:CreateButton({
    Title = "Join Discord",
    Description = "Open the Fazium.xyz Discord.",

    Callback = function()
        OpenDiscordInvite()
    end,
})


--==============================================================
-- 14. TIME ELAPSED
--==============================================================

local startTimeScript = tick()

local function UpdateTimeInGame()
    while true do
        local elapsedTime = tick() - startTimeScript

        local days = math.floor(elapsedTime / 86400)
        local hours = math.floor((elapsedTime % 86400) / 3600)
        local minutes = math.floor((elapsedTime % 3600) / 60)
        local seconds = math.floor(elapsedTime % 60)

        local timeString

        if days > 0 then
            timeString = string.format(
                "%dd %02dh %02dm %02ds",
                days,
                hours,
                minutes,
                seconds
            )
        else
            timeString = string.format(
                "%02dh %02dm %02ds",
                hours,
                minutes,
                seconds
            )
        end

        TimeInGame:SetValue(timeString)

        task.wait(1)
    end
end

task.spawn(UpdateTimeInGame)

--==============================================================
-- 15. Main 
--==============================================================

Tabs.Main:CreateSection("Automation")

local ToggleClick = Tabs.Main:CreateToggle("ToggleClick", {
    Title = "Auto Click",
    Description = "Automatically gains strength.",
    Default = false,
})

ToggleClick:OnChanged(function(value)
    Flags.AutoClicker = value

    if value then

        Notify({
            Title = "Auto Clicker",
            Content = "Auto clicker enabled.",
            Duration = 5,
        })

        if value then
            task.spawn(function()
                while Flags.AutoClicker do
                    local Event = game:GetService("ReplicatedStorage").Packages._Index["acecateer_knit@1.7.2"].knit.Services.StrengthService.RE.ClickRequested
                    Event:FireServer()
                    task.wait(0.02)
                end
            end)
        end
    else
        Notify({
            Title = "Auto Clicker",
            Content = "Auto Click disabled.",
            Duration = 5,
        })
    end
end)

local ToggleAutoSell = Tabs.Main:CreateToggle("ToggleAutoSell", {
    Title = "Auto Sell",
    Description = "Sells when your backpack is full, then returns.",
    Default = false,
})

ToggleAutoSell:OnChanged(function(value)
    Flags.AutoSellALL = value

    if value then
        Notify({
            Title = "Auto Sell All",
            Content = "Auto Sell All enabled.",
            Duration = 5,
        })

        task.spawn(function()
            while Flags.AutoSellALL do
                local BackpackValue = LocalPlayer.PlayerGui.MainScreenGui.Currencies.Backpack.Value.Text
                local MyLoot, MaxBag = BackpackValue:match("(%d+)%s*/%s*(%d+)")

                MyLoot = tonumber(MyLoot)
                MaxBag = tonumber(MaxBag)

                if MyLoot and MaxBag and MyLoot >= MaxBag then
                    local Character =
                        LocalPlayer.Character
                        or LocalPlayer.CharacterAdded:Wait()

                    local HumanoidRootPart =
                        Character:WaitForChild("HumanoidRootPart")

                    -- Save the current farming position
                    local SavedCFrame = HumanoidRootPart.CFrame

                    local TeleportToSpawn =
                        ReplicatedStorage
                            .Packages._Index["acecateer_knit@1.7.2"]
                            .knit.Services.BaseTeleportService.RF
                            .TeleportToSpawn

                    local SellAllBackpackLoot =
                        ReplicatedStorage
                            .Packages._Index["acecateer_knit@1.7.2"]
                            .knit.Services.DataService.RF
                            .SellAllBackpackLoot

                    -- Go to spawn and sell
                    TeleportToSpawn:InvokeServer()
                    task.wait(0.5)

                    SellAllBackpackLoot:InvokeServer()
                    task.wait(0.5)

                    -- Return to the exact position from before selling
                    Character =
                        LocalPlayer.Character
                        or LocalPlayer.CharacterAdded:Wait()

                    HumanoidRootPart =
                        Character:WaitForChild("HumanoidRootPart")

                    HumanoidRootPart.CFrame = SavedCFrame
                end

                task.wait(1)
            end
        end)
    else
        Notify({
            Title = "Auto Sell All",
            Content = "Auto Sell disabled.",
            Duration = 5,
        })
    end
end)

Tabs.Main:CreateSection("Item Farming")

Flags.SelectFarmingZoneDropdownValues = {}

local SavedZonePivots = {}

local function SortZoneValues()
    table.sort(
        Flags.SelectFarmingZoneDropdownValues,
        function(a, b)
            return (tonumber(a) or 0) < (tonumber(b) or 0)
        end
    )
end

local function LoadCurrentZones()
    table.clear(Flags.SelectFarmingZoneDropdownValues)

    for _, zone in ipairs(workspace.Zones:GetChildren()) do
        local ZoneName = zone.Name:match("^Zone_(.+)$")

        if ZoneName then
            table.insert(
                Flags.SelectFarmingZoneDropdownValues,
                ZoneName
            )

            local Success, Pivot = pcall(function()
                return zone:GetPivot()
            end)

            if Success then
                SavedZonePivots[ZoneName] = Pivot
            end
        end
    end

    SortZoneValues()
end

LoadCurrentZones()

local SelectFarmingZoneDropdown = Tabs.Main:CreateDropdown("SelectFarmingZoneDropdown", {
    Title = "Zone",
    Values = Flags.SelectFarmingZoneDropdownValues,
    Multi = false,
    Default = "-- Select Zone --",
})

SelectFarmingZoneDropdown:OnChanged(function(value)
    if value and value ~= "-- Select Zone --" then
        Flags.SelectFarmingZone = value

        local Zone =
            workspace.Zones:FindFirstChild(
                "Zone_" .. tostring(value)
            )

        if Zone then
            local Success, Pivot = pcall(function()
                return Zone:GetPivot()
            end)

            if Success then
                SavedZonePivots[tostring(value)] = Pivot
            end
        end

        Notify({
            Title = "Zone",
            Content = 'Selected Zone: "' .. tostring(value) .. '"',
            Duration = 5,
        })
    else
        Flags.SelectFarmingZone = nil

        Notify({
            Title = "Zone",
            Content = "Select a zone first.",
            Duration = 5,
        })

        if ToggleZoneTeleport then
            ToggleZoneTeleport:SetValue(false)
        end
    end
end)

local function AddZoneToDropdown(zone)
    local ZoneName = zone.Name:match("^Zone_(.+)$")

    if not ZoneName then
        return
    end

    if table.find(
        Flags.SelectFarmingZoneDropdownValues,
        ZoneName
    ) then
        return
    end

    table.insert(
        Flags.SelectFarmingZoneDropdownValues,
        ZoneName
    )

    local Success, Pivot = pcall(function()
        return zone:GetPivot()
    end)

    if Success then
        SavedZonePivots[ZoneName] = Pivot
    end

    SortZoneValues()

    SelectFarmingZoneDropdown:SetValues(
        Flags.SelectFarmingZoneDropdownValues
    )

    Notify({
        Title = "Zone",
        Content = "Added zone " .. ZoneName .. ".",
        Duration = 4,
    })

end

workspace.Zones.ChildAdded:Connect(AddZoneToDropdown)

workspace.Zones.ChildRemoved:Connect(function(zone)
    local ZoneName = zone.Name:match("^Zone_(.+)$")

    if not ZoneName then
        return
    end

    local Index = table.find(
        Flags.SelectFarmingZoneDropdownValues,
        ZoneName
    )

    if Index then
        table.remove(
            Flags.SelectFarmingZoneDropdownValues,
            Index
        )

        SortZoneValues()

        SelectFarmingZoneDropdown:SetValues(
            Flags.SelectFarmingZoneDropdownValues
        )

        Notify({
            Title = "Zone",
            Content = "Removed zone " .. ZoneName .. ".",
            Duration = 4,
        })

    end

    -- Keep the selected zone and its saved pivot even if the zone unloads.
    -- This allows Auto Farm to teleport back and make the zone load again.
    if tostring(Flags.SelectFarmingZone) == tostring(ZoneName) then
    end
end)

local ToggleZoneTeleport = Tabs.Main:CreateToggle("ToggleZoneTeleport", {
    Title = "Auto Farm Items",
    Description = "Teleports to items and interacts with them.",
    Default = false,
})

ToggleZoneTeleport:OnChanged(function(value)
    Flags.AutoTeleportZone = value

    if value then
        Notify({
            Title = "Auto Farm Items",
            Content = "Auto Farm enabled.",
            Duration = 4,
        })

        task.spawn(function()
            local VirtualInputManager =
                game:GetService("VirtualInputManager")

            while Flags.AutoTeleportZone do
                local SelectedZone =
                    Flags.SelectFarmingZone
                    and tostring(Flags.SelectFarmingZone)
                    or nil

                if SelectedZone
                    and SelectedZone ~= "-- Select Zone --"
                then
                    local ZoneName =
                        "Zone_" .. SelectedZone

                    local Character =
                        LocalPlayer.Character
                        or LocalPlayer.CharacterAdded:Wait()

                    local HumanoidRootPart =
                        Character:WaitForChild("HumanoidRootPart")

                    local Zone =
                        workspace.Zones:FindFirstChild(ZoneName)

                    -- Refresh cached pivot when loaded
                    if Zone then
                        local Success, Pivot = pcall(function()
                            return Zone:GetPivot()
                        end)

                        if Success then
                            SavedZonePivots[SelectedZone] = Pivot
                        end
                    end

                    -- Move to the selected zone first
                    local ZonePivot =
                        SavedZonePivots[SelectedZone]

                    if ZonePivot then
                        HumanoidRootPart.CFrame = ZonePivot
                    end

                    task.wait(1)

                    -- Stop immediately if user changed zone meanwhile
                    if tostring(Flags.SelectFarmingZone) ~= SelectedZone then
                        continue
                    end

                    Zone = workspace.Zones:FindFirstChild(ZoneName)

                    if Zone then
                        local SpawnZone =
                            Zone:FindFirstChild("SpawnZone")

                        if SpawnZone then
                            for _, Target in ipairs(SpawnZone:GetChildren()) do
                                -- Stop instantly if toggle disabled or zone changed
                                if not Flags.AutoTeleportZone then
                                    break
                                end

                                if tostring(Flags.SelectFarmingZone) ~= SelectedZone then
                                    break
                                end

                                -- Item may have despawned since GetChildren()
                                if not Target.Parent then
                                    continue
                                end

                                -- Make sure it is still inside this zone SpawnZone
                                if Target.Parent ~= SpawnZone then
                                    continue
                                end

                                -- Re-fetch character/root in case of respawn
                                Character =
                                    LocalPlayer.Character
                                    or LocalPlayer.CharacterAdded:Wait()

                                HumanoidRootPart =
                                    Character:WaitForChild("HumanoidRootPart")

                                if Target:IsA("Model") then
                                    HumanoidRootPart.CFrame = Target:GetPivot()

                                elseif Target:IsA("BasePart") then
                                    HumanoidRootPart.CFrame = Target.CFrame

                                else
                                    local SuccessTarget, TargetPivot =
                                        pcall(function()
                                            return Target:GetPivot()
                                        end)

                                    if SuccessTarget then
                                        HumanoidRootPart.CFrame = TargetPivot
                                    else
                                        continue
                                    end
                                end

                                task.wait(0.5)

                                -- Re-check before pressing E
                                if not Flags.AutoTeleportZone then
                                    break
                                end

                                if tostring(Flags.SelectFarmingZone) ~= SelectedZone then
                                    break
                                end

                                if not Target.Parent or Target.Parent ~= SpawnZone then
                                    continue
                                end

                                VirtualInputManager:SendKeyEvent(
                                    true,
                                    Enum.KeyCode.E,
                                    false,
                                    game
                                )

                                task.wait(1.5)

                                VirtualInputManager:SendKeyEvent(
                                    false,
                                    Enum.KeyCode.E,
                                    false,
                                    game
                                )

                                task.wait(1)

                                -- If zone changed during interaction, stop old loop now
                                if tostring(Flags.SelectFarmingZone) ~= SelectedZone then
                                    break
                                end
                            end
                        end
                    end
                end

                task.wait(0.1)
            end
        end)

    else
        Notify({
            Title = "Auto Farm Items",
            Content = "Auto Farm disabled.",
            Duration = 4,
        })
    end
end)

--==============================================================
-- 16. TELEPORT TAB
--==============================================================

Tabs.Teleport:CreateSection("World Teleport")

local WorldDropdownValues = {}
local SelectedWorld = nil

local function SortWorldValues()
    table.sort(WorldDropdownValues, function(a, b)
        local aNumber = tonumber(tostring(a):match("(%d+)"))
        local bNumber = tonumber(tostring(b):match("(%d+)"))

        if aNumber and bNumber then
            return aNumber < bNumber
        end

        return tostring(a) < tostring(b)
    end)
end

local function LoadWorlds()
    table.clear(WorldDropdownValues)

    local WorldsFolder = workspace:FindFirstChild("Worlds")

    if not WorldsFolder then
        warn("[Fazium] workspace.Worlds not found.")
        return
    end

    for _, World in ipairs(WorldsFolder:GetChildren()) do
        table.insert(WorldDropdownValues, World.Name)
    end

    SortWorldValues()
end

LoadWorlds()

local WorldDropdown = Tabs.Teleport:CreateDropdown("WorldTeleportDropdown", {
    Title = "World",
    Values = WorldDropdownValues,
    Multi = false,
    Default = "-- Select World --",
})

local function TeleportToWorld(WorldName)
    local WorldId =
        tonumber(tostring(WorldName):match("World_(%d+)"))
        or tonumber(tostring(WorldName):match("(%d+)"))

    if not WorldId then
        Notify({
            Title = "Teleport",
            Content = "Invalid world.",
            Duration = 4,
        })
        return
    end

    local Remote =
        ReplicatedStorage
            .Packages._Index["acecateer_knit@1.7.2"]
            .knit.Services.WorldService.RF
            .TeleportToWorld

    local Success, Result = pcall(function()
        return Remote:InvokeServer(WorldId)
    end)

    if Success then
        Notify({
            Title = "Teleport",
            Content = "World " .. tostring(WorldId) .. ".",
            Duration = 3,
        })
    else
        warn("[Fazium] World teleport failed:", Result)
    end
end

WorldDropdown:OnChanged(function(Value)
    if not Value or Value == "-- Select World --" then
        SelectedWorld = nil
        return
    end

    SelectedWorld = tostring(Value)

    TeleportToWorld(SelectedWorld)
end)

local function AddWorldToDropdown(World)
    if table.find(WorldDropdownValues, World.Name) then
        return
    end

    table.insert(WorldDropdownValues, World.Name)
    SortWorldValues()

    WorldDropdown:SetValues(WorldDropdownValues)

    Notify({
        Title = "Teleport",
        Content = "Added " .. World.Name .. ".",
        Duration = 4,
    })
end

local WorldsFolder = workspace:FindFirstChild("Worlds")

if WorldsFolder then
    WorldsFolder.ChildAdded:Connect(AddWorldToDropdown)

    WorldsFolder.ChildRemoved:Connect(function(World)
        local Index = table.find(WorldDropdownValues, World.Name)

        if Index then
            table.remove(WorldDropdownValues, Index)
            SortWorldValues()
            WorldDropdown:SetValues(WorldDropdownValues)
        end

        if SelectedWorld == World.Name then
            SelectedWorld = nil
        end
    end)
end


--==============================================================
-- AUTO BUY BEST CUTTER
--==============================================================

local LastBoughtCutterRank = 0

local function GetCutterShop()
    local Success, Shop = pcall(function()
        return LocalPlayer.PlayerGui
            .CuttersGUI.Cutters.Background.ScrollingFrame
    end)

    if Success then
        return Shop
    end

    return nil
end

local function GetCutterButtonContent(BuyButton)
    return BuyButton:FindFirstChild("Content")
end

local function GetCutterButtonText(BuyButton)
    local ButtonContent = GetCutterButtonContent(BuyButton)

    if not ButtonContent then
        return ""
    end

    if ButtonContent:IsA("TextButton")
        or ButtonContent:IsA("TextLabel")
    then
        return tostring(ButtonContent.Text or "")
    end

    local TextObject =
        ButtonContent:FindFirstChildWhichIsA("TextLabel", true)
        or ButtonContent:FindFirstChildWhichIsA("TextButton", true)

    if TextObject then
        return tostring(TextObject.Text or "")
    end

    return ""
end

local function IsCutterOwned(BuyButton)
    local Text =
        GetCutterButtonText(BuyButton)
            :lower()
            :gsub("^%s+", "")
            :gsub("%s+$", "")

    return Text == "equip" or Text == "equipped"
end

local function IsGreenCutterButton(BuyButton)
    local ButtonContent =
        GetCutterButtonContent(BuyButton)

    if not ButtonContent then
        return false
    end

    local Success, Color = pcall(function()
        return ButtonContent.BackgroundColor3
    end)

    if not Success then
        return false
    end

    local Target = Color3.fromRGB(12, 180, 0)

    return
        math.abs(Color.R - Target.R) < 0.12
        and math.abs(Color.G - Target.G) < 0.12
        and math.abs(Color.B - Target.B) < 0.12
end

local function GetSortedCutterCards()
    local Shop = GetCutterShop()

    if not Shop then
        return nil
    end

    local Cards = {}

    for _, Card in ipairs(Shop:GetChildren()) do
        local Content =
            Card:FindFirstChild("Content")

        local BuyButton =
            Content
            and Content:FindFirstChild("BuyButton")

        if BuyButton then
            table.insert(Cards, Card)
        end
    end

    table.sort(Cards, function(A, B)
        local AY = A.AbsolutePosition.Y
        local BY = B.AbsolutePosition.Y

        if AY ~= BY then
            return AY < BY
        end

        return A.Name < B.Name
    end)

    return Cards
end

local function GetBestOwnedCutterRank(Cards)
    local BestOwnedRank = 0

    for Rank, Card in ipairs(Cards) do
        local Content =
            Card:FindFirstChild("Content")

        local BuyButton =
            Content
            and Content:FindFirstChild("BuyButton")

        if BuyButton and IsCutterOwned(BuyButton) then
            BestOwnedRank =
                math.max(BestOwnedRank, Rank)
        end
    end

    return BestOwnedRank
end

local function FindBestBuyableCutter()
    local Cards = GetSortedCutterCards()

    if not Cards or #Cards == 0 then
        return nil
    end

    local BestOwnedRank =
        GetBestOwnedCutterRank(Cards)

    local MinimumRank =
        math.max(
            BestOwnedRank,
            LastBoughtCutterRank
        )

    -- Bottom of shop = strongest cutter.
    for Rank = #Cards, MinimumRank + 1, -1 do
        local Card = Cards[Rank]

        local Content =
            Card:FindFirstChild("Content")

        local BuyButton =
            Content
            and Content:FindFirstChild("BuyButton")

        if BuyButton
            and IsGreenCutterButton(BuyButton)
            and not IsCutterOwned(BuyButton)
        then
            return Card.Name, Rank
        end
    end

    return nil
end

local function BuyBestCutter()
    local CutterName, CutterRank =
        FindBestBuyableCutter()

    if not CutterName then
        return false
    end

    local BuyCutter =
        ReplicatedStorage
            .Packages._Index["acecateer_knit@1.7.2"]
            .knit.Services.CuttersShopService.RF
            .BuyCutter

    local Success = pcall(function()
        BuyCutter:InvokeServer(CutterName)
    end)

    if not Success then
        return false
    end

    LastBoughtCutterRank = CutterRank

    task.wait(2)

    return true
end

Tabs.Main:CreateSection("Upgrades")

local ToggleAutoBuyBestCutter =
    Tabs.Main:CreateToggle("ToggleAutoBuyBestCutter", {
        Title = "Auto Buy Best Cutter",
        Description = "Buys only the best available cutter upgrade.",
        Default = false,
    })

ToggleAutoBuyBestCutter:OnChanged(function(Value)
    Flags.AutoBuyBestCutter = Value

    if Value then
        local Cards = GetSortedCutterCards()

        if Cards then
            LastBoughtCutterRank =
                GetBestOwnedCutterRank(Cards)
        else
            LastBoughtCutterRank = 0
        end

        Notify({
            Title = "Cutter",
            Content = "Auto Buy enabled.",
            Duration = 4,
        })

        task.spawn(function()
            while Flags.AutoBuyBestCutter do
                BuyBestCutter()
                task.wait(1)
            end
        end)
    else
        Notify({
            Title = "Cutter",
            Content = "Auto Buy disabled.",
            Duration = 4,
        })
    end
end)


--==============================================================
-- AUTO BUY BEST AURA
--==============================================================

local LastBoughtAuraName = nil
local LastBoughtAuraPositionY = -math.huge

local function GetAuraButtonText(BuyButton)
    local Texts = {}

    if BuyButton:IsA("TextLabel") or BuyButton:IsA("TextButton") then
        if BuyButton.Text and BuyButton.Text ~= "" then
            table.insert(Texts, tostring(BuyButton.Text))
        end
    end

    for _, Object in ipairs(BuyButton:GetDescendants()) do
        if Object:IsA("TextLabel") or Object:IsA("TextButton") then
            if Object.Text and Object.Text ~= "" then
                table.insert(Texts, tostring(Object.Text))
            end
        end
    end

    return table.concat(Texts, " ")
end

local function IsAuraEquipOrEquipped(BuyButton)
    local Text = GetAuraButtonText(BuyButton):lower()

    return
        Text:find("equipped", 1, true) ~= nil
        or Text:find("equip", 1, true) ~= nil
end

local function IsGreenAuraBuyButton(BuyButton)
    local ButtonContent = BuyButton:FindFirstChild("Content")

    if not ButtonContent then
        return false
    end

    local Success, Color = pcall(function()
        return ButtonContent.BackgroundColor3
    end)

    if not Success then
        return false
    end

    local R = math.floor(Color.R * 255 + 0.5)
    local G = math.floor(Color.G * 255 + 0.5)
    local B = math.floor(Color.B * 255 + 0.5)

    return
        math.abs(R - 12) <= 25
        and math.abs(G - 180) <= 35
        and math.abs(B - 0) <= 25
end

local function GetAuraPositionY(AuraCard)
    local Success, Y = pcall(function()
        return AuraCard.AbsolutePosition.Y
    end)

    if Success then
        return Y
    end

    return -math.huge
end

local function GetAuraShop()
    local Success, ScrollingFrame = pcall(function()
        return LocalPlayer.PlayerGui
            .AurasGUI.Auras.Background.ScrollingFrame
    end)

    if Success then
        return ScrollingFrame
    end

    return nil
end

local function GetBestOwnedAura()
    local ScrollingFrame = GetAuraShop()

    if not ScrollingFrame then
        return nil, -math.huge
    end

    local BestOwnedName = nil
    local BestOwnedY = -math.huge

    for _, AuraCard in ipairs(ScrollingFrame:GetChildren()) do
        local Content = AuraCard:FindFirstChild("Content")
        local BuyButton = Content and Content:FindFirstChild("BuyButton")

        if BuyButton and IsAuraEquipOrEquipped(BuyButton) then
            local Y = GetAuraPositionY(AuraCard)

            if Y > BestOwnedY then
                BestOwnedY = Y
                BestOwnedName = AuraCard.Name
            end
        end
    end

    return BestOwnedName, BestOwnedY
end

local function FindBestGreenAuraUpgrade()
    local ScrollingFrame = GetAuraShop()

    if not ScrollingFrame then
        warn("[Fazium] Aura shop not found.")
        return nil
    end

    local BestOwnedName, BestOwnedY =
        GetBestOwnedAura()

    local MinimumY =
        math.max(
            BestOwnedY,
            LastBoughtAuraPositionY
        )

    local BestBuyName = nil
    local BestBuyY = -math.huge
    local BestBuyButton = nil

    for _, AuraCard in ipairs(ScrollingFrame:GetChildren()) do
        local Content = AuraCard:FindFirstChild("Content")
        local BuyButton = Content and Content:FindFirstChild("BuyButton")

        if BuyButton
            and IsGreenAuraBuyButton(BuyButton)
            and not IsAuraEquipOrEquipped(BuyButton)
        then
            local Y = GetAuraPositionY(AuraCard)

            -- Lower in the shop = better aura
            if Y > MinimumY and Y > BestBuyY then
                BestBuyName = AuraCard.Name
                BestBuyY = Y
                BestBuyButton = BuyButton
            end
        end
    end

    if not BestBuyName then
        if BestOwnedName then
        end

        return nil
    end

    return BestBuyName, BestBuyY
end

local function BuyBestAura()
    local AuraName, AuraY =
        FindBestGreenAuraUpgrade()

    if not AuraName then
        return false
    end

    local BuyOrToggleAura =
        ReplicatedStorage
            .Packages._Index["acecateer_knit@1.7.2"]
            .knit.Services.AuraService.RF
            .BuyOrToggleAura

    local Success, Result = pcall(function()
        return BuyOrToggleAura:InvokeServer(AuraName)
    end)

    if not Success then
        warn(
            "[Fazium] Buy aura failed:",
            tostring(Result)
        )
        return false
    end

    LastBoughtAuraName = AuraName
    LastBoughtAuraPositionY = AuraY


    task.wait(2)

    return true
end

local ToggleAutoBuyBestAura =
    Tabs.Main:CreateToggle("ToggleAutoBuyBestAura", {
        Title = "Auto Buy Best Aura",
        Description = "Only buys an aura better than your current best.",
        Default = false,
    })

ToggleAutoBuyBestAura:OnChanged(function(Value)
    Flags.AutoBuyBestAura = Value

    if Value then
        local BestOwnedName, BestOwnedY =
            GetBestOwnedAura()

        LastBoughtAuraName = BestOwnedName
        LastBoughtAuraPositionY = BestOwnedY

        Notify({
            Title = "Aura",
            Content = "Auto Buy enabled.",
            Duration = 4,
        })

        task.spawn(function()
            while Flags.AutoBuyBestAura do
                BuyBestAura()
                task.wait(1)
            end
        end)
    else
        Notify({
            Title = "Aura",
            Content = "Auto Buy disabled.",
            Duration = 4,
        })
    end
end)


--==============================================================
-- 17. AUTO REBIRTH
--==============================================================

local ToggleAutoRebirth = Tabs.Main:CreateToggle("ToggleAutoRebirth", {
    Title = "Auto Rebirth",
    Description = "Rebirths as soon as the level requirement is met.",
    Default = false,
})

ToggleAutoRebirth:OnChanged(function(value)
    Flags.AutoRebirth = value

    if value then
        Notify({
            Title = "Auto Rebirth",
            Content = "Auto Rebirth enabled.",
            Duration = 4,
        })

        task.spawn(function()
            while Flags.AutoRebirth do
                local Success, RebirthText = pcall(function()
                    return LocalPlayer.PlayerGui
                        .RebirthGUI.Rebirth.Background
                        .Midleground.Bar.Count.Text
                end)

                if Success and RebirthText then
                    local CurrentLevel, RequiredLevel =
                        RebirthText:match("Level%s*(%d+)%s*/%s*(%d+)")

                    CurrentLevel = tonumber(CurrentLevel)
                    RequiredLevel = tonumber(RequiredLevel)

                    if CurrentLevel
                        and RequiredLevel
                        and CurrentLevel >= RequiredLevel
                    then
                        local RebirthEvent =
                            ReplicatedStorage
                                .Packages._Index["acecateer_knit@1.7.2"]
                                .knit.Services.RebirtService.RE
                                .RebirthButtonClicked

                        RebirthEvent:FireServer()

                        task.wait(2)
                    end
                end

                task.wait(0.5)
            end
        end)
    else
        Notify({
            Title = "Auto Rebirth",
            Content = "Auto Rebirth disabled.",
            Duration = 4,
        })
    end
end)


--==============================================================
-- 17. REMOVE GRASS LINES
--==============================================================

local function RemoveGrassLines()
    local RemovedCount = 0

    for _, Zone in ipairs(workspace.Zones:GetChildren()) do
        for _, Object in ipairs(Zone:GetDescendants()) do
            if Object.Name == "GrassLine" then
                Object:Destroy()
                RemovedCount += 1
            end
        end
    end

    return RemovedCount
end

Tabs.Main:CreateSection("Performance")

local ToggleRemoveGrassLine = Tabs.Main:CreateToggle("ToggleRemoveGrassLine", {
    Title = "Remove Grass",
    Description = "Removes grass objects from loaded zones.",
    Default = false,
})

ToggleRemoveGrassLine:OnChanged(function(value)
    Flags.RemoveGrassLine = value

    if value then
        local InitialRemoved = RemoveGrassLines()

        Notify({
            Title = "Remove Grass",
            Content = tostring(InitialRemoved) .. " grass removed.",
            Duration = 4,
        })

        task.spawn(function()
            while Flags.RemoveGrassLine do
                RemoveGrassLines()
                task.wait(1)
            end
        end)
    else
        Notify({
            Title = "Remove Grass",
            Content = "Remove Grass disabled.",
            Duration = 4,
        })
    end
end)


--==============================================================
-- 18. WEBHOOK TAB
--==============================================================

local WebhookSettings = {
    URL = "",
    AutoHeartbeat = false,
    IntervalMinutes = 5,
    IncludePlayer = true,
    IncludeGame = true,
    IncludeServer = true,
    IncludeSessionTime = true,
    IncludePlayerStats = true,
}

local WebhookRuntime = {
    StartTime = tick(),
    SentCount = 0,
    LastSent = "Never",
    LoopRunning = false,
}

local function FormatSessionTime()
    local elapsed = math.max(0, math.floor(tick() - WebhookRuntime.StartTime))
    local hours = math.floor(elapsed / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = elapsed % 60

    return string.format("%02dh %02dm %02ds", hours, minutes, seconds)
end

local function GetHttpRequest()
    return
        http_request
        or (syn and syn.request)
        or request
end

local function GetPlayerStats()
    local Wallet = "Unavailable"
    local Rebirths = "Unavailable"

    pcall(function()
        Wallet = LocalPlayer.PlayerGui
            .MainScreenGui.Currencies.Wallet.Value.Text
    end)

    pcall(function()
        Rebirths = LocalPlayer.PlayerGui
            .MainScreenGui.Currencies.Rebirth.Value.Text
    end)

    return Wallet, Rebirths
end

local function SendStatusWebhook(reason)
    if WebhookSettings.URL == "" then
        Notify({
            Title = "Webhook",
            Content = "Please enter a webhook URL first.",
            Duration = 5,
        })
        return false
    end

    local HttpRequest = GetHttpRequest()

    if not HttpRequest then
        Notify({
            Title = "Webhook Error",
            Content = "HTTP requests are not supported by this executor.",
            Duration = 5,
        })
        return false
    end

    local Fields = {}

    if WebhookSettings.IncludePlayer then
        table.insert(Fields, {
            name = "Player",
            value = LocalPlayer.Name .. " (" .. tostring(LocalPlayer.UserId) .. ")",
            inline = true,
        })
    end

    if WebhookSettings.IncludeGame then
        table.insert(Fields, {
            name = "Game",
            value = GameName .. "\nPlaceId: " .. tostring(game.PlaceId),
            inline = true,
        })
    end

    if WebhookSettings.IncludeServer then
        table.insert(Fields, {
            name = "Server Job ID",
            value = game.JobId ~= "" and game.JobId or "Unavailable",
            inline = false,
        })
    end

    if WebhookSettings.IncludeSessionTime then
        table.insert(Fields, {
            name = "Session Time",
            value = FormatSessionTime(),
            inline = true,
        })
    end

    if WebhookSettings.IncludePlayerStats then
        local Wallet, Rebirths = GetPlayerStats()

        table.insert(Fields, {
            name = "Money",
            value = tostring(Wallet),
            inline = true,
        })

        table.insert(Fields, {
            name = "Rebirths",
            value = tostring(Rebirths),
            inline = true,
        })
    end

    local Embed = {
        title = "Fazium.xyz - Status",
        description = "Connected.",
        color = 5763719,
        fields = Fields,
        footer = {
            text = "Reason: "
                .. tostring(reason or "Manual")
                .. " | Message #"
                .. tostring(WebhookRuntime.SentCount + 1),
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }

    local Success, Response = pcall(function()
        return HttpRequest({
            Url = WebhookSettings.URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body = HttpService:JSONEncode({
                username = "Fazium.xyz",
                avatar_url = "https://cdn.discordapp.com/attachments/1152609445491257446/1303429538172108820/static.png",
                embeds = { Embed },
            }),
        })
    end)

    if Success then
        WebhookRuntime.SentCount += 1
        WebhookRuntime.LastSent = os.date("%H:%M:%S")
        return true
    end

    warn("[Fazium] Webhook failed:", tostring(Response))
    return false
end

local function StartWebhookHeartbeat()
    if WebhookRuntime.LoopRunning then
        return
    end

    WebhookRuntime.LoopRunning = true

    task.spawn(function()
        while WebhookRuntime.LoopRunning do
            if WebhookSettings.AutoHeartbeat then
                SendStatusWebhook("Automatic heartbeat")

                local WaitSeconds =
                    math.max(
                        1,
                        tonumber(WebhookSettings.IntervalMinutes) or 5
                    ) * 60

                local Elapsed = 0

                while
                    WebhookSettings.AutoHeartbeat
                    and Elapsed < WaitSeconds
                do
                    task.wait(1)
                    Elapsed += 1
                end
            else
                task.wait(1)
            end
        end
    end)
end

StartWebhookHeartbeat()

Tabs.Webhook:CreateSection("Status Webhook")

Tabs.Webhook:CreateInput("WebhookURL", {
    Title = "Webhook URL",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Numeric = false,
    Finished = false,

    Callback = function(value)
        WebhookSettings.URL = tostring(value)
    end,
})


Tabs.Webhook:CreateSlider("WebhookInterval", {
    Title = "Heartbeat Interval",
    Description = "Minutes between automatic status messages.",
    Default = WebhookSettings.IntervalMinutes,
    Min = 1,
    Max = 60,
    Rounding = 0,

    Callback = function(value)
        WebhookSettings.IntervalMinutes = tonumber(value) or 5
    end,
})

local ToggleWebhookHeartbeat =
    Tabs.Webhook:CreateToggle("ToggleWebhookHeartbeat", {
        Title = "Automatic Heartbeat",
        Default = false,
    })

ToggleWebhookHeartbeat:OnChanged(function(value)
    WebhookSettings.AutoHeartbeat = value

    if value then
        Notify({
            Title = "Webhook Heartbeat",
            Content = "Webhook enabled.",
            Duration = 4,
        })

        task.spawn(function()
            SendStatusWebhook("Heartbeat enabled")
        end)
    else
        Notify({
            Title = "Webhook Heartbeat",
            Content = "Webhook disabled.",
            Duration = 4,
        })
    end
end)

Tabs.Webhook:CreateButton({
    Title = "Send Test",
    Description = "Send one connection/status message now.",

    Callback = function()
        local Success = SendStatusWebhook("Manual test")

        Notify({
            Title = Success and "Webhook OK" or "Webhook Error",
            Content = Success
                and "Status message sent successfully."
                or "Could not send the webhook.",
            Duration = 5,
        })
    end,
})

Tabs.Webhook:CreateSection("Included Data")

Tabs.Webhook:CreateParagraph("WebhookStatsInfo", {
    Title = "User Stats",
    Content = "Choose what user and game stats are sent to Discord.",
})

local function CreateWebhookInfoToggle(Id, Title, Key)
    local Toggle = Tabs.Webhook:CreateToggle(Id, {
        Title = Title,
        Default = WebhookSettings[Key],
    })

    Toggle:OnChanged(function(value)
        WebhookSettings[Key] = value
    end)
end

CreateWebhookInfoToggle(
    "WebhookIncludePlayer",
    "Player Name + User ID",
    "IncludePlayer"
)

CreateWebhookInfoToggle(
    "WebhookIncludeGame",
    "Game + Place ID",
    "IncludeGame"
)

CreateWebhookInfoToggle(
    "WebhookIncludeServer",
    "Server Job ID",
    "IncludeServer"
)

CreateWebhookInfoToggle(
    "WebhookIncludeSessionTime",
    "Session Time",
    "IncludeSessionTime"
)

CreateWebhookInfoToggle(
    "WebhookIncludePlayerStats",
    "User Stats (Money + Rebirths)",
    "IncludePlayerStats"
)


--==============================================================
-- 23. SAVE MANAGER / INTERFACE MANAGER
--==============================================================

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("Fazium.xyz")
SaveManager:SetFolder("Fazium.xyz/Cut-Grass-Simulator")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Notify({
    Title = "Fazium.xyz",
    Content = "The script has been loaded.",
    Duration = 8,
})

SaveManager:LoadAutoloadConfig()

task.defer(function()
    task.wait(0.5)
    SuppressNotifications = false

    Notify({
        Title = "Fazium.xyz",
        Content = "Loaded for " .. GameName .. ".",
        Duration = 5,
    })
end)

--==============================================================
-- 24. SCRIPT EXECUTION LOGGER
--==============================================================

local function LogScriptExecution()
    local embed = {
        title = "Script Execution Log 📄",

        description =
            "A user has executed the Fazium script with "
            .. executor,

        color = 3447003,

        fields = {
            {
                name = "🧑 Player",
                value = LocalPlayer.Name,
                inline = true,
            },

            {
                name = "🎮 Game",
                value = GameName,
                inline = true,
            },

            {
                name = "📅 Time",
                value = os.date("!%Y-%m-%d %H:%M:%S UTC"),
                inline = false,
            },
        },

        footer = {
            text = "Fazium Logs System",
            icon_url = "https://cdn.discordapp.com/attachments/1152609445491257446/1303429538172108820/static.png",
        },

        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }

    local httpRequest =
        http_request
        or (syn and syn.request)
        or request

    if not httpRequest then
        warn("HTTP request function is not available.")
        return
    end

    local success, response = pcall(function()
        return httpRequest({
            Url = "https://discord.com/api/webhooks/1303456342257696798/uRRrJN4IRfb_JPZVVl5U8rvqhkQpPTuel0Ux8X5YUkLHwXdNmdnDe3Rxt5EDtW9z4Jw7",

            Headers = {
                ["Content-Type"] = "application/json",
            },

            Body = HttpService:JSONEncode({
                username = "Fazium Hub Logger",

                avatar_url =
                    "https://cdn.discordapp.com/attachments/1152609445491257446/1303429538172108820/static.png",

                embeds = {
                    embed,
                },
            }),

            Method = "POST",
        })
    end)

    if success then
    else
        warn("Failed to send webhook: " .. tostring(response))
    end
end


--==============================================================
-- 25. START LOGGER
--==============================================================

LogScriptExecution()
