local Portal = require(game.ReplicatedStorage.Shared.Portal)
local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()

task.wait(2)

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
local whitelist = {}
for _, v in pairs(game:GetService("CollectionService"):GetTagged("PortalWall")) do
	table.insert(whitelist, v)
	print(v)
end

params.FilterDescendantsInstances = whitelist

local function getClick(): (Vector3, Vector3, BasePart)
	local hit
	while not hit do
		Mouse.Button1Down:wait()
		local dir = Mouse.UnitRay.Direction
		local pos = workspace.CurrentCamera.CFrame.Position
		hit = workspace:Raycast(pos, dir * 1000, params)
		print(hit)
	end
	return hit.Position, hit.Normal, hit.Instance
end

while wait(1) do
	local posA, normalA, partA = getClick()
	local posB, normalB, partB = getClick()
	local cframeA = CFrame.lookAlong(posA + normalA * 0.001, normalA)
	local cframeB = CFrame.lookAlong(posB + normalB * 0.001, normalB)
	local portal = Portal.new(cframeA, cframeB, { partA }, { partB }, workspace.Model)
	game:GetService("RunService").Stepped:Connect(function()
		portal:render()
	end)
end
