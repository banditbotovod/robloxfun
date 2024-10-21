local guiElement = script.Parent
local userInputService = game:GetService("UserInputService")
local dragging
local dragInput
local dragStart
local startPos


local function update(input)
	local delta = input.Position - dragStart
	guiElement.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

guiElement.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = guiElement.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

guiElement.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

userInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		update(input)
	end
end)

script.Parent:WaitForChild("Close").MouseButton1Up:Connect(function()
	script.Parent.Parent.MainFrame.Visible = false;
end)

script.Parent:WaitForChild("Code").MouseButton1Up:Connect(function()
	script.Parent.CommandBar.Visible = true
	script.Parent.CommandBar.Margin.TextLabel.Visible = true
	script.Parent.Parent.MainFrame.ScriptsFrame.Visible = false
	script.Parent.Buttons.Visible = true
	script.Parent.Execute.Visible = true
	script.Parent.clear.Visible = true
end)

script.Parent:WaitForChild("Minimize").MouseButton1Up:Connect(function()
	script.Parent.Parent.MainFrame.Visible = false
	script.Parent.Parent.Frame.Visible = true
end)

local remote = script.Parent.Execute:WaitForChild("RemoteEvent")

-----------------------------------------------===========
local scrollFrame = script.Parent:WaitForChild("OutPut"):WaitForChild("ScrollingFrame")
local function logMessage(message, messageType)
	local newLabel = Instance.new("TextLabel")
	newLabel.Size = UDim2.new(1, 0, 0, 30)
	newLabel.BackgroundTransparency = 1
	newLabel.TextSize = 15
	newLabel.TextWrapped = true
	newLabel.Font = Enum.Font.SourceSans
	if messageType == "error" then
		newLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		newLabel.Text = '[Error] ' .. message
	elseif messageType == "warning" then
		newLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
		newLabel.Text = '[Warning] ' .. message
	else
		newLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		newLabel.Text = '[Log] ' .. message
	end
	newLabel.Parent = scrollFrame
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollFrame.UIListLayout.AbsoluteContentSize.Y)
	scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.UIListLayout.AbsoluteContentSize.Y)
end
script.Parent:WaitForChild("Execute").MouseButton1Up:Connect(function()
	local displayText = script.Parent:WaitForChild("CommandBar").Margin.Display.Text
	local inputText = script.Parent:WaitForChild("CommandBar").Margin.Input.Text
	remote:FireServer(inputText, displayText)
	logMessage('Executed - "' .. inputText .. '"', "log")
end)

script.Parent:WaitForChild("clear").MouseButton1Up:Connect(function()
	script.Parent.CommandBar.Margin.Display.Text = ""
	script.Parent.CommandBar.Margin.Input.Text = ""
end)

local player = game.Players.LocalPlayer

script.Parent:WaitForChild("TextButton").MouseButton1Up:Connect(function()
	player.Character.Humanoid.Health = 0
end)

script.Parent:WaitForChild("Scripts").MouseButton1Up:Connect(function()
	script.Parent.CommandBar.Visible = false
	script.Parent.CommandBar.Margin.TextLabel.Visible = false
	script.Parent.ScriptsFrame.Visible = true
	script.Parent.Buttons.Visible = false
	script.Parent.Execute.Visible = false
	script.Parent.clear.Visible = false
end)

local Margin = script.Parent.CommandBar:WaitForChild("Margin")
local Input = Margin.Input
local Display = Margin.Display
local LineNumbers = Margin.TextLabel

