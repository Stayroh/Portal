--!strict

local viewportWindow = require(game.ReplicatedStorage.Shared.viewportWindow)
local PortalReference: Model = game.ReplicatedStorage.Assets.Portal

local Portal: PortalClass = {} :: PortalClass
Portal.__index = Portal

type PortalClass = {
	new: (cframeA: CFrame, cframeB: CFrame, noCollideA: { BasePart }, noCollideB: { BasePart }, scene: Model) -> Portal,
	render: (self: Portal) -> nil,
	updateScene: (self: Portal, scene: Model) -> nil,
	destroy: (self: Portal) -> nil,
	updateA: (self: Portal, cframe: CFrame, noCollide: { BasePart }) -> nil,
	updateB: (self: Portal, cframe: CFrame, noCollide: { BasePart }) -> nil,
	__index: PortalClass,
	updateCollisions: (self: Portal) -> nil,
}

local LIGHT_COLOR = Color3.new(1, 1, 1)
local AMBIENT_COLOR = Color3.new(0.5, 0.5, 0.5)

export type Portal = typeof(setmetatable(
	{} :: {
		cframeA: CFrame,
		cframeB: CFrame,
		noCollideA: { BasePart },
		noCollideB: { BasePart },
		portalA: Model,
		portalB: Model,
		sceneA: Model,
		sceneB: Model,
		viewportWindowA: viewportWindow.ViewportWindow,
		viewportWindowB: viewportWindow.ViewportWindow,
		noCollisionContraintsA: {
			[BasePart]: {
				Constraints: { NoCollisionConstraint },
				ghostPart: BasePart?,
			},
		},
		noCollisionContraintsB: {
			[BasePart]: {
				Constraints: { NoCollisionConstraint },
				ghostPart: BasePart?,
			},
		},
	},
	Portal
))

local function setCopy(original: Model, copy: Model, cframe: CFrame)
	local originalCFrame = original:GetPivot()
	copy:PivotTo(cframe)
	for _, copyPart in pairs(copy:GetChildren()) do
		if copyPart:IsA("BasePart") then
			local originalPart = original:FindFirstChild(copyPart.Name)
			local offset = originalCFrame:ToObjectSpace(originalPart.CFrame)
			copyPart.CFrame = cframe:ToWorldSpace(offset)
		elseif copyPart:IsA("Accessory") then
			local handle = copyPart.Handle
			local originalPart = original:FindFirstChild(copyPart.Name).Handle
			local offset = originalCFrame:ToObjectSpace(originalPart.CFrame)
			handle.CFrame = cframe:ToWorldSpace(offset)
		end
	end
end

function Portal:render()
	local camera = workspace.CurrentCamera
	local cameraCFrame = camera.CFrame

	local surfaceACF, surfaceASize = self.viewportWindowA:GetSurfaceCFrameSize()
	local surfaceBCF, surfaceBSize = self.viewportWindowB:GetSurfaceCFrameSize()

	local rotatedSurfaceBCF = surfaceBCF * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)
	local rotatedSurfaceACF = surfaceACF * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)

	local renderACF = rotatedSurfaceBCF * surfaceACF:ToObjectSpace(cameraCFrame)
	local renderBCF = rotatedSurfaceACF * surfaceBCF:ToObjectSpace(cameraCFrame)

	self:updateCollisions()
	self.viewportWindowA:RenderManual(renderACF, rotatedSurfaceBCF, surfaceBSize)
	self.viewportWindowB:RenderManual(renderBCF, rotatedSurfaceACF, surfaceASize)

	return nil
end

function Portal:updateScene(scene: Model)
	self.sceneA:Destroy()
	self.sceneA = scene:Clone()
	self.sceneA.Parent = self.viewportWindowA.worldViewportFrame

	self.sceneB:Destroy()
	self.sceneB = scene:Clone()
	self.sceneB.Parent = self.viewportWindowB.worldViewportFrame

	return nil
end

