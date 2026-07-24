local replicatedstorage = game.ReplicatedStorage
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()


if char:GetAttribute("KillerName") then
	    print("you are killer")
	else
		return
end

if char:GetAttribute("KillerName") ~= "Pursuer" then
	print("you have to be pursuer to run this")
    return
end

--[[ Don't change this ]]--
local LocalPlayer, LP = game:GetService("Players").LocalPlayer, game:GetService("Players").LocalPlayer
local Character, Char
local HumanoidRootPart, HRP
local Humanoid, Hum
pcall(function()
Character, Char = LocalPlayer.Character, LocalPlayer.Character
end)
pcall(function()
HumanoidRootPart, HRP = Character.HumanoidRootPart, Character.HumanoidRootPart
end)
pcall(function()
Humanoid, Hum = Character.Humanoid, Character.Humanoid
end)
LocalPlayer.CharacterAdded:Connect(function(char)
pcall(function()
Character, Char = nil, nil
HumanoidRootPart, HRP = nil, nil
Humanoid, Hum = nil, nil
task.wait()
Character, Char = char, char
repeat task.wait() until char:FindFirstChild("HumanoidRootPart")
HumanoidRootPart, HRP = char.HumanoidRootPart, char.HumanoidRootPart
repeat task.wait() until Character:FindFirstChild("Humanoid")
Humanoid, Hum = char.Humanoid, char.Humanoid
end)
end)







function CreateMessage(a)
local instancename = (a=="Message" and a) or "Hint"
local msg = Instance.new(instancename,game:GetService("CoreGui"))
msg.Text = ""
return msg
end

-- Loading my modules
local msg = CreateMessage()
msg.Text = "Loading Modules... (0/4)"
local modules = {
	{"Main Module", "https://raw.githubusercontent.com/NewNexer/NexerHub/refs/heads/main/Modified%20Module.luau", true},
	{"Client Replicator", "https://raw.githubusercontent.com/NewNexer/NexerHub/refs/heads/main/DOD/Modules/ClientReplicator.luau", true},
	{"Client Animations", "https://raw.githubusercontent.com/NewNexer/NexerHub/refs/heads/main/DOD/Modules/ClientAnimations.luau", true},
	{"Client Abilities", "https://raw.githubusercontent.com/NewNexer/NexerHub/refs/heads/main/DOD/Modules/ClientAbilities.luau", true},
}
local loaded, attempts = {}, {}
for i = 1, #modules do attempts[i] = 0 end
local i = 1
repeat task.wait()
	local suc, res = pcall(function()
		return modules[i][3] and loadstring(game:HttpGet(modules[i][2]))() or game:HttpGet(modules[i][2])
	end)
	if not suc then
		attempts[i] += 1
		msg.Text = "Failed loading module '"..modules[i][1].."', retry: "..attempts[i]
		task.wait(1)
	else
		loaded[modules[i][1]] = res
		msg.Text = "Loading module '"..modules[i][1].."'... ("..tostring(i).."/4)"
		i += 1
		task.wait(1)
	end
until i > #modules
local Module, CReplicator, CAnimations, CAbilities = loaded["Main Module"], loaded["Client Replicator"], loaded["Client Animations"], loaded["Client Abilities"]
msg.Text = "YOU ARE NOW ULTRASUER, WARNING YOU CAN ONLY RUN THIS ONCE AS OF NOW"
task.delay(2, function() msg:Destroy() end)


--[[ Additional Connections Handler ]]--
local rs = game:GetService("RunService")
local Heartbeat = {}
rs.Heartbeat:Connect(function()
for i,v in next, Heartbeat do
if v~=nil then
task.spawn(v)
end
end
end)

local NoFatigue = true
if NoFatigue == true then
task.spawn(function()
Heartbeat.LoopNoFatigue = function() if Character~=nil and Character:GetAttribute("Fatigue")~=nil and Character:GetAttribute("Fatigue") == 1 then Character:SetAttribute("Fatigue", 0) end end
repeat task.wait(0.1) until NoFatigue == false
if Heartbeat.LoopNoFatigue~=nil then
Heartbeat.LoopNoFatigue = nil
end
end)
end
local NoSpeedDebuffs = true
if NoSpeedDebuffs == true then
task.spawn(function()
Heartbeat.LoopNoSpeedDebuffs = function() if Character~=nil and Character:GetAttribute("WalkSpeedModifier")~=nil and Character:GetAttribute("WalkSpeedModifier")<0 then Character:SetAttribute("WalkSpeedModifier", 0) end end
repeat task.wait(0.1) until NoSpeedDebuffs == false
if Heartbeat.LoopNoSpeedDebuffs~=nil then
Heartbeat.LoopNoSpeedDebuffs = nil
end
end)
end

local NoCDSwing = true
if NoCDSwing~=true then return end
Character:SetAttribute("SwingCooldown","")
Character:GetAttributeChangedSignal("SwingCooldown"):Connect(function()
if NoCDSwing~=true then return end
Character:SetAttribute("SwingCooldown","")
end)
Character:SetAttribute("EjectCooldown","")
Character:GetAttributeChangedSignal("EjectCooldown"):Connect(function()
if NoCDSwing~=true then return end
Character:SetAttribute("EjectCooldown","")
end)
LocalPlayer.CharacterAdded:Connect(function(cac)
task.spawn(function()
if InfiniteStamina~=true then return end
cac:SetAttribute("MaxStamina",math.huge)
cac:GetAttributeChangedSignal("MaxStamina"):Connect(function()
if InfiniteStamina~=true then return end
cac:SetAttribute("MaxStamina",math.huge)
end)
end)
task.spawn(function()
if CanJump~=true then return end
cac:WaitForChild("Humanoid",9e9).UseJumpPower=true
end)
task.spawn(function()
if NoCDSwing~=true then return end
cac:SetAttribute("SwingCooldown","")
cac:GetAttributeChangedSignal("SwingCooldown"):Connect(function()
if NoCDSwing~=true then return end
cac:SetAttribute("SwingCooldown","")
end)
end)
task.spawn(function()
if NoCDSwing~=true then return end
cac:SetAttribute("EjectCooldown","")
cac:GetAttributeChangedSignal("EjectCooldown"):Connect(function()
if NoCDSwing~=true then return end
cac:SetAttribute("EjectCooldown","")
end)
end)
end)

function ReloadClientReplicator()
pcall(function()
ClientReplicator.Disconnect()
end)
pcall(function()
ClientReplicator = nil
end)
loadstring(game:HttpGet("https://raw.githubusercontent.com/NewNexer/NexerHub/refs/heads/main/DOD/Modules/ClientReplicator.luau"))()
end

ClientReplicator["Extend Hitbox"] = true
ClientReplicator["Studs"] = 1.5

local HitboxReacherEnabled = false
local HitboxReacherRange = 20

HitboxReacherEnabled = true
HitboxReacherRange = true

local noclip_connection = nil
local camera_connection = nil

ClientReplicator["Spoof Enabled"] = Value

function setupevilpursuer() 
local Animations = char:FindFirstChild("Animations")

local GameLeSounds = replicatedstorage.Sounds
local ChaseTheme = Animations:FindFirstChild("ChaseTheme")

ChaseTheme.SoundId = "rbxassetid://70601819363531"

local Anims = {
    Cleave = "116715653550146",
    CleaveEnd = "80815120469334",
    CleaveVariant = "83348134311266",
    Howl = "121742294178562",
    HowlVariant = "100501922654340",
    Idle = "72302851897153",
    QuickStalk = "89427900174026",
    Sprint = "96466802514756",
    Stalk = "102500736910427",
    StalkCleave = "72001574245287",
    StalkLoop = "102302720518230",
    Stunned = "87593869628310",
    Swing = "110928868845015",
    Walk = "126800100356307"
}

for i, v in pairs(Animations:GetChildren()) do
	if v:IsA("Animation") then 
		v.AnimationId = "rbxassetid://" .. Anims[v.Name]
	end
end


char:SetAttribute("MaxStamina", 300)
char:SetAttribute("WalkSpeed", 11)
char:SetAttribute("SprintSpeed", 33)

local highlight = Instance.new("Highlight")
highlight.Parent = char
highlight.FillColor = Color3.fromRGB(8, 8, 255)
highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
highlight.FillTransparency = 15

GameLeSounds.LMSSongs.Eternity.SoundId = "rbxassetid://98757689536447"
GameLeSounds.LMSSongs.FlashlightVsPursuer.SoundId = "rbxassetid://98757689536447"
GameLeSounds.LMSSongs["Double Trouble"].SoundId = "rbxassetid://98757689536447"
GameLeSounds.LMSSongs.DienationLMS.SoundId = "rbxassetid://98757689536447"
end

setupevilpursuer()

while true do
    wait(5)
    if char.Parent == "Killer" then
    if char:GetAttribute("KillerName") then 
    	if char:GetAttribute("KillerName") == "Pursuer" then 
    		setupevilpursuer()
    	end
    end
    else
    	GameLeSounds.LMSSongs.Eternity.SoundId = "rbxassetid://86018517086620"
        GameLeSounds.LMSSongs.FlashlightVsPursuer.SoundId = "rbxassetid://105425959016831"
        GameLeSounds.LMSSongs["Double Trouble"].SoundId = "rbxassetid://102327893551966"
        GameLeSounds.LMSSongs.DienationLMS.SoundId = "rbxassetid://93918596362091"
    end
end