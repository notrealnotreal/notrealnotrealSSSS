local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

game:GetService("Lighting")

local ClientModules = ReplicatedStorage:WaitForChild("ClientModules")
local Events = ReplicatedStorage:WaitForChild("Events")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera
local v1 = LocalPlayer:GetMouse()

-- ============================================================================
-- SETTINGS CONFIG
-- ============================================================================
local SettingsConfig = {
	Categories = {
		"Preferences",
		"PVP",
		"Accessibility",
		"Audio",
		"Keybinds",
		"Profile",
		"Fun"
	},
	Settings = {
		AFK = { Name = "AFK", Title = "AFK Mode", LayoutOrder = 0, Category = "Preferences" },
		Debug = { Name = "Debug", Title = "Debug Information", Bio = "Developer stuff.", LayoutOrder = 10, Category = "Preferences" },
		CollisionBox = { Name = "CollisionBox", Title = "Show CollisionBoxes.", LayoutOrder = 3, Category = "Preferences" },
		KindMode = { Name = "KindMode", Title = "Kind Mode", Bio = "Disables being the killer and gaining evilness.", LayoutOrder = 2, Category = "Preferences" },
		Tags = { Name = "Tags", Title = "Tags", Bio = "Whether or not your tags will be shown incase you have any.", OnByDefault = true, LayoutOrder = 4, Category = "Profile" },
		SprintToggle = { Name = "SprintToggle", Title = "Sprint Toggle", Bio = "Whether or not your sprint will be toggleable instead of held.", LayoutOrder = 6, Category = "Preferences" },
		Points = { Name = "Points", Title = "Point Messages", OnByDefault = true, LayoutOrder = 6, Category = "Preferences" },
		LowHealthUI = { Name = "LowHealthUI", Title = "Low Health UI", OnByDefault = true, LayoutOrder = 6, Category = "Preferences" },
		CameraPoint = { Name = "CameraPoint", Title = "Camera Point", LayoutOrder = 6, Category = "Preferences", Options = { "Torso", "HumanoidRootPart", "Head" } },
		LMSUI = { Name = "LMSUI", Title = "LMS UI", Bio = "Whether or not the LMS UI will appear on your screen.", OnByDefault = true, LayoutOrder = 2, Category = "Preferences" },
		PointBoosts = { Name = "PointBoosts", Title = "Point Boosts", Bio = "If you currently have a point boost, turning this off will pause it.", OnByDefault = true, LayoutOrder = 8, Category = "Preferences" },
		VisiblePointBoosts = { Name = "VisiblePointBoosts", Title = "Visible Point Boosts", Bio = "Whether or not point boosts will be visible ingame.", OnByDefault = true, LayoutOrder = 9, Category = "Preferences" },
		FOV = { Name = "FOV", Title = "Field of View", Slider = true, Volume = true, Default = 0.7, LayoutOrder = 2, Category = "Preferences" },
		MasterVolume = { Name = "MasterVolume", Title = "Master Volume", Slider = true, Volume = true, Default = 1, LayoutOrder = 1, Category = "Audio" },
		MusicVolume = { Name = "MusicVolume", Title = "Music", Slider = true, Volume = true, Default = 0.9, LayoutOrder = 2, Category = "Audio" },
		SFXVolume = { Name = "SFXVolume", Title = "SFX", Slider = true, Volume = true, Default = 0.8, LayoutOrder = 3, Category = "Audio" },
		EmoteVolume = { Name = "EmoteVolume", Title = "Emotes", Slider = true, Volume = true, Default = 0.9, LayoutOrder = 4, Category = "Audio" },
		ChaseThemes = { Name = "ChaseThemes", Title = "Chase Themes", LayoutOrder = 7, OnByDefault = true, Category = "Audio" },
		GlobalChaseThemes = { Name = "GlobalChaseThemes", Title = "Global Chase Themes", Bio = "Whether or not you will hear your own chase themes even when not near a civilian.", LayoutOrder = 8, Category = "Audio" },
		UseDefaultChaseThemes = { Name = "UseDefaultChaseThemes", Title = "Default Chase Themes", Bio = "Forces every skin to use the killer's default chase theme.", LayoutOrder = 9, Category = "Audio" },
		Ability1Keybind = { Name = "Ability1Keybind", Title = "Main Ability Keybind", Keybind = true, Default = "MouseButton1", ConsoleDefault = "ButtonR2", LayoutOrder = 1, Category = "Keybinds" },
		Ability2Keybind = { Name = "Ability2Keybind", Title = "Ability 2 Keybind", Keybind = true, Default = "Q", ConsoleDefault = "ButtonL1", LayoutOrder = 2, Category = "Keybinds" },
		Ability3Keybind = { Name = "Ability3Keybind", Title = "Ability 3 Keybind", Keybind = true, Default = "E", ConsoleDefault = "ButtonR1", LayoutOrder = 3, Category = "Keybinds" },
		Ability4Keybind = { Name = "Ability4Keybind", Title = "Ability 4 Keybind", Keybind = true, Default = "R", ConsoleDefault = "ButtonY", LayoutOrder = 4, Category = "Keybinds" },
		Ability5Keybind = { Name = "Ability5Keybind", Title = "Ability 5 Keybind", Keybind = true, Default = "T", ConsoleDefault = "ButtonB", LayoutOrder = 5, Category = "Keybinds" },
		Ability6Keybind = { Name = "Ability6Keybind", Title = "Ability 6 Keybind", Keybind = true, Default = "Y", ConsoleDefault = "ButtonX", LayoutOrder = 6, Category = "Keybinds" },
		SprintKeybind = { Name = "SprintKeybind", Title = "Sprint Keybind", Keybind = true, Default = "LeftShift", ConsoleDefault = "ButtonL2", LayoutOrder = 7, Category = "Keybinds" },
		EmoteKeybind = { Name = "EmoteKeybind", Title = "Emote Keybind", Keybind = true, Default = "G", ConsoleDefault = "DPadUp", LayoutOrder = 8, Category = "Keybinds" },
		InteractKeybind = { Name = "InteractKeybind", Title = "Interact Keybind", Keybind = true, Default = "Space", ConsoleDefault = "ButtonX", LayoutOrder = 9, Category = "Keybinds" },
		ShiftlockKeybind = { Name = "ShiftlockKeybind", Title = "Shiftlock Keybind", Keybind = true, Default = "LeftControl", ConsoleDefault = "ButtonL3", LayoutOrder = 10, Category = "Keybinds" },
		ResetKeybinds = { Name = "ResetKeybinds", Title = "Reset Keybinds", Trigger = true, LayoutOrder = 20, Category = "Keybinds" },
		Epilepsy = { Name = "Epilepsy", Title = "Epilepsy Mode", Bio = "Playing this game with such condition is NOT recommended.", LayoutOrder = 3, Category = "Accessibility" },
		CameraShake = { Name = "CameraShake", Title = "Camera Shake", OnByDefault = true, LayoutOrder = 6, Category = "Accessibility" },
		LowDetailMode = { Name = "LowDetailMode", Title = "Low Detail Mode", LayoutOrder = 6, Category = "Accessibility" },
		MapEffects = { Name = "MapEffects", Title = "Map Effects", Bio = "Whether or not map effects such as rain & snow will render on the screen.", OnByDefault = true, LayoutOrder = 4, Category = "Accessibility" },
		SimpleDestroyables = { Name = "SimpleDestroyables", Title = "Simple Destroyables", Bio = "Whether or not destroyables will be instantly removed upon being broken.", LayoutOrder = 9, Category = "Preferences" },
		LMSEffects = { Name = "LMSEffects", Title = "LMS Effects", Bio = "Whether or not special Last Man Standing effects will render on your screen.", OnByDefault = true, LayoutOrder = 7, Category = "Accessibility" },
		Blood = { Name = "Blood", Title = "Blood", LayoutOrder = 7, Category = "Accessibility", Options = { "Off", "Default", "Food", "Paint", "Junk" } },
		ScreensaverTime = { Name = "ScreensaverTime", Title = "Screensaver Time", Bio = "How much time it takes for screensavers appear on your screen.", LayoutOrder = 11, Category = "Preferences", Options = { "120", "300", "80", "10", "Off" } },
		StaminaCounter = { Name = "StaminaCounter", Title = "Stamina Counter", Bio = "Adds a central Stamina counter.", LayoutOrder = 8, Category = "Accessibility" },
		SpeedCounter = { Name = "SpeedCounter", Title = "Speed Counter", Bio = "Adds a central Speed counter.", LayoutOrder = 9, Category = "Accessibility" },
		CursorCentralCounters = { Name = "CursorCentralCounters", Title = "Cursor Central Counters", Bio = "Whether or not the central stamina and speed counters will follow the cursor.", LayoutOrder = 10, Category = "Accessibility" },
		Hitboxes = { Name = "Hitboxes", Title = "Show Hitboxes", LayoutOrder = 1, Category = "PVP" },
		HitboxLinger = { Name = "HitboxLinger", Title = "Hitbox Linger", LayoutOrder = 1, Category = "PVP", Options = { "1", "1.5", "2", "2.5", "3", ".5", ".25", ".1" } },
		Hitmarkers = { Name = "Hitmarkers", Title = "Show Hitmarkers", Bio = "Whether or not hitmarkers will be displayed on your screen.", OnByDefault = true, LayoutOrder = 2, Category = "PVP" },
		AccumulatedHitmarkers = { Name = "AccumulatedHitmarkers", Title = "Accumulated Hitmarkers", Bio = "Goes with the hitmarker setting, but combines the number of damage dealt to the target.", LayoutOrder = 2, Category = "PVP" },
		HurtBox = { Name = "HurtBox", Title = "Show HurtBoxes", LayoutOrder = 2, Category = "PVP" },
		Hitsounds = { Name = "Hitsounds", Title = "Hitsounds", LayoutOrder = 4, Category = "PVP", OnByDefault = true },
		HitsoundID = { Name = "HitsoundID", Title = "Hitsound ID", LayoutOrder = 5, Category = "PVP", SoundID = true },
		Crosshair = { Name = "Crosshair", Title = "Crosshair", LayoutOrder = 6, Category = "PVP" },
		CrosshairImage = { Name = "CrosshairImage", Title = "Crosshair Image", LayoutOrder = 7, Category = "PVP", SoundID = true },
		AutomaticDeckSelection = { Name = "AutomaticDeckSelection", Title = "Automatic Deck Selection", Bio = "Automatically picks random ability decks for you.", LayoutOrder = 1, Category = "Fun" },
		DesktopDombs = { Name = "DesktopDombs", Title = "Desktop Dombs", LayoutOrder = 2, Category = "Fun", Options = { "0", "1", "2", "3", "4", "5", "10", "20", "50" } },
		SkinInventory = { Name = "SkinInventory", Title = "Skin Inventory", LayoutOrder = 1, Category = "Profile", Options = { "Public", "Friends-Only", "Private" } },
		AchievementInventory = { Name = "AchievementInventory", Title = "Achievement Inventory", LayoutOrder = 2, Category = "Profile", Options = { "Public", "Friends-Only", "Private" } },
		Playtime = { Name = "Playtime", Title = "Playtime", LayoutOrder = 3, Category = "Profile", Options = { "Public", "Friends-Only", "Private" } },
		AchievementDisplay = { Name = "AchievementDisplay", Title = "Achievement Display", LayoutOrder = 4, Category = "Profile", Options = { "None" } }
	}
}

