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
	__index: PortalClass,
	updateViewportParts: (self: Portal) -> nil,
	updateCollisions: (self: Portal, isPortalA: boolean) -> nil,
	updatePhysics: (self: Portal, isPortalA: boolean) -> nil,
	updateTouchingParts: (self: Portal, isPortalA: boolean) -> nil,
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
		scene: Model,
		touchingPartsA: { [BasePart]: { real: BasePart, fake1: BasePart, fake2: BasePart } },
		touchingPartsB: { [BasePart]: { real: BasePart, fake1: BasePart, fake2: BasePart } },
		scenePartAdded: RBXScriptConnection,
		scenePartRemoving: RBXScriptConnection,
		viewportParts: { [BasePart]: { A: BasePart, B: BasePart } },
		sceneB: Model,
		active: boolean,
		viewportChar: { A: Model, B: Model }?,
		viewportWindowA: viewportWindow.ViewportWindow,
		viewportWindowB: viewportWindow.ViewportWindow,
		noCollisionContraintsA: {
			[BasePart]: {
				Constraints: { NoCollisionConstraint },
			},
		},
		noCollisionContraintsB: {
			[BasePart]: {
				Constraints: { NoCollisionConstraint },
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
	if not self.active then
		return nil
	end

	local camera = workspace.CurrentCamera
	local cameraCFrame = camera.CFrame

	local surfaceACF, surfaceASize = self.viewportWindowA:GetSurfaceCFrameSize()
	local surfaceBCF, surfaceBSize = self.viewportWindowB:GetSurfaceCFrameSize()

	local rotatedSurfaceBCF = surfaceBCF * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)
	local rotatedSurfaceACF = surfaceACF * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)

	local renderACF = rotatedSurfaceBCF * surfaceACF:ToObjectSpace(cameraCFrame)
	local renderBCF = rotatedSurfaceACF * surfaceBCF:ToObjectSpace(cameraCFrame)

	self:updatePhysics(true)
	self:updateCollisions(true)
	self:updateCollisions(false)
	self:updateViewportParts()
	self:updateTouchingParts(true)
	self:updateTouchingParts(false)
	self.viewportWindowA:RenderManual(renderACF, rotatedSurfaceBCF, surfaceBSize)
	self.viewportWindowB:RenderManual(renderBCF, rotatedSurfaceACF, surfaceASize)

	return nil
end

function Portal:updateTouchingParts(isPortalA: boolean)
	local newParts = game.Workspace:GetPartsInPart((isPortalA and self.portalA or self.portalB).Hitbox)
	local touchingParts = isPortalA and self.touchingPartsA or self.touchingPartsB
	local char = game.Players.LocalPlayer.Character
	local newTracker = {}

	local foundChar = false

	for _, part in pairs(newParts) do
		if part.Anchored then
			continue
		end
		if part:IsDescendantOf(char) then
			foundChar = true
			continue
		end
		if not part:IsDescendantOf(self.scene) then
			continue
		end
		newTracker[part] = true
		if not touchingParts[part] then
			--NewPartAction
			local realPart = part:Clone()
			--Transform the part to the other portal
			realPart.Anchored = true
			realPart.CanCollide = false
			realPart.CanTouch = false
			realPart.CanQuery = false
			realPart.CFrame = ((isPortalA and self.cframeB or self.cframeA) * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)):ToWorldSpace(
				(isPortalA and self.cframeA or self.cframeB):ToObjectSpace(part.CFrame)
			)
			realPart.Parent = (isPortalA and self.portalA or self.portalB).Illusion
			local fakePart1, fakePart2 = realPart:Clone(), realPart:Clone()
			fakePart1.Parent = (isPortalA and self.viewportWindowB or self.viewportWindowA).worldViewportFrame
			fakePart2.Parent = (isPortalA and self.viewportWindowA or self.viewportWindowB).worldViewportFrame
			touchingParts[part] = { real = realPart, fake1 = fakePart1, fake2 = fakePart2 }
		else
			--UpdatePartAction
			local realPart = touchingParts[part].real
			realPart.CFrame = ((isPortalA and self.cframeB or self.cframeA) * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)):ToWorldSpace(
				(isPortalA and self.cframeA or self.cframeB):ToObjectSpace(part.CFrame)
			)
			local fakePart1, fakePart2 = touchingParts[part].fake1, touchingParts[part].fake2
			fakePart1.CFrame = realPart.CFrame
			fakePart2.CFrame = realPart.CFrame
		end
	end

	for part, _ in pairs(touchingParts) do
		if not newTracker[part] then
			--RemoveAction
			touchingParts[part].real:Destroy()
			touchingParts[part].fake1:Destroy()
			touchingParts[part].fake2:Destroy()
			touchingParts[part] = nil
		end
	end
