local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer

local BUILDER_ID = 129279692364812
local LOADER_ID = 100588763114828

if game.GameId ~= BUILDER_ID and game.PlaceId ~= BUILDER_ID
	and game.GameId ~= LOADER_ID and game.PlaceId ~= LOADER_ID then
	return
end

local Colors = {
	Background = Color3.fromRGB(17, 18, 24),
	Panel = Color3.fromRGB(25, 27, 35),
	Secondary = Color3.fromRGB(35, 38, 48),
	Button = Color3.fromRGB(46, 50, 64),
	Selected = Color3.fromRGB(105, 95, 255),
	Text = Color3.fromRGB(240, 240, 245),
	Muted = Color3.fromRGB(155, 158, 175),
	Green = Color3.fromRGB(75, 190, 125),
	Red = Color3.fromRGB(220, 85, 85)
}

local DirectionOptions = {
	"Forward",
	"Backward",
	"Left",
	"Right",
	"Up",
	"Down",
	"ForwardLeft",
	"ForwardRight",
	"BackwardLeft",
	"BackwardRight",
	"ThroughCamera"
}

local function Create(Class, Parent, Properties)
	local Object = Instance.new(Class)

	for Property, Value in pairs(Properties or {}) do
		Object[Property] = Value
	end

	Object.Parent = Parent

	return Object
end

local function Round(Object, Radius)
	Create("UICorner", Object, {
		CornerRadius = UDim.new(0, Radius or 8)
	})
end

local function Stroke(Object, Color, Thickness)
	Create("UIStroke", Object, {
		Color = Color or Colors.Button,
		Thickness = Thickness or 1,
		Transparency = 0.2
	})
end

local function Label(Parent, Text, Size, Position)
	return Create("TextLabel", Parent, {
		BackgroundTransparency = 1,
		Position = Position or UDim2.new(),
		Size = Size or UDim2.new(1, 0, 0, 30),
		Text = Text,
		TextColor3 = Colors.Text,
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true
	})
end

local function Button(Parent, Text, Size, Position, Callback)
	local Object = Create("TextButton", Parent, {
		BackgroundColor3 = Colors.Button,
		Position = Position or UDim2.new(),
		Size = Size or UDim2.fromOffset(120, 35),
		Text = Text,
		TextColor3 = Colors.Text,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = true
	})

	Round(Object, 7)

	if Callback then
		Object.Activated:Connect(Callback)
	end

	return Object
end

local function TextBox(Parent, Text, Size, Position, MultiLine)
	local Object = Create("TextBox", Parent, {
		BackgroundColor3 = Colors.Secondary,
		Position = Position or UDim2.new(),
		Size = Size or UDim2.fromOffset(200, 32),
		Text = Text or "",
		TextColor3 = Colors.Text,
		PlaceholderColor3 = Colors.Muted,
		PlaceholderText = "Enter a value...",
		TextSize = 13,
		Font = Enum.Font.Gotham,
		ClearTextOnFocus = false,
		MultiLine = MultiLine or false,
		TextWrapped = MultiLine or false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = MultiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
	})

	Round(Object, 6)

	return Object
end

local function Clear(Parent)
	for _, Child in ipairs(Parent:GetChildren()) do
		if not Child:IsA("UIListLayout")
			and not Child:IsA("UIPadding")
			and not Child:IsA("UIGridLayout") then

			Child:Destroy()
		end
	end
end

local function AssetId(Value)
	Value = tostring(Value or "")

	if Value == "" then
		return ""
	end

	if tonumber(Value) then
		return "rbxassetid://" .. Value
	end

	return Value
end

local function ParseVector(Text)
	local Numbers = {}

	for Number in string.gmatch(tostring(Text or ""), "-?[%d%.]+") do
		table.insert(Numbers, tonumber(Number) or 0)
	end

	return Vector3.new(
		Numbers[1] or 0,
		Numbers[2] or 0,
		Numbers[3] or 0
	)
end

local function NewGraph()
	return {
		StartNodeId = "",
		Nodes = {},
		Branches = {}
	}
end

local function DirectionVector(Direction, Root)
	local Forward = Root.CFrame.LookVector
	local Right = Root.CFrame.RightVector

	if Direction == "Forward" then
		return Forward
	elseif Direction == "Backward" then
		return -Forward
	elseif Direction == "Left" then
		return -Right
	elseif Direction == "Right" then
		return Right
	elseif Direction == "Up" then
		return Vector3.new(0, 1, 0)
	elseif Direction == "Down" then
		return Vector3.new(0, -1, 0)
	elseif Direction == "ForwardLeft" then
		return (Forward - Right).Unit
	elseif Direction == "ForwardRight" then
		return (Forward + Right).Unit
	elseif Direction == "BackwardLeft" then
		return (-Forward - Right).Unit
	elseif Direction == "BackwardRight" then
		return (-Forward + Right).Unit
	elseif Direction == "ThroughCamera" then
		local Camera = workspace.CurrentCamera

		if Camera then
			return Camera.CFrame.LookVector
		end

		return Forward
	end

	return Forward
end

local function NormalizeGraph(Graph)
	if type(Graph) ~= "table" then
		return NewGraph()
	end

	if type(Graph.Nodes) ~= "table" then
		Graph.Nodes = {}
	end

	if type(Graph.Branches) ~= "table" then
		Graph.Branches = {}
	end

	Graph.StartNodeId = Graph.StartNodeId or ""

	for Index, Node in ipairs(Graph.Nodes) do
		if type(Node) == "table" then
			Node.Id = tostring(Node.Id or ("Node" .. Index))
			Node.Type = Node.Type or "Wait"
			Node.NextNodeId = Node.NextNodeId or ""
		end
	end

	for Name, Branch in pairs(Graph.Branches) do
		if type(Branch) == "table" then
			NormalizeGraph(Branch)
		else
			Graph.Branches[Name] = nil
		end
	end

	return Graph
end

local function NormalizeData(Data)
	if type(Data) ~= "table" then
		return false
	end

	Data.Version = Data.Version or 3
	Data.Name = Data.Name or "Custom Class"
	Data.Description = Data.Description or ""
	Data.CurrencyName = Data.CurrencyName or "Coins"

	if type(Data.Values) ~= "table" then
		Data.Values = {}
	end

	if type(Data.Parts) ~= "table" then
		Data.Parts = {}
	end

	Data.Ability = NormalizeGraph(Data.Ability)
	Data.AltAbility = NormalizeGraph(Data.AltAbility)

	if type(Data.PassiveAbilities) ~= "table" then
		Data.PassiveAbilities = {}
	end

	if type(Data.Upgrades) ~= "table" then
		Data.Upgrades = {}
	end

	for _, Passive in ipairs(Data.PassiveAbilities) do
		if type(Passive) == "table" then
			Passive.Name = Passive.Name or "Passive"
			Passive.Trigger = Passive.Trigger or "OnLoad"
			Passive.Graph = NormalizeGraph(Passive.Graph)
		end
	end

	for _, Upgrade in ipairs(Data.Upgrades) do
		if type(Upgrade) == "table" then
			Upgrade.Name = Upgrade.Name or "Upgrade"
			Upgrade.Description = Upgrade.Description or ""
			Upgrade.Image = Upgrade.Image or ""
			Upgrade.Cost = math.max(0, tonumber(Upgrade.Cost) or 0)

			if type(Upgrade.Changes) ~= "table" then
				Upgrade.Changes = {}
			end
		end
	end

	for _, PartData in ipairs(Data.Parts) do
		if type(PartData) == "table" then
			PartData.Name = PartData.Name or "Part"
			PartData.Size = PartData.Size or "4,1,4"
			PartData.Offset = PartData.Offset or "0,0,-5"
			PartData.Color = PartData.Color or "130,120,255"
			PartData.Transparency = tonumber(PartData.Transparency) or 0
			PartData.Material = PartData.Material or "Neon"
			PartData.Anchored = PartData.Anchored ~= false
			PartData.CanCollide = PartData.CanCollide == true
			PartData.Lifetime = tonumber(PartData.Lifetime) or 0
			PartData.MeshId = PartData.MeshId or ""
		end
	end

	return true
end

local loadedData = nil
local activeValues = {}
local loadedCharacter = false

local Upgrades
local EnableRSpecial

local AbilityBusy = false

local function ExecuteNode(Node, Context)
	local Character = Player.Character

	if not Character then
		return
	end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local Root = Character:FindFirstChild("HumanoidRootPart")

	if not Humanoid or not Root then
		return
	end

	local Type = Node.Type

	if Type == "Move" then
		local Direction = DirectionVector(Node.Direction or "Forward", Root)
		local Distance = math.clamp(tonumber(Node.Distance) or 20, -300, 300)
		local Duration = math.clamp(tonumber(Node.Duration) or 0.25, 0.05, 15)

		local Tween = TweenService:Create(
			Root,
			TweenInfo.new(
				Duration,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),
			{
				CFrame = Root.CFrame + Direction * Distance
			}
		)

		Tween:Play()
		Tween.Completed:Wait()

	elseif Type == "Wait" then
		task.wait(math.clamp(tonumber(Node.Duration) or 1, 0, 60))

	elseif Type == "SetValue" then
		if Node.Editable == false then
			return
		end

		local Key = Node.Key or "Power"
		local Amount = tonumber(Node.Amount) or 1
		local Operation = Node.Operation or "Add"

		local Current = tonumber(activeValues[Key]) or 0

		if Operation == "Add" then
			activeValues[Key] = Current + Amount
		elseif Operation == "Multiply" then
			activeValues[Key] = Current * Amount
		elseif Operation == "Set" then
			activeValues[Key] = Amount
		end

	elseif Type == "Particle" then
		local Attachment = Instance.new("Attachment")
		Attachment.Parent = Root

		local Emitter = Instance.new("ParticleEmitter")
		Emitter.Texture = AssetId(Node.TextureId)
		Emitter.Rate = 0
		Emitter.Lifetime = NumberRange.new(0.5, 1.2)
		Emitter.Speed = NumberRange.new(5, 12)
		Emitter.SpreadAngle = Vector2.new(180, 180)
		Emitter.Parent = Attachment

		Emitter:Emit(
			math.clamp(tonumber(Node.EmitCount) or 25, 1, 200)
		)

		Debris:AddItem(
			Attachment,
			math.clamp(tonumber(Node.Duration) or 2, 0.1, 15)
		)

	elseif Type == "Afterimage" then
		local Duration = math.clamp(tonumber(Node.Duration) or 1, 0.1, 5)
		local Interval = math.clamp(tonumber(Node.Interval) or 0.12, 0.04, 1)
		local Transparency = math.clamp(tonumber(Node.Transparency) or 0.5, 0, 1)

		local StartTime = os.clock()

		while os.clock() - StartTime < Duration do
			if not Player.Character then
				break
			end

			for _, Part in ipairs(Player.Character:GetDescendants()) do
				if Part:IsA("BasePart") then
					local Success, Clone = pcall(function()
						return Part:Clone()
					end)

					if Success and Clone then
						for _, Child in ipairs(Clone:GetChildren()) do
							if not Child:IsA("SpecialMesh")
								and not Child:IsA("Decal")
								and not Child:IsA("Texture")
								and not Child:IsA("SurfaceAppearance") then

								Child:Destroy()
							end
						end

						Clone.Anchored = true
						Clone.CanCollide = false
						Clone.CanTouch = false
						Clone.CanQuery = false
						Clone.Massless = true
						Clone.Transparency = math.max(
							Transparency,
							Part.Transparency
						)

						Clone.CFrame = Part.CFrame
						Clone.Parent = workspace

						TweenService:Create(
							Clone,
							TweenInfo.new(0.5),
							{
								Transparency = 1
							}
						):Play()

						Debris:AddItem(Clone, 0.6)
					end
				end
			end

			task.wait(Interval)
		end

	elseif Type == "Shockwave" then
		local Size = math.clamp(tonumber(Node.Size) or 12, 1, 150)
		local Duration = math.clamp(tonumber(Node.Duration) or 0.4, 0.05, 5)

		local Wave = Instance.new("Part")
		Wave.Name = "CustomShockwave"
		Wave.Anchored = true
		Wave.CanCollide = false
		Wave.CanTouch = false
		Wave.CanQuery = false
		Wave.Material = Enum.Material.Neon
		Wave.Color = Color3.fromRGB(130, 120, 255)
		Wave.Transparency = 0.25
		Wave.Shape = Enum.PartType.Cylinder
		Wave.Size = Vector3.new(0.25, 1, 1)
		Wave.CFrame = Root.CFrame * CFrame.Angles(0, 0, math.rad(90))
		Wave.Parent = workspace

		if Node.MeshId and Node.MeshId ~= "" then
			local Mesh = Instance.new("SpecialMesh")
			Mesh.MeshType = Enum.MeshType.FileMesh
			Mesh.MeshId = AssetId(Node.MeshId)
			Mesh.Scale = Vector3.new(0.15, 1, 1)
			Mesh.Parent = Wave

			TweenService:Create(
				Mesh,
				TweenInfo.new(
					Duration,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				),
				{
					Scale = Vector3.new(0.15, Size, Size)
				}
			):Play()
		else
			TweenService:Create(
				Wave,
				TweenInfo.new(
					Duration,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				),
				{
					Size = Vector3.new(0.25, Size, Size),
					Transparency = 1
				}
			):Play()
		end

		Debris:AddItem(Wave, Duration + 0.2)

	elseif Type == "Part" then
		local Preset

		for _, PartData in ipairs(loadedData and loadedData.Parts or {}) do
			if PartData.Name == Node.Preset then
				Preset = PartData
				break
			end
		end

		if not Preset then
			warn("Part preset not found:", Node.Preset)
			return
		end

		local NewPart = Instance.new("Part")
		NewPart.Name = Preset.Name
		NewPart.Size = ParseVector(Preset.Size)
		NewPart.Size = Vector3.new(
			math.max(0.1, NewPart.Size.X),
			math.max(0.1, NewPart.Size.Y),
			math.max(0.1, NewPart.Size.Z)
		)

		local RGB = ParseVector(Preset.Color)

		NewPart.Color = Color3.fromRGB(
			math.clamp(RGB.X, 0, 255),
			math.clamp(RGB.Y, 0, 255),
			math.clamp(RGB.Z, 0, 255)
		)

		NewPart.Transparency = math.clamp(
			tonumber(Preset.Transparency) or 0,
			0,
			1
		)

		NewPart.Anchored = Preset.Anchored == true
		NewPart.CanCollide = Preset.CanCollide == true
		NewPart.CanTouch = true
		NewPart.CanQuery = true

		local Material = Enum.Material[Preset.Material]

		if Material then
			NewPart.Material = Material
		end

		NewPart.CFrame = Root.CFrame * CFrame.new(
			ParseVector(Preset.Offset)
		)

		if Preset.MeshId and Preset.MeshId ~= "" then
			local Mesh = Instance.new("SpecialMesh")
			Mesh.MeshType = Enum.MeshType.FileMesh
			Mesh.MeshId = AssetId(Preset.MeshId)
			Mesh.Parent = NewPart
		end

		NewPart.Parent = workspace

		local StorageName = Node.StoreAs

		if not StorageName or StorageName == "" then
			StorageName = Preset.Name
		end

		Context.Parts[StorageName] = NewPart
		Context.Parts[Preset.Name] = NewPart

		local Lifetime = tonumber(Node.Lifetime)

		if Lifetime == nil or Lifetime <= 0 then
			Lifetime = tonumber(Preset.Lifetime) or 0
		end

		if Lifetime > 0 then
			Debris:AddItem(NewPart, math.clamp(Lifetime, 0.1, 300))
		end

	elseif Type == "Teleport" then
		local Mode = Node.Mode or "Offset"

		if Mode == "SavedPart" then
			local Target = Context.Parts[Node.TargetPart]

			if Target and Target.Parent then
				Root.CFrame = Target.CFrame * CFrame.new(
					0,
					Target.Size.Y / 2 + 3,
					0
				)
			else
				warn("Teleport target part not found:", Node.TargetPart)
			end
		else
			local Direction = DirectionVector(
				Node.Direction or "Forward",
				Root
			)

			local Distance = math.clamp(
				tonumber(Node.Distance) or 10,
				-300,
				300
			)

			Root.CFrame = Root.CFrame + Direction * Distance
		end

	elseif Type == "Rope" then
		local Target = Context.Parts[Node.TargetPart]

		if not Target or not Target.Parent then
			warn("Rope target part not found:", Node.TargetPart)
			return
		end

		local Duration = math.clamp(
			tonumber(Node.Duration) or 3,
			0.1,
			120
		)

		local Attachment0 = Instance.new("Attachment")
		Attachment0.Parent = Root

		local Attachment1 = Instance.new("Attachment")
		Attachment1.Parent = Target

		local Rope = Instance.new("RopeConstraint")
		Rope.Attachment0 = Attachment0
		Rope.Attachment1 = Attachment1
		Rope.Visible = true
		Rope.Thickness = 0.08
		Rope.Length = math.clamp(
			tonumber(Node.Length) or (Root.Position - Target.Position).Magnitude,
			1,
			300
		)
		Rope.Parent = Root

		Debris:AddItem(Rope, Duration)
		Debris:AddItem(Attachment0, Duration)
		Debris:AddItem(Attachment1, Duration)
	end
end