local Colors = {
	[Color3.fromRGB(86, 156, 214)] = {
		"goto", "if", "in", "local", "nil", "not", "or", "repeat", "return", 
		"then", "until", "while"
	},
	[Color3.fromRGB(28, 130, 255)] = {
		"and", "break", "do", "else", "elseif", "end", "for", "function",
		"then", "until", "while"
	},
	[Color3.fromRGB(78, 201, 176)] = {
		"assert", "collectgarbage", "dofile", "error", "getmetatable", "ipairs", "load", 
		"loadfile", "next", "pairs", "pcall", "print", "rawequal", "rawget", "rawlen", 
		"rawset", "require", "select", "setmetatable", "tonumber", "tostring", "type", 
		"xpcall", "printident"
	},
	[Color3.fromRGB(255, 234, 0)] = {
		"%d+", "true", "false"
	},
	[Color3.fromRGB(214, 157, 133)] = {
		'".-"', "'.-'"
	},
	[Color3.fromRGB(231, 2, 2)] = {
		"_G", "_VERSION", "coroutine", "debug", "io", "math", "os", "package", "string", "table", "utf8"
	},
	[Color3.fromRGB(197, 134, 192)] = {
		"aaaaaaaaa"
	},
	[Color3.fromRGB(106, 153, 85)] = {
		"%-%-.-\n"
	}
}

local ColorizePattern = '<font color="rgb(%d, %d, %d)">%s</font>'

local function Colorize(text, color)
	return string.format(ColorizePattern, color.r * 255, color.g * 255, color.b * 255, text)
end

local function EscapeHTML(text)
	text = string.gsub(text, "&", "&amp;")
	text = string.gsub(text, "<", "&lt;")
	text = string.gsub(text, ">", "&gt;")
	text = string.gsub(text, "\"", "&quot;")
	text = string.gsub(text, "'", "&#039;")
	return text
end

local function ProcessText(text)
	text = EscapeHTML(text)
	text = string.gsub(text, 'print%("%s*(.-)%s*"%s*%)', function(match)
		return 'print("<font color="rgb(255, 255, 0)">' .. match .. '</font>")'
	end)
	for color, keywords in pairs(Colors) do
		for _, keyword in ipairs(keywords) do
			text = string.gsub(text, '%f[%a]' .. keyword .. '%f[%A]', function(match)
				return Colorize(match, color)
			end)
		end
	end

	return text
end

local function UpdateLineNumbers()
	local lines = string.split(Input.Text, "\n")
	local lineNumbersText = ""
	for i = 1, #lines do
		lineNumbersText = lineNumbersText .. i .. "\n"
	end
	LineNumbers.Text = lineNumbersText
end

local function InputChanged()
	local text = Input.Text
	Display.Text = ProcessText(text)
	UpdateLineNumbers()
end

Input:GetPropertyChangedSignal("Text"):Connect(InputChanged)
UpdateLineNumbers()

script.Parent.Parent:WaitForChild("Frame"):WaitForChild("TextButton").MouseButton1Up:Connect(function()
	script.Parent.Visible = true
end)

-----------=====================================================

local Player = game.Players.LocalPlayer
local username = Player.Name

local ScriptN1 = script.Parent:WaitForChild("ScriptsFrame"):WaitForChild("ScrollingFrame"):WaitForChild("Script1")
local ScriptN2 = script.Parent:WaitForChild("ScriptsFrame"):WaitForChild("ScrollingFrame"):WaitForChild("Script2")
local ScriptN3 = script.Parent:WaitForChild("ScriptsFrame"):WaitForChild("ScrollingFrame"):WaitForChild("Script3")
local ScriptN4 = script.Parent:WaitForChild("ScriptsFrame"):WaitForChild("ScrollingFrame"):WaitForChild("Script4")
local ScriptN5 = script.Parent:WaitForChild("ScriptsFrame"):WaitForChild("ScrollingFrame"):WaitForChild("Script5")
local ScriptN6 = script.Parent:WaitForChild("ScriptsFrame"):WaitForChild("ScrollingFrame"):WaitForChild("Script6")
local ScriptN7 = script.Parent:WaitForChild("ScriptsFrame"):WaitForChild("ScrollingFrame"):WaitForChild("Script7")
local ScriptN8 = script.Parent:WaitForChild("ScriptsFrame"):WaitForChild("ScrollingFrame"):WaitForChild("Script8")
local ScriptN9 = script.Parent:WaitForChild("ScriptsFrame"):WaitForChild("ScrollingFrame"):WaitForChild("Script9")
local ScriptN10 = script.Parent:WaitForChild("ScriptsFrame"):WaitForChild("ScrollingFrame"):WaitForChild("Script10")
local ScriptN11 = script.Parent:WaitForChild("ScriptsFrame"):WaitForChild("ScrollingFrame"):WaitForChild("Script11")
local ScriptN12 = script.Parent:WaitForChild("ScriptsFrame"):WaitForChild("ScrollingFrame"):WaitForChild("Script12")