function Portal:updateCollisions()
	--Collision for portal A
	local char = game.Players.LocalPlayer.Character

	local useViewportGhosts = false

	do
		local newParts = game.Workspace:GetPartsInPart(self.portalA.Hitbox)
		local newTracker = {}

		local foundChar = false

		for _, part in pairs(newParts) do
			if part.Anchored then
				continue
			end
			if char and part:IsDescendantOf(char) then
				foundChar = true
			end
			newTracker[part] = true
			if not self.noCollisionContraintsA[part] then
				--NewPartAction
				self.noCollisionContraintsA[part] = { Constraints = {} }
				for i, noCollide in pairs(self.noCollideA) do
					local constraint = Instance.new("NoCollisionConstraint")
					constraint.Part0 = part
					constraint.Part1 = noCollide
					constraint.Parent = part
					self.noCollisionContraintsA[part].Constraints[i] = constraint
				end
				if not (char and part:IsDescendantOf(char)) and part.Name ~= "Handle" then
					local ghostPart = part:Clone()
					ghostPart.CFrame = (self.cframeB * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)):ToWorldSpace(
						self.cframeA:ToObjectSpace(part.CFrame)
					)
					ghostPart.CanTouch = false
					ghostPart.CanQuery = false
					ghostPart.CanCollide = false
					ghostPart.Anchored = true
					ghostPart.Parent = self.portalB.Illusion
					self.noCollisionContraintsA[part].ghostPart = ghostPart
				end
			else
				--UpdatePartAction
				local ghostPart = self.noCollisionContraintsA[part].ghostPart
				if ghostPart then
					ghostPart.CFrame = (self.cframeB * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)):ToWorldSpace(
						self.cframeA:ToObjectSpace(part.CFrame)
					)
				end
			end
		end

		for part, _ in pairs(self.noCollisionContraintsA) do
			if not newTracker[part] then
				--RemoveAction
				for _, constraint in pairs(self.noCollisionContraintsA[part].Constraints) do
					constraint:Destroy()
				end
				if self.noCollisionContraintsA[part].ghostPart then
					self.noCollisionContraintsA[part].ghostPart:Destroy()
				end
				self.noCollisionContraintsA[part] = nil
			end
		end

		if foundChar and char then
			useViewportGhosts = true
			local ghostChar = self.portalB:FindFirstChild("Char")
			if not ghostChar then
				char.Archivable = true
				ghostChar = char:Clone() :: Model
				ghostChar.Name = "Char"
				for _, v in pairs(ghostChar:GetChildren()) do
					if v:IsA("BasePart") then
						v.CanCollide = false
						v.Anchored = true
						v.CanTouch = false
						v.CanQuery = false
					end
				end
				ghostChar.Parent = self.portalB
			end
			local viewportChar = self.viewportWindowB.worldViewportFrame:FindFirstChild("Char")
			if not viewportChar then
				viewportChar = ghostChar:Clone()
				viewportChar.Parent = self.viewportWindowB.worldViewportFrame
			end
			local otherSideCFrame = (self.cframeB * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)):ToWorldSpace(
				self.cframeA:ToObjectSpace(char.PrimaryPart.CFrame)
			)
			local ghostViewportChar = self.viewportWindowA.worldViewportFrame:FindFirstChild("Char")
			if not ghostViewportChar then
				ghostViewportChar = ghostChar:Clone()
				ghostViewportChar.Parent = self.viewportWindowA.worldViewportFrame
			end
			setCopy(char, ghostChar, otherSideCFrame)
			setCopy(char, ghostViewportChar, otherSideCFrame)
			setCopy(char, viewportChar, char:GetPivot())

			ghostChar.Parent = self.portalB
		elseif self.portalB:FindFirstChild("Char") then
			self.portalB:FindFirstChild("Char"):Destroy()
		end
	end

	--Collision for portal B
	do
		local newParts = game.Workspace:GetPartsInPart(self.portalB.Hitbox)
		local newTracker = {}

		local foundChar = false

		for _, part in pairs(newParts) do
			if part.Anchored then
				continue
			end
			if char and part:IsDescendantOf(char) then
				foundChar = true
			end
			newTracker[part] = true
			if not self.noCollisionContraintsB[part] then
				--NewPartAction
				self.noCollisionContraintsB[part] = { Constraints = {} }
				for i, noCollide in pairs(self.noCollideB) do
					local constraint = Instance.new("NoCollisionConstraint")
					constraint.Part0 = part
					constraint.Part1 = noCollide
					constraint.Parent = part
					self.noCollisionContraintsB[part].Constraints[i] = constraint
				end
				if not (char and part:IsDescendantOf(char)) and part.Name ~= "Handle" then
					local ghostPart = part:Clone()
					ghostPart.CFrame = (self.cframeA * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)):ToWorldSpace(
						self.cframeB:ToObjectSpace(part.CFrame)
					)
					ghostPart.CanTouch = false
					ghostPart.CanQuery = false
					ghostPart.CanCollide = false
					ghostPart.Anchored = true
					ghostPart.Parent = self.portalA.Illusion
					self.noCollisionContraintsB[part].ghostPart = ghostPart
				end
			else
				--UpdatePartAction
				local ghostPart = self.noCollisionContraintsB[part].ghostPart
				if ghostPart then
					ghostPart.CFrame = (self.cframeA * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)):ToWorldSpace(
						self.cframeB:ToObjectSpace(part.CFrame)
					)
				end
			end
		end

		for part, _ in pairs(self.noCollisionContraintsB) do
			if not newTracker[part] then
				--RemoveAction
				for _, constraint in pairs(self.noCollisionContraintsB[part].Constraints) do
					constraint:Destroy()
				end
				if self.noCollisionContraintsB[part].ghostPart then
					self.noCollisionContraintsB[part].ghostPart:Destroy()
				end
				self.noCollisionContraintsB[part] = nil
			end
		end

		if foundChar and char then
			useViewportGhosts = true
			local ghostChar = self.portalA:FindFirstChild("Char")
			if not ghostChar then
				char.Archivable = true
				ghostChar = char:Clone() :: Model
				ghostChar.Name = "Char"
				for _, v in pairs(ghostChar:GetChildren()) do
					if v:IsA("BasePart") then
						v.CanCollide = false
						v.Anchored = true
						v.CanTouch = false
						v.CanQuery = false
					end
				end
				ghostChar.Parent = self.portalA
			end
			local viewportChar = self.viewportWindowA.worldViewportFrame:FindFirstChild("Char")
			if not viewportChar then
				viewportChar = ghostChar:Clone()
				viewportChar.Parent = self.viewportWindowA.worldViewportFrame
			end
			local otherSideCFrame = (self.cframeA * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)):ToWorldSpace(
				self.cframeB:ToObjectSpace(char.PrimaryPart.CFrame)
			)
			local ghostViewportChar = self.viewportWindowB.worldViewportFrame:FindFirstChild("Char")
			if not ghostViewportChar then
				ghostViewportChar = ghostChar:Clone()
				ghostViewportChar.Parent = self.viewportWindowB.worldViewportFrame
			end
			setCopy(char, ghostChar, otherSideCFrame)
			setCopy(char, ghostViewportChar, otherSideCFrame)
			setCopy(char, viewportChar, char:GetPivot())

			ghostChar.Parent = self.portalA
		elseif self.portalA:FindFirstChild("Char") then
			self.portalA:FindFirstChild("Char"):Destroy()
		end
	end

	if not useViewportGhosts then
		if self.viewportWindowA.worldViewportFrame:FindFirstChild("Char") then
			self.viewportWindowA.worldViewportFrame:FindFirstChild("Char"):Destroy()
		end
		if self.viewportWindowB.worldViewportFrame:FindFirstChild("Char") then
			self.viewportWindowB.worldViewportFrame:FindFirstChild("Char"):Destroy()
		end
	end

	return nil
