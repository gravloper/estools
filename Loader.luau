local base = "https://raw.githubusercontent.com/gravloper/estools/refs/heads/main/Games/"

local supported = {
	-- no support right now, im more focused on dvhub
}

local plr = game:GetService("Players").LocalPlayer
local CoreGui = game:GetService("CoreGui")

local function getParent()
	local ok, res = pcall(function() return CoreGui end)
	if ok and res then
		return res
	end
	return plr:WaitForChild("PlayerGui")
end

local screen = Instance.new("ScreenGui")
screen.Name = "dvhub_loader"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.Parent = getParent()

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
	if not getter then return nil end
	local ok, src = pcall(getter, game, url)
	if not ok then return nil end
	return src
end

local function run(src)
	local loader = loadstring or load
	if not loader then return end
	local fn, err = loader(src)
	if not fn then
		warn("dvhub compile failed: " .. tostring(err))
		return
	end
	fn()
end

local placeId = tostring(game.PlaceId)
local target = supported[placeId]

local src
if target then
	src = fetch(base .. target)
else
	src = fetch(base .. "Universal/dvhub.luau")
end

-- keep the loading box up a bit so it doesnt just uhh you know maybe i didd it for fun bro r ugsu
task.wait(0.5)

alive = false
screen:Destroy()

if src then
	run(src)
else
	warn("couldnt fetch script")
end