ScriptN1.MouseButton1Up:Connect(function()
	script.Parent.CommandBar.Margin.Display.Text = "require(2823974237).giveGuns'"..username.."'"
	script.Parent.CommandBar.Margin.Input.Text = "require(2823974237).giveGuns'"..username.."'"
	script.Parent.ScriptsFrame.Visible = false
	script.Parent.CommandBar.Visible = true
	script.Parent.CommandBar.Margin.TextLabel.Visible = true
	script.Parent.Buttons.Visible = true
	script.Parent.Execute.Visible = true
	script.Parent.clear.Visible = true
end)

ScriptN2.MouseButton1Up:Connect(function()
	script.Parent.CommandBar.Margin.Display.Text = 'require(13716575182)("'..username..'")'
	script.Parent.CommandBar.Margin.Input.Text = 'require(13716575182)("'..username..'")'
	script.Parent.ScriptsFrame.Visible = false
	script.Parent.CommandBar.Visible = true
	script.Parent.CommandBar.Margin.TextLabel.Visible = true
	script.Parent.Buttons.Visible = true
	script.Parent.Execute.Visible = true
	script.Parent.clear.Visible = true
end)

ScriptN3.MouseButton1Up:Connect(function()
	script.Parent.CommandBar.Margin.Display.Text = 'require(11102724246).load("'..username..'")'
	script.Parent.CommandBar.Margin.Input.Text = 'require(11102724246).load("'..username..'")'
	script.Parent.ScriptsFrame.Visible = false
	script.Parent.CommandBar.Visible = true
	script.Parent.CommandBar.Margin.TextLabel.Visible = true
	script.Parent.Buttons.Visible = true
	script.Parent.Execute.Visible = true
	script.Parent.clear.Visible = true
end)

ScriptN4.MouseButton1Up:Connect(function()
	script.Parent.CommandBar.Margin.Display.Text = 'require(11560761226).HD("'..username..'")'
	script.Parent.CommandBar.Margin.Input.Text = 'require(11560761226).HD("'..username..'")'
	script.Parent.ScriptsFrame.Visible = false
	script.Parent.CommandBar.Visible = true
	script.Parent.CommandBar.Margin.TextLabel.Visible = true
	script.Parent.Buttons.Visible = true
	script.Parent.Execute.Visible = true
	script.Parent.clear.Visible = true
end)

ScriptN5.MouseButton1Up:Connect(function()
	script.Parent.CommandBar.Margin.Display.Text = 'require(13924408521).TeamFatGUI("'..username..'")--pass is temfatguiv15eas'
	script.Parent.CommandBar.Margin.Input.Text = 'require(13924408521).TeamFatGUI("'..username..'")--pass is temfatguiv15eas'
	script.Parent.ScriptsFrame.Visible = false
	script.Parent.CommandBar.Visible = true
	script.Parent.CommandBar.Margin.TextLabel.Visible = true
	script.Parent.Buttons.Visible = true
	script.Parent.Execute.Visible = true
	script.Parent.clear.Visible = true
end)