-- ============================================================================
-- VARIABLES
-- ============================================================================
local Variables = {
	CurrentCamera = nil,
	Stamina = nil,
	FOVModifier = 0,
	IntrosAllowed = nil,
	ResultsOpen = false,
	SelectedKiller = nil,
	SelectedSkin = nil,
	SelectedCustomization = nil,
	SelectedCategory = nil,
	ConfirmItem = nil,
	ConfirmType = nil,
	CurrentSong = nil,
	SongPriority = false,
	ChaseId = nil,
	CurrentChaseTheme = nil,
	VolumeModifier = 0,
	ResultsVictory = nil,
	CurrentArea = nil,
	LibraryRoom = nil,
	Achievements = nil,
	TimeInLibrary = 0,
	PreferredInput = nil,
	AbilityInput1 = Enum.UserInputType.MouseButton1,
	AbilityInput2 = Enum.KeyCode.Q,
	AbilityInput3 = Enum.KeyCode.E,
	AbilityInput4 = Enum.KeyCode.R,
	AbilityInput5 = Enum.KeyCode.T,
	AbilityInput6 = Enum.KeyCode.Y,
	SprintKeybind = Enum.KeyCode.LeftShift,
	ShiftlockKeybind = Enum.KeyCode.LeftControl,
	InteractKeybind = Enum.KeyCode.Space,
	EmoteKeybind = Enum.KeyCode.G,
	FOVSetting = 70,
	format = function(p1)
		return string.format("%02i", p1)
	end
}

