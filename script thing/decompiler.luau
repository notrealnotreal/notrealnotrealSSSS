local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ROOT = print("insert thing here")

--// GUI
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local box = Instance.new("TextBox")
box.Size = UDim2.fromScale(0.9,0.9)
box.Position = UDim2.fromScale(0.05,0.05)
box.MultiLine = true
box.ClearTextOnFocus = false
box.TextEditable = true
box.TextWrapped = false
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.Font = Enum.Font.Code
box.TextSize = 14
box.Parent = gui

local output = {}

local function stringify(value)
	local t = typeof(value)

	if t == "string" then
		return string.format("%q", value)
	elseif t == "Instance" then
		return value:GetFullName()
	elseif t == "Color3" then
		return tostring(value)
	elseif t == "UDim2" or t == "UDim" or t == "Vector2" or
		   t == "Vector3" or t == "CFrame" or
		   t == "BrickColor" or t == "EnumItem" or
		   t == "Rect" then
		return tostring(value)
	else
		return tostring(value)
	end
end

local function dump(inst, depth)
	depth = depth or 0

	local indent = string.rep("    ", depth)

	-- Don't inspect scripts, just record where they are.
	if inst:IsA("Script")
	or inst:IsA("LocalScript")
	or inst:IsA("ModuleScript") then

		table.insert(output, indent .. inst.Name .. " (" .. inst.ClassName .. ")")
		table.insert(output, indent .. "Path: " .. inst:GetFullName())
		table.insert(output, indent .. "Properties: <Skipped - Script>")
		table.insert(output, "")

		-- Just in case the script has children
		for _, child in ipairs(inst:GetChildren()) do
			dump(child, depth + 1)
		end

		return
	end

	table.insert(output, indent .. inst.Name .. " (" .. inst.ClassName .. ")")
	table.insert(output, indent .. "Path: " .. inst:GetFullName())

	for _, prop in ipairs({
		"Name","Archivable","Active","AnchorPoint","AutomaticSize",
		"BackgroundColor3","BackgroundTransparency","BorderColor3",
		"BorderMode","BorderSizePixel","ClassName","ClipsDescendants",
		"LayoutOrder","Position","Rotation","Selectable","Size",
		"Visible","ZIndex","Text","TextColor3","TextSize","Font",
		"Image","ImageColor3","ImageTransparency","Value","Enabled"
	}) do
		local ok, value = pcall(function()
			return inst[prop]
		end)

		if ok then
			table.insert(output,
				indent ..
				"    " .. prop .. " = " .. stringify(value))
		end
	end

	local attrs = inst:GetAttributes()
	if next(attrs) then
		table.insert(output, indent .. "    Attributes:")
		for name, value in pairs(attrs) do
			table.insert(output,
				indent ..
				"        " .. name .. " = " .. stringify(value))
		end
	end

	table.insert(output, "")

	for _, child in ipairs(inst:GetChildren()) do
		dump(child, depth + 1)
	end
end

dump(ROOT)

box.Text = table.concat(output,"\n")