local base = "https://raw.githubusercontent.com/gravloper/estools/refs/heads/main/Games/"

local supported = {
	-- nothing supported /whatever
}

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

local errGui = Instance.new("ScreenGui")
errGui.Name = "dvhub_errors"
errGui.ResetOnSpawn = false
errGui.IgnoreGuiInset = true
errGui.Parent = parent

local function notify(code)
	local msg = errorCodes[tostring(code)] or "Unknown error"

	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(0, 260, 0, 40)
	toast.Position = UDim2.new(0.5, -130, 0, -10)
	toast.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	toast.BackgroundTransparency = 1
	toast.BorderSizePixel = 0
	toast.ZIndex = 50
	toast.Parent = errGui

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

local screen = Instance.new("ScreenGui")
screen.Name = "dvhub_loader"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.Parent = parent

local box = Instance.new("Frame")
box.Size = UDim2.new(0, 150, 0, 40)
box.Position = UDim2.new(0.5, -75, 0.5, -20)
box.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
box.BackgroundTransparency = 0.35
box.BorderSizePixel = 0
box.Parent = screen

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.85
stroke.Thickness = 1
stroke.Parent = box

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.Code
label.TextSize = 13
label.TextColor3 = Color3.fromRGB(230, 230, 230)
label.Text = "dvhub loading."
label.Parent = box

local alive = true
task.spawn(function()
	local dots = 0
	while alive do
		dots = (dots % 3) + 1
		label.Text = "dvhub loading" .. string.rep(".", dots)
		task.wait(0.35)
	end
end)

local function fetch(url)
	local getter = game.HttpGet or game.HttpGetAsync
	if not getter then return nil, -3 end
	local ok2, src = pcall(getter, game, url)
	if not ok2 or not src then return nil, 1000 end
	return src, nil
end

local placeId = tostring(game.PlaceId)
local target = supported[placeId]

local token = tostring(math.random(100000, 999999)) .. tostring(os.clock()):gsub("%.", "")
_G.dvhub_token = token

local url = target and (base .. target) or (base .. "Universal/dvhub.luau")
local src, errCode = fetch(url)

alive = false
screen:Destroy()

if src then
	local loader = loadstring or load
	if loader then
		local fn, err = loader(src)
		if fn then
			local ranOk, runErr = pcall(fn)
			if not ranOk then
				notify(751)
				warn("runtime failed: " .. tostring(runErr))
			end
		else
			_G.dvhub_token = nil
			notify(-9595959)
			warn("dvhub compile failed: " .. tostring(err))
		end
	else
		_G.dvhub_token = nil
		notify(5921)
	end
else
	_G.dvhub_token = nil
	notify(errCode or 1000)
end