function Variables.convertToHMS(p1)
	local v1 = (p1 - p1 % 60) / 60
	local v2 = p1 - v1 * 60
	local v3 = (v1 - v1 % 60) / 60
	local v4 = v1 - v3 * 60
	local v5 = (v3 - v3 % 24) / 24
	local v6 = v3 - v5 * 24
	local v7 = ("%*d%*h%*m%*s"):format(Variables.format(v5), Variables.format(v6), Variables.format(v4), (Variables.format(v2)))

	if v5 <= 0 then
		if v6 <= 0 then
			return ("%*m%*s"):format(Variables.format(v4), (Variables.format(v2)))
		end
		v7 = ("%*h%*m%*s"):format(Variables.format(v6), Variables.format(v4), (Variables.format(v2)))
	end

	return v7
end

function Variables.GetKeybindString(p1, p2)
	local v1

	if typeof(p1) == "string" then
		v1 = p1
	else
		local v2 = if p1 then p1.KeyCode and (if p1.KeyCode.Name == "Unknown" then false else true) else p1
		local _ = v2 and p1.KeyCode.Name or (p1 and p1.UserInputType.Name or nil)
		v1 = if v2 then game.UserInputService:GetStringForKeyCode(p1.KeyCode) ~= "" and not p2 and game.UserInputService:GetStringForKeyCode(p1.KeyCode) or p1.KeyCode.Name elseif p1 then p1.UserInputType.Name else p1
	end

	if not p2 and v1 == "MouseButton1" then
		v1 = "M1"
	elseif not p2 and v1 == "MouseButton2" then
		v1 = "M2"
	elseif not p2 and v1 == "MouseButton3" then
		v1 = "M3"
	end

	return if typeof(v1) == "string" and v1 then v1 else tostring(v1)
end

function Variables.GetKeybindStringAbility(p1)
	local v1 = p1.Name

	if p1.EnumType == Enum.KeyCode and game.UserInputService:GetStringForKeyCode(p1) ~= "" then
		v1 = game.UserInputService:GetStringForKeyCode(p1)
	end

	if v1 == "MouseButton1" then
		return "M1"
	end
	if v1 == "MouseButton2" then
		return "M2"
	end
	if v1 == "MouseButton3" then
		return "M3"
	end
	if v1 == " " then
		v1 = "Space"
	end

	return v1
end

function Variables.AbilityTip(p1, p2, p3)
	if p3 then
		return ("<font color='rgb(137, 255, 26)'>Usage:</font> <font color='rgb(255, 255, 255)'>%*</font>"):format(p3)
	end
	if p1 and p1.Synergies and p1.Synergies[p2] then
		return ("<font color='rgb(137, 255, 26)'>Usage:</font> <font color='rgb(255, 255, 255)'>%*</font>"):format(p1.Synergies[p2].Tip)
	end
	return ("<font color='rgb(137, 255, 26)'>Usage:</font> <font color='rgb(255, 255, 255)'>%*</font>"):format((p1 and p1.Tip) or "No tips for this ability.")
end

function Variables.KeybindLoop()
	local function KeyCodeExists(p1)
		return pcall(function()
			return Enum.KeyCode[p1]
		end)
	end

	while task.wait(0.1) do
		local shiftlockAttr = LocalPlayer:WaitForChild("Stats"):WaitForChild("Settings"):WaitForChild("ShiftlockKeybind"):GetAttribute("Keybind")
		if pcall(function() return Enum.KeyCode[shiftlockAttr] end) and Enum.KeyCode[shiftlockAttr].Name ~= "Unknown" then
			Variables.ShiftlockKeybind = Enum.KeyCode[shiftlockAttr]
		else
			Variables.ShiftlockKeybind = Enum.UserInputType[shiftlockAttr]
		end

		local sprintAttr = LocalPlayer.Stats.Settings.SprintKeybind:GetAttribute("Keybind")
		if pcall(function() return Enum.KeyCode[sprintAttr] end) and Enum.KeyCode[sprintAttr].Name ~= "Unknown" then
			Variables.SprintKeybind = Enum.KeyCode[sprintAttr]
		else
			Variables.SprintKeybind = Enum.UserInputType[sprintAttr]
		end

		local interactAttr = LocalPlayer.Stats.Settings.InteractKeybind:GetAttribute("Keybind")
		if pcall(function() return Enum.KeyCode[interactAttr] end) and Enum.KeyCode[interactAttr].Name ~= "Unknown" then
			Variables.InteractKeybind = Enum.KeyCode[interactAttr]
		else
			Variables.InteractKeybind = Enum.UserInputType[interactAttr]
		end

		local emoteAttr = LocalPlayer.Stats.Settings.EmoteKeybind:GetAttribute("Keybind")
		if pcall(function() return Enum.KeyCode[emoteAttr] end) and Enum.KeyCode[emoteAttr].Name ~= "Unknown" then
			Variables.EmoteKeybind = Enum.KeyCode[emoteAttr]
		else
			Variables.EmoteKeybind = Enum.UserInputType[emoteAttr]
		end
	end
end

coroutine.wrap(Variables.KeybindLoop)()

-- ============================================================================
-- GUI COLLECT (use existing)
-- ============================================================================
local MainGui = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainGui", 15)

local RoundUI = MainGui and MainGui:WaitForChild("RoundUI", 5)
local PlayerUI = RoundUI and RoundUI:WaitForChild("PlayerUI", 5)
local Teams = workspace:WaitForChild("GameAssets"):WaitForChild("Teams", 5)

-- ============================================================================
-- BADWARERIFT (inlined)
-- ============================================================================
local BadwareRift = {}
do
	local RiftSelect = nil
	pcall(function()
		RiftSelect = ReplicatedStorage.ClientModules.Gui.Game.Ability.Require.BadwareRift:WaitForChild("RiftSelect"):Clone()
	end)

	local t2 = {
		_initialised = false,
		Buttons = {}
	}

	function t2.CreateButton(p3)
		local v1, v2, v3

		if LocalPlayer.PlayerGui:FindFirstChild("RiftFolder") then
			v1 = LocalPlayer.PlayerGui:FindFirstChild("RiftFolder")
		else
			v1 = Instance.new("Folder", LocalPlayer.PlayerGui)
			v1.Name = "RiftFolder"
		end

		if not RiftSelect then return end
		v2 = RiftSelect:Clone()
		v2.Parent = v1
		v2.Adornee = p3.PrimaryPart
		table.insert(t2.Buttons, v2)
		v2.Button.MouseEnter:Connect(function()
			v2.Button.Sprite.ImageColor3 = Color3.fromRGB(169, 255, 78)
			v2.Button.Label.TextColor3 = Color3.fromRGB(169, 255, 78)
		end)
		v2.Button.MouseLeave:Connect(function()
			v2.Button.Sprite.ImageColor3 = Color3.fromRGB(255, 255, 255)
			v2.Button.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
		end)
		v2.Button.Activated:Connect(function()
			Events.RemoteEvents.Abilities.BadwareRift:FireServer(p3)
		end)
	end

	function t2.Init()
		local Character = LocalPlayer.Character
		if not t2._initialised and Character then
			t2._initialised = true
			for _, v in workspace.GameAssets.Teams.Other:GetChildren() do
				if v.Name == "Computer" then
					t2.CreateButton(v)
				end
			end
			repeat
				task.wait(0.1)
			until not (Character and Character.Parent and Character:GetAttribute("UsingAbility"))
			t2._initialised = false
		end
		for _, v in t2.Buttons do
			v:Destroy()
		end
		table.clear(t2.Buttons)
	end

	Events.RemoteEvents.Abilities.BadwareRift.OnClientEvent:Connect(t2.Init)
	BadwareRift = t2