end

function Portal.new(
	cframeA: CFrame,
	cframeB: CFrame,
	noCollideA: { BasePart },
	noCollideB: { BasePart },
	scene: Model
): Portal
	local self = setmetatable({}, Portal) :: Portal
	self.cframeA = cframeA
	self.cframeB = cframeB
	self.noCollideA = noCollideA
	self.noCollideB = noCollideB

	self.noCollisionContraintsA = {}
	self.noCollisionContraintsB = {}

	self.portalA = PortalReference:Clone()
	self.portalA.Parent = workspace
	self.portalA:PivotTo(cframeA)

	self.portalB = PortalReference:Clone()
	self.portalB.Parent = workspace
	self.portalB:PivotTo(cframeB)

	self.viewportWindowA = viewportWindow.fromPart(self.portalA.Display, Enum.NormalId.Front)
	self.viewportWindowB = viewportWindow.fromPart(self.portalB.Display, Enum.NormalId.Front)
	self.viewportWindowA.worldViewportFrame.LightDirection = -game.Lighting:GetSunDirection()
	self.viewportWindowB.worldViewportFrame.LightDirection = -game.Lighting:GetSunDirection()
	self.viewportWindowA.worldViewportFrame.Ambient = AMBIENT_COLOR
	self.viewportWindowB.worldViewportFrame.Ambient = AMBIENT_COLOR
	self.viewportWindowA.skyboxViewportFrame.Ambient = LIGHT_COLOR
	self.viewportWindowB.skyboxViewportFrame.Ambient = LIGHT_COLOR

	self.sceneA = scene:Clone()
	self.sceneA.Parent = self.viewportWindowA.worldViewportFrame
	self.sceneB = scene:Clone()
	self.sceneB.Parent = self.viewportWindowB.worldViewportFrame
	return self
end

return Portal