end

function Portal:updateViewportParts()
	local char = game:GetService("Players").LocalPlayer.Character
	if char and not self.viewportChar then
		char.Archivable = true
		self.viewportChar = { A = char:Clone(), B = char:Clone() }
		self.viewportChar.A.Parent = self.viewportWindowA.worldViewportFrame
		self.viewportChar.B.Parent = self.viewportWindowB.worldViewportFrame
	elseif char and self.viewportChar then
		setCopy(char, self.viewportChar.A, char.HumanoidRootPart.CFrame)
		setCopy(char, self.viewportChar.B, char.HumanoidRootPart.CFrame)
	elseif not char and self.viewportChar then
		self.viewportChar.A:Destroy()
		self.viewportChar.B:Destroy()
		self.viewportChar = nil
	end

	for part, viewportPart in pairs(self.viewportParts) do
		local partA, partB = viewportPart.A, viewportPart.B
		local partCFrame = part.CFrame
		partA.CFrame = partCFrame
		partB.CFrame = partCFrame
	end
	return nil
end

function Portal:updateScene(scene: Model)
	self.scene = scene
	if self.scenePartAdded then
		self.scenePartAdded:Disconnect()
	end
	if self.scenePartRemoving then
		self.scenePartRemoving:Disconnect()
	end

	if self.sceneA then
		self.sceneA:Destroy()
	end

	self.sceneA = scene:Clone()
	for _, part in pairs(self.sceneA:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end
		if part.Anchored then
			continue
		end
		part:Destroy()
	end
	self.sceneA.Parent = self.viewportWindowA.worldViewportFrame

	if self.sceneB then
		self.sceneB:Destroy()
	end
	self.sceneB = self.sceneA:Clone()
	self.sceneB.Parent = self.viewportWindowB.worldViewportFrame

	for _, viewportPart in pairs(self.viewportParts) do
		viewportPart.A:Destroy()
		viewportPart.B:Destroy()
	end

	self.viewportParts = {}

	local function createViewportPart(part: BasePart)
		if self.viewportParts[part] then
			return
		end
		if part.Name == "Dieter" then
			print("Found Dieter")
		end
		local partA, partB = part:Clone(), part:Clone()
		partA.Parent = self.viewportWindowA.worldViewportFrame
		partB.Parent = self.viewportWindowB.worldViewportFrame
		self.viewportParts[part] = { A = partA, B = partB }
	end

	for _, part in pairs(scene:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end
		if part.Anchored then
			continue
		end
		createViewportPart(part)
	end
	self.scenePartAdded = scene.DescendantAdded:Connect(function(part)
		if not part:IsA("BasePart") then
			return
		end
		if part.Anchored then
			return
		end
		createViewportPart(part)
	end)
	self.scenePartRemoving = scene.DescendantRemoving:Connect(function(part)
		if not part:IsA("BasePart") then
			return
		end
		if self.viewportParts[part] then
			self.viewportParts[part].A:Destroy()
			self.viewportParts[part].B:Destroy()
			self.viewportParts[part] = nil
		end
	end)

	return nil
end

function Portal:destroy()
	self.active = false
	self.portalA:Destroy()
	self.portalB:Destroy()
	self.sceneA:Destroy()
	self.sceneB:Destroy()
	self.viewportWindowA:Destroy()
	self.viewportWindowB:Destroy()

	for _, noCollide in pairs(self.noCollisionContraintsA) do
		for _, constraint in pairs(noCollide.Constraints) do
			constraint:Destroy()
		end
	end

	for _, noCollide in pairs(self.noCollisionContraintsB) do
		for _, constraint in pairs(noCollide.Constraints) do
			constraint:Destroy()
		end
	end

	return nil
end

function Portal:updatePhysics(isPortalA: boolean)
	local touchingParts = game.Workspace:GetPartsInPart((isPortalA and self.portalA or self.portalB).Hitbox)

	if isPortalA then
		self:updatePhysics(false)
	end

	local char = game.Players.LocalPlayer.Character

	local foundChar = false

	for _, part in pairs(touchingParts) do
		if part.Anchored then
			continue
		elseif part:IsDescendantOf(char) then
			foundChar = true
			continue
		end
		local portalCFrame = isPortalA and self.cframeA or self.cframeB
		local toPortalOffset = portalCFrame:ToObjectSpace(part.CFrame)
		--check wether the center of the part is behind the portal
		if toPortalOffset.Z > 0 then
			--TP the part to the other portal and handle velocity
			local otherPortalCFrame = isPortalA and self.cframeB or self.cframeA
			local velocity = part.Velocity
			local newCFrame = (otherPortalCFrame * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)):ToWorldSpace(
				toPortalOffset
			)
			local newVelocity = (otherPortalCFrame * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)):VectorToWorldSpace(
				portalCFrame:VectorToObjectSpace(velocity)
			)
			part.CFrame = newCFrame
			part.AssemblyLinearVelocity = newVelocity
		end
	end

	if foundChar and char then
		local portalCFrame = isPortalA and self.cframeA or self.cframeB
		local toPortalOffset = portalCFrame:ToObjectSpace(char.HumanoidRootPart.CFrame)
		--check wether the center of the part is behind the portal
		if toPortalOffset.Z > 0 then
			--TP the part to the other portal and handle velocity
			local otherPortalCFrame = isPortalA and self.cframeB or self.cframeA
			local velocity = char.HumanoidRootPart.AssemblyLinearVelocity
			local newCFrame = (otherPortalCFrame * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)):ToWorldSpace(
				toPortalOffset
			)
			local newVelocity = (otherPortalCFrame * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)):VectorToWorldSpace(
				portalCFrame:VectorToObjectSpace(velocity)
			)
			char:PivotTo(CFrame.lookAlong(newCFrame.Position, char.HumanoidRootPart.CFrame.LookVector))
			game.Workspace.CurrentCamera.CFrame =
				CFrame.lookAlong(game.Workspace.CurrentCamera.CFrame.Position, newCFrame.LookVector)
			char.HumanoidRootPart.AssemblyLinearVelocity = newVelocity
		end
	end

	return nil
