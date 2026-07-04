-- AdminPanel - Self-contained LocalScript
-- Everything is created and managed from this single script

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local J = Enum.KeyCode.J
local fromRGB = Color3.fromRGB
local insert = table.insert

-- ============================================================================
-- SIGNAL IMPLEMENTATION
-- ============================================================================
local _signal_free_thread = nil

local function acquireRunnerThreadAndCallEventHandler(handler, ...)
	local prev = _signal_free_thread
	_signal_free_thread = nil
	handler(...)
	_signal_free_thread = prev
end

local function runEventHandlerInFreeThread(...)
	acquireRunnerThreadAndCallEventHandler(...)
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

local ConnectionMT = {}
ConnectionMT.__index = ConnectionMT

function ConnectionMT:Disconnect()
	if not self.Connected then return end
	self.Connected = false
	if self._signal._handlerListHead == self then
		self._signal._handlerListHead = self._next
		return
	end
	local prev = self._signal._handlerListHead
	while prev and prev._next ~= self do
		prev = prev._next
	end
	if not prev then return end
	prev._next = self._next
end

ConnectionMT.Destroy = ConnectionMT.Disconnect

setmetatable(ConnectionMT, {
	__index = function(_, key)
		error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(_, key, _)
		error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end
})

local SignalMT = {}
SignalMT.__index = SignalMT

function SignalMT.new()
	return setmetatable({
		_handlerListHead = false,
		_proxyHandler = nil,
		_yieldedThreads = nil
	}, SignalMT)
end

function SignalMT:Wrap(signal)
	assert(typeof(signal) == "RBXScriptSignal", "Argument #1 to Signal.Wrap must be a RBXScriptSignal; got " .. typeof(signal))
	local sig = SignalMT.new()
	sig._proxyHandler = signal:Connect(function(...)
		sig:Fire(...)
	end)
	return sig
end

function SignalMT:Is(obj)
	return type(obj) == "table" and getmetatable(obj) == SignalMT
end

function SignalMT:Connect(fn)
	local conn = setmetatable({
		Connected = true,
		_next = false,
		_signal = self,
		_fn = fn
	}, ConnectionMT)
	if self._handlerListHead then
		conn._next = self._handlerListHead
	end
	self._handlerListHead = conn
	return conn
end

function SignalMT:ConnectOnce(fn)
	return self:Once(fn)
end

function SignalMT:Once(fn)
	local fired = false
	local conn = nil
	conn = self:Connect(function(...)
		if not fired then
			fired = true
			conn:Disconnect()
			fn(...)
		end
	end)
	return conn
end

function SignalMT:GetConnections()
	local result = {}
	local node = self._handlerListHead
	while node do
		insert(result, node)
		node = node._next
	end
	return result
end

function SignalMT:DisconnectAll()
	local node = self._handlerListHead
	while node do
		node.Connected = false
		node = node._next
	end
	self._handlerListHead = false
	local yielded = rawget(self, "_yieldedThreads")
	if not yielded then return end
	for thread in yielded do
		if coroutine.status(thread) == "suspended" then
			print(debug.traceback(thread, "signal disconnected; yielded thread cancelled", 2))
			task.cancel(thread)
		end
	end
	table.clear(yielded)
end

function SignalMT:Fire(...)
	local node = self._handlerListHead
	while node do
		if node.Connected then
			if not _signal_free_thread then
				_signal_free_thread = coroutine.create(runEventHandlerInFreeThread)
			end
			task.spawn(_signal_free_thread, node._fn, ...)
		end
		node = node._next
	end
end

function SignalMT:FireDeferred(...)
	local node = self._handlerListHead
	while node do
		local conn = node
		task.defer(function(...)
			if not conn.Connected then return end
			conn._fn(...)
		end, ...)
		node = node._next
	end
end