end

-- ============================================================================
-- BADWAREBOLT (stub - not provided)
-- ============================================================================
pcall(function()
	require(ReplicatedStorage.ClientModules.Gui.Game.Ability.Require.BadwareBolt)
end)

-- ============================================================================
-- BUGLE EVENT (inlined, adjusted)
-- ============================================================================
local BugleEvent = {}
do
	local t3 = {
		_initialised = false,
		EventSpeed = 0.7,
		Keybinds = {
			Enum.KeyCode.Q,
			Enum.KeyCode.E,
			Enum.KeyCode.R,
			Enum.KeyCode.T,
			Enum.KeyCode.F,
			Enum.KeyCode.C
		},
		UIEffect = function(p3)
			TweenService:Create(p3.Parent, TweenInfo.new(0.1), {
				Position = UDim2.new(0, 0, 0.02, 0)
			}):Play()
			task.delay(0.1, function()
				TweenService:Create(p3.Parent, TweenInfo.new(0.15), {
					Position = UDim2.new(0, 0, 0, 0)
				}):Play()
			end)
		end
	}

	function t3.EventSuccess(p3, p4)
		p4.ImageColor3 = Color3.fromRGB(121, 217, 70)
		if p4:FindFirstChild("Keybind") then
			p3.Keybind.TextColor3 = Color3.fromRGB(121, 217, 70)
			p4.UIStroke.Enabled = true
			TweenService:Create(p4.UIStroke, TweenInfo.new(0.2), { Transparency = 1 }):Play()
			p4.Size = p3.Center.Size
		end
		t3.UIEffect(p4)
		ReplicatedStorage.Events.RemoteEvents.Abilities.Bugle:FireServer(true)
	end

	function t3.EventFail(p3, p4)
		p4.ImageColor3 = Color3.fromRGB(255, 16, 16)
		if p4:FindFirstChild("Keybind") then
			p3.Keybind.TextColor3 = Color3.fromRGB(255, 23, 23)
			p4.UIStroke.Enabled = true
			TweenService:Create(p4.UIStroke, TweenInfo.new(0.2), { Transparency = 1 }):Play()
			p4.Size = p3.Center.Size
		end
		t3.UIEffect(p4)
		ReplicatedStorage.Events.RemoteEvents.Abilities.Bugle:FireServer(false)
	end

	function t3.CreateEvent(p3, p4)
		if Variables.PreferredInput == Enum.PreferredInput.Touch then
			return t3.CreateMobileEvent(p3, p4)
		end

		local v1 = p3.Events.Template:Clone()
		v1.Visible = true
		v1.Parent = p3.Events
		Debris:AddItem(v1, p4 + 0.05)

		local v2 = TweenService:Create(v1, TweenInfo.new(p4 * 0.85, Enum.EasingStyle.Linear), {
			Size = p3.Center.Size
		})
		v2:Play()
		v1.ImageColor3 = Color3.fromRGB(255, 206, 60)
		p3.Keybind.TextColor3 = Color3.fromRGB(255, 206, 60)
		table.clear(t3.Keybinds)

		for i = 2, 5 do
			local v3 = LocalPlayer.Stats.Settings[("Ability%*Keybind"):format(i)]:GetAttribute("Keybind")
			if pcall(function() return Enum.KeyCode[v3] end) and Enum.KeyCode[v3].Name ~= "Unknown" then
				table.insert(t3.Keybinds, Enum.KeyCode[v3])
			else
				table.insert(t3.Keybinds, Enum.UserInputType[v3])
			end
		end

		local v6 = t3.Keybinds[math.random(1, #t3.Keybinds)]
		p3.Keybind.Text = v6.Name

		local v7 = nil
		v7 = UserInputService.InputBegan:Connect(function(p12, p2)
			if p2 then return end
			if p12.KeyCode ~= v6 and p12.UserInputType ~= v6 then return end
			v7:Disconnect()
			v7 = nil
			t3.EventSuccess(p3, v1)
		end)

		v2.Completed:Connect(function()
			if v7 then
				v7:Disconnect()
				t3.EventFail(p3, v1)
			end
		end)
	end

	function t3.CreateMobileEvent(p3, p4)
		local v1 = p3.Events.MobileTemplate:Clone()
		v1.Visible = true
		v1.Parent = p3.Events
		v1.Position = UDim2.new(math.random(-20, 20) / 50, 0, math.random(-20, 20) / 50, 0)
		Debris:AddItem(v1, p4 + 0.05)
		v1.ImageColor3 = Color3.fromRGB(255, 206, 60)

		local v2 = TweenService:Create(v1, TweenInfo.new(p4 * 0.85, Enum.EasingStyle.Linear), {
			ImageColor3 = Color3.fromRGB(255, 255, 255)
		})
		v2:Play()

		local v3 = nil
		v3 = v1.Activated:Connect(function()
			v3:Disconnect()
			v3 = nil
			t3.EventSuccess(p3, v1)
		end)
		v2.Completed:Connect(function()
			if v3 then
				v3:Disconnect()
				t3.EventFail(p3, v1)
			end
		end)
	end

	function t3.Init(p3)
		t3._initialised = true
		p3.Keybind.Text = ""
		p3.Start.Visible = true
		p3.Start.Text = "PRESS THE CORRECT KEYS!"
		p3.Events.Template.Visible = false

		local Character = LocalPlayer.Character
		for i = 1, 8 do
			if not (Character and Character:GetAttribute("UsingAbility")) then break end
			p3.Start.Visible = not p3.Start.Visible
			task.wait(0.1)
		end
		p3.Start.Visible = false

		local v1 = t3.EventSpeed + 0.2
		local v2 = if LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Synergy") == "NoiseMaker" then 8 else 4

		if LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Synergy") == "NoiseMaker" then
			v1 = (t3.EventSpeed + 0.2) * 0.8
		end

		for j = 1, v2 do
			if not (Character and Character:GetAttribute("UsingAbility")) then break end
			t3.CreateEvent(p3, v1)
			task.wait(v1)
		end

		t3._initialised = false
	end

	BugleEvent = t3
end

-- ============================================================================
-- PIETRAJECTORY (stub - not provided)
-- ============================================================================
local PieTrajectory = { Init = function() end }

-- ============================================================================
-- ABILITY MODULE
-- ============================================================================
local t = {}
local v2 = false

local function ColorAbility(p3, p4)
	for _, v in pairs(p3:GetDescendants()) do
		if v:IsA("TextLabel") and not v:GetAttribute("Hastened") then
			v.TextColor3 = p4
		end
	end
	if p3:GetAttribute("KillerAbility") then return end
	p3.Icon.ImageColor3 = p4
end

function t.DisplayKeybind(p3, p4)
	if p4:FindFirstChild("Input") then
		p4.Input.Text = Variables.GetKeybindStringAbility(p3)
		p4:SetAttribute("Keybind", p3.Name)
	end
end

function t.UpdateAbilityKeybind(p3, p4, p5, p6)
	if not p4 then return end
	local v1 = if p5 then p5 - 1 else #RoundUI.PlayerUI.Abilities.Folder:GetChildren() + (p6 or 0)
	local v2 = Variables["AbilityInput" .. v1]
	p4.LayoutOrder = if p3.InputShown == "M1" and MainGui.Devices.Mobile.Visible then 100 else v1
	t.DisplayKeybind(v2, p4)
	return v2
end

function t.CreateAbility(p3, p4)
	if RoundUI.PlayerUI.Abilities.Folder:FindFirstChild(p3.Name) then return end

	if LocalPlayer.Character then
		LocalPlayer.Character:GetAttribute("RerollAbility")
	end

	local v1 = ReplicatedStorage.ClientModules.Gui.Game.Ability.AbilityTemplate:Clone()
	local v2 = nil
	local count = 0

	if LocalPlayer.Character and LocalPlayer.Character:IsDescendantOf(Teams.Survivor) then
		count = count + 1
	else
		v1:SetAttribute("KillerAbility", true)
	end

	local v3 = #RoundUI.PlayerUI.Abilities.Folder:GetChildren() + count

	for i = 1, 6 do
		local v4 = LocalPlayer.Stats.Settings[("Ability%*Keybind"):format(i)]:GetAttribute("Keybind")
		if pcall(function() return Enum.KeyCode[v4] end) and Enum.KeyCode[v4].Name ~= "Unknown" then
			Variables["AbilityInput" .. i] = Enum.KeyCode[v4]
		else
			Variables["AbilityInput" .. i] = Enum.UserInputType[v4]
		end
	end

	if p4 then
		v2 = t.UpdateAbilityKeybind(p3, v1, nil, count)
	elseif p3.InputShown == "Q" then
		v2 = Variables["AbilityInput" .. count + 2]
		v3 = 2
	elseif p3.InputShown == "E" then
		v2 = Variables["AbilityInput" .. count + 3]
		v3 = 3
	elseif p3.InputShown == "R" then
		v2 = Variables["AbilityInput" .. count + 4]
		v3 = 4
	elseif p3.InputShown == "T" then
		v2 = Variables["AbilityInput" .. count + 5]
		v3 = 5
	elseif p3.InputShown == "Y" then
		v2 = Variables["AbilityInput" .. count + 6]
		v3 = 6
	elseif p3.InputShown == "M1" then
		v2 = Variables["AbilityInput" .. count + 1]
		v3 = 1
	end

	if p3.InputShown == "M1" and MainGui.Devices.Mobile.Visible then
		v3 = 10000
	end

	if not p4 then
		t.DisplayKeybind(v2, v1)
		v1.LayoutOrder = v3
	end

	v1.Parent = PlayerUI.Abilities.Folder
	v1.Name = p3.Name
	v1.Input.Text = Variables.GetKeybindStringAbility(v2)
	v1.Title.Text = p3.DisplayName
	v1.Cooldown.Visible = false
	v1.CooldownLabel.Visible = false
	v1.Gimmicks.Limit.Visible = false
	v1:SetAttribute("Category", p3.Category)

	local Input = v1.Input
	Input.TextTransparency = Input.TextTransparency + 1

	local Input2 = v1.Input
	Input2.TextStrokeTransparency = Input2.TextStrokeTransparency + 1

	task.delay(1, function()
		if v1 and (v1.Parent and v1:FindFirstChild("Input")) then
			local I = v1.Input
			I.TextTransparency = I.TextTransparency - 1
			local I2 = v1.Input
			I2.TextStrokeTransparency = I2.TextStrokeTransparency - 1
		end
	end)

	if p3.Icon then
		v1.Icon.Image = p3.Icon
	end

	if p3.ColorScheme then
		ColorAbility(v1, p3.ColorScheme)
	end

	local v5 = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Synergy")

	task.spawn(function()
		local Character = LocalPlayer.Character
		while v1 and (v1.Parent and Character) do
			v5 = Character:GetAttribute("Synergy")
			local v12 = Character:GetAttribute(v1.Name .. "Cooldown") or 0

			if v12 > 0 then
				t.PutOnCooldown(v1, v12, p3)
			end

			if p3.Synergies and p3.Synergies[v5] then
				ColorAbility(v1, p3.Synergies[v5].Color)
				v1:SetAttribute("Tip", Variables.AbilityTip(p3, v5))
				v1:SetAttribute("IsSynergy", true)
			else
				if v1:GetAttribute("IsSynergy") then
					v1:SetAttribute("Tip", Variables.AbilityTip(p3, v5))
				end
				v1:SetAttribute("IsSynergy", false)
			end

			task.wait(0.125)
		end
	end)

	v1:SetAttribute("Tip", Variables.AbilityTip(p3, v5))

	local t2 = {}

	table.insert(t2, v1.MouseEnter:Connect(function()
		RoundUI.PlayerUI.Abilities.Tip.Label.Text = v1:GetAttribute("Tip")
		RoundUI.PlayerUI.Abilities.Tip.Visible = true
		for _, v in Teams.Killer:GetChildren() do
			if (v:GetAttribute("KillerName") or "Pursuer") == "Harken" then
				break
			end
		end
	end))

	table.insert(t2, v1.MouseLeave:Connect(function()
		RoundUI.PlayerUI.Abilities.Tip.Visible = false
	end))

	table.insert(t2, v1.Activated:Connect(function()
		t.UseAbility(p3, v1)
	end))

	table.insert(t2, v1.Destroying:Connect(function()
		for _, v in pairs(t2) do
			v:Disconnect()
		end
	end))

	for _, v in pairs(v1.Gimmicks:GetChildren()) do
		v.Visible = false
	end

	PlayerUI.Abilities.Tip.Visible = false

	if not PlayerUI.Abilities.Folder:FindFirstChildWhichIsA("ImageButton") then
		PlayerUI.Other.SideBars.FlashlightPower.Visible = false
	end

	local Character = LocalPlayer.Character

	task.delay(0.1, function()
		if not table.find({
			"FirewallBypass", "Revolver", "Implement", "Copywrite", "Repurpose",
			"Deploy", "Swing", "Cleave", "Howl", "HarkenSwitch", "Repress",
			"Agitation", "Bugle"
		}, v1.Name) then
			return
		end

		while v1 and (v1.Parent and (Character and Character.Parent)) do
			if v1.Name == "FirewallBypass" then
				local count2 = 0
				for _, v in pairs(Teams.Other:GetChildren()) do
					if v.Name == "Computer" then
						count2 = count2 + 1
						if not v:GetAttribute("Checked") then
							if not LocalPlayer.PlayerGui:FindFirstChild("RiftFolder") then
								Instance.new("Folder", LocalPlayer.PlayerGui).Name = "RiftFolder"
							end
							v:SetAttribute("Checked", true)
							local v12 = ReplicatedStorage.ClientModules.Gui.Game.Ability.Require.BadwareRift.PCUI.PCUI:Clone()
							v12.Parent = LocalPlayer.PlayerGui.RiftFolder
							v12.Adornee = v.PrimaryPart
						end
					end
				end
				if LocalPlayer.PlayerGui:FindFirstChild("RiftFolder") then
					for _, v in pairs(LocalPlayer.PlayerGui.RiftFolder:GetChildren()) do
						if v:IsA("BillboardGui") and (v.Adornee and v.Adornee.Parent) then
							if v:FindFirstChild("Holder") then
								local v22 = v.Adornee.Parent
								v.Holder.Label.Text = (v22:GetAttribute("Percentage") or 100) .. "%"
								v.Enabled = if LocalPlayer:DistanceFromCharacter(v22.PrimaryPart.Position) >= 35 then not LocalPlayer.PlayerGui.RiftFolder:FindFirstChild("RiftSelect") else false
							end
							continue
						end
						v:Destroy()
					end
				end
				v1.Gimmicks.Limit.Label.Text = ("%*/4"):format(count2)
				v1.Gimmicks.Limit.Visible = true
			elseif v1.Name == "Revolver" then
				if (Character:GetAttribute("RevolverAmmo") or 1) >= 1 then
					v1.Icon.Image = p3.Icon
					v1.Title.Text = p3.DisplayName
				else
					v1.Icon.Image = p3.ReloadIcon
					v1.Title.Text = "Reload"
				end
			elseif v1.Name == "Implement" then
				if not (Character and Character.Parent) then break end
				local count2 = 0
				for _, v in pairs(Teams.Other:GetChildren()) do
					if v.Name == "Wall" then count2 = count2 + 1 end
				end
				v1.Gimmicks.Limit.Label.Text = ("%*/5"):format(count2)
				v1.Gimmicks.Limit.Visible = true
			elseif v1.Name == "Copywrite" then
				if not (Character and Character.Parent) then break end
				local count2 = 0
				for _, v in pairs(Teams.Other:GetChildren()) do
					if v.Name == "MusicBox" then count2 = count2 + 1 end
				end
				v1.Gimmicks.Limit.Label.Text = ("%*/2"):format(count2)
				v1.Gimmicks.Limit.Visible = true
			elseif v1.Name == "Repurpose" then
				local v4 = LocalPlayer.Character:GetAttribute("StoredItem")
				if v4 and v4 == "Wall" then
					v1.Gimmicks.Repurpose.Visible = true
					v1.Gimmicks.Repurpose.Image = "rbxassetid://18895735642"
					v1.Title.Text = "(Wall)"
				elseif v4 and v4 == "MusicBox" then
					v1.Gimmicks.Repurpose.Visible = true
					v1.Gimmicks.Repurpose.Image = "rbxassetid://84526769532677"
					v1.Title.Text = "(Music Box)"
				elseif v4 and v4 == "Survivor" then
					v1.Gimmicks.Repurpose.Visible = true
					v1.Gimmicks.Repurpose.Image = "rbxassetid://10771373165"
					v1.Title.Text = "(Puppet)"
				else
					v1.Gimmicks.Repurpose.Visible = false
					v1.Title.Text = "Repurpose"
				end
			elseif v1.Name == "Deploy" then
				local count2 = 0
				for _, v in pairs(Teams.Other:GetChildren()) do
					if v.Name == "Killbot" then count2 = count2 + 1 end
				end
				v1.Gimmicks.Limit.Label.Text = ("%*/4"):format(count2)
				v1.Gimmicks.Limit.Visible = true
			elseif (v1.Name == "Swing" or p3.StalkVariant) and Character:GetAttribute("KillerName") == "Pursuer" then
				local v5 = Character:GetAttribute("OnStalk")
				if v1:FindFirstChild("Locked") and v1.Name == "Swing" then
					v1:SetAttribute("IsLocked", v5)
				end
				if p3.StalkVariant then
					v1:SetAttribute("Tip", v5 and Variables.AbilityTip(nil, nil, p3.StalkVariantTip) or Variables.AbilityTip(p3))
					v1.Icon.Image = v5 and p3.StalkVariant or p3.Icon
					v1.Title.Text = v5 and p3.StalkVariantName or p3.DisplayName
				end
			elseif (v1.Name == "HarkenSwitch" or p3.EnrageIcon) and Character:GetAttribute("KillerName") == "Harken" then
				if p3.EnrageIcon then
					v1.Icon.Image = Character:GetAttribute("Enraged") and p3.EnrageIcon or p3.Icon
					v1.Title.Text = Character:GetAttribute("Enraged") and p3.EnrageDisplayName or p3.DisplayName
					v1:SetAttribute("Tip", Character:GetAttribute("Enraged") and Variables.AbilityTip(nil, nil, p3.EnrageTip) or Variables.AbilityTip(p3))
					ColorAbility(v1, (Character:GetAttribute("Enraged") or v1.Title.Text == "ENRAGE") and Color3.fromRGB(255, 23, 23) or p3.ColorScheme)
				else
					ColorAbility(v1, p3.ColorScheme)
				end
			end

			task.wait(0.7)
		end
	end)

	if p4 then
		table.insert(t2, PlayerUI.Abilities.Folder.ChildRemoved:Connect(function(p12)
			task.wait(math.random(-1000, 1000) / 10000)
			if p12 == v1 or not (p12.LayoutOrder < v1.LayoutOrder) then return end
			t.UpdateAbilityKeybind(p3, v1, v1.LayoutOrder, count)
		end))
	else
		return
	end
end

function t.RemoveAbility(p3)
	if not (p3 and RoundUI.PlayerUI.Abilities.Folder:FindFirstChild(p3)) then return end
	RoundUI.PlayerUI.Abilities.Folder[p3].Visible = false
	Debris:AddItem(RoundUI.PlayerUI.Abilities.Folder[p3], 0.5)
end

Events.RemoteEvents.RemoveAbility.OnClientEvent:Connect(t.RemoveAbility)

function t.AbilityTween(p3)
	TweenService:Create(p3, TweenInfo.new(0.2), {
		Size = UDim2.new(0.9, 0, 0.9, 0)
	}):Play()

	if p3:FindFirstChild("UseEffect") then
		p3.UseEffect.Visible = true
		p3.UseEffect.BackgroundTransparency = 0.5
		TweenService:Create(p3.UseEffect, TweenInfo.new(0.4), {
			BackgroundTransparency = 1
		}):Play()
	end

	task.wait(0.2)
	TweenService:Create(p3, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
		Size = UDim2.new(1, 0, 1, 0)
	}):Play()
end

function t.PutOnCooldown(p3, p4, p5)
	local Character = LocalPlayer.Character
	if not (p3 and p3.Parent) then return end
	if p3.Cooldown.Visible then return end

	local v1 = nil
	p3.Input.Visible = false
	p3.InputImage.Visible = false
	p3.Cooldown.Visible = true
	p3.CooldownLabel.Visible = true
	p3.Icon.ImageTransparency = 0.7

	local v2 = LocalPlayer.Character:GetAttribute(p3.Name .. "Cooldown") or 0

	p3.Cooldown.Size = UDim2.new(1, 0, 1, 0)
	p3.CooldownLabel.Text = ""

	task.spawn(function()
		pcall(t.AbilityTween, p3)
	end)

	local v3 = nil
	v3 = Character:GetAttributeChangedSignal(p3.Name .. "Cooldown"):Connect(function()
		if not (p3 and p3.Parent) then return end
		if not (Character and Character.Parent) then return end

		v2 = LocalPlayer.Character:GetAttribute(p3.Name .. "Cooldown") or 0

		if v2 > 10 then
			v2 = math.round(v2)
		end

		if (LocalPlayer.Character:GetAttribute("Hastened") or 0) > 1 and not p5.UnnafectedByHastened then
			p3.CooldownLabel.TextColor3 = Color3.fromRGB(255, 236, 90)
			p3.CooldownLabel:SetAttribute("Hastened", true)
			v1 = true
		elseif (LocalPlayer.Character:GetAttribute("Stagnated") or 0) > 0 then
			p3.CooldownLabel.TextColor3 = Color3.fromRGB(160, 201, 255)
			p3.CooldownLabel:SetAttribute("Hastened", true)
			v1 = true
		else
			p3.CooldownLabel:SetAttribute("Hastened", false)
			if v1 then
				p3.CooldownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end

		p3.Cooldown.Size = UDim2.new(1, 0, v2 / p4, 0)
		p3.CooldownLabel.Text = v2 .. "s"

		if p5.DisplayName then
			if Character:GetAttribute("Recast" .. p5.Name) then
				if p5.RecastIcon then p3.Icon.Image = p5.RecastIcon end
				p3.Title.Text = p5.RecastDisplayName
			elseif p5.RecastDisplayName then
				if p5.RecastIcon then p3.Icon.Image = p5.Icon end
				p3.Title.Text = p5.DisplayName
			end
		end

		if v2 and v2 ~= 0 then return end
		v3:Disconnect()

		if p3 and p3.Parent then
			p3.CooldownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
		if not (p3 and p3.Parent) then return end

		task.spawn(function()
			pcall(t.AbilityTween, p3)
		end)
		p3.Input.Visible = true
		p3.InputImage.Visible = true
		p3.Cooldown.Visible = false
		p3.CooldownLabel.Visible = false
		p3.Icon.ImageTransparency = 0
	end)
end

function t.UseAbility(p3, p4)
	if not LocalPlayer.Character then return end
	if v2 then return end

	MainGui.EmoteSelection.Visible = false
	v2 = true
	delay(0.05, function()
		v2 = false
	end)

	if p4.Cooldown.Visible then return end
	Events.RemoteFunctions.UseAbility:InvokeServer(p3.Name)
end

function t.CheckForKeybind(p3)
	local v1 = nil
	for _, v in pairs(RoundUI.PlayerUI.Abilities.Folder:GetChildren()) do
		if v:IsA("ImageButton") and v:GetAttribute("Keybind") == tostring(p3) then
			v1 = v
		end
	end

	if not v1 then return end

	local v2 = nil
	for _, v in pairs(ClientModules.Characters:GetChildren()) do
		local v3 = require(v)
		if v3.Abilities and v3.Abilities[v1.Name] then
			v2 = v3
			break
		end
		v2 = v3
	end

	if not v2 then return "Fail" end
	t.UseAbility(v2.Abilities[v1.Name], v1)
end

-- Event: Dazed
Events.RemoteEvents.Dazed.OnClientEvent:Connect(function()
	for _, v in pairs(RoundUI.PlayerUI.Abilities.Folder:GetChildren()) do
		if not v:IsA("UIComponent") and (v:GetAttribute("Category") == "Sentinel" and not v:GetAttribute("DoingDazeTween")) then
			task.spawn(function()
				v:SetAttribute("DoingDazeTween", true)
				local ImageColor3 = v.Icon.ImageColor3
				for i = 1, 6 do
					v.Icon.ImageColor3 = Color3.fromRGB(255, 210, 47)
					task.wait(0.4)
					TweenService:Create(v.Icon, TweenInfo.new(0.25), { ImageColor3 = ImageColor3 }):Play()
					task.wait(0.6)
				end
				v:SetAttribute("DoingDazeTween", false)
			end)
		end
	end
end)

-- Remote functions
function Events.RemoteFunctions.CameraDirection.OnClientInvoke()
	return workspace.CurrentCamera.CFrame.LookVector
end

function Events.RemoteFunctions.MouseDirection.OnClientInvoke()
	if Variables.PreferredInput == Enum.PreferredInput.KeyboardAndMouse then
		return (v1.Hit.Position - workspace.CurrentCamera.CFrame.Position).Unit
	end
	return workspace.CurrentCamera.CFrame.LookVector
end

Events.RemoteEvents.CoolMessage.OnClientEvent:Connect(function(p3)
	RoundUI.Message.Visible = true
	RoundUI.Message.Text = p3
	task.wait(3)
	RoundUI.Message.Visible = false
end)

function Events.RemoteFunctions.MousePos.OnClientInvoke()
	return v1.Hit.Position
end

-- Bugle event
Events.RemoteEvents.Abilities.Bugle.OnClientEvent:Connect(function()
	RoundUI.Civilian.Bugle.Visible = true
	RoundUI.PlayerUI.Abilities.Visible = false
	local v1 = Variables
	v1.FOVModifier = v1.FOVModifier - 15
	BugleEvent.Init(RoundUI.Civilian.Bugle.Minigame)
	RoundUI.Civilian.Bugle.Visible = false
	RoundUI.PlayerUI.Abilities.Visible = true
	local v2 = Variables
	v2.FOVModifier = v2.FOVModifier + 15
end)

-- Pie event
Events.RemoteEvents.Abilities.Pie.OnClientEvent:Connect(function()
	RoundUI.Civilian.Pie.Visible = true
	RoundUI.PlayerUI.Abilities.Visible = false
	local v1 = Variables
	v1.FOVModifier = v1.FOVModifier - 15
	PieTrajectory.Init(RoundUI.Civilian.Pie.Meter)
	RoundUI.Civilian.Pie.Visible = false
	RoundUI.PlayerUI.Abilities.Visible = true
	local v2 = Variables
	v2.FOVModifier = v2.FOVModifier + 15
end)

-- CreateAbility from server
Events.RemoteEvents.CreateAbility.OnClientEvent:Connect(function(p3, p4)
	t.CreateAbility(p3, p4)
end)

-- GetDevice
function Events.RemoteFunctions.GetDevice.OnClientInvoke()
	if Variables.PreferredInput == Enum.PreferredInput.Touch then return "Mobile" end
	if Variables.PreferredInput == Enum.PreferredInput.Gamepad then return "Console" end
	return "PC"
end

-- Keybind input handler
UserInputService.InputBegan:Connect(function(p3, p4)
	if p4 then return end
	Variables.PreferredInput = UserInputService.PreferredInput

	local KeyCode = p3.KeyCode
	local UserInputType = p3.UserInputType

	if KeyCode == Variables.AbilityInput1 or UserInputType == Variables.AbilityInput1 then
		t.CheckForKeybind(Variables.AbilityInput1.Name)
		return
	end
	if KeyCode == Variables.AbilityInput2 or UserInputType == Variables.AbilityInput2 then
		t.CheckForKeybind(Variables.AbilityInput2.Name)
		return
	end
	if KeyCode == Variables.AbilityInput3 or UserInputType == Variables.AbilityInput3 then
		t.CheckForKeybind(Variables.AbilityInput3.Name)
		return
	end
	if KeyCode == Variables.AbilityInput4 or UserInputType == Variables.AbilityInput4 then
		t.CheckForKeybind(Variables.AbilityInput4.Name)
		return
	end
	if KeyCode == Variables.AbilityInput5 or UserInputType == Variables.AbilityInput5 then
		t.CheckForKeybind(Variables.AbilityInput5.Name)
		return
	end
	if KeyCode ~= Variables.AbilityInput6 and UserInputType ~= Variables.AbilityInput6 then return end
	t.CheckForKeybind(Variables.AbilityInput6.Name)
end)

-- ============================================================================
-- ABILITY LOOKUP
-- ============================================================================
local function findAbility(name)
	if not name or name == "" then return nil end

	local charactersFolder = ClientModules:FindFirstChild("Characters")
	if not charactersFolder then return nil end

	for _, moduleScript in pairs(charactersFolder:GetChildren()) do
		local ok, mod = pcall(require, moduleScript)
		if ok and mod and mod.Abilities then
			for abilityName, abilityData in pairs(mod.Abilities) do
				if abilityName == name then
					return abilityData
				end
				if abilityData.DisplayName and abilityData.DisplayName == name then
					return abilityData
				end
			end
		end
	end

	return nil
end

-- ============================================================================
-- UI CREATION (inside existing MainGui, draggable)
-- ============================================================================
local frame = Instance.new("Frame")
frame.Name = "AbilityCreator"
frame.Size = UDim2.new(0, 260, 0, 120)
frame.Position = UDim2.new(0, 10, 0.5, -60)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = MainGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(50, 200, 50)
frameStroke.Thickness = 1.5
frameStroke.Parent = frame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -40, 0, 24)
titleLabel.Position = UDim2.new(0, 8, 0, 6)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Ability Creator"
titleLabel.TextColor3 = Color3.fromRGB(50, 200, 50)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -26, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