end

function Portal:updateCollisions(isPortalA: boolean)
	local newParts = game.Workspace:GetPartsInPart((isPortalA and self.portalA or self.portalB).Hitbox)
	local newTracker = {}

	local noCollisionConstraints = isPortalA and self.noCollisionContraintsA or self.noCollisionContraintsB
	for _, part in pairs(newParts) do
		if part.Anchored then
			continue
		end
		newTracker[part] = true

		if not noCollisionConstraints[part] then
			--NewPartAction
			noCollisionConstraints[part] = { Constraints = {} }
			for i, noCollide in pairs(isPortalA and self.noCollideA or self.noCollideB) do
				local constraint = Instance.new("NoCollisionConstraint")
				constraint.Part0 = part
				constraint.Part1 = noCollide
				constraint.Parent = part
				noCollisionConstraints[part].Constraints[i] = constraint
			end
		end
	end

	for part, _ in pairs(noCollisionConstraints) do
		if not newTracker[part] then
			--RemoveAction
			for _, constraint in pairs(noCollisionConstraints[part].Constraints) do
				constraint:Destroy()
			end
			noCollisionConstraints[part] = nil
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
	self.active = true

	self.cframeA = cframeA
	self.cframeB = cframeB
	self.noCollideA = noCollideA
	self.noCollideB = noCollideB

	self.noCollisionContraintsA = {}
	self.noCollisionContraintsB = {}

	self.touchingPartsA = {}
	self.touchingPartsB = {}

	self.portalA = PortalReference:Clone()
	self.portalA.Parent = workspace
	self.portalA:PivotTo(cframeA)

	self.portalB = PortalReference:Clone()
	self.portalB.Parent = workspace
	self.portalB:PivotTo(cframeB)
	self.scene = scene

	local Sky = game.Lighting:FindFirstChildOfClass("Sky")

	self.viewportWindowA = viewportWindow.fromPart(self.portalA.Display, Enum.NormalId.Front)
	self.viewportWindowB = viewportWindow.fromPart(self.portalB.Display, Enum.NormalId.Front)
	self.viewportWindowA.worldViewportFrame.LightDirection = -game.Lighting:GetSunDirection()
	self.viewportWindowB.worldViewportFrame.LightDirection = -game.Lighting:GetSunDirection()
	self.viewportWindowA.worldViewportFrame.Ambient = AMBIENT_COLOR
	self.viewportWindowB.worldViewportFrame.Ambient = AMBIENT_COLOR
	self.viewportWindowA.skyboxViewportFrame.Ambient = LIGHT_COLOR
	self.viewportWindowB.skyboxViewportFrame.Ambient = LIGHT_COLOR

	if Sky then
		self.viewportWindowA:SetSky(Sky)
		self.viewportWindowB:SetSky(Sky)
	end

	self.viewportParts = {}
	self:updateScene(scene)

	return self
end

return Portal
