--```lua

-- PASTEBIN CODE: NULLSCAPEBOII6769

local hint = Instance.new("Hint")
local message = Instance.new("Message")
local placeId = game.PlaceId

if placeId == 100588763114828 then
    hint.Parent = workspace
    hint.Text = "Loading script."
else
   message.Parent = workspace
   message.Text = "You are not currently in the game place or you are not playing nullscape, please enter a game inside of nullscape to be able to use this script."
   wait(10)
   pcall(function() message:Destroy() end)
   return 
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "le nullscape ui boiii",
   Icon = 114293255506804, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "nullscape",
   LoadingSubtitle = "by whoever idk you aks me bro",
   ShowText = "NullscapeUi", -- for mobile users to unhide rayfield, change if you'd like
   Theme = {
    TextColor = Color3.fromRGB(240, 240, 240),

    Background = Color3.fromRGB(20, 20, 20), -- main black background
    Topbar = Color3.fromRGB(25, 25, 25),
    Shadow = Color3.fromRGB(15, 15, 15),

    NotificationBackground = Color3.fromRGB(128, 0, 128),
    NotificationActionsBackground = Color3.fromRGB(20, 20, 20),

    TabBackground = Color3.fromRGB(128, 0, 128),
    TabStroke = Color3.fromRGB(100, 140, 190),
    TabBackgroundSelected = Color3.fromRGB(52, 21, 57),
    TabTextColor = Color3.fromRGB(20, 20, 20),
    SelectedTabTextColor = Color3.fromRGB(240, 240, 240), 

    ElementBackground = Color3.fromRGB(128, 0, 128),
    ElementBackgroundHover = Color3.fromRGB(105, 0, 105),
    SecondaryElementBackground = Color3.fromRGB(128, 0, 128),
    ElementStroke = Color3.fromRGB(50, 50, 50),
    SecondaryElementStroke = Color3.fromRGB(40, 40, 40),
            
    SliderBackground = Color3.fromRGB(40, 40, 40),
    SliderProgress = Color3.fromRGB(128, 0, 128),
    SliderStroke = Color3.fromRGB(100, 140, 190),

    ToggleBackground = Color3.fromRGB(40, 40, 40),
    ToggleEnabled = Color3.fromRGB(128, 0, 128),
    ToggleDisabled = Color3.fromRGB(100, 100, 100),
    ToggleEnabledStroke = Color3.fromRGB(100, 140, 190),
    ToggleDisabledStroke = Color3.fromRGB(125, 125, 125),
    ToggleEnabledOuterStroke = Color3.fromRGB(60, 60, 60),
    ToggleDisabledOuterStroke = Color3.fromRGB(65, 65, 65),

    DropdownSelected = Color3.fromRGB(128, 0, 128),
    DropdownUnselected = Color3.fromRGB(40, 40, 40),

    InputBackground = Color3.fromRGB(128, 0, 128),
    InputStroke = Color3.fromRGB(80, 120, 180),
    PlaceholderColor = Color3.fromRGB(128, 0, 128)
}, -- Check https://[Log in to view URL]
 
   ToggleUIKeybind = "P", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)
 
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface
 
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Null Hub"
   },
 
   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },
 
   KeySystem = true, -- Set this to true to use our key system
   KeySettings = {
      Title = "Verification",
      Subtitle = "are you ultra null boi",
      Note = "Put Yes", -- Use this to tell the user how to get a key
      FileName = "Nullestion", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Yes", "yes", "yEs", "yeS", "YEs", "yES", "YES", "uber secret code that nobody will find out gulp", "throzyckd", "67"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})

local MainTab = Window:CreateTab("Main", 4483362458) -- Title, Image
local GameTab = Window:CreateTab("Game", 4483362458) -- Title, Image
local FunTab = Window:CreateTab("Fun", 4483362458) -- Title, Image
local whatever = Window:CreateTab("hi this was added cuz my friend requested it", 126824355195428) -- Title, Image

local sound = game:GetService("SoundService")
local sfxfolder = sound.SFXFolder

local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char.HumanoidRootPart
local humanoid = char:WaitForChild("Humanoid")

local ExecutingEnemy = false
local ExecutingHusk = false
local Enemy = "Bell"

local function message(text)
   local message = Instance.new("Hint")
   message.Parent = workspace
   message.Text = text
   wait(3)
   pcall(function() message:Destroy() end)
end


local function sound()
    sfxfolder.PlayerDeath:Play()
end

local function KillEnemy(state)
    ExecutingEnemy = state
    sound()
end

local function KillHusk(state)
    ExecutingHusk = state
    sound()
end

local function spawnEnemy(Enemy)
   local enemylist = game.ReplicatedStorage.EnemyFolder.Enemies
   local selectedEnemy = enemylist:FindFirstChild(Enemy)
   print("this and that")
   if selectedEnemy then
       local cloneselected = selectedEnemy:Clone()
        for _, obj in ipairs(cloneselected:GetDescendants()) do
	        if obj:IsA("Script") or obj:IsA("LocalScript") then
		        obj.Enabled = true
	        end
        end
       cloneselected.Parent = workspace.Enemies
       cloneselected.Position = hrp.Position + Vector3.new(0, 10, 0)
       message("Spawned enemy " .. cloneselected.Name .. " into enemy files.")
   else
       message("Could not find enemy.")
   end
end


-- // WHATEVER \\ --

whatever:CreateButton({
    Name = "hi",
    CurrentValue = false,
    Flag = "HLELOENGIHBOURSEEYOULATERNBEIGHBOTU",
    Callback = function()
        print("hi")
        sound()
    end,
})

-- // MAIN TAB \\ --

MainTab:CreateParagraph({Title = "WIP.", Content = "missing more features id wish to add, more things along the way like enemy spawning and others, keybind is P! huge thanks to Nexer with their old hub scripts and me sharing just a bit of them!"})

local Button = MainTab:CreateButton({
    Name = "Infinite Yield",
    Callback = function()
        sound()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end,
})

MainTab:CreateParagraph({Title = "", Content = "It's recommended to use yields loopws and loopjp if you wanna go fast! i'm too lazy to make it myself"})

-- // GAME TAB \\ --

GameTab:CreateParagraph({Title = "ENEMY KILLER INFO", Content = "Does not kill Guardians and Voidbound Guardians since they are server sided! This will also affect spawned enemies!"})

GameTab:CreateToggle({
    Name = "Kill enemies when game starts",
    CurrentValue = false,
    Flag = "ExecuteEnemy",
    Callback = KillEnemy
})

GameTab:CreateToggle({
    Name = "Kill husks when game starts",
    CurrentValue = false,
    Flag = "ExecuteHusk",
    Callback = KillHusk
})

GameTab:CreateParagraph({Title = "ENEMY SPAWNER INFO", Content = "(Remember it's all client sided!) Heres a list of all enemies you can summon currently: Baby, Bell, Cadence, Flesh, Fleshling, Guardian, ICBM, Kolona, Mart, Oblivion, Operator, Ponderer, Quartz, Random, Scrapmaw, ShadowBaby, ShadowBabyConcept, ShadowGuardian, Sigil, Skinwalker, Slicer, Springer, Telefragger, Voidbreaker, nilEnemy, Nilmirage"})

GameTab:CreateButton({
    Name = "Spawn enemy put from 'Selected Enemy' box.",
    CurrentValue = false,
    Flag = "SpawnEnemy",
    Callback = function()
        sound()
        spawnEnemy(Enemy)
    end,
})

GameTab:CreateInput({Name = "Selected Enemy"; PlaceholderText = Enemy; NumbersOnly = false; OnEnter = true; RemoveTextAfterFocusLost = false; Callback = function(Value)
Enemy = Value
end;})

GameTab:CreateButton({
    Name = "Clear all Enemies",
    CurrentValue = false,
    Flag = "ClearEnemies",
    Callback = function()
        for i, v in pairs(game.Workspace:FindFirstChild("Enemies"):GetChildren()) do
            pcall(function() v:Destroy() end)
        end
    end,
})

GameTab:CreateButton({
    Name = "Activate Anti Void",
    CurrentValue = false,
    Flag = "AntiVoid",
    Callback = function()
        local antivoidtpplace = "Center of the Map"
        local a = workspace.KillVoid:Clone()
        a.Position = workspace.KillVoid.Position + Vector3.new(0,20,0)
        a.CanTouch = false
        pcall(function() a.TouchInterest:Destroy() end)
        pcall(function() a:FindFirstChildOfClass("TouchTransmitter"):Destroy() end)
        task.wait()
        a.CanCollide = false
        a.Transparency = 1
        a.Name = "AntiVoid"
        a.Parent = workspace    
        end,
})

GameTab:CreateToggle({Name = "Auto-Remove Ice Tiles"; CurrentValue = false; Callback = function(Value)
local newpart = Instance.new("Part")
newpart.Name = "WawawaCode"
newpart.Anchored = true
newpart.Parent = workspace
end; })

GameTab:CreateSlider({Name = "FOV"; Range = {0,360}; Increment = 1; Suffix = ""; CurrentValue = workspace.CurrentCamera.FieldOfView; Callback = function(Value)
workspace.CurrentCamera.FieldOfView = Value
end; })


-- // FUN TAB \\ --
--[[
FunTab:CreateButton({
    Name = "Pull Unanchored Parts button.",
    CurrentValue = false,
    Flag = "PullPartsButton",
    Callback = function()
    end,
})
]]

FunTab:CreateButton({Name = "Unlock Reset Button"; Callback = function()
game.StarterGui:SetCore("ResetButtonCallback", true)
end; })


-- on hold for rework
task.spawn(function()
    sfxfolder.NewLevel:Play()
    message("PLEASE DO NOT RUN THIS SCRIPT MORE THAN TWICE, THINGS MAY BREAK!")
end)

hint:Destroy()
while true do
if ExecutingEnemy == true then
    for _, v in pairs(game.Workspace:FindFirstChild('Enemies'):GetChildren()) do
        if v.Name == "Guardian" or v.Name == "ShadowGuardian" then
            
        else
            pcall(function() v:Destroy() end)
        end
    end
end
if ExecutingEnemy == false and ExecutingHusuk == true then
   pcall(function() workspace.Skinwalkers:ClearAllChildren() end)
end
if game.Workspace:FindFirstChild("WawawaCode") then
for _,c in next, workspace.CurrentRooms:GetDescendants() do
if c:IsA("BasePart") and c.Material==Enum.Material.Ice then
c.Material=Enum.Material.Plastic
end
end 
end

wait(0.05)
end
--```