local inputBox = Instance.new("TextBox")
inputBox.Name = "AbilityInput"
inputBox.Size = UDim2.new(1, -16, 0, 30)
inputBox.Position = UDim2.new(0, 8, 0, 34)
inputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
inputBox.BorderSizePixel = 0
inputBox.Text = ""
inputBox.PlaceholderText = "Ability name (e.g. Swing)"
inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
inputBox.TextSize = 13
inputBox.Font = Enum.Font.Gotham
inputBox.ClearTextOnFocus = false
inputBox.Parent = frame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = inputBox

local createBtn = Instance.new("TextButton")
createBtn.Name = "CreateBtn"
createBtn.Size = UDim2.new(1, -16, 0, 30)
createBtn.Position = UDim2.new(0, 8, 0, 70)
createBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
createBtn.BorderSizePixel = 0
createBtn.Text = "Create Ability"
createBtn.TextColor3 = Color3.fromRGB(200, 255, 200)
createBtn.TextSize = 13
createBtn.Font = Enum.Font.GothamBold
createBtn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = createBtn

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, -16, 0, 14)
statusLabel.Position = UDim2.new(0, 8, 0, 104)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- ============================================================================
-- DRAGGING (drag via title bar)
-- ============================================================================
do
	local dragging = false
	local dragStart = nil
	local startPos = nil

	titleLabel.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)

	titleLabel.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- ============================================================================
-- CLOSE BUTTON
-- ============================================================================
closeBtn.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

-- ============================================================================
-- BUTTON HANDLER
-- ============================================================================
createBtn.MouseButton1Click:Connect(function()
	local abilityName = inputBox.Text
	if not abilityName or abilityName == "" then
		statusLabel.Text = "Type an ability name first."
		statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end

	local abilityData = findAbility(abilityName)

	if not abilityData then
		statusLabel.Text = "Ability '" .. abilityName .. "' not found."
		statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end

	local ok, err = pcall(function()
		t.CreateAbility(abilityData, false)
	end)

	if ok then
		statusLabel.Text = "Created: " .. (abilityData.DisplayName or abilityData.Name)
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		statusLabel.Text = "Error: " .. tostring(err)
		statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
end)