function SignalMT:Wait()
	local yielded = rawget(self, "_yieldedThreads")
	if not yielded then
		yielded = {}
		rawset(self, "_yieldedThreads", yielded)
	end
	local thread = coroutine.running()
	yielded[thread] = true
	self:Once(function(...)
		yielded[thread] = nil
		if coroutine.status(thread) ~= "suspended" then return end
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function SignalMT:Destroy()
	self:DisconnectAll()
	local proxy = rawget(self, "_proxyHandler")
	if proxy then
		proxy:Disconnect()
	end
end

setmetatable(SignalMT, {
	__index = function(_, key)
		error(("Attempt to get Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(_, key, _)
		error(("Attempt to set Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end
})

local Signal = table.freeze({
	new = SignalMT.new,
	Wrap = SignalMT.Wrap,
	Is = SignalMT.Is
})

-- ============================================================================
-- DROPDOWN MODULE
-- ============================================================================
local DropdownModule = {}
DropdownModule.__index = DropdownModule

local _dropdown_tween_info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local function dropdownCreateInstances(ctx)
	ctx.CurrentPlayer = nil
	local instance = ctx.Instance

	local function firePlayerSelected(player)
		instance.Text = player and player.Name or "Select Player"
		ctx.CurrentPlayer = player
		ctx.onArgumentChange:Fire(ctx.CurrentPlayer)
	end

	local function createPlayerCard(player)
		if not instance:FindFirstChild("Dropdown") then return end
		if not instance.Dropdown:FindFirstChild(player.Name) then
			local card = createDROPDOWN_USER_PRESET()
			card.Name = player.Name
			card.UserName.Text = player.Name
			local success, thumb = pcall(function()
				return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)
			end)
			if success then
				card.UserIcon.Image = thumb
			end
			card.MouseButton1Down:Connect(function()
				local selected = player
				instance.Text = selected and selected.Name or "Select Player"
				ctx.CurrentPlayer = selected
				ctx.onArgumentChange:Fire(ctx.CurrentPlayer)
				ctx.ToggleVisibility()
			end)
			card.Visible = true
			card.Parent = instance.Dropdown
		end
	end

	Players.PlayerAdded:Connect(createPlayerCard)
	for _, player in Players:GetPlayers() do
		if player then
			createPlayerCard(player)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		if not instance:FindFirstChild("Dropdown") then return end
		local card = instance.Dropdown:FindFirstChild(player.Name)
		if card then
			card:Destroy()
			instance.Text = "Select Player"
			ctx.CurrentPlayer = nil
			ctx.onArgumentChange:Fire(ctx.CurrentPlayer)
		end
	end)
end

function DropdownModule.CreateInstance(params)
	local ctx = setmetatable({
		onArgumentChange = Signal.new()
	}, DropdownModule)
	local visible = false
	local dropdownBtn = createDropdownInstance()
	dropdownBtn.Text = params.PlaceholderText
	ctx.Instance = dropdownBtn

	local function toggleVisibility()
		visible = not visible
		local props = {}
		props.Rotation = if visible then 90 else 0
		TweenService:Create(dropdownBtn.isOpened, _dropdown_tween_info, props):Play()
		dropdownBtn.Dropdown.Visible = not dropdownBtn.Dropdown.Visible
	end

	ctx.ToggleVisibility = toggleVisibility

	local function adjustCanvasSize()
		if not dropdownBtn:FindFirstChild("Dropdown") then return end
		local count = math.max(#dropdownBtn.Dropdown:GetChildren() - 4, 0)
		local sample = dropdownBtn.Dropdown:FindFirstChildOfClass("ImageButton")
		local itemHeight = if sample then sample.AbsoluteSize.Y or 0 else 0
		dropdownBtn.Dropdown.CanvasSize = UDim2.new(1, 0, 0, count * (itemHeight + dropdownBtn.Dropdown.ScrollBarThickness * 0.75))
	end

	dropdownBtn.MouseButton1Down:Connect(toggleVisibility)
	dropdownBtn.Dropdown.ChildAdded:Connect(adjustCanvasSize)
	dropdownBtn.Dropdown:GetPropertyChangedSignal("AbsoluteSize"):Connect(adjustCanvasSize)
	dropdownBtn.Dropdown.ChildRemoved:Connect(adjustCanvasSize)

	pcall(params and params.Callback or dropdownCreateInstances, ctx)
	adjustCanvasSize()

	return { dropdownBtn, ctx }
end

-- ============================================================================
-- INPUT STRING MODULE
-- ============================================================================
local InputStringModule = {}
InputStringModule.__index = InputStringModule

function InputStringModule.CreateInstance(params)
	local ctx = setmetatable({
		onArgumentChange = Signal.new()
	}, InputStringModule)
	local inputBox = createINPUT_PRESET()
	inputBox.Name = "NewInputString"
	inputBox.PlaceholderText = if params then params.PlaceholderText or "Insert Text Here" else "Insert Text Here"
	inputBox.FocusLost:Connect(function()
		ctx.onArgumentChange:Fire(inputBox.Text)
	end)
	return { inputBox, ctx }
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================
local _config_cache = {}

local Configuration = {
	Ban = {
		LayoutOrder = 1,
		RequiredKey = 2.5,
		Page = {
			{
				Name = "Username",
				Type = "InputString",
				Parameters = {
					PlaceholderText = "Input UserID or Username here"
				}
			},
			{
				Name = "Player",
				Type = "Dropdown",
				Parameters = {
					PlaceholderText = "Select Player"
				}
			},
			{
				Name = "Time",
				Type = "Dropdown",
				Parameters = {
					PlaceholderText = "Select Time",
					Callback = function(ctx)
						local instance = ctx.Instance
						local timeValues = {
							["1 Day"] = 86400,
							["3 Days"] = 259200,
							["1 Week"] = 604800,
							["2 Weeks"] = 1209600,
							["1 Month"] = 2678400,
							["3 Months"] = 8035200,
							PERMANENT = 2153433600
						}
						local timeOrder = {
							["1 Day"] = 1,
							["3 Days"] = 2,
							["1 Week"] = 3,
							["2 Weeks"] = 4,
							["1 Month"] = 5,
							["3 Months"] = 6,
							PERMANENT = 7
						}

						local function fireTimeSelected(label)
							instance.Text = label or "Select Time"
							ctx.CurrentTime = timeValues[label]
							ctx.onArgumentChange:Fire(ctx.CurrentTime)
						end

						local function createTimeCard(label)
							if not instance:FindFirstChild("Dropdown") then return end
							if not instance.Dropdown:FindFirstChild(label) then
								local card = createDROPDOWN_PRESET()
								card.Name = label
								card.Display.Text = label
								card.LayoutOrder = timeOrder[label]
								card.MouseButton1Down:Connect(function()
									local selected = label
									instance.Text = selected or "Select Time"
									ctx.CurrentTime = timeValues[selected]
									ctx.onArgumentChange:Fire(ctx.CurrentTime)
									ctx.ToggleVisibility()
								end)
								card.Visible = true
								card.Parent = instance.Dropdown
							end
						end

						for label in timeValues do
							createTimeCard(label)
						end
					end
				}
			},
			{
				Name = "Public Reason",
				Type = "InputString",
				Parameters = {
					PlaceholderText = "Public reason for the ban."
				}
			},
			{
				Name = "Private Reason",
				Type = "InputString",
				Parameters = {
					PlaceholderText = "Private reason for the ban."
				}
			}
		}
	},
	Unban = {
		LayoutOrder = 2,
		RequiredKey = 2.5,
		Page = {
			{
				Name = "Username",
				Type = "InputString",
				Parameters = {
					PlaceholderText = "Input UserID or Username here"
				}
			}
		}
	},
	Kick = {
		LayoutOrder = 3,
		Page = {
			{
				Name = "Player",
				Type = "Dropdown",
				Parameters = {
					PlaceholderText = "Select Player"
				}
			},
			{
				Name = "Reason",
				Type = "InputString",
				Parameters = {
					PlaceholderText = "Input reason here."
				}
			}
		}
	},
	Announcement = {
		LayoutOrder = 4,
		RequiredKey = 5,
		Page = {
			{
				Name = "Message",
				Type = "InputString",
				Parameters = {
					PlaceholderText = "Input message here."
				}
			},
			{
				Name = "Duration",
				Type = "InputString",
				Parameters = {
					PlaceholderText = "The duration of the message. (default is 10 seconds)"
				}
			}
		}
	},
	Gamemode = {
		LayoutOrder = 5,
		RequiredKey = 2,
		Page = {
			{
				Name = "Gamemode",
				Type = "Dropdown",
				Parameters = {
					PlaceholderText = "Select Gamemode",
					Callback = function(ctx)
						local instance = ctx.Instance
						local gamemodeList = _config_cache.GamemodeList or ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("RemoteFunctions") and ReplicatedStorage.Events.RemoteFunctions:FindFirstChild("GetGamemodeInfo") and ReplicatedStorage.Events.RemoteFunctions.GetGamemodeInfo:InvokeServer()

						if gamemodeList and not _config_cache.GamemodeList then
							_config_cache.GamemodeList = gamemodeList
						end

						local function fireGamemodeSelected(name)
							instance.Text = name or "Select Gamemode"
							ctx.CurrentTime = name
							ctx.onArgumentChange:Fire(ctx.CurrentTime)
						end

						local function createGamemodeCard(index, name)
							if not instance:FindFirstChild("Dropdown") then return end
							if not instance.Dropdown:FindFirstChild(name) then
								local card = createDROPDOWN_PRESET()
								card.Name = name
								card.Display.Text = name
								card.LayoutOrder = index
								card.MouseButton1Down:Connect(function()
									local selected = name
									instance.Text = selected or "Select Gamemode"
									ctx.CurrentTime = selected
									ctx.onArgumentChange:Fire(ctx.CurrentTime)
									ctx.ToggleVisibility()
								end)
								card.Visible = true
								card.Parent = instance.Dropdown
							end
						end

						if gamemodeList then
							for index, name in gamemodeList do
								createGamemodeCard(index, name)
							end
						end
					end
				}
			}
		}
	},
	Kill = {
		LayoutOrder = 6,
		RequiredKey = 2,
		Page = {
			{
				Name = "Player",
				Type = "Dropdown",
				Parameters = {
					PlaceholderText = "Select Player"
				}
			}
		}
	},
	Maps = {
		LayoutOrder = 7,
		RequiredKey = 2,
		Page = {
			{
				Name = "Map",
				Type = "Dropdown",
				Parameters = {
					PlaceholderText = "Select Map",
					Callback = function(ctx)
						local instance = ctx.Instance
						local mapList = _config_cache.MapList or ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("RemoteFunctions") and ReplicatedStorage.Events.RemoteFunctions:FindFirstChild("GetMapInfo") and ReplicatedStorage.Events.RemoteFunctions.GetMapInfo:InvokeServer()

						if mapList and not _config_cache.MapList then
							_config_cache.MapList = mapList
						end

						local function fireMapSelected(name)
							instance.Text = name or "Select Map"
							ctx.CurrentTime = name
							ctx.onArgumentChange:Fire(ctx.CurrentTime)
						end

						local function createMapCard(index, name)
							if not instance:FindFirstChild("Dropdown") then return end
							if not instance.Dropdown:FindFirstChild(name) then
								local card = createDROPDOWN_PRESET()
								card.Name = name
								card.Display.Text = name
								card.LayoutOrder = index
								card.MouseButton1Down:Connect(function()
									local selected = name
									instance.Text = selected or "Select Map"
									ctx.CurrentTime = selected
									ctx.onArgumentChange:Fire(ctx.CurrentTime)
									ctx.ToggleVisibility()
								end)
								card.Visible = true
								card.Parent = instance.Dropdown
							end
						end

						if mapList then
							for index, name in mapList do
								createMapCard(index, name)
							end
						end
					end
				}
			}
		}
	},
	Timer = {
		LayoutOrder = 8,
		RequiredKey = 2,
		Page = {
			{
				Name = "State",
				Type = "Dropdown",
				Parameters = {
					PlaceholderText = "Select State",
					Callback = function(ctx)
						local instance = ctx.Instance
						local stateValues = {
							Pause = true,
							Unpause = false
						}

						local function fireStateSelected(label)
							instance.Text = label or "Select State"
							ctx.CurrentState = stateValues[label]
							ctx.onArgumentChange:Fire(ctx.CurrentState)
						end

						local function createStateCard(label)
							if not instance:FindFirstChild("Dropdown") then return end
							if not instance.Dropdown:FindFirstChild(label) then
								local card = createDROPDOWN_PRESET()
								card.Name = label
								card.Display.Text = label
								card.LayoutOrder = 1
								card.MouseButton1Down:Connect(function()
									local selected = label
									instance.Text = selected or "Select State"
									ctx.CurrentState = stateValues[selected]
									ctx.onArgumentChange:Fire(ctx.CurrentState)
									ctx.ToggleVisibility()
								end)
								card.Visible = true
								card.Parent = instance.Dropdown
							end
						end

						for label in stateValues do
							createStateCard(label)
						end
					end
				}
			}
		}
	},
	Spawn = {
		LayoutOrder = 9,
		RequiredKey = 2,
		Page = {
			{
				Name = "Player",
				Type = "Dropdown",
				Parameters = {
					PlaceholderText = "Select Player"
				}
			},
			{
				Name = "Type",
				Type = "Dropdown",
				Parameters = {
					PlaceholderText = "Select Type",
					Callback = function(ctx)
						local instance = ctx.Instance
						local typeValues = {
							Civilian = false,
							Killer = true
						}

						local function fireTypeSelected(label)
							instance.Text = label or "Select Type"
							ctx.CurrentType = typeValues[label]
							ctx.onArgumentChange:Fire(ctx.CurrentType)
						end

						local function createTypeCard(label)
							if not instance:FindFirstChild("Dropdown") then return end
							if not instance.Dropdown:FindFirstChild(label) then
								local card = createDROPDOWN_PRESET()
								card.Name = label
								card.Display.Text = label
								card.LayoutOrder = 1
								card.MouseButton1Down:Connect(function()
									local selected = label
									instance.Text = selected or "Select Type"
									ctx.CurrentType = typeValues[selected]
									ctx.onArgumentChange:Fire(ctx.CurrentType)
									ctx.ToggleVisibility()
								end)
								card.Visible = true
								card.Parent = instance.Dropdown
							end
						end

						for label in typeValues do
							createTypeCard(label)
						end
					end
				}
			}
		}
	},
	["Force Killer"] = {
		LayoutOrder = 10,
		RequiredKey = 2,
		Page = {
			{
				Name = "Player",
				Type = "Dropdown",
				Parameters = {
					PlaceholderText = "Select Player"
				}
			}
		}
	}
}

-- ============================================================================
-- UI CREATION FUNCTIONS
-- ============================================================================

local function createUICorner()
	local c = Instance.new("UICorner")
	return c
end

local function createUIStroke()
	local s = Instance.new("UIStroke")
	s.ZIndex = 1
	s.Enabled = true
	return s
end

local function createUIGradient()
	local g = Instance.new("UIGradient")
	g.Rotation = -90
	g.Enabled = true
	return g
end

local function createUIListLayout()
	local l = Instance.new("UIListLayout")
	return l
end

local function createUIAspectRatioConstraint()
	local a = Instance.new("UIAspectRatioConstraint")
	return a
end

local function createUISizeConstraint()
	local s = Instance.new("UISizeConstraint")
	return s
end

function createTOP_BUTTON_PRESET()
	local btn = Instance.new("TextButton")
	btn.Name = "TOP_BUTTON_PRESET"
	btn.Archivable = true
	btn.Active = true
	btn.AnchorPoint = Vector2.new(0, 0)
	btn.AutomaticSize = Enum.AutomaticSize.None
	btn.BackgroundColor3 = fromRGB(57, 127, 49)
	btn.BackgroundTransparency = 0
	btn.BorderColor3 = Color3.new(0, 0, 0)
	btn.BorderMode = Enum.BorderMode.Outline
	btn.BorderSizePixel = 0
	btn.ClipsDescendants = false
	btn.LayoutOrder = 0
	btn.Position = UDim2.new(0, 0, 0, 0)
	btn.Rotation = 0
	btn.Selectable = true
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.Visible = true
	btn.ZIndex = 1
	btn.Text = "Button"
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 14
	btn.Font = Enum.Font.Arial

	local uicorner = createUICorner()
	uicorner.Parent = btn

	return btn
end

function createEXECUTE_BUTTON_PRESET()
	local btn = Instance.new("TextButton")
	btn.Name = "EXECUTE_BUTTON_PRESET"
	btn.Archivable = true
	btn.Active = true
	btn.AnchorPoint = Vector2.new(0, 0)
	btn.AutomaticSize = Enum.AutomaticSize.None
	btn.BackgroundColor3 = fromRGB(61, 113, 45)
	btn.BackgroundTransparency = 0
	btn.BorderColor3 = Color3.new(0, 0, 0)
	btn.BorderMode = Enum.BorderMode.Outline
	btn.BorderSizePixel = 0
	btn.ClipsDescendants = false
	btn.LayoutOrder = 0
	btn.Position = UDim2.new(0, 0, 0, 0)
	btn.Rotation = 0
	btn.Selectable = true
	btn.Size = UDim2.new(0.45, 0, 0.15, 0)
	btn.Visible = true
	btn.ZIndex = 1
	btn.Text = "Execute"
	btn.TextColor3 = fromRGB(89, 167, 67)
	btn.TextSize = 14
	btn.Font = Enum.Font.ArialBold

	local uicorner = createUICorner()
	uicorner.Parent = btn

	return btn
end

function createSection_PRESET()
	local frame = Instance.new("Frame")
	frame.Name = "Section_PRESET"
	frame.Archivable = true
	frame.Active = false
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.None
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 1
	frame.BorderColor3 = Color3.new(0, 0, 0)
	frame.BorderMode = Enum.BorderMode.Outline
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = false
	frame.LayoutOrder = 0
	frame.Position = UDim2.new(0, 0, 0, 0)
	frame.Rotation = 0
	frame.Selectable = false
	frame.Size = UDim2.new(1, 0, 0.33, 0)
	frame.Visible = true
	frame.ZIndex = 100

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Archivable = true
	header.Active = false
	header.AnchorPoint = Vector2.new(0, 0)
	header.AutomaticSize = Enum.AutomaticSize.None
	header.BackgroundColor3 = Color3.new(1, 1, 1)
	header.BackgroundTransparency = 1
	header.BorderColor3 = Color3.new(0, 0, 0)
	header.BorderMode = Enum.BorderMode.Outline
	header.BorderSizePixel = 0
	header.ClipsDescendants = false
	header.LayoutOrder = 0
	header.Position = UDim2.new(0, 0, 0, 0)
	header.Rotation = 0
	header.Selectable = false
	header.Size = UDim2.new(1, 0, 0.45, 0)
	header.Visible = true
	header.ZIndex = 1
	header.Text = "[OPTION NAME]"
	header.TextColor3 = Color3.new(1, 1, 1)
	header.TextSize = 14
	header.Font = Enum.Font.ArialBold

	local stroke = createUIStroke()
	stroke.Parent = header

	local gradient = createUIGradient()
	gradient.Parent = header

	header.Parent = frame

	local layout = createUIListLayout()
	layout.Parent = frame

	return frame
end

function createDROPDOWN_PRESET()
	local btn = Instance.new("ImageButton")
	btn.Name = "DROPDOWN_PRESET"
	btn.Archivable = true
	btn.Active = true
	btn.AnchorPoint = Vector2.new(0, 0)
	btn.AutomaticSize = Enum.AutomaticSize.None
	btn.BackgroundColor3 = fromRGB(66, 66, 66)
	btn.BackgroundTransparency = 0
	btn.BorderColor3 = Color3.new(0, 0, 0)
	btn.BorderMode = Enum.BorderMode.Outline
	btn.BorderSizePixel = 0
	btn.ClipsDescendants = false
	btn.LayoutOrder = 0
	btn.Position = UDim2.new(0, 0, 0, 0)
	btn.Rotation = 0
	btn.Selectable = true
	btn.Size = UDim2.new(1, 0, 0.35, 0)
	btn.Visible = false
	btn.ZIndex = 1
	btn.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	btn.ImageColor3 = Color3.new(1, 1, 1)
	btn.ImageTransparency = 1

	local uicorner = createUICorner()
	uicorner.Parent = btn

	local display = Instance.new("TextLabel")
	display.Name = "Display"
	display.Archivable = true
	display.Active = false
	display.AnchorPoint = Vector2.new(1, 0.5)
	display.AutomaticSize = Enum.AutomaticSize.None
	display.BackgroundColor3 = Color3.new(1, 1, 1)
	display.BackgroundTransparency = 1
	display.BorderColor3 = Color3.new(0, 0, 0)
	display.BorderMode = Enum.BorderMode.Outline
	display.BorderSizePixel = 0
	display.ClipsDescendants = false
	display.LayoutOrder = 0
	display.Position = UDim2.new(1, 0, 0.5, 0)
	display.Rotation = 0
	display.Selectable = false
	display.Size = UDim2.new(0.8, 0, 0.8, 0)
	display.Visible = true
	display.ZIndex = 1
	display.Text = "PLACEHOLDER"
	display.TextColor3 = Color3.new(1, 1, 1)
	display.TextSize = 14
	display.Font = Enum.Font.ArialBold

	display.Parent = btn

	return btn
end

function createDropdownInstance()
	local btn = Instance.new("TextButton")
	btn.Name = "DROPDOWN_PRESET"
	btn.Archivable = true
	btn.Active = true
	btn.AnchorPoint = Vector2.new(0, 0)
	btn.AutomaticSize = Enum.AutomaticSize.None
	btn.BackgroundColor3 = fromRGB(95, 95, 95)
	btn.BackgroundTransparency = 0
	btn.BorderColor3 = Color3.new(0, 0, 0)
	btn.BorderMode = Enum.BorderMode.Outline
	btn.BorderSizePixel = 0
	btn.ClipsDescendants = false
	btn.LayoutOrder = 0
	btn.Position = UDim2.new(0, 0, 0, 0)
	btn.Rotation = 0
	btn.Selectable = true
	btn.Size = UDim2.new(0.75, 0, 0.25, 0)
	btn.Visible = true
	btn.ZIndex = 2
	btn.Text = "Select Player"
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 14
	btn.Font = Enum.Font.ArialBold

	local uicorner = createUICorner()
	uicorner.Parent = btn

	local isOpened = Instance.new("TextLabel")
	isOpened.Name = "isOpened"
	isOpened.Archivable = true
	isOpened.Active = false
	isOpened.AnchorPoint = Vector2.new(1, 0)
	isOpened.AutomaticSize = Enum.AutomaticSize.None
	isOpened.BackgroundColor3 = Color3.new(1, 1, 1)
	isOpened.BackgroundTransparency = 1
	isOpened.BorderColor3 = Color3.new(0, 0, 0)
	isOpened.BorderMode = Enum.BorderMode.Outline
	isOpened.BorderSizePixel = 0
	isOpened.ClipsDescendants = false
	isOpened.LayoutOrder = 0
	isOpened.Position = UDim2.new(1, 0, 0, 0)
	isOpened.Rotation = 0
	isOpened.Selectable = false
	isOpened.Size = UDim2.new(0.1, 0, 1, 0)
	isOpened.Visible = true
	isOpened.ZIndex = 1
	isOpened.Text = ">"
	isOpened.TextColor3 = Color3.new(1, 1, 1)
	isOpened.TextSize = 14
	isOpened.Font = Enum.Font.ArialBold

	isOpened.Parent = btn

	local dropdown = Instance.new("ScrollingFrame")
	dropdown.Name = "Dropdown"
	dropdown.Archivable = true
	dropdown.Active = true
	dropdown.AnchorPoint = Vector2.new(0, 0)
	dropdown.AutomaticSize = Enum.AutomaticSize.None
	dropdown.BackgroundColor3 = fromRGB(95, 95, 95)
	dropdown.BackgroundTransparency = 0
	dropdown.BorderColor3 = Color3.new(0, 0, 0)
	dropdown.BorderMode = Enum.BorderMode.Outline
	dropdown.BorderSizePixel = 0
	dropdown.ClipsDescendants = true
	dropdown.LayoutOrder = 0
	dropdown.Position = UDim2.new(0, 0, 1, 0)
	dropdown.Rotation = 0
	dropdown.Selectable = true
	dropdown.Size = UDim2.new(1, 0, 5, 0)
	dropdown.Visible = false
	dropdown.ZIndex = 1

	local dropUicorner = createUICorner()
	dropUicorner.Parent = dropdown

	local dropLayout = createUIListLayout()
	dropLayout.Parent = dropdown

	local dropGrid = Instance.new("UIGridLayout")
	dropGrid.Parent = dropdown

	dropdown.Parent = btn

	return btn
end

function createDROPDOWN_USER_PRESET()
	local btn = Instance.new("ImageButton")
	btn.Name = "DROPDOWN_USER_PRESET"
	btn.Archivable = true
	btn.Active = true
	btn.AnchorPoint = Vector2.new(0, 0)
	btn.AutomaticSize = Enum.AutomaticSize.None
	btn.BackgroundColor3 = fromRGB(66, 66, 66)
	btn.BackgroundTransparency = 0
	btn.BorderColor3 = Color3.new(0, 0, 0)
	btn.BorderMode = Enum.BorderMode.Outline
	btn.BorderSizePixel = 0
	btn.ClipsDescendants = false
	btn.LayoutOrder = 0
	btn.Position = UDim2.new(0, 0, 0, 0)
	btn.Rotation = 0
	btn.Selectable = true
	btn.Size = UDim2.new(1, 0, 0.35, 0)
	btn.Visible = false
	btn.ZIndex = 1
	btn.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	btn.ImageColor3 = Color3.new(1, 1, 1)
	btn.ImageTransparency = 1

	local uicorner = createUICorner()
	uicorner.Parent = btn

	local userIcon = Instance.new("ImageLabel")
	userIcon.Name = "UserIcon"
	userIcon.Archivable = true
	userIcon.Active = false
	userIcon.AnchorPoint = Vector2.new(0, 0)
	userIcon.AutomaticSize = Enum.AutomaticSize.None
	userIcon.BackgroundColor3 = Color3.new(1, 1, 1)
	userIcon.BackgroundTransparency = 1
	userIcon.BorderColor3 = Color3.new(0, 0, 0)
	userIcon.BorderMode = Enum.BorderMode.Outline
	userIcon.BorderSizePixel = 0
	userIcon.ClipsDescendants = false
	userIcon.LayoutOrder = 0
	userIcon.Position = UDim2.new(0, 0, 0, 0)
	userIcon.Rotation = 0
	userIcon.Selectable = false
	userIcon.Size = UDim2.new(0.12, 0, 1, 0)
	userIcon.Visible = true
	userIcon.ZIndex = 1
	userIcon.Image = "rbxthumb://type=AvatarHeadShot&id=87009930&w=60&h=60"
	userIcon.ImageColor3 = Color3.new(1, 1, 1)
	userIcon.ImageTransparency = 0

	local iconUicorner = createUICorner()
	iconUicorner.Parent = userIcon

	userIcon.Parent = btn

	local userName = Instance.new("TextLabel")
	userName.Name = "UserName"
	userName.Archivable = true
	userName.Active = false
	userName.AnchorPoint = Vector2.new(1, 0.5)
	userName.AutomaticSize = Enum.AutomaticSize.None
	userName.BackgroundColor3 = Color3.new(1, 1, 1)
	userName.BackgroundTransparency = 1
	userName.BorderColor3 = Color3.new(0, 0, 0)
	userName.BorderMode = Enum.BorderMode.Outline
	userName.BorderSizePixel = 0
	userName.ClipsDescendants = false
	userName.LayoutOrder = 0
	userName.Position = UDim2.new(1, 0, 0.5, 0)
	userName.Rotation = 0
	userName.Selectable = false
	userName.Size = UDim2.new(0.8, 0, 0.8, 0)
	userName.Visible = true
	userName.ZIndex = 1
	userName.Text = "aaronrtwo"
	userName.TextColor3 = Color3.new(1, 1, 1)
	userName.TextSize = 14
	userName.Font = Enum.Font.ArialBold

	userName.Parent = btn

	return btn
end

function createINPUT_PRESET()
	local input = Instance.new("TextBox")
	input.Name = "INPUT_PRESET"
	input.Archivable = true
	input.Active = true
	input.AnchorPoint = Vector2.new(0, 0)
	input.AutomaticSize = Enum.AutomaticSize.None
	input.BackgroundColor3 = fromRGB(95, 95, 95)
	input.BackgroundTransparency = 0
	input.BorderColor3 = Color3.new(0, 0, 0)
	input.BorderMode = Enum.BorderMode.Outline
	input.BorderSizePixel = 0
	input.ClipsDescendants = false
	input.LayoutOrder = 0
	input.Position = UDim2.new(0, 0, 0, 0)
	input.Rotation = 0
	input.Selectable = true
	input.Size = UDim2.new(0.75, 0, 0.25, 0)
	input.Visible = true
	input.ZIndex = 2
	input.Text = ""
	input.TextColor3 = Color3.new(1, 1, 1)
	input.TextSize = 14
	input.Font = Enum.Font.ArialBold

	local uicorner = createUICorner()
	uicorner.Parent = input

	return input
end

function createLogTemplate()
	local label = Instance.new("TextLabel")
	label.Name = "LogTemplate"
	label.Archivable = true
	label.Active = false
	label.AnchorPoint = Vector2.new(0, 0)
	label.AutomaticSize = Enum.AutomaticSize.None
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.7
	label.BorderColor3 = Color3.new(0, 0, 0)
	label.BorderMode = Enum.BorderMode.Outline
	label.BorderSizePixel = 0
	label.ClipsDescendants = false
	label.LayoutOrder = 0
	label.Position = UDim2.new(0, 0, 0, 0)
	label.Rotation = 0
	label.Selectable = false
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.Visible = true
	label.ZIndex = 1
	label.Text = "<font color='rgb(255, 200, 0)'>BANNED</font> Saucefy10!"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 14
	label.Font = Enum.Font.Arial
	label.RichText = true

	local stroke = createUIStroke()
	stroke.Parent = label

	return label
end

-- ============================================================================
-- BUILD THE COMPLETE UI
-- ============================================================================

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminPanel"
screenGui.Archivable = true
screenGui.Enabled = true
screenGui.Parent = playerGui

-- Create AdminFrame
local adminFrame = Instance.new("Frame")
adminFrame.Name = "AdminFrame"
adminFrame.Archivable = true
adminFrame.Active = false
adminFrame.AnchorPoint = Vector2.new(1, 1)
adminFrame.AutomaticSize = Enum.AutomaticSize.None
adminFrame.BackgroundColor3 = fromRGB(20, 20, 22)
adminFrame.BackgroundTransparency = 0.1
adminFrame.BorderColor3 = Color3.new(0, 0, 0)
adminFrame.BorderMode = Enum.BorderMode.Outline
adminFrame.BorderSizePixel = 0
adminFrame.ClipsDescendants = false
adminFrame.LayoutOrder = 0
adminFrame.Position = UDim2.new(1, 0, 1, 0)
adminFrame.Rotation = 0
adminFrame.Selectable = false
adminFrame.Size = UDim2.new(0.4, 0, 0.4, 0)
adminFrame.Visible = true
adminFrame.ZIndex = 3
adminFrame.Parent = screenGui

-- ButtonSFX
local buttonSFX = Instance.new("Sound")
buttonSFX.Name = "ButtonSFX"
buttonSFX.Parent = adminFrame

-- UIStroke
local adminStroke = createUIStroke()
adminStroke.Parent = adminFrame

-- Background ImageLabel
local background = Instance.new("ImageLabel")
background.Name = "Background"
background.Archivable = true
background.Active = false
background.AnchorPoint = Vector2.new(0, 0)
background.AutomaticSize = Enum.AutomaticSize.None
background.BackgroundColor3 = Color3.new(0, 0, 0)
background.BackgroundTransparency = 0
background.BorderColor3 = Color3.new(0, 0, 0)
background.BorderMode = Enum.BorderMode.Outline
background.BorderSizePixel = 0
background.ClipsDescendants = false
background.LayoutOrder = 0
background.Position = UDim2.new(0, 0, 0, 0)
background.Rotation = 0
background.Selectable = false
background.Size = UDim2.new(1, 0, 1, 0)
background.Visible = true
background.ZIndex = 0
background.Image = "rbxassetid://112741858475996"
background.ImageColor3 = Color3.new(1, 1, 1)
background.ImageTransparency = 0.9
background.Parent = adminFrame

local bgGradient = createUIGradient()
bgGradient.Parent = background

local bgCorner = createUICorner()
bgCorner.Parent = background

-- UICorner for adminFrame
local adminCorner = createUICorner()
adminCorner.Parent = adminFrame

-- Buttons Frame (tab bar)
local buttonsFrame = Instance.new("Frame")
buttonsFrame.Name = "Buttons"
buttonsFrame.Archivable = true
buttonsFrame.Active = false
buttonsFrame.AnchorPoint = Vector2.new(0, 1)
buttonsFrame.AutomaticSize = Enum.AutomaticSize.None
buttonsFrame.BackgroundColor3 = fromRGB(50, 50, 50)
buttonsFrame.BackgroundTransparency = 0
buttonsFrame.BorderColor3 = Color3.new(0, 0, 0)
buttonsFrame.BorderMode = Enum.BorderMode.Outline
buttonsFrame.BorderSizePixel = 0
buttonsFrame.ClipsDescendants = false
buttonsFrame.LayoutOrder = 0
buttonsFrame.Position = UDim2.new(0, 0, 0, -3)
buttonsFrame.Rotation = 0
buttonsFrame.Selectable = false
buttonsFrame.Size = UDim2.new(1, 0, 0.1, 0)
buttonsFrame.Visible = true
buttonsFrame.ZIndex = 1
buttonsFrame.Parent = adminFrame

local buttonsStroke = createUIStroke()
buttonsStroke.Parent = buttonsFrame

local buttonsCorner = createUICorner()
buttonsCorner.Parent = buttonsFrame

local buttonsLayout = createUIListLayout()
buttonsLayout.Parent = buttonsFrame

-- Title Background
local titleBackground = Instance.new("ImageLabel")
titleBackground.Name = "TitleBackground"
titleBackground.Archivable = true
titleBackground.Active = false
titleBackground.AnchorPoint = Vector2.new(0, 0)
titleBackground.AutomaticSize = Enum.AutomaticSize.None
titleBackground.BackgroundColor3 = fromRGB(15, 50, 0)
titleBackground.BackgroundTransparency = 0
titleBackground.BorderColor3 = Color3.new(0, 0, 0)
titleBackground.BorderMode = Enum.BorderMode.Outline
titleBackground.BorderSizePixel = 0
titleBackground.ClipsDescendants = false
titleBackground.LayoutOrder = 0
titleBackground.Position = UDim2.new(0, 0, 0, 0)
titleBackground.Rotation = 0
titleBackground.Selectable = false
titleBackground.Size = UDim2.new(1, 0, 0.05, 0)
titleBackground.Visible = true
titleBackground.ZIndex = 1
titleBackground.Image = ""
titleBackground.ImageColor3 = Color3.new(1, 1, 1)
titleBackground.ImageTransparency = 0.9
titleBackground.Parent = adminFrame

local titleBgCorner = createUICorner()
titleBgCorner.Parent = titleBackground

-- Title text
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Archivable = true
title.Active = false
title.AnchorPoint = Vector2.new(0, 0)
title.AutomaticSize = Enum.AutomaticSize.None
title.BackgroundColor3 = Color3.new(0, 0, 0)
title.BackgroundTransparency = 1
title.BorderColor3 = Color3.new(0, 0, 0)
title.BorderMode = Enum.BorderMode.Outline
title.BorderSizePixel = 0
title.ClipsDescendants = false
title.LayoutOrder = 1
title.Position = UDim2.new(0, 0, 0, 0)
title.Rotation = 0
title.Selectable = false
title.Size = UDim2.new(1, 0, 0.05, 0)
title.Visible = true
title.ZIndex = 2
title.Text = "Admin Panel"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 14
title.Font = Enum.Font.ArialBold
title.Parent = adminFrame

local titleGradient = createUIGradient()
titleGradient.Parent = title

local titleStroke = createUIStroke()
titleStroke.Parent = title

-- AdminArea (ScrollingFrame)
local adminArea = Instance.new("ScrollingFrame")
adminArea.Name = "AdminArea"
adminArea.Archivable = true
adminArea.Active = true
adminArea.AnchorPoint = Vector2.new(0, 0)
adminArea.AutomaticSize = Enum.AutomaticSize.None
adminArea.BackgroundColor3 = Color3.new(1, 1, 1)
adminArea.BackgroundTransparency = 1
adminArea.BorderColor3 = Color3.new(0, 0, 0)
adminArea.BorderMode = Enum.BorderMode.Outline
adminArea.BorderSizePixel = 0
adminArea.ClipsDescendants = true
adminArea.LayoutOrder = 0
adminArea.Position = UDim2.new(0, 0, 0.05, 0)
adminArea.Rotation = 0
adminArea.Selectable = true
adminArea.Size = UDim2.new(1, 0, 0.95, 0)
adminArea.Visible = true
adminArea.ZIndex = 1
adminArea.Parent = adminFrame

local adminAreaLayout = createUIListLayout()
adminAreaLayout.Parent = adminArea

-- Aspect Ratio & Size Constraints
local aspectRatio = createUIAspectRatioConstraint()
aspectRatio.Parent = adminFrame

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.Parent = adminFrame

-- PanelBtn (toggle button)
local panelBtn = Instance.new("ImageButton")
panelBtn.Name = "PanelBtn"
panelBtn.Archivable = true
panelBtn.Active = true
panelBtn.AnchorPoint = Vector2.new(0, 0)
panelBtn.AutomaticSize = Enum.AutomaticSize.None
panelBtn.BackgroundColor3 = Color3.new(1, 1, 1)
panelBtn.BackgroundTransparency = 1
panelBtn.BorderColor3 = Color3.new(0, 0, 0)
panelBtn.BorderMode = Enum.BorderMode.Outline
panelBtn.BorderSizePixel = 0
panelBtn.ClipsDescendants = false
panelBtn.LayoutOrder = 0
panelBtn.Position = UDim2.new(0.008625, 0, 0.38148, 0)
panelBtn.Rotation = 0
panelBtn.Selectable = true
panelBtn.Size = UDim2.new(0.04219, 0, 0.0815, 0)
panelBtn.Visible = false
panelBtn.ZIndex = 1
panelBtn.Image = "rbxassetid://8618269848"
panelBtn.ImageColor3 = Color3.new(1, 1, 1)
panelBtn.ImageTransparency = 0
panelBtn.Parent = screenGui

local panelAspect = createUIAspectRatioConstraint()
panelAspect.Parent = panelBtn

local icon = Instance.new("ImageLabel")
icon.Name = "Icon"
icon.Archivable = true
icon.Active = false
icon.AnchorPoint = Vector2.new(0, 0)
icon.AutomaticSize = Enum.AutomaticSize.None
icon.BackgroundColor3 = Color3.new(1, 1, 1)
icon.BackgroundTransparency = 1
icon.BorderColor3 = Color3.new(0, 0, 0)
icon.BorderMode = Enum.BorderMode.Outline
icon.BorderSizePixel = 0
icon.ClipsDescendants = false
icon.LayoutOrder = 0
icon.Position = UDim2.new(0.158127, 0, 0.158127, 0)
icon.Rotation = 0
icon.Selectable = false
icon.Size = UDim2.new(0.699, 0, 0.684, 0)
icon.Visible = true
icon.ZIndex = 1
icon.Image = "rbxassetid://78105527764905"
icon.ImageColor3 = Color3.new(1, 1, 1)
icon.ImageTransparency = 0.5
icon.Parent = panelBtn

local iconAspect = createUIAspectRatioConstraint()
iconAspect.Parent = icon

-- Logs Frame
local logsFrame = Instance.new("Frame")
logsFrame.Name = "Logs"
logsFrame.Archivable = true
logsFrame.Active = false
logsFrame.AnchorPoint = Vector2.new(0, 0)
logsFrame.AutomaticSize = Enum.AutomaticSize.None
logsFrame.BackgroundColor3 = fromRGB(20, 20, 22)
logsFrame.BackgroundTransparency = 1
logsFrame.BorderColor3 = Color3.new(0, 0, 0)
logsFrame.BorderMode = Enum.BorderMode.Outline
logsFrame.BorderSizePixel = 0
logsFrame.ClipsDescendants = false
logsFrame.LayoutOrder = 0
logsFrame.Position = UDim2.new(0, 0, 0.05, 0)
logsFrame.Rotation = 0
logsFrame.Selectable = false
logsFrame.Size = UDim2.new(1, 0, 0.03, 0)
logsFrame.Visible = true
logsFrame.ZIndex = 3
logsFrame.Parent = screenGui

local logsLayout = createUIListLayout()
logsLayout.Parent = logsFrame

-- LogTemplate
local logTemplate = createLogTemplate()
logTemplate.Parent = screenGui
logTemplate.Visible = false

-- ============================================================================
-- MAIN LOGIC
-- ============================================================================

-- Get player key from server
local Events = ReplicatedStorage:FindFirstChild("Events")
local playerKey = nil
if Events and Events:FindFirstChild("RemoteFunctions") and Events.RemoteFunctions:FindFirstChild("GetPlayerKey") then
	playerKey = Events.RemoteFunctions.GetPlayerKey:InvokeServer()
end

local currentTab = nil
local tabButtons = {}
local isBuilding = true

local function cleanUpAdminArea()
	for _, child in adminArea:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

-- Create tab buttons from configuration
for tabName, tabConfig in Configuration do
	if playerKey and tabConfig.RequiredKey and playerKey < tabConfig.RequiredKey then
		continue
	end

	local tabBtn = createTOP_BUTTON_PRESET()
	tabBtn.Name = tabName
	tabBtn.Text = tabName
	tabBtn.BackgroundColor3 = fromRGB(58, 57, 56)
	tabBtn.LayoutOrder = tabConfig.LayoutOrder
	tabBtn.Parent = buttonsFrame

	local tabEntry = {
		Instance = tabBtn,
		Connections = {}
	}

	local function switchTab()
		if not isBuilding then return end
		if currentTab == tabBtn then return end

		if currentTab then
			currentTab.BackgroundColor3 = fromRGB(58, 57, 56)
		end

		isBuilding = false
		buttonSFX:Play()
		cleanUpAdminArea()

		currentTab = tabBtn
		tabBtn.BackgroundColor3 = fromRGB(57, 127, 49)

		local pageCount = #tabConfig.Page
		local argValues = {}

		for index, pageEntry in tabConfig.Page do
			local success, result = pcall(function()
				local module = pageEntry.Type == "Dropdown" and DropdownModule or InputStringModule
				return module.CreateInstance(pageEntry.Parameters)
			end)

			if tabBtn ~= tabBtn then
				break
			end

			if success then
				local section = createSection_PRESET()
				section.ZIndex = #tabConfig.Page - index + 10
				section.Header.Text = pageEntry.Name

				local toggleInstance = result[1]
				local toggleContext = result[2]

				toggleContext.onArgumentChange:Connect(function(value)
					argValues[index] = value
				end)

				toggleInstance.LayoutOrder = index
				toggleInstance.Parent = section
				section.Parent = adminArea

				continue
			end

			print(("[AdminPanel :: switchTab]: Failed to get toggle type: %s"):format(pageEntry.Type))
		end

		local executeBtn = createEXECUTE_BUTTON_PRESET()
		executeBtn.Activated:Connect(function()
			buttonSFX:Play()
			local success, result = pcall(function()
				return Events.RemoteFunctions.FireAdminConsole:InvokeServer(tabName, table.unpack(argValues, 1, pageCount))
			end)
			if not success then
				print(("[AdminPanel :: switchTab]: Failed to invoke: FireAdminConsole, due to: \n%s"):format(result))
			end
		end)
		executeBtn.LayoutOrder = 0
		executeBtn.Parent = adminArea

		isBuilding = true
	end

	tabEntry.Connections[1] = tabBtn.Activated:Connect(switchTab)
	tabEntry.Switch = switchTab
	tabButtons[tabName] = tabEntry
end

-- Auto-select the first tab
for _, entry in tabButtons do
	entry.Switch()
	break
end

-- PanelBtn toggle
panelBtn.Activated:Connect(function()
	adminFrame.Visible = not adminFrame.Visible
end)

-- Log messages from server
if Events and Events:FindFirstChild("RemoteEvents") and Events.RemoteEvents:FindFirstChild("APMsg") then
	Events.RemoteEvents.APMsg.OnClientEvent:Connect(function(sound, message)
		if sound then
			sound:Play()
		end
		local logEntry = logTemplate:Clone()
		logEntry.Visible = true
		logEntry.Text = message
		logEntry.Parent = logsFrame
		Debris:AddItem(logEntry, 10)
	end)
end

-- Keyboard/mouse toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == J then
		adminFrame.Visible = not adminFrame.Visible
	end
	if input.UserInputType ~= Enum.UserInputType.Touch then return end
	panelBtn.Visible = true
end)