local function ExecuteGraph(Graph, Context, InputKey, BranchRoot)
	if type(Graph) ~= "table" or type(Graph.Nodes) ~= "table" then
		return
	end

	BranchRoot = BranchRoot or Graph

	Context = Context or {
		Parts = {}
	}

	Context.Parts = Context.Parts or {}

	local NodeMap = {}

	for _, Node in ipairs(Graph.Nodes) do
		if type(Node) == "table" and Node.Id then
			NodeMap[Node.Id] = Node
		end
	end

	local CurrentId = Graph.StartNodeId

	if not CurrentId or CurrentId == "" then
		CurrentId = Graph.Nodes[1] and Graph.Nodes[1].Id
	end

	local History = {}
	local Steps = 0

	local function SwitchBranch(BranchName)
		if not BranchName or BranchName == "" then
			return false
		end

		local TargetGraph = BranchRoot.Branches
			and BranchRoot.Branches[BranchName]

		if not TargetGraph then
			warn("Branch not found:", BranchName)
			return false
		end

		ExecuteGraph(TargetGraph, Context, InputKey, BranchRoot)

		return true
	end

	while CurrentId and CurrentId ~= "" and Steps < 500 do
		local Node = NodeMap[CurrentId]

		if not Node then
			break
		end

		Steps += 1

		if Node.Type == "Brancher" then
			SwitchBranch(Node.Branch)
			return

		elseif Node.Type == "Hold" then
			local Duration = math.clamp(
				tonumber(Node.Duration) or 1,
				0.05,
				30
			)

			local Held = false
			local Started = os.clock()

			if InputKey then
				Held = true

				while os.clock() - Started < Duration do
					if not UserInputService:IsKeyDown(InputKey) then
						Held = false
						break
					end

					task.wait(0.03)
				end
			end

			if Held then
				SwitchBranch(Node.HeldBranch)
			else
				SwitchBranch(Node.ReleasedBranch)
			end

			return

		elseif Node.Type == "Tag" and Node.Mode == "Get" then
			local TagName = tostring(Node.TagName or "Tagged")
			local TagValue = Player:GetAttribute("CustomTag_" .. TagName)

			if TagValue == true then
				if SwitchBranch(Node.SuccessBranch) then
					return
				end
			else
				if SwitchBranch(Node.FailureBranch) then
					return
				end
			end

		else
			if Node.Type == "Tag" and Node.Mode == "Set" then
				local TagName = tostring(Node.TagName or "Tagged")
				Player:SetAttribute("CustomTag_" .. TagName, true)
			else
				if Node.Type == "Loop" then
					local NodeCount = math.clamp(
						math.floor(tonumber(Node.NodeCount) or 1),
						1,
						25
					)

					local Repeats = math.clamp(
						math.floor(tonumber(Node.Repeats) or 2),
						1,
						20
					)

					local StartIndex = math.max(
						1,
						#History - NodeCount + 1
					)

					local PreviousNodes = {}

					for Index = StartIndex, #History do
						table.insert(PreviousNodes, History[Index])
					end

					for RepeatIndex = 1, Repeats do
						for _, PreviousNode in ipairs(PreviousNodes) do
							if PreviousNode.Type ~= "Loop"
								and PreviousNode.Type ~= "Brancher"
								and PreviousNode.Type ~= "Hold"
								and PreviousNode.Type ~= "Tag" then

								Steps += 1

								if Steps >= 500 then
									break
								end

								ExecuteNode(PreviousNode, Context)
							end
						end

						if Steps >= 500 then
							break
						end
					end
				else
					ExecuteNode(Node, Context)
				end
			end

			if Node.Type ~= "Loop" then
				table.insert(History, Node)
			end
		end

		CurrentId = Node.NextNodeId
	end
end

