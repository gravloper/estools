local plr = game:GetService("Players").LocalPlayer
local CoreGui = game:GetService("CoreGui")
local Http = game:GetService("HttpService")

local parent
local ok, res = pcall(function() return CoreGui end)
if ok and res then
	parent = res
else
	parent = plr:WaitForChild("PlayerGui")
end

local gui = Instance.new("ScreenGui")
gui.Name = "dvhub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = parent

-- error code lookup, pulled from github once and cached
local errorCodes = {}
do
	local getter = game.HttpGet or game.HttpGetAsync
	if getter then
		local ok2, src = pcall(getter, game, "https://raw.githubusercontent.com/gravloper/estools/refs/heads/main/errors.json")
		if ok2 and src then
			local ok3, decoded = pcall(function() return Http:JSONDecode(src) end)
			if ok3 and decoded then
				errorCodes = decoded
			end
		end
	end
end

-- error toast, same look as the main panel, slides/fades in top center
local function notify(code)
	local msg = errorCodes[tostring(code)] or "Unknown error"

	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(0, 260, 0, 40)
	toast.Position = UDim2.new(0.5, -130, 0, -10)
	toast.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	toast.BackgroundTransparency = 1
	toast.BorderSizePixel = 0
	toast.ZIndex = 50
	toast.Parent = gui

	local tstroke = Instance.new("UIStroke")
	tstroke.Color = Color3.fromRGB(255, 90, 90)
	tstroke.Transparency = 1
	tstroke.Thickness = 1
	tstroke.Parent = toast

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Code
	label.TextSize = 13
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextWrapped = true
	label.TextTransparency = 1
	label.Text = "Code " .. tostring(code) .. " : " .. msg
	label.Parent = toast

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://139746569667955"
	sound.Volume = 0.6
	sound.Parent = toast
	sound:Play()

	local TweenService = game:GetService("TweenService")
	local fadeIn = TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
		Position = UDim2.new(0.5, -130, 0, 20),
		BackgroundTransparency = 0.35,
	})
	local strokeIn = TweenService:Create(tstroke, TweenInfo.new(0.25), {Transparency = 0.7})
	local textIn = TweenService:Create(label, TweenInfo.new(0.25), {TextTransparency = 0})

	fadeIn:Play()
	strokeIn:Play()
	textIn:Play()

	task.delay(3, function()
		local fadeOut = TweenService:Create(toast, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, -130, 0, -10),
			BackgroundTransparency = 1,
		})
		local strokeOut = TweenService:Create(tstroke, TweenInfo.new(0.3), {Transparency = 1})
		local textOut = TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 1})
		fadeOut:Play()
		strokeOut:Play()
		textOut:Play()
		fadeOut.Completed:Wait()
		toast:Destroy()
	end)
end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 170)
main.Position = UDim2.new(0, 30, 0, 120)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
main.BackgroundTransparency = 0.35
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.85
stroke.Thickness = 1
stroke.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 18)
title.Position = UDim2.new(0, 0, 0, 4)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Code
title.TextSize = 13
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "----- Tools -----"
title.Parent = main

local function run(url)
	local getter = game.HttpGet or game.HttpGetAsync
	if not getter then
		notify(753)
		return
	end
	local ok2, src = pcall(getter, game, url)
	if not ok2 or not src then
		notify(752)
		return
	end
	local loader = loadstring or load
	if not loader then
		notify(754)
		return
	end
	local fn, err = loader(src)
	if not fn then
		notify(755)
		warn("compile failed: " .. tostring(err))
		return
	end
	local ranOk, runErr = pcall(fn)
	if not ranOk then
		notify(751)
		warn("runtime failed: " .. tostring(runErr))
	end
end

local function makeBtn(name, y, url)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 18)
	btn.Position = UDim2.new(0, 12, 0, y)
	btn.BackgroundTransparency = 1
	btn.Font = Enum.Font.Code
	btn.TextSize = 13
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.TextColor3 = Color3.fromRGB(230, 230, 230)
	btn.Text = name
	btn.AutoButtonColor = false
	btn.Parent = main

	btn.MouseEnter:Connect(function()
		btn.TextColor3 = Color3.fromRGB(140, 200, 255)
	end)
	btn.MouseLeave:Connect(function()
		btn.TextColor3 = Color3.fromRGB(230, 230, 230)
	end)

	local busy = false
	btn.MouseButton1Click:Connect(function()
		if busy then return end
		busy = true

		local dots = 0
		local anim = task.spawn(function()
			while busy do
				dots = (dots % 3) + 1
				btn.Text = "Loading" .. string.rep(".", dots)
				task.wait(0.35)
			end
		end)

		local started = os.clock()
		run(url)
		local elapsed = os.clock() - started
		if elapsed < 0.6 then
			task.wait(0.6 - elapsed)
		end

		busy = false
		task.cancel(anim)
		btn.Text = name
	end)

	return btn
end

makeBtn("Execute Dex++", 26, "https://github.com/AZYsGithub/DexPlusPlus/releases/download/stable-3.0/out.lua")
makeBtn("Execute Nameless Admin", 46, "https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/NA%20testing.lua")
makeBtn("Execute Cobalt Spy", 66, "https://github.com/notpoiu/cobalt/releases/latest/download/Coballuau") -- simulate error
makeBtn("Execute Simplespy", 86, "https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua")

local verHeader = Instance.new("TextLabel")
verHeader.Size = UDim2.new(1, 0, 0, 18)
verHeader.Position = UDim2.new(0, 0, 0, 112)
verHeader.BackgroundTransparency = 1
verHeader.Font = Enum.Font.Code
verHeader.TextSize = 13
verHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
verHeader.Text = "----- Version -----"
verHeader.Parent = main

local verLabel = Instance.new("TextLabel")
verLabel.Size = UDim2.new(1, -20, 0, 16)
verLabel.Position = UDim2.new(0, 12, 0, 132)
verLabel.BackgroundTransparency = 1
verLabel.Font = Enum.Font.Code
verLabel.TextSize = 12
verLabel.TextXAlignment = Enum.TextXAlignment.Left
verLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
verLabel.Text = "Build     : v0.0.5 beta"
verLabel.Parent = main

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 90, 0, 16)
closeBtn.Position = UDim2.new(1, -98, 1, -22)
closeBtn.BackgroundTransparency = 1
closeBtn.Font = Enum.Font.Code
closeBtn.TextSize = 12
closeBtn.TextXAlignment = Enum.TextXAlignment.Right
closeBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
closeBtn.Text = "Remove UI"
closeBtn.AutoButtonColor = false
closeBtn.Parent = main

closeBtn.MouseEnter:Connect(function()
	closeBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
end)
closeBtn.MouseLeave:Connect(function()
	closeBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
end)
closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)
