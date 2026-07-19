--!strict

local Players = game:GetService("Players")
local CoreGui : Instance = game:GetService("CoreGui")
local LP = Players.LocalPlayer

local new = Instance.new
local udim2 = UDim2.new
local color3 = Color3.fromRGB
local fmt = string.format
local insert = table.insert

type RowDef = {
	Label : string,
	OnFire : (() -> ())?,
}

local function resolveRoot() : Instance
	local ok, root = pcall(function() return CoreGui end)
	if ok and root then return root end
	return LP:WaitForChild("PlayerGui")
end

local Console = {}
Console.__index = Console

function Console.new(name: string)
	local self = setmetatable({}, Console)

	self._gui = new("ScreenGui")
	self._gui.Name = name
	self._gui.ResetOnSpawn = false
	self._gui.IgnoreGuiInset = true
	self._gui.DisplayOrder = 999
	self._gui.Parent = resolveRoot()

	self._root = new("Frame")
	self._root.Name = "Root"
	self._root.Size = udim2(0, 260, 0, 210)
	self._root.Position = udim2(0, 30, 0, 120)
	self._root.BackgroundColor3 = color3(10, 10, 10)
	self._root.BackgroundTransparency = 0.35
	self._root.BorderSizePixel = 0
	self._root.Active = true
	self._root.Draggable = true
	self._root.Parent = self._gui

	local stroke = new("UIStroke")
	stroke.Color = color3(255, 255, 255)
	stroke.Transparency = 0.85
	stroke.Thickness = 1
	stroke.Parent = self._root

	self._cursor = 0
	self._conns = {}

	return self
end

function Console:_advance(px: number)
	self._cursor += px
	return self._cursor - px
end

function Console:Section(label: string)
	local y = self:_advance(20)
	local h = new("TextLabel")
	h.BackgroundTransparency = 1
	h.Size = udim2(1, 0, 0, 18)
	h.Position = udim2(0, 0, 0, y + 4)
	h.Font = Enum.Font.Code
	h.TextSize = 13
	h.TextColor3 = color3(255, 255, 255)
	h.Text = fmt("----- %s -----", label)
	h.Parent = self._root
	return self
end

function Console:Rows(defs: {RowDef})
	for _, def in ipairs(defs) do
		local y = self:_advance(20)
		local btn = new("TextButton")
		btn.AutoButtonColor = false
		btn.BackgroundTransparency = 1
		btn.Size = udim2(1, -20, 0, 18)
		btn.Position = udim2(0, 12, 0, y + 6)
		btn.Font = Enum.Font.Code
		btn.TextSize = 13
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.TextColor3 = color3(230, 230, 230)
		btn.Text = def.Label
		btn.Parent = self._root

		insert(self._conns, btn.MouseEnter:Connect(function()
			btn.TextColor3 = color3(140, 200, 255)
		end))
		insert(self._conns, btn.MouseLeave:Connect(function()
			btn.TextColor3 = color3(230, 230, 230)
		end))

		if def.OnFire then
			local fire = def.OnFire
			local busy = false
			insert(self._conns, btn.MouseButton1Click:Connect(function()
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
				local ok, err = pcall(fire)

				local elapsed = os.clock() - started
				if elapsed < 0.6 then
					task.wait(0.6 - elapsed)
				end

				busy = false
				task.cancel(anim)
				btn.Text = def.Label

				if not ok then
					warn(fmt("[%s] handler failed: %s", def.Label, tostring(err)))
				end
			end))
		end
	end
	return self
end

function Console:InfoRows(pairs_: {[string]: string})
	for k, v in pairs(pairs_) do
		local y = self:_advance(16)
		local lbl = new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size = udim2(1, -20, 0, 16)
		lbl.Position = udim2(0, 12, 0, y + 6)
		lbl.Font = Enum.Font.Code
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextColor3 = color3(200, 200, 200)
		lbl.Text = fmt("%-10s: %s", k, v)
		lbl.Parent = self._root
	end
	return self
end

function Console:Destroy()
	for _, c in ipairs(self._conns) do
		c:Disconnect()
	end
	self._gui:Destroy()
end

local function exec(url: string)
	local getter = (game :: any).HttpGet or (game :: any).HttpGetAsync
	assert(getter, "no http primitive exposed on game")

	local ok, src = pcall(getter, game, url)
	if not ok or not src then
		warn("fetch failed -> " .. url)
		return
	end

	local loader = (loadstring or load) :: (string) -> ((...any) -> ...any)?
	local fn, cerr = loader(src)
	if not fn then
		warn("compile failed -> " .. tostring(cerr))
		return
	end

	fn()
end

local hub = Console.new("DevHubClassic")

hub:Section("Tools"):Rows({
	{
		Label = "Execute Dex++",
		OnFire = function()
			exec("https://github.com/AZYsGithub/DexPlusPlus/releases/download/stable-3.0/out.lua")
		end,
	},
	{
		Label = "Execute Nameless Admin",
		OnFire = function()
			exec("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/NA%20testing.lua")
		end,
	},
	{
		Label = "Execute Cobalt Spy",
		OnFire = function()
			exec("https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau")
		end,
	},
	{
		Label = "Execute Simplespy",
		OnFire = function()
			exec("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua")
		end,
	},
})

hub:Section("Status"):InfoRows({
	Status = "Ready",
	Loaded = os.date("%X"),
})

do
	local closeBtn = new("TextButton")
	closeBtn.AutoButtonColor = false
	closeBtn.BackgroundTransparency = 1
	closeBtn.Size = udim2(0, 90, 0, 16)
	closeBtn.Position = udim2(1, -98, 1, -22)
	closeBtn.Font = Enum.Font.Code
	closeBtn.TextSize = 12
	closeBtn.TextXAlignment = Enum.TextXAlignment.Right
	closeBtn.TextColor3 = color3(230, 230, 230)
	closeBtn.Text = "Remove UI"
	closeBtn.Parent = hub._root

	closeBtn.MouseEnter:Connect(function()
		closeBtn.TextColor3 = color3(255, 90, 90)
	end)
	closeBtn.MouseLeave:Connect(function()
		closeBtn.TextColor3 = color3(230, 230, 230)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		hub:Destroy()
	end)
end

return hub