local function CreateBuilder()
	local Data = {
		Version = 3,
		Name = "Custom Class",
		Description = "",
		CurrencyName = "Coins",

		Values = {
			Power = 1,
			Speed = 1,
			Coins = 0
		},

		Parts = {},

		Ability = NewGraph(),
		AltAbility = NewGraph(),

		PassiveAbilities = {},
		Upgrades = {}
	}

	local Gui = Create("ScreenGui", Player:WaitForChild("PlayerGui"), {
		Name = "CharacterBuilder",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 50
	})

	local Main = Create("Frame", Gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1120, 720),
		BackgroundColor3 = Colors.Background
	})

	Round(Main, 12)
	Stroke(Main, Colors.Button, 2)

	local Header = Create("Frame", Main, {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Colors.Panel
	})

	Round(Header, 12)

	local HeaderTitle = Label(
		Header,
		"CHARACTER BUILDER",
		UDim2.fromOffset(210, 45),
		UDim2.fromOffset(18, 5)
	)

	HeaderTitle.Font = Enum.Font.GothamBold

	local NameBox = TextBox(
		Header,
		Data.Name,
		UDim2.fromOffset(240, 34),
		UDim2.new(1, -300, 0, 11)
	)

	NameBox.PlaceholderText = "Character name"

	NameBox.FocusLost:Connect(function()
		if NameBox.Text ~= "" then
			Data.Name = NameBox.Text
		end
	end)

	local CloseButton = Button(
		Header,
		"X",
		UDim2.fromOffset(35, 35),
		UDim2.new(1, -45, 0, 10)
	)

	CloseButton.BackgroundColor3 = Colors.Red

	local Sidebar = Create("Frame", Main, {
		Position = UDim2.fromOffset(0, 56),
		Size = UDim2.new(0, 160, 1, -56),
		BackgroundColor3 = Colors.Panel
	})

	Create("UIListLayout", Sidebar, {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	Create("UIPadding", Sidebar, {
		PaddingTop = UDim.new(0, 15),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10)
	})

	local Editor = Create("Frame", Main, {
		Position = UDim2.fromOffset(160, 56),
		Size = UDim2.new(1, -160, 1, -56),
		BackgroundTransparency = 1
	})

	local Toolbar = Create("ScrollingFrame", Editor, {
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -290, 0, 48),
		BackgroundColor3 = Colors.Panel,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.X,
		CanvasSize = UDim2.fromOffset(1800, 0)
	})

	Create("UIListLayout", Toolbar, {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	Create("UIPadding", Toolbar, {
		PaddingLeft = UDim.new(0, 7),
		PaddingRight = UDim.new(0, 7)
	})

	local NodeCanvas = Create("ScrollingFrame", Editor, {
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, -290, 1, -48),
		BackgroundColor3 = Color3.fromRGB(20, 22, 29),
		BorderSizePixel = 0,
		ScrollBarThickness = 7,
		Active = true,
		CanvasSize = UDim2.fromOffset(1200, 900)
	})

	local Inspector = Create("ScrollingFrame", Editor, {
		Position = UDim2.new(1, -290, 0, 0),
		Size = UDim2.new(0, 290, 1, 0),
		BackgroundColor3 = Colors.Panel,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new()
	})

	Create("UIListLayout", Inspector, {
		Padding = UDim.new(0, 9),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	Create("UIPadding", Inspector, {
		PaddingTop = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 15)
	})

	local DataScroll = Create("ScrollingFrame", Editor, {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(20, 22, 29),
		BorderSizePixel = 0,
		ScrollBarThickness = 7,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Visible = false
	})

	Create("UIListLayout", DataScroll, {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	Create("UIPadding", DataScroll, {
		PaddingTop = UDim.new(0, 15),
		PaddingLeft = UDim.new(0, 15),
		PaddingRight = UDim.new(0, 15),
		PaddingBottom = UDim.new(0, 20)
	})

	local Section = "Ability"
	local CurrentBranch = "Main"
	local SelectedNodeId = nil
	local SelectedPassive = 1
	local Navigation = {}
	local Dragging = nil
	local LinesFrame = nil

	local InputChangedConnection
	local InputEndedConnection

	local RenderGraph
	local RenderToolbar
	local RenderValues
	local RenderParts
	local RenderUpgrades
	local RenderImport
	local RenderExport
	local RenderInspector
	local Refresh

	local function GetAbilityRoot()
		if Section == "Ability" then
			return Data.Ability
		elseif Section == "AltAbility" then
			return Data.AltAbility
		end

		return nil
	end

	local function GetGraph()
		local Root = GetAbilityRoot()

		if Root then
			if CurrentBranch == "Main" then
				return Root
			end

			return Root.Branches[CurrentBranch]
		end

		if Section == "Passives" then
			local Passive = Data.PassiveAbilities[SelectedPassive]

			return Passive and Passive.Graph
		end

		return nil
	end

	local function GetBranchNames()
		local Root = GetAbilityRoot()
		local Names = {}

		if Root then
			for Name in pairs(Root.Branches) do
				table.insert(Names, Name)
			end
		end

		table.sort(Names)

		return Names
	end

	local function AddPageLabel(Text)
		local Object = Label(
			DataScroll,
			Text,
			UDim2.new(1, -10, 0, 35)
		)

		Object.Font = Enum.Font.GothamBold
		Object.TextSize = 19

		return Object
	end

	local function AddDataButton(Text, Callback)
		return Button(
			DataScroll,
			Text,
			UDim2.fromOffset(180, 34),
			nil,
			Callback
		)
	end

	local function NextUniqueBranchName(Root)
		local Number = 1

		while Root.Branches["Branch" .. Number] do
			Number += 1
		end

		return "Branch" .. Number
	end

	RenderInspector = function()
		Clear(Inspector)

		local Graph = GetGraph()
		local Root = GetAbilityRoot()

		if Section == "Passives" then
			local Passive = Data.PassiveAbilities[SelectedPassive]

			if Passive then
				local Heading = Label(
					Inspector,
					"PASSIVE SETTINGS",
					UDim2.new(1, -10, 0, 30)
				)

				Heading.Font = Enum.Font.GothamBold

				Label(
					Inspector,
					"Passive name",
					UDim2.new(1, -10, 0, 18)
				).TextColor3 = Colors.Muted

				local PassiveName = TextBox(
					Inspector,
					Passive.Name,
					UDim2.new(1, -10, 0, 32)
				)

				PassiveName.FocusLost:Connect(function()
					Passive.Name = PassiveName.Text
					RenderToolbar()
				end)

				Label(
					Inspector,
					"Trigger",
					UDim2.new(1, -10, 0, 18)
				).TextColor3 = Colors.Muted

				local Trigger = TextBox(
					Inspector,
					Passive.Trigger or "OnLoad",
					UDim2.new(1, -10, 0, 32)
				)

				Trigger.PlaceholderText = "OnLoad / EverySecond / OnHealthChanged"

				Trigger.FocusLost:Connect(function()
					Passive.Trigger = Trigger.Text
				end)

				Button(
					Inspector,
					"DELETE PASSIVE",
					UDim2.new(1, -10, 0, 32),
					nil,
					function()
						table.remove(Data.PassiveAbilities, SelectedPassive)

						SelectedPassive = math.max(
							1,
							math.min(SelectedPassive, #Data.PassiveAbilities)
						)

						SelectedNodeId = nil

						Refresh()
					end
				).BackgroundColor3 = Colors.Red
			end
		end

		local Node

		if Graph then
			for _, Item in ipairs(Graph.Nodes) do
				if Item.Id == SelectedNodeId then
					Node = Item
					break
				end
			end
		end

		if not Node then
			local Heading = Label(
				Inspector,
				"NODE SETTINGS",
				UDim2.new(1, -10, 0, 30)
			)

			Heading.Font = Enum.Font.GothamBold

			local Info = Label(
				Inspector,
				"Select a node to edit its settings. Connect nodes using NextNodeId.",
				UDim2.new(1, -10, 0, 75)
			)

			Info.TextColor3 = Colors.Muted

			return
		end

		local Heading = Label(
			Inspector,
			Node.Type .. " NODE",
			UDim2.new(1, -10, 0, 30)
		)

		Heading.Font = Enum.Font.GothamBold

		local function AddField(FieldName, Default)
			local FieldLabel = Label(
				Inspector,
				FieldName,
				UDim2.new(1, -10, 0, 18)
			)

			FieldLabel.TextColor3 = Colors.Muted

			local Field = TextBox(
				Inspector,
				tostring(Node[FieldName] or Default or ""),
				UDim2.new(1, -10, 0, 32)
			)

			Field.FocusLost:Connect(function()
				Node[FieldName] = Field.Text

				if FieldName == "NextNodeId" then
					RenderGraph()
				end
			end)

			return Field
		end

		local function AddToggle(FieldName, Options)
			local Current = Node[FieldName]

			if not table.find(Options, Current) then
				Current = Options[1]
			end

			Node[FieldName] = Current

			local Toggle = Button(
				Inspector,
				FieldName .. ": " .. tostring(Current),
				UDim2.new(1, -10, 0, 36),
				nil,
				function()
					local Index = table.find(Options, Node[FieldName]) or 1
					Index += 1

					if Index > #Options then
						Index = 1
					end

					Node[FieldName] = Options[Index]
					RenderInspector()
				end
			)

			Toggle.BackgroundColor3 = Colors.Selected

			return Toggle
		end

		local function AddBranchChoice(FieldName)
			local Names = GetBranchNames()

			local Options = {}

			for _, Name in ipairs(Names) do
				table.insert(Options, Name)
			end

			if #Options == 0 then
				local NoBranches = Label(
					Inspector,
					"Create a branch first using + BRANCH.",
					UDim2.new(1, -10, 0, 35)
				)

				NoBranches.TextColor3 = Colors.Muted

				return
			end

			AddToggle(FieldName, Options)
		end

		local function AddPartChoice(FieldName)
			local Options = {}

			for _, PartData in ipairs(Data.Parts) do
				table.insert(Options, PartData.Name)
			end

			if #Options == 0 then
				local NoParts = Label(
					Inspector,
					"Create a part preset in the PART VALUES section first.",
					UDim2.new(1, -10, 0, 45)
				)

				NoParts.TextColor3 = Colors.Muted

				return
			end

			AddToggle(FieldName, Options)
		end

		AddField("NextNodeId", "")

		if Node.Type == "Move" then
			AddToggle("Direction", DirectionOptions)
			AddField("Distance", "20")
			AddField("Duration", "0.25")

		elseif Node.Type == "Loop" then
			AddField("NodeCount", "1")
			AddField("Repeats", "2")

		elseif Node.Type == "Brancher" then
			AddBranchChoice("Branch")

		elseif Node.Type == "Hold" then
			AddField("Duration", "1")
			AddBranchChoice("HeldBranch")
			AddBranchChoice("ReleasedBranch")

		elseif Node.Type == "Tag" then
			AddToggle("Mode", {"Set", "Get"})
			AddField("TagName", "Tagged")

			if Node.Mode == "Get" then
				AddBranchChoice("SuccessBranch")
				AddBranchChoice("FailureBranch")
			end

		elseif Node.Type == "Part" then
			AddPartChoice("Preset")
			AddField("StoreAs", "Part1")
			AddField("Lifetime", "0")

		elseif Node.Type == "Teleport" then
			AddToggle("Mode", {"Offset", "SavedPart"})

			if Node.Mode == "SavedPart" then
				AddField("TargetPart", "Part1")
			else
				AddToggle("Direction", DirectionOptions)
				AddField("Distance", "10")
			end

		elseif Node.Type == "Rope" then
			AddField("TargetPart", "Part1")
			AddField("Duration", "3")
			AddField("Length", "10")

		elseif Node.Type == "Wait" then
			AddField("Duration", "1")

		elseif Node.Type == "SetValue" then
			local EditableButton = Button(
				Inspector,
				"EDITABLE VALUES: " .. (Node.Editable ~= false and "ON" or "OFF"),
				UDim2.new(1, -10, 0, 36),
				nil,
				function()
					Node.Editable = Node.Editable == false

					RenderInspector()
					RenderGraph()
				end
			)

			EditableButton.BackgroundColor3 =
				Node.Editable ~= false and Colors.Green or Colors.Red

			if Node.Editable ~= false then
				AddField("Key", "Power")
				AddToggle("Operation", {"Add", "Multiply", "Set"})
				AddField("Amount", "1")

				Label(
					Inspector,
					"SELECT CUSTOM VALUE",
					UDim2.new(1, -10, 0, 24)
				).Font = Enum.Font.GothamBold

				local Keys = {}

				for Key in pairs(Data.Values) do
					table.insert(Keys, Key)
				end

				table.sort(Keys)

				for _, Key in ipairs(Keys) do
					local ValueButton = Button(
						Inspector,
						Key .. " = " .. tostring(Data.Values[Key]),
						UDim2.new(1, -10, 0, 30),
						nil,
						function()
							Node.Key = Key
							RenderInspector()
						end
					)

					ValueButton.BackgroundColor3 =
						Node.Key == Key and Colors.Selected or Colors.Button
				end
			end

		else
			local Fields = {
				Particle = {"TextureId", "Duration", "EmitCount"},
				Afterimage = {"Duration", "Interval", "Transparency"},
				Shockwave = {"MeshId", "Size", "Duration"}
			}

			for _, FieldName in ipairs(Fields[Node.Type] or {}) do
				AddField(FieldName)
			end
		end

		Button(
			Inspector,
			"DELETE NODE",
			UDim2.new(1, -10, 0, 35),
			nil,
			function()
				for Index, Item in ipairs(Graph.Nodes) do
					if Item.Id == Node.Id then
						table.remove(Graph.Nodes, Index)
						break
					end
				end

				for _, Item in ipairs(Graph.Nodes) do
					if Item.NextNodeId == Node.Id then
						Item.NextNodeId = ""
					end
				end

				if Graph.StartNodeId == Node.Id then
					Graph.StartNodeId = Graph.Nodes[1]
						and Graph.Nodes[1].Id or ""
				end

				SelectedNodeId = nil

				RenderGraph()
			end
		).BackgroundColor3 = Colors.Red
	end

	local function RedrawLines(Graph)
		if not LinesFrame then
			return
		end

		Clear(LinesFrame)

		local NodeMap = {}

		for _, Node in ipairs(Graph.Nodes) do
			NodeMap[Node.Id] = Node
		end

		for _, Node in ipairs(Graph.Nodes) do
			local Target = NodeMap[Node.NextNodeId]

			if Target then
				local X1 = (Node.X or 30) + 87
				local Y1 = (Node.Y or 30) + 48
				local X2 = (Target.X or 30) + 87
				local Y2 = (Target.Y or 30) + 48

				local Difference = Vector2.new(
					X2 - X1,
					Y2 - Y1
				)

				Create("Frame", LinesFrame, {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromOffset(X1, Y1),
					Size = UDim2.fromOffset(Difference.Magnitude, 3),
					Rotation = math.deg(math.atan2(Difference.Y, Difference.X)),
					BackgroundColor3 = Colors.Selected,
					BorderSizePixel = 0,
					ZIndex = 1
				})
			end
		end
	end

	RenderGraph = function()
		local Graph = GetGraph()

		Clear(NodeCanvas)

		if not Graph then
			LinesFrame = nil

			Label(
				NodeCanvas,
				"Create a passive ability using + PASSIVE.",
				UDim2.fromOffset(400, 50),
				UDim2.fromOffset(30, 30)
			)

			RenderInspector()

			return
		end

		local MaximumX = 800
		local MaximumY = 600

		for _, Node in ipairs(Graph.Nodes) do
			MaximumX = math.max(MaximumX, (Node.X or 30) + 250)
			MaximumY = math.max(MaximumY, (Node.Y or 30) + 180)
		end

		NodeCanvas.CanvasSize = UDim2.fromOffset(MaximumX, MaximumY)

		LinesFrame = Create("Frame", NodeCanvas, {
			Size = UDim2.fromOffset(MaximumX, MaximumY),
			BackgroundTransparency = 1,
			ZIndex = 1
		})

		RedrawLines(Graph)

		for _, Node in ipairs(Graph.Nodes) do
			local IsSelected = SelectedNodeId == Node.Id

			local Card = Create("TextButton", NodeCanvas, {
				Position = UDim2.fromOffset(Node.X or 30, Node.Y or 30),
				Size = UDim2.fromOffset(175, 100),
				BackgroundColor3 = IsSelected and Colors.Selected or Colors.Panel,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 3
			})

			Round(Card, 8)
			Stroke(Card, IsSelected and Colors.Text or Colors.Button, 1)

			local NodeTitle = Label(
				Card,
				Node.Type,
				UDim2.new(1, -15, 0, 27),
				UDim2.fromOffset(9, 5)
			)

			NodeTitle.ZIndex = 4

			local IDLabel = Label(
				Card,
				"ID: " .. Node.Id,
				UDim2.new(1, -15, 0, 20),
				UDim2.fromOffset(9, 33)
			)

			IDLabel.TextColor3 = Colors.Muted
			IDLabel.ZIndex = 4

			local NextLabel = Label(
				Card,
				"Next: " .. (
					Node.NextNodeId ~= "" and tostring(Node.NextNodeId) or "END"
				),
				UDim2.new(1, -15, 0, 25),
				UDim2.fromOffset(9, 57)
			)

			NextLabel.TextColor3 = Colors.Muted
			NextLabel.ZIndex = 4

			Card.Activated:Connect(function()
				SelectedNodeId = Node.Id
				RenderGraph()
			end)

			Card.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					Dragging = {
						Node = Node,
						Card = Card,
						Start = Input.Position,
						OriginalX = Node.X or 30,
						OriginalY = Node.Y or 30
					}
				end
			end)
		end

		RenderInspector()
	end

	local function AddNode(Type)
		local Graph = GetGraph()

		if not Graph then
			return
		end

		local Id = "Node" .. string.sub(
			HttpService:GenerateGUID(false),
			1,
			8
		)

		local Number = #Graph.Nodes + 1

		local Node = {
			Id = Id,
			Type = Type,
			NextNodeId = "",
			X = 35 + ((Number - 1) % 3) * 220,
			Y = 35 + math.floor((Number - 1) / 3) * 150,
			Editable = Type == "SetValue"
		}

		local Defaults = {
			Move = {
				Direction = "Forward",
				Distance = "20",
				Duration = "0.25"
			},

			Wait = {
				Duration = "1"
			},

			SetValue = {
				Key = "Power",
				Operation = "Add",
				Amount = "1"
			},

			Particle = {
				TextureId = "",
				Duration = "2",
				EmitCount = "25"
			},

			Afterimage = {
				Duration = "1",
				Interval = "0.12",
				Transparency = "0.5"
			},

			Shockwave = {
				MeshId = "",
				Size = "12",
				Duration = "0.4"
			},

			Loop = {
				NodeCount = "1",
				Repeats = "2"
			},

			Brancher = {
				Branch = ""
			},

			Hold = {
				Duration = "1",
				HeldBranch = "",
				ReleasedBranch = ""
			},

			Tag = {
				Mode = "Set",
				TagName = "Tagged",
				SuccessBranch = "",
				FailureBranch = ""
			},

			Part = {
				Preset = "",
				StoreAs = "Part1",
				Lifetime = "0"
			},

			Teleport = {
				Mode = "Offset",
				TargetPart = "Part1",
				Direction = "Forward",
				Distance = "10"
			},

			Rope = {
				TargetPart = "Part1",
				Duration = "3",
				Length = "10"
			}
		}

		for Key, Value in pairs(Defaults[Type] or {}) do
			Node[Key] = Value
		end

		local Previous = Graph.Nodes[#Graph.Nodes]

		if Previous then
			if not Previous.NextNodeId or Previous.NextNodeId == "" then
				Previous.NextNodeId = Node.Id
			end
		else
			Graph.StartNodeId = Node.Id
		end

		table.insert(Graph.Nodes, Node)

		SelectedNodeId = Node.Id

		RenderToolbar()
		RenderGraph()
	end

	RenderToolbar = function()
		Clear(Toolbar)

		local function AddToolbarButton(Text, Callback, Selected)
			local Object = Button(
				Toolbar,
				Text,
				UDim2.fromOffset(105, 32),
				nil,
				Callback
			)

			if Selected then
				Object.BackgroundColor3 = Colors.Selected
			end

			return Object
		end

		local Root = GetAbilityRoot()

		if Root then
			AddToolbarButton("+ BRANCH", function()
				local Name = NextUniqueBranchName(Root)

				Root.Branches[Name] = NewGraph()
				CurrentBranch = Name
				SelectedNodeId = nil

				Refresh()
			end)

			AddToolbarButton(
				"MAIN",
				function()
					CurrentBranch = "Main"
					SelectedNodeId = nil
					Refresh()
				end,
				CurrentBranch == "Main"
			)

			for _, Name in ipairs(GetBranchNames()) do
				local BranchName = Name

				AddToolbarButton(
					BranchName,
					function()
						CurrentBranch = BranchName
						SelectedNodeId = nil
						Refresh()
					end,
					CurrentBranch == BranchName
				)
			end

			if CurrentBranch ~= "Main" then
				AddToolbarButton("DELETE BRANCH", function()
					Root.Branches[CurrentBranch] = nil
					CurrentBranch = "Main"
					SelectedNodeId = nil

					Refresh()
				end)
			end
		end

		if Section == "Passives" then
			AddToolbarButton("+ PASSIVE", function()
				table.insert(Data.PassiveAbilities, {
					Name = "Passive " .. (#Data.PassiveAbilities + 1),
					Trigger = "OnLoad",
					Graph = NewGraph()
				})

				SelectedPassive = #Data.PassiveAbilities
				SelectedNodeId = nil

				Refresh()
			end)

			for Index, Passive in ipairs(Data.PassiveAbilities) do
				local PassiveIndex = Index

				AddToolbarButton(
					Passive.Name or ("Passive " .. Index),
					function()
						SelectedPassive = PassiveIndex
						SelectedNodeId = nil

						Refresh()
					end,
					SelectedPassive == PassiveIndex
				)
			end
		end

		local Types = {
			"Move",
			"Wait",
			"SetValue",
			"Particle",
			"Afterimage",
			"Shockwave",
			"Loop",
			"Brancher",
			"Hold",
			"Tag",
			"Part",
			"Teleport",
			"Rope"
		}

		for _, Type in ipairs(Types) do
			AddToolbarButton("+ " .. Type, function()
				AddNode(Type)
			end)
		end
	end

	RenderValues = function()
		Clear(DataScroll)

		AddPageLabel("CUSTOM VALUES")

		local Info = Label(
			DataScroll,
			"Create values that abilities, nodes and upgrades can modify.",
			UDim2.new(1, -15, 0, 38)
		)

		Info.TextColor3 = Colors.Muted

		AddDataButton("+ ADD VALUE", function()
			local Number = 1

			while Data.Values["Value" .. Number] ~= nil do
				Number += 1
			end

			Data.Values["Value" .. Number] = 1

			RenderValues()
		end)

		local Keys = {}

		for Key in pairs(Data.Values) do
			table.insert(Keys, Key)
		end

		table.sort(Keys)

		for _, OriginalKey in ipairs(Keys) do
			local Row = Create("Frame", DataScroll, {
				Size = UDim2.new(1, -15, 0, 48),
				BackgroundColor3 = Colors.Panel
			})

			Round(Row, 7)

			local KeyBox = TextBox(
				Row,
				OriginalKey,
				UDim2.new(0.42, -5, 0, 30),
				UDim2.fromOffset(8, 9)
			)

			local ValueBox = TextBox(
				Row,
				tostring(Data.Values[OriginalKey]),
				UDim2.new(0.32, -5, 0, 30),
				UDim2.new(0.43, 0, 0, 9)
			)

			local Remove = Button(
				Row,
				"X",
				UDim2.new(0.16, -5, 0, 30),
				UDim2.new(0.82, 0, 0, 9),
				function()
					Data.Values[OriginalKey] = nil
					RenderValues()
				end
			)

			Remove.BackgroundColor3 = Colors.Red

			KeyBox.FocusLost:Connect(function()
				local NewKey = KeyBox.Text

				if NewKey ~= "" and NewKey ~= OriginalKey
					and Data.Values[NewKey] == nil then

					local OldValue = Data.Values[OriginalKey]

					Data.Values[OriginalKey] = nil
					Data.Values[NewKey] = OldValue

					RenderValues()
				elseif NewKey ~= OriginalKey then
					RenderValues()
				end
			end)

			ValueBox.FocusLost:Connect(function()
				Data.Values[OriginalKey] = tonumber(ValueBox.Text) or 0
			end)
		end
	end

	RenderParts = function()
		Clear(DataScroll)

		AddPageLabel("PART VALUES")

		local Info = Label(
			DataScroll,
			"Create reusable part presets. Part nodes summon these parts, and Teleport and Rope nodes can reference the spawned parts.",
			UDim2.new(1, -15, 0, 55)
		)

		Info.TextColor3 = Colors.Muted

		AddDataButton("+ ADD PART PRESET", function()
			local Number = #Data.Parts + 1

			table.insert(Data.Parts, {
				Name = "Part" .. Number,
				Size = "4,1,4",
				Offset = "0,0,-5",
				Color = "130,120,255",
				Transparency = 0,
				Material = "Neon",
				Anchored = true,
				CanCollide = false,
				Lifetime = 0,
				MeshId = ""
			})

			RenderParts()
		end)

		for Index, PartData in ipairs(Data.Parts) do
			local PartIndex = Index

			local Card = Create("Frame", DataScroll, {
				Size = UDim2.new(1, -15, 0, 440),
				BackgroundColor3 = Colors.Panel
			})

			Round(Card, 8)
			Stroke(Card)

			local PartTitle = Label(
				Card,
				"PART PRESET " .. Index,
				UDim2.new(1, -110, 0, 27),
				UDim2.fromOffset(10, 8)
			)

			PartTitle.Font = Enum.Font.GothamBold

			local Remove = Button(
				Card,
				"DELETE",
				UDim2.fromOffset(85, 28),
				UDim2.new(1, -95, 0, 7),
				function()
					table.remove(Data.Parts, PartIndex)
					RenderParts()
				end
			)

			Remove.BackgroundColor3 = Colors.Red

			local function AddPartField(FieldName, Y, Default)
				Label(
					Card,
					FieldName,
					UDim2.new(0.27, 0, 0, 28),
					UDim2.fromOffset(10, Y)
				).TextColor3 = Colors.Muted

				local Field = TextBox(
					Card,
					tostring(PartData[FieldName] or Default or ""),
					UDim2.new(0.68, -10, 0, 30),
					UDim2.new(0.29, 0, 0, Y)
				)

				Field.FocusLost:Connect(function()
					if FieldName == "Transparency" or FieldName == "Lifetime" then
						PartData[FieldName] = tonumber(Field.Text) or 0
					else
						PartData[FieldName] = Field.Text
					end
				end)
			end

			AddPartField("Name", 43, "Part")
			AddPartField("Size", 82, "4,1,4")
			AddPartField("Offset", 121, "0,0,-5")
			AddPartField("Color", 160, "130,120,255")
			AddPartField("Transparency", 199, "0")
			AddPartField("Material", 238, "Neon")
			AddPartField("Lifetime", 277, "0")
			AddPartField("MeshId", 316, "")

			local AnchoredButton = Button(
				Card,
				"ANCHORED: " .. (PartData.Anchored and "ON" or "OFF"),
				UDim2.new(0.46, -5, 0, 34),
				UDim2.fromOffset(10, 365),
				function()
					PartData.Anchored = not PartData.Anchored
					RenderParts()
				end
			)

			AnchoredButton.BackgroundColor3 =
				PartData.Anchored and Colors.Green or Colors.Button

			local CollideButton = Button(
				Card,
				"COLLIDE: " .. (PartData.CanCollide and "ON" or "OFF"),
				UDim2.new(0.46, -5, 0, 34),
				UDim2.new(0.52, 0, 0, 365),
				function()
					PartData.CanCollide = not PartData.CanCollide
					RenderParts()
				end
			)

			CollideButton.BackgroundColor3 =
				PartData.CanCollide and Colors.Green or Colors.Button
		end
	end

	RenderUpgrades = function()
		Clear(DataScroll)

		AddPageLabel("UPGRADE SHOP")

		local Info = Label(
			DataScroll,
			"Each upgrade has its own price, image, description and custom value changes.",
			UDim2.new(1, -15, 0, 45)
		)

		Info.TextColor3 = Colors.Muted

		Label(
			DataScroll,
			"Currency value name",
			UDim2.new(1, -15, 0, 20)
		).TextColor3 = Colors.Muted

		local CurrencyBox = TextBox(
			DataScroll,
			Data.CurrencyName,
			UDim2.new(1, -15, 0, 32)
		)

		CurrencyBox.FocusLost:Connect(function()
			if CurrencyBox.Text ~= "" then
				Data.CurrencyName = CurrencyBox.Text
			end
		end)

		AddDataButton("+ ADD UPGRADE", function()
			table.insert(Data.Upgrades, {
				Name = "New Upgrade",
				Description = "",
				Cost = 0,
				Image = "",
				Changes = {
					Power = 1
				}
			})

			RenderUpgrades()
		end)

		for Index, Upgrade in ipairs(Data.Upgrades) do
			local UpgradeIndex = Index

			local Row = Create("Frame", DataScroll, {
				Size = UDim2.new(1, -15, 0, 250),
				BackgroundColor3 = Colors.Panel
			})

			Round(Row, 8)
			Stroke(Row)

			local NameBox = TextBox(
				Row,
				Upgrade.Name or "",
				UDim2.new(0.72, -12, 0, 30),
				UDim2.fromOffset(8, 8)
			)

			local Remove = Button(
				Row,
				"DELETE",
				UDim2.new(0.24, -8, 0, 30),
				UDim2.new(0.76, 0, 0, 8),
				function()
					table.remove(Data.Upgrades, UpgradeIndex)
					RenderUpgrades()
				end
			)

			Remove.BackgroundColor3 = Colors.Red

			local Description = TextBox(
				Row,
				Upgrade.Description or "",
				UDim2.new(1, -16, 0, 30),
				UDim2.fromOffset(8, 47)
			)

			local CostBox = TextBox(
				Row,
				tostring(Upgrade.Cost or 0),
				UDim2.new(0.3, -8, 0, 30),
				UDim2.fromOffset(8, 86)
			)

			local ImageBox = TextBox(
				Row,
				tostring(Upgrade.Image or ""),
				UDim2.new(0.66, -5, 0, 30),
				UDim2.new(0.33, 0, 0, 86)
			)

			Label(
				Row,
				"CUSTOM VALUE CHANGES (JSON)",
				UDim2.new(1, -16, 0, 19),
				UDim2.fromOffset(8, 125)
			).TextColor3 = Colors.Muted

			local ChangesBox = TextBox(
				Row,
				HttpService:JSONEncode(Upgrade.Changes or {}),
				UDim2.new(1, -16, 0, 95),
				UDim2.fromOffset(8, 146),
				true
			)

			ChangesBox.PlaceholderText = '{"Power": 2, "Speed": 1.5}'

			NameBox.FocusLost:Connect(function()
				Upgrade.Name = NameBox.Text
			end)

			Description.FocusLost:Connect(function()
				Upgrade.Description = Description.Text
			end)

			CostBox.FocusLost:Connect(function()
				Upgrade.Cost = math.max(0, tonumber(CostBox.Text) or 0)
			end)

			ImageBox.FocusLost:Connect(function()
				Upgrade.Image = ImageBox.Text
			end)

			ChangesBox.FocusLost:Connect(function()
				local Success, Result = pcall(function()
					return HttpService:JSONDecode(ChangesBox.Text)
				end)

				if Success and type(Result) == "table" then
					Upgrade.Changes = Result
				end
			end)
		end
	end

	RenderImport = function()
		Clear(DataScroll)

		AddPageLabel("IMPORT CHARACTER")

		local Info = Label(
			DataScroll,
			"Paste character JSON exported from the character builder. This will replace the current editor data.",
			UDim2.new(1, -15, 0, 55)
		)

		Info.TextColor3 = Colors.Muted

		local ImportBox = TextBox(
			DataScroll,
			"",
			UDim2.new(1, -15, 0, 350),
			nil,
			true
		)

		ImportBox.Font = Enum.Font.Code
		ImportBox.TextSize = 12
		ImportBox.TextXAlignment = Enum.TextXAlignment.Left
		ImportBox.TextYAlignment = Enum.TextYAlignment.Top
		ImportBox.PlaceholderText = "Paste character JSON here..."

		local Status = Label(
			DataScroll,
			"",
			UDim2.new(1, -15, 0, 35)
		)

		Status.TextColor3 = Colors.Red

		AddDataButton("LOAD CHARACTER DATA", function()
			local Success, Result = pcall(function()
				return HttpService:JSONDecode(ImportBox.Text)
			end)

			if not Success then
				Status.Text = "Invalid JSON."
				Status.TextColor3 = Colors.Red
				return
			end

			if not NormalizeData(Result) then
				Status.Text = "Invalid character data."
				Status.TextColor3 = Colors.Red
				return
			end

			Data = Result
			Section = "Ability"
			CurrentBranch = "Main"
			SelectedNodeId = nil
			SelectedPassive = 1

			Refresh()
		end)

		AddDataButton("CLEAR IMPORT BOX", function()
			ImportBox.Text = ""
			Status.Text = ""
		end)
	end

	RenderExport = function()
		Clear(DataScroll)

		AddPageLabel("EXPORT CHARACTER")

		local Info = Label(
			DataScroll,
			"Generate your character data as JSON. This includes abilities, branches, values, part presets, passives and upgrades.",
			UDim2.new(1, -15, 0, 55)
		)

		Info.TextColor3 = Colors.Muted

		local JSONBox = TextBox(
			DataScroll,
			"",
			UDim2.new(1, -15, 0, 420),
			nil,
			true
		)

		JSONBox.ClearTextOnFocus = false
		JSONBox.TextXAlignment = Enum.TextXAlignment.Left
		JSONBox.TextYAlignment = Enum.TextYAlignment.Top
		JSONBox.Font = Enum.Font.Code
		JSONBox.TextSize = 12

		AddDataButton("GENERATE JSON", function()
			local Success, Result = pcall(function()
				return HttpService:JSONEncode(Data)
			end)

			if Success then
				JSONBox.Text = Result
			else
				JSONBox.Text = "Export failed: " .. tostring(Result)
			end
		end)

		Label(
			DataScroll,
			"Click the JSON box, press CTRL + A, then CTRL + C to copy.",
			UDim2.new(1, -15, 0, 35)
		).TextColor3 = Colors.Muted
	end

	Refresh = function()
		NameBox.Text = Data.Name

		for Name, Object in pairs(Navigation) do
			Object.BackgroundColor3 =
				Name == Section and Colors.Selected or Colors.Button
		end

		local IsGraph =
			Section == "Ability"
			or Section == "AltAbility"
			or Section == "Passives"

		Toolbar.Visible = IsGraph
		NodeCanvas.Visible = IsGraph
		Inspector.Visible = IsGraph
		DataScroll.Visible = not IsGraph

		if IsGraph then
			RenderToolbar()
			RenderGraph()
		elseif Section == "Values" then
			RenderValues()
		elseif Section == "Parts" then
			RenderParts()
		elseif Section == "Upgrades" then
			RenderUpgrades()
		elseif Section == "Import" then
			RenderImport()
		elseif Section == "Export" then
			RenderExport()
		end
	end

	InputChangedConnection = UserInputService.InputChanged:Connect(function(Input)
		if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
			local Difference = Input.Position - Dragging.Start

			Dragging.Node.X = math.max(
				0,
				Dragging.OriginalX + Difference.X
			)

			Dragging.Node.Y = math.max(
				0,
				Dragging.OriginalY + Difference.Y
			)

			Dragging.Card.Position = UDim2.fromOffset(
				Dragging.Node.X,
				Dragging.Node.Y
			)

			local Graph = GetGraph()

			if Graph then
				RedrawLines(Graph)
			end
		end
	end)

	InputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			Dragging = nil
		end
	end)

	CloseButton.Activated:Connect(function()
		if InputChangedConnection then
			InputChangedConnection:Disconnect()
		end

		if InputEndedConnection then
			InputEndedConnection:Disconnect()
		end

		Gui:Destroy()
	end)

	local Sections = {
		{"Ability", "E ABILITY"},
		{"AltAbility", "R ABILITY"},
		{"Passives", "PASSIVES"},
		{"Values", "CUSTOM VALUES"},
		{"Parts", "PART VALUES"},
		{"Upgrades", "UPGRADE SHOP"},
		{"Import", "IMPORT"},
		{"Export", "EXPORT"}
	}

	for _, Entry in ipairs(Sections) do
		local SectionName = Entry[1]
		local DisplayName = Entry[2]

		Navigation[SectionName] = Button(
			Sidebar,
			DisplayName,
			UDim2.new(1, 0, 0, 42),
			nil,
			function()
				Section = SectionName
				CurrentBranch = "Main"
				SelectedNodeId = nil

				Refresh()
			end
		)
	end

	Refresh()
end

local function CreateLoader()
	local Gui = Create("ScreenGui", Player:WaitForChild("PlayerGui"), {
		Name = "CharacterLoader",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 50
	})

	local Main = Create("Frame", Gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(760, 590),
		BackgroundColor3 = Colors.Background
	})

	Round(Main, 12)
	Stroke(Main, Colors.Button, 2)

	local Title = Label(
		Main,
		"CUSTOM CHARACTER LOADER",
		UDim2.new(1, -90, 0, 45),
		UDim2.fromOffset(20, 10)
	)

	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 20

	local CloseButton = Button(
		Main,
		"X",
		UDim2.fromOffset(35, 35),
		UDim2.new(1, -50, 0, 12),
		function()
			Gui:Destroy()
		end
	)

	CloseButton.BackgroundColor3 = Colors.Red

	local ImportPanel = Create("Frame", Main, {
		Position = UDim2.fromOffset(20, 65),
		Size = UDim2.new(1, -40, 1, -85),
		BackgroundTransparency = 1
	})

	Label(
		ImportPanel,
		"Paste your exported character JSON below.",
		UDim2.new(1, 0, 0, 30),
		UDim2.fromOffset(0, 0)
	).TextColor3 = Colors.Muted

	local ImportBox = TextBox(
		ImportPanel,
		"",
		UDim2.new(1, 0, 1, -115),
		UDim2.fromOffset(0, 35),
		true
	)

	ImportBox.TextXAlignment = Enum.TextXAlignment.Left
	ImportBox.TextYAlignment = Enum.TextYAlignment.Top
	ImportBox.Font = Enum.Font.Code
	ImportBox.TextSize = 12
	ImportBox.PlaceholderText = "Paste character JSON here..."

	local Status = Label(
		ImportPanel,
		"",
		UDim2.new(0.65, -5, 0, 38),
		UDim2.new(0, 0, 1, -70)
	)

	Status.TextColor3 = Colors.Red

	local LoadButton = Button(
		ImportPanel,
		"LOAD CHARACTER",
		UDim2.new(0.35, -5, 0, 42),
		UDim2.new(0.65, 5, 1, -72)
	)

	LoadButton.BackgroundColor3 = Colors.Selected

	local ShopOpen = false
	local ShopGui = nil

	local function CloseShop()
		ShopOpen = false

		if ShopGui then
			ShopGui:Destroy()
			ShopGui = nil
		end
	end

	local PassiveToken = 0
	local PassiveConnections = {}

	local function StartPassives()
		PassiveToken += 1

		local Token = PassiveToken

		for _, Connection in ipairs(PassiveConnections) do
			Connection:Disconnect()
		end

		table.clear(PassiveConnections)

		if not loadedData then
			return
		end

		for _, Passive in ipairs(loadedData.PassiveAbilities) do
			local Trigger = Passive.Trigger or "OnLoad"
			local Graph = Passive.Graph

			if Trigger == "OnLoad" then
				task.spawn(function()
					ExecuteGraph(Graph, {Parts = {}})
				end)

			elseif Trigger == "EverySecond" then
				task.spawn(function()
					while Token == PassiveToken and loadedCharacter do
						task.wait(1)

						if Token ~= PassiveToken then
							break
						end

						ExecuteGraph(Graph, {Parts = {}})
					end
				end)

			elseif Trigger == "OnHealthChanged" then
				local Character = Player.Character
				local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

				if Humanoid then
					local Debounce = false

					local Connection = Humanoid.HealthChanged:Connect(function()
						if Debounce then
							return
						end

						Debounce = true

						task.spawn(function()
							ExecuteGraph(Graph, {Parts = {}})

							task.wait(0.3)

							Debounce = false
						end)
					end)

					table.insert(PassiveConnections, Connection)
				end
			end
		end
	end

	local function GetCurrency()
		if not loadedData then
			return nil
		end

		local CurrencyName = loadedData.CurrencyName or "Coins"

		local Leaderstats = Player:FindFirstChild("leaderstats")
		local CurrencyObject = Leaderstats and Leaderstats:FindFirstChild(CurrencyName)

		if CurrencyObject and (
			CurrencyObject:IsA("IntValue")
			or CurrencyObject:IsA("NumberValue")
		) then
			return CurrencyObject.Value, function(NewAmount)
				CurrencyObject.Value = NewAmount
			end
		end

		if activeValues[CurrencyName] ~= nil then
			return tonumber(activeValues[CurrencyName]) or 0, function(NewAmount)
				activeValues[CurrencyName] = NewAmount
			end
		end

		return nil
	end

	local function ApplyUpgrade(Upgrade)
		for Key, Value in pairs(Upgrade.Changes or {}) do
			if type(Value) == "number" then
				activeValues[Key] =
					(tonumber(activeValues[Key]) or 0) + Value
			else
				activeValues[Key] = Value
			end
		end
	end

	local function OpenUpgradeShop()
		if not loadedCharacter or not loadedData or ShopOpen then
			return false
		end

		ShopOpen = true

		local PurchasedThisShop = false

		ShopGui = Create("ScreenGui", Player:WaitForChild("PlayerGui"), {
			Name = "CustomUpgradeShop",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			DisplayOrder = 60
		})

		local Shop = Create("Frame", ShopGui, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(700, 520),
			BackgroundColor3 = Colors.Background
		})

		Round(Shop, 12)
		Stroke(Shop, Colors.Selected, 2)

		local ShopTitle = Label(
			Shop,
			"UPGRADE SHOP",
			UDim2.new(1, -80, 0, 40),
			UDim2.fromOffset(18, 10)
		)

		ShopTitle.Font = Enum.Font.GothamBold
		ShopTitle.TextSize = 20

		local CloseShopButton = Button(
			Shop,
			"X",
			UDim2.fromOffset(35, 32),
			UDim2.new(1, -47, 0, 12),
			CloseShop
		)

		CloseShopButton.BackgroundColor3 = Colors.Red

		local CurrencyLabel = Label(
			Shop,
			"",
			UDim2.new(1, -30, 0, 28),
			UDim2.fromOffset(18, 52)
		)

		CurrencyLabel.TextColor3 = Colors.Green

		local CurrentCurrency = GetCurrency()

		if CurrentCurrency ~= nil then
			CurrencyLabel.Text =
				(loadedData.CurrencyName or "Coins") .. ": " .. tostring(CurrentCurrency)
		else
			CurrencyLabel.Text =
				"Currency unavailable: " .. (loadedData.CurrencyName or "Coins")
		end

		local StatusLabel = Label(
			Shop,
			"",
			UDim2.new(1, -30, 0, 25),
			UDim2.fromOffset(18, 80)
		)

		StatusLabel.TextColor3 = Colors.Red

		local List = Create("ScrollingFrame", Shop, {
			Position = UDim2.fromOffset(15, 115),
			Size = UDim2.new(1, -30, 1, -130),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 5,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new()
		})

		Create("UIListLayout", List, {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder
		})

		Create("UIPadding", List, {
			PaddingBottom = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 5)
		})

		if #loadedData.Upgrades == 0 then
			local Empty = Label(
				List,
				"No upgrades are available.",
				UDim2.new(1, -10, 0, 55)
			)

			Empty.TextColor3 = Colors.Muted
		end

		for _, Upgrade in ipairs(loadedData.Upgrades) do
			local Card = Create("Frame", List, {
				Size = UDim2.new(1, -10, 0, 125),
				BackgroundColor3 = Colors.Panel
			})

			Round(Card, 8)
			Stroke(Card)

			local Image = Create("ImageLabel", Card, {
				Position = UDim2.fromOffset(10, 12),
				Size = UDim2.fromOffset(100, 100),
				BackgroundColor3 = Colors.Secondary,
				Image = AssetId(Upgrade.Image),
				ScaleType = Enum.ScaleType.Fit
			})

			Round(Image, 7)

			local Name = Label(
				Card,
				Upgrade.Name or "Upgrade",
				UDim2.new(1, -290, 0, 28),
				UDim2.fromOffset(122, 10)
			)

			Name.Font = Enum.Font.GothamBold
			Name.TextSize = 16

			local Description = Label(
				Card,
				Upgrade.Description or "",
				UDim2.new(1, -290, 0, 45),
				UDim2.fromOffset(122, 41)
			)

			Description.TextColor3 = Colors.Muted
			Description.TextSize = 12

			local Cost = Label(
				Card,
				"Cost: " .. tostring(Upgrade.Cost or 0),
				UDim2.new(1, -290, 0, 25),
				UDim2.fromOffset(122, 88)
			)

			Cost.TextColor3 = Colors.Green

			local BuyButton = Button(
				Card,
				"PURCHASE",
				UDim2.fromOffset(135, 38),
				UDim2.new(1, -145, 0.5, -19)
			)

			BuyButton.BackgroundColor3 = Colors.Selected

			BuyButton.Activated:Connect(function()
				if PurchasedThisShop or not ShopOpen then
					return
				end

				local Price = math.max(
					0,
					tonumber(Upgrade.Cost) or 0
				)

				local Currency, SetCurrency = GetCurrency()

				if Price > 0 then
					if Currency == nil then
						StatusLabel.Text = "Required currency is unavailable."
						return
					end

					if Currency < Price then
						StatusLabel.Text = "Not enough currency."
						return
					end

					SetCurrency(Currency - Price)
				end

				PurchasedThisShop = true

				ApplyUpgrade(Upgrade)

				CloseShop()
			end)
		end

		return true
	end

	Upgrades = function()
		if not loadedCharacter then
			return false
		end

		return OpenUpgradeShop()
	end

	EnableRSpecial = function()
		return false
	end

	_G.Upgrades = Upgrades
	_G.EnableRSpecial = EnableRSpecial

	_G.CustomCharacter = {
		Upgrades = Upgrades,
		EnableRSpecial = EnableRSpecial,

		GetData = function()
			return loadedData
		end,

		GetValues = function()
			return activeValues
		end
	}

	LoadButton.Activated:Connect(function()
		local Success, Result = pcall(function()
			return HttpService:JSONDecode(ImportBox.Text)
		end)

		if not Success or not NormalizeData(Result) then
			Status.Text = "Invalid character JSON."
			return
		end

		loadedData = Result
		activeValues = table.clone(loadedData.Values)

		loadedCharacter = true

		Gui:Destroy()

		task.spawn(StartPassives)
	end)

	Player.CharacterAdded:Connect(function()
		if loadedCharacter then
			task.wait(0.5)
			StartPassives()
		end
	end)
end

if game.GameId == BUILDER_ID or game.PlaceId == BUILDER_ID then
	CreateBuilder()

elseif game.GameId == LOADER_ID or game.PlaceId == LOADER_ID then
	CreateLoader()

	UserInputService.InputBegan:Connect(function(Input, GameProcessed)
		if GameProcessed or UserInputService:GetFocusedTextBox() then
			return
		end

		if not loadedCharacter or not loadedData then
			return
		end

		if Input.KeyCode == Enum.KeyCode.E then
			if AbilityBusy then
				return
			end

			AbilityBusy = true

			task.spawn(function()
				local Success, Error = pcall(function()
					ExecuteGraph(
						loadedData.Ability,
						{Parts = {}},
						Enum.KeyCode.E,
						loadedData.Ability
					)
				end)

				if not Success then
					warn("Ability error:", Error)
				end

				AbilityBusy = false
			end)
		end
	end)
end

if game.PlaceId == LOADER_ID then
	game.ReplicatedStorage.UpgradeFolder.Upgrades.ChildAdded:Connect(function(childaddedboisssss)
        if childaddedboisssss.Name == "NinjaBelt" then
        	EnableRSpecial()
        end
    end)

    while true do
    	wait(task.random(180, 320))
        Upgrades()
    end
endlocal Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer

local BUILDER_ID = 129279692364812
local LOADER_ID = 100588763114828

if game.GameId ~= BUILDER_ID and game.PlaceId ~= BUILDER_ID
	and game.GameId ~= LOADER_ID and game.PlaceId ~= LOADER_ID then
	return
end

local Colors = {
	Background = Color3.fromRGB(17, 18, 24),
	Panel = Color3.fromRGB(25, 27, 35),
	Secondary = Color3.fromRGB(35, 38, 48),
	Button = Color3.fromRGB(46, 50, 64),
	Selected = Color3.fromRGB(105, 95, 255),
	Text = Color3.fromRGB(240, 240, 245),
	Muted = Color3.fromRGB(155, 158, 175),
	Green = Color3.fromRGB(75, 190, 125),
	Red = Color3.fromRGB(220, 85, 85)
}

local DirectionOptions = {
	"Forward",
	"Backward",
	"Left",
	"Right",
	"Up",
	"Down",
	"ForwardLeft",
	"ForwardRight",
	"BackwardLeft",
	"BackwardRight",
	"ThroughCamera"
}

local function Create(Class, Parent, Properties)
	local Object = Instance.new(Class)

	for Property, Value in pairs(Properties or {}) do
		Object[Property] = Value
	end

	Object.Parent = Parent

	return Object
end

local function Round(Object, Radius)
	Create("UICorner", Object, {
		CornerRadius = UDim.new(0, Radius or 8)
	})
end

local function Stroke(Object, Color, Thickness)
	Create("UIStroke", Object, {
		Color = Color or Colors.Button,
		Thickness = Thickness or 1,
		Transparency = 0.2
	})
end

local function Label(Parent, Text, Size, Position)
	return Create("TextLabel", Parent, {
		BackgroundTransparency = 1,
		Position = Position or UDim2.new(),
		Size = Size or UDim2.new(1, 0, 0, 30),
		Text = Text,
		TextColor3 = Colors.Text,
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true
	})
end

local function Button(Parent, Text, Size, Position, Callback)
	local Object = Create("TextButton", Parent, {
		BackgroundColor3 = Colors.Button,
		Position = Position or UDim2.new(),
		Size = Size or UDim2.fromOffset(120, 35),
		Text = Text,
		TextColor3 = Colors.Text,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = true
	})

	Round(Object, 7)

	if Callback then
		Object.Activated:Connect(Callback)
	end

	return Object
end

local function TextBox(Parent, Text, Size, Position, MultiLine)
	local Object = Create("TextBox", Parent, {
		BackgroundColor3 = Colors.Secondary,
		Position = Position or UDim2.new(),
		Size = Size or UDim2.fromOffset(200, 32),
		Text = Text or "",
		TextColor3 = Colors.Text,
		PlaceholderColor3 = Colors.Muted,
		PlaceholderText = "Enter a value...",
		TextSize = 13,
		Font = Enum.Font.Gotham,
		ClearTextOnFocus = false,
		MultiLine = MultiLine or false,
		TextWrapped = MultiLine or false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = MultiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
	})

	Round(Object, 6)

	return Object
end

local function Clear(Parent)
	for _, Child in ipairs(Parent:GetChildren()) do
		if not Child:IsA("UIListLayout")
			and not Child:IsA("UIPadding")
			and not Child:IsA("UIGridLayout") then

			Child:Destroy()
		end
	end
end

local function AssetId(Value)
	Value = tostring(Value or "")

	if Value == "" then
		return ""
	end

	if tonumber(Value) then
		return "rbxassetid://" .. Value
	end

	return Value
end

local function ParseVector(Text)
	local Numbers = {}

	for Number in string.gmatch(tostring(Text or ""), "-?[%d%.]+") do
		table.insert(Numbers, tonumber(Number) or 0)
	end

	return Vector3.new(
		Numbers[1] or 0,
		Numbers[2] or 0,
		Numbers[3] or 0
	)
end

local function NewGraph()
	return {
		StartNodeId = "",
		Nodes = {},
		Branches = {}
	}
end

local function DirectionVector(Direction, Root)
	local Forward = Root.CFrame.LookVector
	local Right = Root.CFrame.RightVector

	if Direction == "Forward" then
		return Forward
	elseif Direction == "Backward" then
		return -Forward
	elseif Direction == "Left" then
		return -Right
	elseif Direction == "Right" then
		return Right
	elseif Direction == "Up" then
		return Vector3.new(0, 1, 0)
	elseif Direction == "Down" then
		return Vector3.new(0, -1, 0)
	elseif Direction == "ForwardLeft" then
		return (Forward - Right).Unit
	elseif Direction == "ForwardRight" then
		return (Forward + Right).Unit
	elseif Direction == "BackwardLeft" then
		return (-Forward - Right).Unit
	elseif Direction == "BackwardRight" then
		return (-Forward + Right).Unit
	elseif Direction == "ThroughCamera" then
		local Camera = workspace.CurrentCamera

		if Camera then
			return Camera.CFrame.LookVector
		end

		return Forward
	end

	return Forward
end

local function NormalizeGraph(Graph)
	if type(Graph) ~= "table" then
		return NewGraph()
	end

	if type(Graph.Nodes) ~= "table" then
		Graph.Nodes = {}
	end

	if type(Graph.Branches) ~= "table" then
		Graph.Branches = {}
	end

	Graph.StartNodeId = Graph.StartNodeId or ""

	for Index, Node in ipairs(Graph.Nodes) do
		if type(Node) == "table" then
			Node.Id = tostring(Node.Id or ("Node" .. Index))
			Node.Type = Node.Type or "Wait"
			Node.NextNodeId = Node.NextNodeId or ""
		end
	end

	for Name, Branch in pairs(Graph.Branches) do
		if type(Branch) == "table" then
			NormalizeGraph(Branch)
		else
			Graph.Branches[Name] = nil
		end
	end

	return Graph
end

local function NormalizeData(Data)
	if type(Data) ~= "table" then
		return false
	end

	Data.Version = Data.Version or 3
	Data.Name = Data.Name or "Custom Class"
	Data.Description = Data.Description or ""
	Data.CurrencyName = Data.CurrencyName or "Coins"

	if type(Data.Values) ~= "table" then
		Data.Values = {}
	end

	if type(Data.Parts) ~= "table" then
		Data.Parts = {}
	end

	Data.Ability = NormalizeGraph(Data.Ability)
	Data.AltAbility = NormalizeGraph(Data.AltAbility)

	if type(Data.PassiveAbilities) ~= "table" then
		Data.PassiveAbilities = {}
	end

	if type(Data.Upgrades) ~= "table" then
		Data.Upgrades = {}
	end

	for _, Passive in ipairs(Data.PassiveAbilities) do
		if type(Passive) == "table" then
			Passive.Name = Passive.Name or "Passive"
			Passive.Trigger = Passive.Trigger or "OnLoad"
			Passive.Graph = NormalizeGraph(Passive.Graph)
		end
	end

	for _, Upgrade in ipairs(Data.Upgrades) do
		if type(Upgrade) == "table" then
			Upgrade.Name = Upgrade.Name or "Upgrade"
			Upgrade.Description = Upgrade.Description or ""
			Upgrade.Image = Upgrade.Image or ""
			Upgrade.Cost = math.max(0, tonumber(Upgrade.Cost) or 0)

			if type(Upgrade.Changes) ~= "table" then
				Upgrade.Changes = {}
			end
		end
	end

	for _, PartData in ipairs(Data.Parts) do
		if type(PartData) == "table" then
			PartData.Name = PartData.Name or "Part"
			PartData.Size = PartData.Size or "4,1,4"
			PartData.Offset = PartData.Offset or "0,0,-5"
			PartData.Color = PartData.Color or "130,120,255"
			PartData.Transparency = tonumber(PartData.Transparency) or 0
			PartData.Material = PartData.Material or "Neon"
			PartData.Anchored = PartData.Anchored ~= false
			PartData.CanCollide = PartData.CanCollide == true
			PartData.Lifetime = tonumber(PartData.Lifetime) or 0
			PartData.MeshId = PartData.MeshId or ""
		end
	end

	return true
end

local loadedData = nil
local activeValues = {}
local loadedCharacter = false

local Upgrades
local EnableRSpecial

local AbilityBusy = false

local function ExecuteNode(Node, Context)
	local Character = Player.Character

	if not Character then
		return
	end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local Root = Character:FindFirstChild("HumanoidRootPart")

	if not Humanoid or not Root then
		return
	end

	local Type = Node.Type

	if Type == "Move" then
		local Direction = DirectionVector(Node.Direction or "Forward", Root)
		local Distance = math.clamp(tonumber(Node.Distance) or 20, -300, 300)
		local Duration = math.clamp(tonumber(Node.Duration) or 0.25, 0.05, 15)

		local Tween = TweenService:Create(
			Root,
			TweenInfo.new(
				Duration,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),
			{
				CFrame = Root.CFrame + Direction * Distance
			}
		)

		Tween:Play()
		Tween.Completed:Wait()

	elseif Type == "Wait" then
		task.wait(math.clamp(tonumber(Node.Duration) or 1, 0, 60))

	elseif Type == "SetValue" then
		if Node.Editable == false then
			return
		end

		local Key = Node.Key or "Power"
		local Amount = tonumber(Node.Amount) or 1
		local Operation = Node.Operation or "Add"

		local Current = tonumber(activeValues[Key]) or 0

		if Operation == "Add" then
			activeValues[Key] = Current + Amount
		elseif Operation == "Multiply" then
			activeValues[Key] = Current * Amount
		elseif Operation == "Set" then
			activeValues[Key] = Amount
		end

	elseif Type == "Particle" then
		local Attachment = Instance.new("Attachment")
		Attachment.Parent = Root

		local Emitter = Instance.new("ParticleEmitter")
		Emitter.Texture = AssetId(Node.TextureId)
		Emitter.Rate = 0
		Emitter.Lifetime = NumberRange.new(0.5, 1.2)
		Emitter.Speed = NumberRange.new(5, 12)
		Emitter.SpreadAngle = Vector2.new(180, 180)
		Emitter.Parent = Attachment

		Emitter:Emit(
			math.clamp(tonumber(Node.EmitCount) or 25, 1, 200)
		)

		Debris:AddItem(
			Attachment,
			math.clamp(tonumber(Node.Duration) or 2, 0.1, 15)
		)

	elseif Type == "Afterimage" then
		local Duration = math.clamp(tonumber(Node.Duration) or 1, 0.1, 5)
		local Interval = math.clamp(tonumber(Node.Interval) or 0.12, 0.04, 1)
		local Transparency = math.clamp(tonumber(Node.Transparency) or 0.5, 0, 1)

		local StartTime = os.clock()

		while os.clock() - StartTime < Duration do
			if not Player.Character then
				break
			end

			for _, Part in ipairs(Player.Character:GetDescendants()) do
				if Part:IsA("BasePart") then
					local Success, Clone = pcall(function()
						return Part:Clone()
					end)

					if Success and Clone then
						for _, Child in ipairs(Clone:GetChildren()) do
							if not Child:IsA("SpecialMesh")
								and not Child:IsA("Decal")
								and not Child:IsA("Texture")
								and not Child:IsA("SurfaceAppearance") then

								Child:Destroy()
							end
						end

						Clone.Anchored = true
						Clone.CanCollide = false
						Clone.CanTouch = false
						Clone.CanQuery = false
						Clone.Massless = true
						Clone.Transparency = math.max(
							Transparency,
							Part.Transparency
						)

						Clone.CFrame = Part.CFrame
						Clone.Parent = workspace

						TweenService:Create(
							Clone,
							TweenInfo.new(0.5),
							{
								Transparency = 1
							}
						):Play()

						Debris:AddItem(Clone, 0.6)
					end
				end
			end

			task.wait(Interval)
		end

	elseif Type == "Shockwave" then
		local Size = math.clamp(tonumber(Node.Size) or 12, 1, 150)
		local Duration = math.clamp(tonumber(Node.Duration) or 0.4, 0.05, 5)

		local Wave = Instance.new("Part")
		Wave.Name = "CustomShockwave"
		Wave.Anchored = true
		Wave.CanCollide = false
		Wave.CanTouch = false
		Wave.CanQuery = false
		Wave.Material = Enum.Material.Neon
		Wave.Color = Color3.fromRGB(130, 120, 255)
		Wave.Transparency = 0.25
		Wave.Shape = Enum.PartType.Cylinder
		Wave.Size = Vector3.new(0.25, 1, 1)
		Wave.CFrame = Root.CFrame * CFrame.Angles(0, 0, math.rad(90))
		Wave.Parent = workspace

		if Node.MeshId and Node.MeshId ~= "" then
			local Mesh = Instance.new("SpecialMesh")
			Mesh.MeshType = Enum.MeshType.FileMesh
			Mesh.MeshId = AssetId(Node.MeshId)
			Mesh.Scale = Vector3.new(0.15, 1, 1)
			Mesh.Parent = Wave

			TweenService:Create(
				Mesh,
				TweenInfo.new(
					Duration,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				),
				{
					Scale = Vector3.new(0.15, Size, Size)
				}
			):Play()
		else
			TweenService:Create(
				Wave,
				TweenInfo.new(
					Duration,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				),
				{
					Size = Vector3.new(0.25, Size, Size),
					Transparency = 1
				}
			):Play()
		end

		Debris:AddItem(Wave, Duration + 0.2)

	elseif Type == "Part" then
		local Preset

		for _, PartData in ipairs(loadedData and loadedData.Parts or {}) do
			if PartData.Name == Node.Preset then
				Preset = PartData
				break
			end
		end

		if not Preset then
			warn("Part preset not found:", Node.Preset)
			return
		end

		local NewPart = Instance.new("Part")
		NewPart.Name = Preset.Name
		NewPart.Size = ParseVector(Preset.Size)
		NewPart.Size = Vector3.new(
			math.max(0.1, NewPart.Size.X),
			math.max(0.1, NewPart.Size.Y),
			math.max(0.1, NewPart.Size.Z)
		)

		local RGB = ParseVector(Preset.Color)

		NewPart.Color = Color3.fromRGB(
			math.clamp(RGB.X, 0, 255),
			math.clamp(RGB.Y, 0, 255),
			math.clamp(RGB.Z, 0, 255)
		)

		NewPart.Transparency = math.clamp(
			tonumber(Preset.Transparency) or 0,
			0,
			1
		)

		NewPart.Anchored = Preset.Anchored == true
		NewPart.CanCollide = Preset.CanCollide == true
		NewPart.CanTouch = true
		NewPart.CanQuery = true

		local Material = Enum.Material[Preset.Material]

		if Material then
			NewPart.Material = Material
		end

		NewPart.CFrame = Root.CFrame * CFrame.new(
			ParseVector(Preset.Offset)
		)

		if Preset.MeshId and Preset.MeshId ~= "" then
			local Mesh = Instance.new("SpecialMesh")
			Mesh.MeshType = Enum.MeshType.FileMesh
			Mesh.MeshId = AssetId(Preset.MeshId)
			Mesh.Parent = NewPart
		end

		NewPart.Parent = workspace

		local StorageName = Node.StoreAs

		if not StorageName or StorageName == "" then
			StorageName = Preset.Name
		end

		Context.Parts[StorageName] = NewPart
		Context.Parts[Preset.Name] = NewPart

		local Lifetime = tonumber(Node.Lifetime)

		if Lifetime == nil or Lifetime <= 0 then
			Lifetime = tonumber(Preset.Lifetime) or 0
		end

		if Lifetime > 0 then
			Debris:AddItem(NewPart, math.clamp(Lifetime, 0.1, 300))
		end

	elseif Type == "Teleport" then
		local Mode = Node.Mode or "Offset"

		if Mode == "SavedPart" then
			local Target = Context.Parts[Node.TargetPart]

			if Target and Target.Parent then
				Root.CFrame = Target.CFrame * CFrame.new(
					0,
					Target.Size.Y / 2 + 3,
					0
				)
			else
				warn("Teleport target part not found:", Node.TargetPart)
			end
		else
			local Direction = DirectionVector(
				Node.Direction or "Forward",
				Root
			)

			local Distance = math.clamp(
				tonumber(Node.Distance) or 10,
				-300,
				300
			)

			Root.CFrame = Root.CFrame + Direction * Distance
		end

	elseif Type == "Rope" then
		local Target = Context.Parts[Node.TargetPart]

		if not Target or not Target.Parent then
			warn("Rope target part not found:", Node.TargetPart)
			return
		end

		local Duration = math.clamp(
			tonumber(Node.Duration) or 3,
			0.1,
			120
		)

		local Attachment0 = Instance.new("Attachment")
		Attachment0.Parent = Root

		local Attachment1 = Instance.new("Attachment")
		Attachment1.Parent = Target

		local Rope = Instance.new("RopeConstraint")
		Rope.Attachment0 = Attachment0
		Rope.Attachment1 = Attachment1
		Rope.Visible = true
		Rope.Thickness = 0.08
		Rope.Length = math.clamp(
			tonumber(Node.Length) or (Root.Position - Target.Position).Magnitude,
			1,
			300
		)
		Rope.Parent = Root

		Debris:AddItem(Rope, Duration)
		Debris:AddItem(Attachment0, Duration)
		Debris:AddItem(Attachment1, Duration)
	end
end

local function ExecuteGraph(Graph, Context, InputKey, BranchRoot)
	if type(Graph) ~= "table" or type(Graph.Nodes) ~= "table" then
		return
	end

	BranchRoot = BranchRoot or Graph

	Context = Context or {
		Parts = {}
	}

	Context.Parts = Context.Parts or {}

	local NodeMap = {}

	for _, Node in ipairs(Graph.Nodes) do
		if type(Node) == "table" and Node.Id then
			NodeMap[Node.Id] = Node
		end
	end

	local CurrentId = Graph.StartNodeId

	if not CurrentId or CurrentId == "" then
		CurrentId = Graph.Nodes[1] and Graph.Nodes[1].Id
	end

	local History = {}
	local Steps = 0

	local function SwitchBranch(BranchName)
		if not BranchName or BranchName == "" then
			return false
		end

		local TargetGraph = BranchRoot.Branches
			and BranchRoot.Branches[BranchName]

		if not TargetGraph then
			warn("Branch not found:", BranchName)
			return false
		end

		ExecuteGraph(TargetGraph, Context, InputKey, BranchRoot)

		return true
	end

	while CurrentId and CurrentId ~= "" and Steps < 500 do
		local Node = NodeMap[CurrentId]

		if not Node then
			break
		end

		Steps += 1

		if Node.Type == "Brancher" then
			SwitchBranch(Node.Branch)
			return

		elseif Node.Type == "Hold" then
			local Duration = math.clamp(
				tonumber(Node.Duration) or 1,
				0.05,
				30
			)

			local Held = false
			local Started = os.clock()

			if InputKey then
				Held = true

				while os.clock() - Started < Duration do
					if not UserInputService:IsKeyDown(InputKey) then
						Held = false
						break
					end

					task.wait(0.03)
				end
			end

			if Held then
				SwitchBranch(Node.HeldBranch)
			else
				SwitchBranch(Node.ReleasedBranch)
			end

			return

		elseif Node.Type == "Tag" and Node.Mode == "Get" then
			local TagName = tostring(Node.TagName or "Tagged")
			local TagValue = Player:GetAttribute("CustomTag_" .. TagName)

			if TagValue == true then
				if SwitchBranch(Node.SuccessBranch) then
					return
				end
			else
				if SwitchBranch(Node.FailureBranch) then
					return
				end
			end

		else
			if Node.Type == "Tag" and Node.Mode == "Set" then
				local TagName = tostring(Node.TagName or "Tagged")
				Player:SetAttribute("CustomTag_" .. TagName, true)
			else
				if Node.Type == "Loop" then
					local NodeCount = math.clamp(
						math.floor(tonumber(Node.NodeCount) or 1),
						1,
						25
					)

					local Repeats = math.clamp(
						math.floor(tonumber(Node.Repeats) or 2),
						1,
						20
					)

					local StartIndex = math.max(
						1,
						#History - NodeCount + 1
					)

					local PreviousNodes = {}

					for Index = StartIndex, #History do
						table.insert(PreviousNodes, History[Index])
					end

					for RepeatIndex = 1, Repeats do
						for _, PreviousNode in ipairs(PreviousNodes) do
							if PreviousNode.Type ~= "Loop"
								and PreviousNode.Type ~= "Brancher"
								and PreviousNode.Type ~= "Hold"
								and PreviousNode.Type ~= "Tag" then

								Steps += 1

								if Steps >= 500 then
									break
								end

								ExecuteNode(PreviousNode, Context)
							end
						end

						if Steps >= 500 then
							break
						end
					end
				else
					ExecuteNode(Node, Context)
				end
			end

			if Node.Type ~= "Loop" then
				table.insert(History, Node)
			end
		end

		CurrentId = Node.NextNodeId
	end
end

local function CreateBuilder()
	local Data = {
		Version = 3,
		Name = "Custom Class",
		Description = "",
		CurrencyName = "Coins",

		Values = {
			Power = 1,
			Speed = 1,
			Coins = 0
		},

		Parts = {},

		Ability = NewGraph(),
		AltAbility = NewGraph(),

		PassiveAbilities = {},
		Upgrades = {}
	}

	local Gui = Create("ScreenGui", Player:WaitForChild("PlayerGui"), {
		Name = "CharacterBuilder",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 50
	})

	local Main = Create("Frame", Gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1120, 720),
		BackgroundColor3 = Colors.Background
	})

	Round(Main, 12)
	Stroke(Main, Colors.Button, 2)

	local Header = Create("Frame", Main, {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Colors.Panel
	})

	Round(Header, 12)

	local HeaderTitle = Label(
		Header,
		"CHARACTER BUILDER",
		UDim2.fromOffset(210, 45),
		UDim2.fromOffset(18, 5)
	)

	HeaderTitle.Font = Enum.Font.GothamBold

	local NameBox = TextBox(
		Header,
		Data.Name,
		UDim2.fromOffset(240, 34),
		UDim2.new(1, -300, 0, 11)
	)

	NameBox.PlaceholderText = "Character name"

	NameBox.FocusLost:Connect(function()
		if NameBox.Text ~= "" then
			Data.Name = NameBox.Text
		end
	end)

	local CloseButton = Button(
		Header,
		"X",
		UDim2.fromOffset(35, 35),
		UDim2.new(1, -45, 0, 10)
	)

	CloseButton.BackgroundColor3 = Colors.Red

	local Sidebar = Create("Frame", Main, {
		Position = UDim2.fromOffset(0, 56),
		Size = UDim2.new(0, 160, 1, -56),
		BackgroundColor3 = Colors.Panel
	})

	Create("UIListLayout", Sidebar, {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	Create("UIPadding", Sidebar, {
		PaddingTop = UDim.new(0, 15),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10)
	})

	local Editor = Create("Frame", Main, {
		Position = UDim2.fromOffset(160, 56),
		Size = UDim2.new(1, -160, 1, -56),
		BackgroundTransparency = 1
	})

	local Toolbar = Create("ScrollingFrame", Editor, {
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -290, 0, 48),
		BackgroundColor3 = Colors.Panel,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.X,
		CanvasSize = UDim2.fromOffset(1800, 0)
	})

	Create("UIListLayout", Toolbar, {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	Create("UIPadding", Toolbar, {
		PaddingLeft = UDim.new(0, 7),
		PaddingRight = UDim.new(0, 7)
	})

	local NodeCanvas = Create("ScrollingFrame", Editor, {
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, -290, 1, -48),
		BackgroundColor3 = Color3.fromRGB(20, 22, 29),
		BorderSizePixel = 0,
		ScrollBarThickness = 7,
		Active = true,
		CanvasSize = UDim2.fromOffset(1200, 900)
	})

	local Inspector = Create("ScrollingFrame", Editor, {
		Position = UDim2.new(1, -290, 0, 0),
		Size = UDim2.new(0, 290, 1, 0),
		BackgroundColor3 = Colors.Panel,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new()
	})

	Create("UIListLayout", Inspector, {
		Padding = UDim.new(0, 9),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	Create("UIPadding", Inspector, {
		PaddingTop = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 15)
	})

	local DataScroll = Create("ScrollingFrame", Editor, {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(20, 22, 29),
		BorderSizePixel = 0,
		ScrollBarThickness = 7,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Visible = false
	})

	Create("UIListLayout", DataScroll, {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	Create("UIPadding", DataScroll, {
		PaddingTop = UDim.new(0, 15),
		PaddingLeft = UDim.new(0, 15),
		PaddingRight = UDim.new(0, 15),
		PaddingBottom = UDim.new(0, 20)
	})

	local Section = "Ability"
	local CurrentBranch = "Main"
	local SelectedNodeId = nil
	local SelectedPassive = 1
	local Navigation = {}
	local Dragging = nil
	local LinesFrame = nil

	local InputChangedConnection
	local InputEndedConnection

	local RenderGraph
	local RenderToolbar
	local RenderValues
	local RenderParts
	local RenderUpgrades
	local RenderImport
	local RenderExport
	local RenderInspector
	local Refresh

	local function GetAbilityRoot()
		if Section == "Ability" then
			return Data.Ability
		elseif Section == "AltAbility" then
			return Data.AltAbility
		end

		return nil
	end

	local function GetGraph()
		local Root = GetAbilityRoot()

		if Root then
			if CurrentBranch == "Main" then
				return Root
			end

			return Root.Branches[CurrentBranch]
		end

		if Section == "Passives" then
			local Passive = Data.PassiveAbilities[SelectedPassive]

			return Passive and Passive.Graph
		end

		return nil
	end

	local function GetBranchNames()
		local Root = GetAbilityRoot()
		local Names = {}

		if Root then
			for Name in pairs(Root.Branches) do
				table.insert(Names, Name)
			end
		end

		table.sort(Names)

		return Names
	end

	local function AddPageLabel(Text)
		local Object = Label(
			DataScroll,
			Text,
			UDim2.new(1, -10, 0, 35)
		)

		Object.Font = Enum.Font.GothamBold
		Object.TextSize = 19

		return Object
	end

	local function AddDataButton(Text, Callback)
		return Button(
			DataScroll,
			Text,
			UDim2.fromOffset(180, 34),
			nil,
			Callback
		)
	end

	local function NextUniqueBranchName(Root)
		local Number = 1

		while Root.Branches["Branch" .. Number] do
			Number += 1
		end

		return "Branch" .. Number
	end

	RenderInspector = function()
		Clear(Inspector)

		local Graph = GetGraph()
		local Root = GetAbilityRoot()

		if Section == "Passives" then
			local Passive = Data.PassiveAbilities[SelectedPassive]

			if Passive then
				local Heading = Label(
					Inspector,
					"PASSIVE SETTINGS",
					UDim2.new(1, -10, 0, 30)
				)

				Heading.Font = Enum.Font.GothamBold

				Label(
					Inspector,
					"Passive name",
					UDim2.new(1, -10, 0, 18)
				).TextColor3 = Colors.Muted

				local PassiveName = TextBox(
					Inspector,
					Passive.Name,
					UDim2.new(1, -10, 0, 32)
				)

				PassiveName.FocusLost:Connect(function()
					Passive.Name = PassiveName.Text
					RenderToolbar()
				end)

				Label(
					Inspector,
					"Trigger",
					UDim2.new(1, -10, 0, 18)
				).TextColor3 = Colors.Muted

				local Trigger = TextBox(
					Inspector,
					Passive.Trigger or "OnLoad",
					UDim2.new(1, -10, 0, 32)
				)

				Trigger.PlaceholderText = "OnLoad / EverySecond / OnHealthChanged"

				Trigger.FocusLost:Connect(function()
					Passive.Trigger = Trigger.Text
				end)

				Button(
					Inspector,
					"DELETE PASSIVE",
					UDim2.new(1, -10, 0, 32),
					nil,
					function()
						table.remove(Data.PassiveAbilities, SelectedPassive)

						SelectedPassive = math.max(
							1,
							math.min(SelectedPassive, #Data.PassiveAbilities)
						)

						SelectedNodeId = nil

						Refresh()
					end
				).BackgroundColor3 = Colors.Red
			end
		end

		local Node

		if Graph then
			for _, Item in ipairs(Graph.Nodes) do
				if Item.Id == SelectedNodeId then
					Node = Item
					break
				end
			end
		end

		if not Node then
			local Heading = Label(
				Inspector,
				"NODE SETTINGS",
				UDim2.new(1, -10, 0, 30)
			)

			Heading.Font = Enum.Font.GothamBold

			local Info = Label(
				Inspector,
				"Select a node to edit its settings. Connect nodes using NextNodeId.",
				UDim2.new(1, -10, 0, 75)
			)

			Info.TextColor3 = Colors.Muted

			return
		end

		local Heading = Label(
			Inspector,
			Node.Type .. " NODE",
			UDim2.new(1, -10, 0, 30)
		)

		Heading.Font = Enum.Font.GothamBold

		local function AddField(FieldName, Default)
			local FieldLabel = Label(
				Inspector,
				FieldName,
				UDim2.new(1, -10, 0, 18)
			)

			FieldLabel.TextColor3 = Colors.Muted

			local Field = TextBox(
				Inspector,
				tostring(Node[FieldName] or Default or ""),
				UDim2.new(1, -10, 0, 32)
			)

			Field.FocusLost:Connect(function()
				Node[FieldName] = Field.Text

				if FieldName == "NextNodeId" then
					RenderGraph()
				end
			end)

			return Field
		end

		local function AddToggle(FieldName, Options)
			local Current = Node[FieldName]

			if not table.find(Options, Current) then
				Current = Options[1]
			end

			Node[FieldName] = Current

			local Toggle = Button(
				Inspector,
				FieldName .. ": " .. tostring(Current),
				UDim2.new(1, -10, 0, 36),
				nil,
				function()
					local Index = table.find(Options, Node[FieldName]) or 1
					Index += 1

					if Index > #Options then
						Index = 1
					end

					Node[FieldName] = Options[Index]
					RenderInspector()
				end
			)

			Toggle.BackgroundColor3 = Colors.Selected

			return Toggle
		end

		local function AddBranchChoice(FieldName)
			local Names = GetBranchNames()

			local Options = {}

			for _, Name in ipairs(Names) do
				table.insert(Options, Name)
			end

			if #Options == 0 then
				local NoBranches = Label(
					Inspector,
					"Create a branch first using + BRANCH.",
					UDim2.new(1, -10, 0, 35)
				)

				NoBranches.TextColor3 = Colors.Muted

				return
			end

			AddToggle(FieldName, Options)
		end

		local function AddPartChoice(FieldName)
			local Options = {}

			for _, PartData in ipairs(Data.Parts) do
				table.insert(Options, PartData.Name)
			end

			if #Options == 0 then
				local NoParts = Label(
					Inspector,
					"Create a part preset in the PART VALUES section first.",
					UDim2.new(1, -10, 0, 45)
				)

				NoParts.TextColor3 = Colors.Muted

				return
			end

			AddToggle(FieldName, Options)
		end

		AddField("NextNodeId", "")

		if Node.Type == "Move" then
			AddToggle("Direction", DirectionOptions)
			AddField("Distance", "20")
			AddField("Duration", "0.25")

		elseif Node.Type == "Loop" then
			AddField("NodeCount", "1")
			AddField("Repeats", "2")

		elseif Node.Type == "Brancher" then
			AddBranchChoice("Branch")

		elseif Node.Type == "Hold" then
			AddField("Duration", "1")
			AddBranchChoice("HeldBranch")
			AddBranchChoice("ReleasedBranch")

		elseif Node.Type == "Tag" then
			AddToggle("Mode", {"Set", "Get"})
			AddField("TagName", "Tagged")

			if Node.Mode == "Get" then
				AddBranchChoice("SuccessBranch")
				AddBranchChoice("FailureBranch")
			end

		elseif Node.Type == "Part" then
			AddPartChoice("Preset")
			AddField("StoreAs", "Part1")
			AddField("Lifetime", "0")

		elseif Node.Type == "Teleport" then
			AddToggle("Mode", {"Offset", "SavedPart"})

			if Node.Mode == "SavedPart" then
				AddField("TargetPart", "Part1")
			else
				AddToggle("Direction", DirectionOptions)
				AddField("Distance", "10")
			end

		elseif Node.Type == "Rope" then
			AddField("TargetPart", "Part1")
			AddField("Duration", "3")
			AddField("Length", "10")

		elseif Node.Type == "Wait" then
			AddField("Duration", "1")

		elseif Node.Type == "SetValue" then
			local EditableButton = Button(
				Inspector,
				"EDITABLE VALUES: " .. (Node.Editable ~= false and "ON" or "OFF"),
				UDim2.new(1, -10, 0, 36),
				nil,
				function()
					Node.Editable = Node.Editable == false

					RenderInspector()
					RenderGraph()
				end
			)

			EditableButton.BackgroundColor3 =
				Node.Editable ~= false and Colors.Green or Colors.Red

			if Node.Editable ~= false then
				AddField("Key", "Power")
				AddToggle("Operation", {"Add", "Multiply", "Set"})
				AddField("Amount", "1")

				Label(
					Inspector,
					"SELECT CUSTOM VALUE",
					UDim2.new(1, -10, 0, 24)
				).Font = Enum.Font.GothamBold

				local Keys = {}

				for Key in pairs(Data.Values) do
					table.insert(Keys, Key)
				end

				table.sort(Keys)

				for _, Key in ipairs(Keys) do
					local ValueButton = Button(
						Inspector,
						Key .. " = " .. tostring(Data.Values[Key]),
						UDim2.new(1, -10, 0, 30),
						nil,
						function()
							Node.Key = Key
							RenderInspector()
						end
					)

					ValueButton.BackgroundColor3 =
						Node.Key == Key and Colors.Selected or Colors.Button
				end
			end

		else
			local Fields = {
				Particle = {"TextureId", "Duration", "EmitCount"},
				Afterimage = {"Duration", "Interval", "Transparency"},
				Shockwave = {"MeshId", "Size", "Duration"}
			}

			for _, FieldName in ipairs(Fields[Node.Type] or {}) do
				AddField(FieldName)
			end
		end

		Button(
			Inspector,
			"DELETE NODE",
			UDim2.new(1, -10, 0, 35),
			nil,
			function()
				for Index, Item in ipairs(Graph.Nodes) do
					if Item.Id == Node.Id then
						table.remove(Graph.Nodes, Index)
						break
					end
				end

				for _, Item in ipairs(Graph.Nodes) do
					if Item.NextNodeId == Node.Id then
						Item.NextNodeId = ""
					end
				end

				if Graph.StartNodeId == Node.Id then
					Graph.StartNodeId = Graph.Nodes[1]
						and Graph.Nodes[1].Id or ""
				end

				SelectedNodeId = nil

				RenderGraph()
			end
		).BackgroundColor3 = Colors.Red
	end

	local function RedrawLines(Graph)
		if not LinesFrame then
			return
		end

		Clear(LinesFrame)

		local NodeMap = {}

		for _, Node in ipairs(Graph.Nodes) do
			NodeMap[Node.Id] = Node
		end

		for _, Node in ipairs(Graph.Nodes) do
			local Target = NodeMap[Node.NextNodeId]

			if Target then
				local X1 = (Node.X or 30) + 87
				local Y1 = (Node.Y or 30) + 48
				local X2 = (Target.X or 30) + 87
				local Y2 = (Target.Y or 30) + 48

				local Difference = Vector2.new(
					X2 - X1,
					Y2 - Y1
				)

				Create("Frame", LinesFrame, {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromOffset(X1, Y1),
					Size = UDim2.fromOffset(Difference.Magnitude, 3),
					Rotation = math.deg(math.atan2(Difference.Y, Difference.X)),
					BackgroundColor3 = Colors.Selected,
					BorderSizePixel = 0,
					ZIndex = 1
				})
			end
		end
	end

	RenderGraph = function()
		local Graph = GetGraph()

		Clear(NodeCanvas)

		if not Graph then
			LinesFrame = nil

			Label(
				NodeCanvas,
				"Create a passive ability using + PASSIVE.",
				UDim2.fromOffset(400, 50),
				UDim2.fromOffset(30, 30)
			)

			RenderInspector()

			return
		end

		local MaximumX = 800
		local MaximumY = 600

		for _, Node in ipairs(Graph.Nodes) do
			MaximumX = math.max(MaximumX, (Node.X or 30) + 250)
			MaximumY = math.max(MaximumY, (Node.Y or 30) + 180)
		end

		NodeCanvas.CanvasSize = UDim2.fromOffset(MaximumX, MaximumY)

		LinesFrame = Create("Frame", NodeCanvas, {
			Size = UDim2.fromOffset(MaximumX, MaximumY),
			BackgroundTransparency = 1,
			ZIndex = 1
		})

		RedrawLines(Graph)

		for _, Node in ipairs(Graph.Nodes) do
			local IsSelected = SelectedNodeId == Node.Id

			local Card = Create("TextButton", NodeCanvas, {
				Position = UDim2.fromOffset(Node.X or 30, Node.Y or 30),
				Size = UDim2.fromOffset(175, 100),
				BackgroundColor3 = IsSelected and Colors.Selected or Colors.Panel,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 3
			})

			Round(Card, 8)
			Stroke(Card, IsSelected and Colors.Text or Colors.Button, 1)

			local NodeTitle = Label(
				Card,
				Node.Type,
				UDim2.new(1, -15, 0, 27),
				UDim2.fromOffset(9, 5)
			)

			NodeTitle.ZIndex = 4

			local IDLabel = Label(
				Card,
				"ID: " .. Node.Id,
				UDim2.new(1, -15, 0, 20),
				UDim2.fromOffset(9, 33)
			)

			IDLabel.TextColor3 = Colors.Muted
			IDLabel.ZIndex = 4

			local NextLabel = Label(
				Card,
				"Next: " .. (
					Node.NextNodeId ~= "" and tostring(Node.NextNodeId) or "END"
				),
				UDim2.new(1, -15, 0, 25),
				UDim2.fromOffset(9, 57)
			)

			NextLabel.TextColor3 = Colors.Muted
			NextLabel.ZIndex = 4

			Card.Activated:Connect(function()
				SelectedNodeId = Node.Id
				RenderGraph()
			end)

			Card.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					Dragging = {
						Node = Node,
						Card = Card,
						Start = Input.Position,
						OriginalX = Node.X or 30,
						OriginalY = Node.Y or 30
					}
				end
			end)
		end

		RenderInspector()
	end

	local function AddNode(Type)
		local Graph = GetGraph()

		if not Graph then
			return
		end

		local Id = "Node" .. string.sub(
			HttpService:GenerateGUID(false),
			1,
			8
		)

		local Number = #Graph.Nodes + 1

		local Node = {
			Id = Id,
			Type = Type,
			NextNodeId = "",
			X = 35 + ((Number - 1) % 3) * 220,
			Y = 35 + math.floor((Number - 1) / 3) * 150,
			Editable = Type == "SetValue"
		}

		local Defaults = {
			Move = {
				Direction = "Forward",
				Distance = "20",
				Duration = "0.25"
			},

			Wait = {
				Duration = "1"
			},

			SetValue = {
				Key = "Power",
				Operation = "Add",
				Amount = "1"
			},

			Particle = {
				TextureId = "",
				Duration = "2",
				EmitCount = "25"
			},

			Afterimage = {
				Duration = "1",
				Interval = "0.12",
				Transparency = "0.5"
			},

			Shockwave = {
				MeshId = "",
				Size = "12",
				Duration = "0.4"
			},

			Loop = {
				NodeCount = "1",
				Repeats = "2"
			},

			Brancher = {
				Branch = ""
			},

			Hold = {
				Duration = "1",
				HeldBranch = "",
				ReleasedBranch = ""
			},

			Tag = {
				Mode = "Set",
				TagName = "Tagged",
				SuccessBranch = "",
				FailureBranch = ""
			},

			Part = {
				Preset = "",
				StoreAs = "Part1",
				Lifetime = "0"
			},

			Teleport = {
				Mode = "Offset",
				TargetPart = "Part1",
				Direction = "Forward",
				Distance = "10"
			},

			Rope = {
				TargetPart = "Part1",
				Duration = "3",
				Length = "10"
			}
		}

		for Key, Value in pairs(Defaults[Type] or {}) do
			Node[Key] = Value
		end

		local Previous = Graph.Nodes[#Graph.Nodes]

		if Previous then
			if not Previous.NextNodeId or Previous.NextNodeId == "" then
				Previous.NextNodeId = Node.Id
			end
		else
			Graph.StartNodeId = Node.Id
		end

		table.insert(Graph.Nodes, Node)

		SelectedNodeId = Node.Id

		RenderToolbar()
		RenderGraph()
	end

	RenderToolbar = function()
		Clear(Toolbar)

		local function AddToolbarButton(Text, Callback, Selected)
			local Object = Button(
				Toolbar,
				Text,
				UDim2.fromOffset(105, 32),
				nil,
				Callback
			)

			if Selected then
				Object.BackgroundColor3 = Colors.Selected
			end

			return Object
		end

		local Root = GetAbilityRoot()

		if Root then
			AddToolbarButton("+ BRANCH", function()
				local Name = NextUniqueBranchName(Root)

				Root.Branches[Name] = NewGraph()
				CurrentBranch = Name
				SelectedNodeId = nil

				Refresh()
			end)

			AddToolbarButton(
				"MAIN",
				function()
					CurrentBranch = "Main"
					SelectedNodeId = nil
					Refresh()
				end,
				CurrentBranch == "Main"
			)

			for _, Name in ipairs(GetBranchNames()) do
				local BranchName = Name

				AddToolbarButton(
					BranchName,
					function()
						CurrentBranch = BranchName
						SelectedNodeId = nil
						Refresh()
					end,
					CurrentBranch == BranchName
				)
			end

			if CurrentBranch ~= "Main" then
				AddToolbarButton("DELETE BRANCH", function()
					Root.Branches[CurrentBranch] = nil
					CurrentBranch = "Main"
					SelectedNodeId = nil

					Refresh()
				end)
			end
		end

		if Section == "Passives" then
			AddToolbarButton("+ PASSIVE", function()
				table.insert(Data.PassiveAbilities, {
					Name = "Passive " .. (#Data.PassiveAbilities + 1),
					Trigger = "OnLoad",
					Graph = NewGraph()
				})

				SelectedPassive = #Data.PassiveAbilities
				SelectedNodeId = nil

				Refresh()
			end)

			for Index, Passive in ipairs(Data.PassiveAbilities) do
				local PassiveIndex = Index

				AddToolbarButton(
					Passive.Name or ("Passive " .. Index),
					function()
						SelectedPassive = PassiveIndex
						SelectedNodeId = nil

						Refresh()
					end,
					SelectedPassive == PassiveIndex
				)
			end
		end

		local Types = {
			"Move",
			"Wait",
			"SetValue",
			"Particle",
			"Afterimage",
			"Shockwave",
			"Loop",
			"Brancher",
			"Hold",
			"Tag",
			"Part",
			"Teleport",
			"Rope"
		}

		for _, Type in ipairs(Types) do
			AddToolbarButton("+ " .. Type, function()
				AddNode(Type)
			end)
		end
	end

	RenderValues = function()
		Clear(DataScroll)

		AddPageLabel("CUSTOM VALUES")

		local Info = Label(
			DataScroll,
			"Create values that abilities, nodes and upgrades can modify.",
			UDim2.new(1, -15, 0, 38)
		)

		Info.TextColor3 = Colors.Muted

		AddDataButton("+ ADD VALUE", function()
			local Number = 1

			while Data.Values["Value" .. Number] ~= nil do
				Number += 1
			end

			Data.Values["Value" .. Number] = 1

			RenderValues()
		end)

		local Keys = {}

		for Key in pairs(Data.Values) do
			table.insert(Keys, Key)
		end

		table.sort(Keys)

		for _, OriginalKey in ipairs(Keys) do
			local Row = Create("Frame", DataScroll, {
				Size = UDim2.new(1, -15, 0, 48),
				BackgroundColor3 = Colors.Panel
			})

			Round(Row, 7)

			local KeyBox = TextBox(
				Row,
				OriginalKey,
				UDim2.new(0.42, -5, 0, 30),
				UDim2.fromOffset(8, 9)
			)

			local ValueBox = TextBox(
				Row,
				tostring(Data.Values[OriginalKey]),
				UDim2.new(0.32, -5, 0, 30),
				UDim2.new(0.43, 0, 0, 9)
			)

			local Remove = Button(
				Row,
				"X",
				UDim2.new(0.16, -5, 0, 30),
				UDim2.new(0.82, 0, 0, 9),
				function()
					Data.Values[OriginalKey] = nil
					RenderValues()
				end
			)

			Remove.BackgroundColor3 = Colors.Red

			KeyBox.FocusLost:Connect(function()
				local NewKey = KeyBox.Text

				if NewKey ~= "" and NewKey ~= OriginalKey
					and Data.Values[NewKey] == nil then

					local OldValue = Data.Values[OriginalKey]

					Data.Values[OriginalKey] = nil
					Data.Values[NewKey] = OldValue

					RenderValues()
				elseif NewKey ~= OriginalKey then
					RenderValues()
				end
			end)

			ValueBox.FocusLost:Connect(function()
				Data.Values[OriginalKey] = tonumber(ValueBox.Text) or 0
			end)
		end
	end

	RenderParts = function()
		Clear(DataScroll)

		AddPageLabel("PART VALUES")

		local Info = Label(
			DataScroll,
			"Create reusable part presets. Part nodes summon these parts, and Teleport and Rope nodes can reference the spawned parts.",
			UDim2.new(1, -15, 0, 55)
		)

		Info.TextColor3 = Colors.Muted

		AddDataButton("+ ADD PART PRESET", function()
			local Number = #Data.Parts + 1

			table.insert(Data.Parts, {
				Name = "Part" .. Number,
				Size = "4,1,4",
				Offset = "0,0,-5",
				Color = "130,120,255",
				Transparency = 0,
				Material = "Neon",
				Anchored = true,
				CanCollide = false,
				Lifetime = 0,
				MeshId = ""
			})

			RenderParts()
		end)

		for Index, PartData in ipairs(Data.Parts) do
			local PartIndex = Index

			local Card = Create("Frame", DataScroll, {
				Size = UDim2.new(1, -15, 0, 440),
				BackgroundColor3 = Colors.Panel
			})

			Round(Card, 8)
			Stroke(Card)

			local PartTitle = Label(
				Card,
				"PART PRESET " .. Index,
				UDim2.new(1, -110, 0, 27),
				UDim2.fromOffset(10, 8)
			)

			PartTitle.Font = Enum.Font.GothamBold

			local Remove = Button(
				Card,
				"DELETE",
				UDim2.fromOffset(85, 28),
				UDim2.new(1, -95, 0, 7),
				function()
					table.remove(Data.Parts, PartIndex)
					RenderParts()
				end
			)

			Remove.BackgroundColor3 = Colors.Red

			local function AddPartField(FieldName, Y, Default)
				Label(
					Card,
					FieldName,
					UDim2.new(0.27, 0, 0, 28),
					UDim2.fromOffset(10, Y)
				).TextColor3 = Colors.Muted

				local Field = TextBox(
					Card,
					tostring(PartData[FieldName] or Default or ""),
					UDim2.new(0.68, -10, 0, 30),
					UDim2.new(0.29, 0, 0, Y)
				)

				Field.FocusLost:Connect(function()
					if FieldName == "Transparency" or FieldName == "Lifetime" then
						PartData[FieldName] = tonumber(Field.Text) or 0
					else
						PartData[FieldName] = Field.Text
					end
				end)
			end

			AddPartField("Name", 43, "Part")
			AddPartField("Size", 82, "4,1,4")
			AddPartField("Offset", 121, "0,0,-5")
			AddPartField("Color", 160, "130,120,255")
			AddPartField("Transparency", 199, "0")
			AddPartField("Material", 238, "Neon")
			AddPartField("Lifetime", 277, "0")
			AddPartField("MeshId", 316, "")

			local AnchoredButton = Button(
				Card,
				"ANCHORED: " .. (PartData.Anchored and "ON" or "OFF"),
				UDim2.new(0.46, -5, 0, 34),
				UDim2.fromOffset(10, 365),
				function()
					PartData.Anchored = not PartData.Anchored
					RenderParts()
				end
			)

			AnchoredButton.BackgroundColor3 =
				PartData.Anchored and Colors.Green or Colors.Button

			local CollideButton = Button(
				Card,
				"COLLIDE: " .. (PartData.CanCollide and "ON" or "OFF"),
				UDim2.new(0.46, -5, 0, 34),
				UDim2.new(0.52, 0, 0, 365),
				function()
					PartData.CanCollide = not PartData.CanCollide
					RenderParts()
				end
			)

			CollideButton.BackgroundColor3 =
				PartData.CanCollide and Colors.Green or Colors.Button
		end
	end

	RenderUpgrades = function()
		Clear(DataScroll)

		AddPageLabel("UPGRADE SHOP")

		local Info = Label(
			DataScroll,
			"Each upgrade has its own price, image, description and custom value changes.",
			UDim2.new(1, -15, 0, 45)
		)

		Info.TextColor3 = Colors.Muted

		Label(
			DataScroll,
			"Currency value name",
			UDim2.new(1, -15, 0, 20)
		).TextColor3 = Colors.Muted

		local CurrencyBox = TextBox(
			DataScroll,
			Data.CurrencyName,
			UDim2.new(1, -15, 0, 32)
		)

		CurrencyBox.FocusLost:Connect(function()
			if CurrencyBox.Text ~= "" then
				Data.CurrencyName = CurrencyBox.Text
			end
		end)

		AddDataButton("+ ADD UPGRADE", function()
			table.insert(Data.Upgrades, {
				Name = "New Upgrade",
				Description = "",
				Cost = 0,
				Image = "",
				Changes = {
					Power = 1
				}
			})

			RenderUpgrades()
		end)

		for Index, Upgrade in ipairs(Data.Upgrades) do
			local UpgradeIndex = Index

			local Row = Create("Frame", DataScroll, {
				Size = UDim2.new(1, -15, 0, 250),
				BackgroundColor3 = Colors.Panel
			})

			Round(Row, 8)
			Stroke(Row)

			local NameBox = TextBox(
				Row,
				Upgrade.Name or "",
				UDim2.new(0.72, -12, 0, 30),
				UDim2.fromOffset(8, 8)
			)

			local Remove = Button(
				Row,
				"DELETE",
				UDim2.new(0.24, -8, 0, 30),
				UDim2.new(0.76, 0, 0, 8),
				function()
					table.remove(Data.Upgrades, UpgradeIndex)
					RenderUpgrades()
				end
			)

			Remove.BackgroundColor3 = Colors.Red

			local Description = TextBox(
				Row,
				Upgrade.Description or "",
				UDim2.new(1, -16, 0, 30),
				UDim2.fromOffset(8, 47)
			)

			local CostBox = TextBox(
				Row,
				tostring(Upgrade.Cost or 0),
				UDim2.new(0.3, -8, 0, 30),
				UDim2.fromOffset(8, 86)
			)

			local ImageBox = TextBox(
				Row,
				tostring(Upgrade.Image or ""),
				UDim2.new(0.66, -5, 0, 30),
				UDim2.new(0.33, 0, 0, 86)
			)

			Label(
				Row,
				"CUSTOM VALUE CHANGES (JSON)",
				UDim2.new(1, -16, 0, 19),
				UDim2.fromOffset(8, 125)
			).TextColor3 = Colors.Muted

			local ChangesBox = TextBox(
				Row,
				HttpService:JSONEncode(Upgrade.Changes or {}),
				UDim2.new(1, -16, 0, 95),
				UDim2.fromOffset(8, 146),
				true
			)

			ChangesBox.PlaceholderText = '{"Power": 2, "Speed": 1.5}'

			NameBox.FocusLost:Connect(function()
				Upgrade.Name = NameBox.Text
			end)

			Description.FocusLost:Connect(function()
				Upgrade.Description = Description.Text
			end)

			CostBox.FocusLost:Connect(function()
				Upgrade.Cost = math.max(0, tonumber(CostBox.Text) or 0)
			end)

			ImageBox.FocusLost:Connect(function()
				Upgrade.Image = ImageBox.Text
			end)

			ChangesBox.FocusLost:Connect(function()
				local Success, Result = pcall(function()
					return HttpService:JSONDecode(ChangesBox.Text)
				end)

				if Success and type(Result) == "table" then
					Upgrade.Changes = Result
				end
			end)
		end
	end

	RenderImport = function()
		Clear(DataScroll)

		AddPageLabel("IMPORT CHARACTER")

		local Info = Label(
			DataScroll,
			"Paste character JSON exported from the character builder. This will replace the current editor data.",
			UDim2.new(1, -15, 0, 55)
		)

		Info.TextColor3 = Colors.Muted

		local ImportBox = TextBox(
			DataScroll,
			"",
			UDim2.new(1, -15, 0, 350),
			nil,
			true
		)

		ImportBox.Font = Enum.Font.Code
		ImportBox.TextSize = 12
		ImportBox.TextXAlignment = Enum.TextXAlignment.Left
		ImportBox.TextYAlignment = Enum.TextYAlignment.Top
		ImportBox.PlaceholderText = "Paste character JSON here..."

		local Status = Label(
			DataScroll,
			"",
			UDim2.new(1, -15, 0, 35)
		)

		Status.TextColor3 = Colors.Red

		AddDataButton("LOAD CHARACTER DATA", function()
			local Success, Result = pcall(function()
				return HttpService:JSONDecode(ImportBox.Text)
			end)

			if not Success then
				Status.Text = "Invalid JSON."
				Status.TextColor3 = Colors.Red
				return
			end

			if not NormalizeData(Result) then
				Status.Text = "Invalid character data."
				Status.TextColor3 = Colors.Red
				return
			end

			Data = Result
			Section = "Ability"
			CurrentBranch = "Main"
			SelectedNodeId = nil
			SelectedPassive = 1

			Refresh()
		end)

		AddDataButton("CLEAR IMPORT BOX", function()
			ImportBox.Text = ""
			Status.Text = ""
		end)
	end

	RenderExport = function()
		Clear(DataScroll)

		AddPageLabel("EXPORT CHARACTER")

		local Info = Label(
			DataScroll,
			"Generate your character data as JSON. This includes abilities, branches, values, part presets, passives and upgrades.",
			UDim2.new(1, -15, 0, 55)
		)

		Info.TextColor3 = Colors.Muted

		local JSONBox = TextBox(
			DataScroll,
			"",
			UDim2.new(1, -15, 0, 420),
			nil,
			true
		)

		JSONBox.ClearTextOnFocus = false
		JSONBox.TextXAlignment = Enum.TextXAlignment.Left
		JSONBox.TextYAlignment = Enum.TextYAlignment.Top
		JSONBox.Font = Enum.Font.Code
		JSONBox.TextSize = 12

		AddDataButton("GENERATE JSON", function()
			local Success, Result = pcall(function()
				return HttpService:JSONEncode(Data)
			end)

			if Success then
				JSONBox.Text = Result
			else
				JSONBox.Text = "Export failed: " .. tostring(Result)
			end
		end)

		Label(
			DataScroll,
			"Click the JSON box, press CTRL + A, then CTRL + C to copy.",
			UDim2.new(1, -15, 0, 35)
		).TextColor3 = Colors.Muted
	end

	Refresh = function()
		NameBox.Text = Data.Name

		for Name, Object in pairs(Navigation) do
			Object.BackgroundColor3 =
				Name == Section and Colors.Selected or Colors.Button
		end

		local IsGraph =
			Section == "Ability"
			or Section == "AltAbility"
			or Section == "Passives"

		Toolbar.Visible = IsGraph
		NodeCanvas.Visible = IsGraph
		Inspector.Visible = IsGraph
		DataScroll.Visible = not IsGraph

		if IsGraph then
			RenderToolbar()
			RenderGraph()
		elseif Section == "Values" then
			RenderValues()
		elseif Section == "Parts" then
			RenderParts()
		elseif Section == "Upgrades" then
			RenderUpgrades()
		elseif Section == "Import" then
			RenderImport()
		elseif Section == "Export" then
			RenderExport()
		end
	end

	InputChangedConnection = UserInputService.InputChanged:Connect(function(Input)
		if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
			local Difference = Input.Position - Dragging.Start

			Dragging.Node.X = math.max(
				0,
				Dragging.OriginalX + Difference.X
			)

			Dragging.Node.Y = math.max(
				0,
				Dragging.OriginalY + Difference.Y
			)

			Dragging.Card.Position = UDim2.fromOffset(
				Dragging.Node.X,
				Dragging.Node.Y
			)

			local Graph = GetGraph()

			if Graph then
				RedrawLines(Graph)
			end
		end
	end)

	InputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			Dragging = nil
		end
	end)

	CloseButton.Activated:Connect(function()
		if InputChangedConnection then
			InputChangedConnection:Disconnect()
		end

		if InputEndedConnection then
			InputEndedConnection:Disconnect()
		end

		Gui:Destroy()
	end)

	local Sections = {
		{"Ability", "E ABILITY"},
		{"AltAbility", "R ABILITY"},
		{"Passives", "PASSIVES"},
		{"Values", "CUSTOM VALUES"},
		{"Parts", "PART VALUES"},
		{"Upgrades", "UPGRADE SHOP"},
		{"Import", "IMPORT"},
		{"Export", "EXPORT"}
	}

	for _, Entry in ipairs(Sections) do
		local SectionName = Entry[1]
		local DisplayName = Entry[2]

		Navigation[SectionName] = Button(
			Sidebar,
			DisplayName,
			UDim2.new(1, 0, 0, 42),
			nil,
			function()
				Section = SectionName
				CurrentBranch = "Main"
				SelectedNodeId = nil

				Refresh()
			end
		)
	end

	Refresh()
end

local function CreateLoader()
	local Gui = Create("ScreenGui", Player:WaitForChild("PlayerGui"), {
		Name = "CharacterLoader",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 50
	})

	local Main = Create("Frame", Gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(760, 590),
		BackgroundColor3 = Colors.Background
	})

	Round(Main, 12)
	Stroke(Main, Colors.Button, 2)

	local Title = Label(
		Main,
		"CUSTOM CHARACTER LOADER",
		UDim2.new(1, -90, 0, 45),
		UDim2.fromOffset(20, 10)
	)

	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 20

	local CloseButton = Button(
		Main,
		"X",
		UDim2.fromOffset(35, 35),
		UDim2.new(1, -50, 0, 12),
		function()
			Gui:Destroy()
		end
	)

	CloseButton.BackgroundColor3 = Colors.Red

	local ImportPanel = Create("Frame", Main, {
		Position = UDim2.fromOffset(20, 65),
		Size = UDim2.new(1, -40, 1, -85),
		BackgroundTransparency = 1
	})

	Label(
		ImportPanel,
		"Paste your exported character JSON below.",
		UDim2.new(1, 0, 0, 30),
		UDim2.fromOffset(0, 0)
	).TextColor3 = Colors.Muted

	local ImportBox = TextBox(
		ImportPanel,
		"",
		UDim2.new(1, 0, 1, -115),
		UDim2.fromOffset(0, 35),
		true
	)

	ImportBox.TextXAlignment = Enum.TextXAlignment.Left
	ImportBox.TextYAlignment = Enum.TextYAlignment.Top
	ImportBox.Font = Enum.Font.Code
	ImportBox.TextSize = 12
	ImportBox.PlaceholderText = "Paste character JSON here..."

	local Status = Label(
		ImportPanel,
		"",
		UDim2.new(0.65, -5, 0, 38),
		UDim2.new(0, 0, 1, -70)
	)

	Status.TextColor3 = Colors.Red

	local LoadButton = Button(
		ImportPanel,
		"LOAD CHARACTER",
		UDim2.new(0.35, -5, 0, 42),
		UDim2.new(0.65, 5, 1, -72)
	)

	LoadButton.BackgroundColor3 = Colors.Selected

	local ShopOpen = false
	local ShopGui = nil

	local function CloseShop()
		ShopOpen = false

		if ShopGui then
			ShopGui:Destroy()
			ShopGui = nil
		end
	end

	local PassiveToken = 0
	local PassiveConnections = {}

	local function StartPassives()
		PassiveToken += 1

		local Token = PassiveToken

		for _, Connection in ipairs(PassiveConnections) do
			Connection:Disconnect()
		end

		table.clear(PassiveConnections)

		if not loadedData then
			return
		end

		for _, Passive in ipairs(loadedData.PassiveAbilities) do
			local Trigger = Passive.Trigger or "OnLoad"
			local Graph = Passive.Graph

			if Trigger == "OnLoad" then
				task.spawn(function()
					ExecuteGraph(Graph, {Parts = {}})
				end)

			elseif Trigger == "EverySecond" then
				task.spawn(function()
					while Token == PassiveToken and loadedCharacter do
						task.wait(1)

						if Token ~= PassiveToken then
							break
						end

						ExecuteGraph(Graph, {Parts = {}})
					end
				end)

			elseif Trigger == "OnHealthChanged" then
				local Character = Player.Character
				local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

				if Humanoid then
					local Debounce = false

					local Connection = Humanoid.HealthChanged:Connect(function()
						if Debounce then
							return
						end

						Debounce = true

						task.spawn(function()
							ExecuteGraph(Graph, {Parts = {}})

							task.wait(0.3)

							Debounce = false
						end)
					end)

					table.insert(PassiveConnections, Connection)
				end
			end
		end
	end

	local function GetCurrency()
		if not loadedData then
			return nil
		end

		local CurrencyName = loadedData.CurrencyName or "Coins"

		local Leaderstats = Player:FindFirstChild("leaderstats")
		local CurrencyObject = Leaderstats and Leaderstats:FindFirstChild(CurrencyName)

		if CurrencyObject and (
			CurrencyObject:IsA("IntValue")
			or CurrencyObject:IsA("NumberValue")
		) then
			return CurrencyObject.Value, function(NewAmount)
				CurrencyObject.Value = NewAmount
			end
		end

		if activeValues[CurrencyName] ~= nil then
			return tonumber(activeValues[CurrencyName]) or 0, function(NewAmount)
				activeValues[CurrencyName] = NewAmount
			end
		end

		return nil
	end

	local function ApplyUpgrade(Upgrade)
		for Key, Value in pairs(Upgrade.Changes or {}) do
			if type(Value) == "number" then
				activeValues[Key] =
					(tonumber(activeValues[Key]) or 0) + Value
			else
				activeValues[Key] = Value
			end
		end
	end

	local function OpenUpgradeShop()
		if not loadedCharacter or not loadedData or ShopOpen then
			return false
		end

		ShopOpen = true

		local PurchasedThisShop = false

		ShopGui = Create("ScreenGui", Player:WaitForChild("PlayerGui"), {
			Name = "CustomUpgradeShop",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			DisplayOrder = 60
		})

		local Shop = Create("Frame", ShopGui, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(700, 520),
			BackgroundColor3 = Colors.Background
		})

		Round(Shop, 12)
		Stroke(Shop, Colors.Selected, 2)

		local ShopTitle = Label(
			Shop,
			"UPGRADE SHOP",
			UDim2.new(1, -80, 0, 40),
			UDim2.fromOffset(18, 10)
		)

		ShopTitle.Font = Enum.Font.GothamBold
		ShopTitle.TextSize = 20

		local CloseShopButton = Button(
			Shop,
			"X",
			UDim2.fromOffset(35, 32),
			UDim2.new(1, -47, 0, 12),
			CloseShop
		)

		CloseShopButton.BackgroundColor3 = Colors.Red

		local CurrencyLabel = Label(
			Shop,
			"",
			UDim2.new(1, -30, 0, 28),
			UDim2.fromOffset(18, 52)
		)

		CurrencyLabel.TextColor3 = Colors.Green

		local CurrentCurrency = GetCurrency()

		if CurrentCurrency ~= nil then
			CurrencyLabel.Text =
				(loadedData.CurrencyName or "Coins") .. ": " .. tostring(CurrentCurrency)
		else
			CurrencyLabel.Text =
				"Currency unavailable: " .. (loadedData.CurrencyName or "Coins")
		end

		local StatusLabel = Label(
			Shop,
			"",
			UDim2.new(1, -30, 0, 25),
			UDim2.fromOffset(18, 80)
		)

		StatusLabel.TextColor3 = Colors.Red

		local List = Create("ScrollingFrame", Shop, {
			Position = UDim2.fromOffset(15, 115),
			Size = UDim2.new(1, -30, 1, -130),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 5,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new()
		})

		Create("UIListLayout", List, {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder
		})

		Create("UIPadding", List, {
			PaddingBottom = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 5)
		})

		if #loadedData.Upgrades == 0 then
			local Empty = Label(
				List,
				"No upgrades are available.",
				UDim2.new(1, -10, 0, 55)
			)

			Empty.TextColor3 = Colors.Muted
		end

		for _, Upgrade in ipairs(loadedData.Upgrades) do
			local Card = Create("Frame", List, {
				Size = UDim2.new(1, -10, 0, 125),
				BackgroundColor3 = Colors.Panel
			})

			Round(Card, 8)
			Stroke(Card)

			local Image = Create("ImageLabel", Card, {
				Position = UDim2.fromOffset(10, 12),
				Size = UDim2.fromOffset(100, 100),
				BackgroundColor3 = Colors.Secondary,
				Image = AssetId(Upgrade.Image),
				ScaleType = Enum.ScaleType.Fit
			})

			Round(Image, 7)

			local Name = Label(
				Card,
				Upgrade.Name or "Upgrade",
				UDim2.new(1, -290, 0, 28),
				UDim2.fromOffset(122, 10)
			)

			Name.Font = Enum.Font.GothamBold
			Name.TextSize = 16

			local Description = Label(
				Card,
				Upgrade.Description or "",
				UDim2.new(1, -290, 0, 45),
				UDim2.fromOffset(122, 41)
			)

			Description.TextColor3 = Colors.Muted
			Description.TextSize = 12

			local Cost = Label(
				Card,
				"Cost: " .. tostring(Upgrade.Cost or 0),
				UDim2.new(1, -290, 0, 25),
				UDim2.fromOffset(122, 88)
			)

			Cost.TextColor3 = Colors.Green

			local BuyButton = Button(
				Card,
				"PURCHASE",
				UDim2.fromOffset(135, 38),
				UDim2.new(1, -145, 0.5, -19)
			)

			BuyButton.BackgroundColor3 = Colors.Selected

			BuyButton.Activated:Connect(function()
				if PurchasedThisShop or not ShopOpen then
					return
				end

				local Price = math.max(
					0,
					tonumber(Upgrade.Cost) or 0
				)

				local Currency, SetCurrency = GetCurrency()

				if Price > 0 then
					if Currency == nil then
						StatusLabel.Text = "Required currency is unavailable."
						return
					end

					if Currency < Price then
						StatusLabel.Text = "Not enough currency."
						return
					end

					SetCurrency(Currency - Price)
				end

				PurchasedThisShop = true

				ApplyUpgrade(Upgrade)

				CloseShop()
			end)
		end

		return true
	end

	Upgrades = function()
		if not loadedCharacter then
			return false
		end

		return OpenUpgradeShop()
	end

	EnableRSpecial = function()
		return false
	end

	_G.Upgrades = Upgrades
	_G.EnableRSpecial = EnableRSpecial

	_G.CustomCharacter = {
		Upgrades = Upgrades,
		EnableRSpecial = EnableRSpecial,

		GetData = function()
			return loadedData
		end,

		GetValues = function()
			return activeValues
		end
	}

	LoadButton.Activated:Connect(function()
		local Success, Result = pcall(function()
			return HttpService:JSONDecode(ImportBox.Text)
		end)

		if not Success or not NormalizeData(Result) then
			Status.Text = "Invalid character JSON."
			return
		end

		loadedData = Result
		activeValues = table.clone(loadedData.Values)

		loadedCharacter = true

		Gui:Destroy()

		task.spawn(StartPassives)
	end)

	Player.CharacterAdded:Connect(function()
		if loadedCharacter then
			task.wait(0.5)
			StartPassives()
		end
	end)
end

if game.GameId == BUILDER_ID or game.PlaceId == BUILDER_ID then
	CreateBuilder()

elseif game.GameId == LOADER_ID or game.PlaceId == LOADER_ID then
	CreateLoader()

	UserInputService.InputBegan:Connect(function(Input, GameProcessed)
		if GameProcessed or UserInputService:GetFocusedTextBox() then
			return
		end

		if not loadedCharacter or not loadedData then
			return
		end

		if Input.KeyCode == Enum.KeyCode.E then
			if AbilityBusy then
				return
			end

			AbilityBusy = true

			task.spawn(function()
				local Success, Error = pcall(function()
					ExecuteGraph(
						loadedData.Ability,
						{Parts = {}},
						Enum.KeyCode.E,
						loadedData.Ability
					)
				end)

				if not Success then
					warn("Ability error:", Error)
				end

				AbilityBusy = false
			end)
		end
	end)
end

if game.PlaceId == LOADER_ID then
	game.ReplicatedStorage.UpgradeFolder.Upgrades.ChildAdded:Connect(function(childaddedboisssss)
        if childaddedboisssss.Name == "NinjaBelt" then
        	EnableRSpecial()
        end
    end)

    while true do
    	wait(task.random(180, 320))
        Upgrades()
    end
end