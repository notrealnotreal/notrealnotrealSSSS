local player = game.Players.LocalPlayer

local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local gui = Instance.new("ScreenGui")
gui.Name = "PullPartsGui"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0.5, -100, 0.9, -25)
button.Text = "Pull Unanchored Parts"
button.Parent = gui

local evilbutton = Instance.new("TextButton")
evilbutton.Size = UDim2.new(0, 200, 0, 50)
evilbutton.Position = UDim2.new(0.5, -100, 0.85, -25)
evilbutton.Text = "Pull Anchored Parts"
evilbutton.Parent = gui


button.Activated:Connect(function()
    hrp.CanCollide = false
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and not obj.Anchored then
			obj.CFrame = hrp.CFrame
		end
	end
    hrp.CanCollide = true
end)

evilbutton.Activated:Connect(function()
    hrp.CanCollide = false
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.CFrame = hrp.CFrame
		end
	end
    hrp.CanCollide = true
end)
