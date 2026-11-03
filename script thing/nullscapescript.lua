local placeId = game.PlaceId

if placeId == 100588763114828 then

else
   return 
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "nullbub script",
   Icon = 114293255506804, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "nullscape",
   LoadingSubtitle = "by nottreal",
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
      FileName = "nullbub"
   },
 
   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "https://discord.gg/dKrbYz3g4h", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },
 
   KeySystem = true, -- Set this to true to use our key system
   KeySettings = {
      Title = "Verification",
      Subtitle = "are you ultra nullbub",
      Note = "Put Yes", -- Use this to tell the user how to get a key
      FileName = "Nullestion", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Yes", "yes", "yEs", "yeS", "YEs", "yES", "YES", "uber secret code that nobody will find out gulp", "throzyckd", "67", "slammy", "nullbub is cool"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})

local MainTab = Window:CreateTab("Main", 4483362458) 
local GameTab = Window:CreateTab("Game", 4483362458)
local EnemyTab = Window:CreateTab("Enemy Spawner", 4483362458)
--local FunTab = Window:CreateTab("Fun", 4483362458)
local SlammyTab = Window:CreateTab("Slammy", 97956330326398)
local NullbubtipsTab = Window:CreateTab("NullbubTips", 4483362458)
local whatever = Window:CreateTab("hi this was added cuz my friend requested it", 126824355195428)

local sound = game:GetService("SoundService")
local sfxfolder = sound.SFXFolder

-- status
local WawawaCode = false

local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char.HumanoidRootPart
local humanoid = char:WaitForChild("Humanoid")

local ExecutingEnemy = false
local ExecutingOthers = false
local ExecutingHusk = false
local ExecutingMart = false

local Enemy = "Bell"

local function message(text)
	Rayfield:Notify("nullbub", tostring(text))
    print("nullbub: " .. text)
end

local dist = 9999999999999999999999999999999999999999999999999999999999999999999999999999999999 -- this holds up the entire enemy deleter script LOOL

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

local function KillMart(state)
    ExecutingMart = state
    sound()
end

local function KillOther(state)
    ExecutingOthers = state
    sound()
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

MainTab:CreateParagraph({Title = "WIP", Content = "Missing more features i'd like to add, more things along the way, keybind is P! huge thanks to Nexer with their old hub scripts and me sharing just a bit of them!"})
MainTab:CreateParagraph({Title = "Server", Content = "https://discord.gg/dKrbYz3g4h"})
MainTab:CreateLabel("if the notification doesnt say anything check F9 mb im too tired to fix ill fix it later, also please use yield this script is just here to support all the automatic process you could use with yield really")

-- // SlAMMY TAB \\ --

SlammyTab:CreateParagraph({Title = "slammy", Content = "the goat"})
SlammyTab:CreateParagraph({Title = "nottreal", Content = "Main Dev"})
SlammyTab:CreateParagraph({Title = "random dude", Content = "reached level 40+ with my script and did voidbound scarf solo WITH beating celestial, longest run ive seen with it so far, im really proud of them!"})

-- // TIPS TAB \\ -- 
NullbubtipsTab:CreateParagraph({Title = "General Help", Content = ""})
NullbubtipsTab:CreateLabel("Please use this script on a solo run or with friends you trust")
NullbubtipsTab:CreateLabel("It's recommended to use yields loopws if you wanna go fast. i'm too lazy to make it myself")
NullbubtipsTab:CreateLabel("If you wanna infinite jump, set a command keybind on yield and set the keybind as the space bar and the command as jump")
NullbubtipsTab:CreateLabel("It's very necessary to set command keybinds they help a LOT")
NullbubtipsTab:CreateParagraph({Title = "FaQ", Content = ""})
NullbubtipsTab:CreateLabel("You are fully immune to celestial during her fight, just watch out for tripmines if you're on standard or extreme")
NullbubtipsTab:CreateLabel("im prob never gonna allow this script to run in the lobby sorry")
NullbubtipsTab:CreateLabel("You are allowed to modify my script its open source for everyone")
NullbubtipsTab:CreateLabel("it is not my fault if you get banned from the game lol")

-- // GAME TAB \\ --

GameTab:CreateParagraph({Title = "ENEMY KILLER INFO", Content = "You are still fragile to Guardian and Voidbound Guardian! This will also affect spawned enemies!"})

GameTab:CreateToggle({
    Name = "Kill enemies when the game starts",
    CurrentValue = false,
    Flag = "ExecuteEnemy",
    Callback = KillEnemy
})

GameTab:CreateToggle({
    Name = "Kills Void Implosions and possibly others when the game starts",
    CurrentValue = false,
    Flag = "ExecuteOthers",
    Callback = KillOther
})

GameTab:CreateToggle({
    Name = "Kill husks when the game starts",
    CurrentValue = false,
    Flag = "ExecuteHusk",
    Callback = KillHusk
})

GameTab:CreateLabel("i think some people are gonna question the existance of this i added this because of beacon imp and beacon imp is just an transformed mart it isnt its own model sorry")
GameTab:CreateToggle({
    Name = "Kill Marts when the game starts",
    CurrentValue = false,
    Flag = "ExecuteMart",
    Callback = KillMart
})


GameTab:CreateButton({
    Name = "Tripmine ESP",
    CurrentValue = false,
    Flag = "TRIPMINEESPHELLIMYOURNEGIBHORUGFGODODOODODODOS",
    Callback = function()
        local tripminething = workspace.Item_Pools.Tripmine_Model
        local highlight = Instance.new("Highlight")
        highlight.Parent = tripminething
        highlight.FillColor = Color3.new(0, 255, 0)
        highlight.OutlineColor = Color3.new(0, 255, 0)
        highlight.FillTransparency = 0
        sound()
    end,
})

GameTab:CreateButton({
    Name = "Clear all Enemies",
    CurrentValue = false,
    Flag = "ClearEnemies",
    Callback = function()
        sound()
        for i, v in pairs(game.Workspace:FindFirstChild("Enemies"):GetChildren()) do
            pcall(function() v:Destroy() end)
        end
    end,
})

GameTab:CreateLabel("Removing bells effect is irreversible.")
GameTab:CreateButton({
    Name = "Remove Bells Effect",
    CurrentValue = false,
    Flag = "CLEARBELLLLL",
    Callback = function()
        sound()
        game.Lighting.Blur.Enabled = false
        game.Lighting.Bloom.Enabled = false
        game.Lighting.ColorCorrection.Enabled = false
        game.Lighting.Flash.Enabled = false
        game.Lighting.Gamma.Enabled = false
    end,
})

GameTab:CreateLabel("Anti Void is currently patched i am working on a rework please wait for it to release.")

GameTab:CreateButton({
    Name = "Fake Count Patch",
    CurrentValue = false,
    Flag = "FAKECOUNT",
    Callback = function()
    	if game.Players.LocalPlayer.PlayerGui:FindFirstChild("fakecountboi") then
    		game.Players.LocalPlayer.PlayerGui:FindFirstChild("fakecountboi"):Destroy()
    	end
    	local gui = Instance.new("ScreenGui")
        gui.Name = "fakecountboi"
        gui.DisplayOrder = 11
        gui.Parent = game.Players.LocalPlayer.PlayerGui
        local TripmineCounter = game.ReplicatedStorage.GiftCounters
        local button = Instance.new("TextLabel")
        button.Size = UDim2.new(0, 200, 0, 50)
        button.Position = UDim2.new(0.5, -100, 0.9, -60)
        button.Text = "" .. tostring(TripmineCounter.Gift:GetAttribute("Collected")) .. "/" .. tostring(TripmineCounter.Gift:GetAttribute("MaxGifts")) .. "" 
        TripmineCounter.Gift:GetAttributeChangedSignal("Collected"):Connect(function()
        	button.Text = "" .. tostring(TripmineCounter.Gift:GetAttribute("Collected")) .. "/" .. tostring(TripmineCounter.Gift:GetAttribute("MaxGifts")) .. "" 
        end)
        button.Parent = gui
        button.TextScaled = true
        sound()
    end,
})


GameTab:CreateToggle({Name = "Auto-Remove Ice Tiles"; CurrentValue = false; Callback = function(Value)
WawawaCode = Value
end; })

-- // ENEMY TAB \\ --

local function spawnEnemy(Enemy)
   local enemylist = game.ReplicatedStorage.EnemyFolder.Enemies
   local selectedEnemy = enemylist:FindFirstChild(Enemy)
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

EnemyTab:CreateParagraph({Title = "ENEMY SPAWNER INFO", Content = "(Remember it's all client sided!) Heres a list of all enemies you can summon currently: Baby, Bell, Cadence, Flesh, Fleshling, Guardian, ICBM, Kolona, Mart, Oblivion, Operator, Ponderer, Quartz, Random, Scrapmaw, ShadowBaby, ShadowBabyConcept, ShadowGuardian, Sigil, Skinwalker, Slicer, Springer, Telefragger, Voidbreaker, nilEnemy, Nilmirage"})

EnemyTab:CreateButton({
    Name = "Spawn enemy put from 'Selected Enemy' box.",
    CurrentValue = false,
    Flag = "SpawnEnemy",
    Callback = function()
        sound()
        spawnEnemy(Enemy)
    end,
})

EnemyTab:CreateInput({Name = "Selected Enemy"; PlaceholderText = Enemy; NumbersOnly = false; OnEnter = true; RemoveTextAfterFocusLost = false; Callback = function(Value)
Enemy = Value
end;})

-- // FUN TAB \\ --


task.spawn(function()
    sfxfolder.NewLevel:Play()
    message("PLEASE DO NOT RUN THIS SCRIPT MORE THAN TWICE, THINGS MAY BREAK!")
end)

local blacklist = {
    Cadence,
    StarMart,
    Guardian,
    ShadowGuardian,
    Mart, -- this is only here so he doesnt get enemy removed
}

local martlist = {
    Mart,
    RedMart
}

-- ok i reworked this it should lag less
game.Workspace:FindFirstChild('Enemies').ChildAdded:Connect(function(childaddedboi)
if ExecutingEnemy == true and dist == 9999999999999999999999999999999999999999999999999999999999999999999999999999999999 then -- i wasnt joking 2 btw
    if table.find(blacklist, childaddedboi.Name) then
    	-- hello
    else
        childaddedboi:Destroy()	
    end
end
if ExecutingMart == true then 
	if table.find(martlist, childaddedboi.Name) then
		childaddedboi:Destroy()
	end
end
if ExecutingEnemy == false and ExecutingHusk == true then
   pcall(function() workspace.Skinwalkers:ClearAllChildren() end)
end
end)

game.Workspace.CurrentRooms.ChildAdded:Connect(function(childaddedboi2)
	for _,c in next, workspace.CurrentRooms:GetDescendants() do
        if c:IsA("BasePart") and c.Material==Enum.Material.Ice then
        c.Material=Enum.Material.Plastic
        end
    end
end)