ScriptN6.MouseButton1Up:Connect(function()
	script.Parent.CommandBar.Margin.Display.Text = 'require(5115249013).fehack("'..username..'")'
	script.Parent.CommandBar.Margin.Input.Text = 'require(5115249013).fehack("'..username..'")'
	script.Parent.ScriptsFrame.Visible = false
	script.Parent.CommandBar.Visible = true
	script.Parent.CommandBar.Margin.TextLabel.Visible = true
	script.Parent.Buttons.Visible = true
	script.Parent.Execute.Visible = true
	script.Parent.clear.Visible = true
end)

ScriptN7.MouseButton1Up:Connect(function()
	script.Parent.CommandBar.Margin.Display.Text = 'require(10791446752).s400("'..username..'")'
	script.Parent.CommandBar.Margin.Input.Text = 'require(10791446752).s400("'..username..'")'
	script.Parent.ScriptsFrame.Visible = false
	script.Parent.CommandBar.Visible = true
	script.Parent.CommandBar.Margin.TextLabel.Visible = true
	script.Parent.Buttons.Visible = true
	script.Parent.Execute.Visible = true
	script.Parent.clear.Visible = true
end)


ScriptN8.MouseButton1Up:Connect(function()
	script.Parent.CommandBar.Margin.Display.Text = 'require(11670894308).Strafe("'..username..'")'
	script.Parent.CommandBar.Margin.Input.Text = 'require(11670894308).Strafe("'..username..'")'
	script.Parent.ScriptsFrame.Visible = false
	script.Parent.CommandBar.Visible = true
	script.Parent.CommandBar.Margin.TextLabel.Visible = true
	script.Parent.Buttons.Visible = true
	script.Parent.Execute.Visible = true
	script.Parent.clear.Visible = true
end)

ScriptN9.MouseButton1Up:Connect(function()
	script.Parent.CommandBar.Margin.Display.Text = 'require(4867426485):SD2("'..username..'")'
	script.Parent.CommandBar.Margin.Input.Text = 'require(4867426485):SD2("'..username..'")'
	script.Parent.ScriptsFrame.Visible = false
	script.Parent.CommandBar.Visible = true
	script.Parent.CommandBar.Margin.TextLabel.Visible = true
	script.Parent.Buttons.Visible = true
	script.Parent.Execute.Visible = true
	script.Parent.clear.Visible = true
end)

ScriptN10.MouseButton1Up:Connect(function()
	script.Parent.CommandBar.Margin.Display.Text = 'require(5068511197).insert("'..username..'")'
	script.Parent.CommandBar.Margin.Input.Text = 'require(5068511197).insert("'..username..'")'
	script.Parent.ScriptsFrame.Visible = false
	script.Parent.CommandBar.Visible = true
	script.Parent.CommandBar.Margin.TextLabel.Visible = true
	script.Parent.Buttons.Visible = true
	script.Parent.Execute.Visible = true
	script.Parent.clear.Visible = true
end)


ScriptN11.MouseButton1Up:Connect(function()
	script.Parent.CommandBar.Margin.Display.Text = 'require(5492934148):Fire("XD","'..username..'")'
	script.Parent.CommandBar.Margin.Input.Text = 'require(5492934148):Fire("XD","'..username..'")'
	script.Parent.ScriptsFrame.Visible = false
	script.Parent.CommandBar.Visible = true
	script.Parent.CommandBar.Margin.TextLabel.Visible = true
	script.Parent.Buttons.Visible = true
	script.Parent.Execute.Visible = true
	script.Parent.clear.Visible = true
end)

ScriptN12.MouseButton1Up:Connect(function()
	script.Parent.CommandBar.Margin.Display.Text = 'require(2845929020).ooga("'..username..'")'
	script.Parent.CommandBar.Margin.Input.Text = 'require(2845929020).ooga("'..username..'")'
	script.Parent.ScriptsFrame.Visible = false
	script.Parent.CommandBar.Visible = true
	script.Parent.CommandBar.Margin.TextLabel.Visible = true
	script.Parent.Buttons.Visible = true
	script.Parent.Execute.Visible = true
	script.Parent.clear.Visible = true
end)
