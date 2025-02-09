local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local module = {}

local function playVisualTweens(Part, order: number)
	local delayNum = 0.012 * order

	if order > 300 then
		delayNum = (0.012 * 300) + (0.004 * order - 0.004 * 300)
	end

	task.delay(delayNum, function()
		local copyPart = Part:Clone()
		copyPart.Size = Part.Size + Vector3.new(0.05, 0.05, 0.05)
		copyPart.Color = Color3.fromRGB(2, 112, 255)
		copyPart.Transparency = 1
		copyPart.Parent = workspace
		copyPart.CanCollide = false
		copyPart.Material = Enum.Material.Neon

		for _, a in ipairs(copyPart:GetChildren()) do
			a:Destroy()
		end

		for _, p in ipairs(ReplicatedStorage.Assets.Models.GoneParticles:GetChildren()) do
			local r = math.random(1, 4)
			if r == 4 then
				local c = p:Clone()
				c.Parent = copyPart
				task.delay(0.1, function()
					c:Emit(4)
				end)
			end
		end

		if order % 2 == 0 then
			local s = ReplicatedStorage.Assets.Sounds.Warp:Clone()
			s.Parent = copyPart
			s:Play()
		end

		local tween = TweenService:Create(
			copyPart,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{ Transparency = 0 }
		)
		tween:Play()
		task.wait(0.2)
		Part.Transparency = 1
		for _, a in ipairs(Part:GetChildren()) do
			a:Destroy()
		end

		local tween2 = TweenService:Create(
			copyPart,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 1, Position = copyPart.Position + Vector3.new(0, 1, 0), Size = copyPart.Size / 2 }
		)

		task.wait(0.2)

		tween2:Play()
		tween2.Completed:Wait()

		Part:Destroy()

		task.wait(1)

		copyPart:Destroy()
	end)
end

local function breakJoints(Object: Instance)
	if not Object:IsA("BasePart") then
		for _, OtherObject in Object:GetDescendants() do
			breakJoints(OtherObject)
		end
	else
		for _, Joint in Object:GetJoints() do
			Joint:Destroy()
		end
	end
end

local block_size = 0.6
local function fillPart(volume: BasePart)
	local left_lower_front_corner = -volume.Size / 2
	local first_block_pos = left_lower_front_corner + Vector3.new(block_size / 2, block_size / 2, block_size / 2)

	for x = 0, volume.Size.X - block_size, block_size do
		for y = 0, volume.Size.Y - block_size, block_size do
			for z = 0, volume.Size.Z - block_size, block_size do
				local r = math.random(1,2)
				local templateBlock 
				if r == 1 then
					templateBlock = ReplicatedStorage.Assets.Models.AnimTrail:Clone()
				else
					templateBlock = ReplicatedStorage.Assets.Models.AnimTrail2:Clone()
				end
				templateBlock.Material = Enum.Material.Neon
				templateBlock.Size = Vector3.new(0.5, 0.5, 0.5)
				templateBlock.Anchored = false
				templateBlock.CanCollide = true
				--templateBlock.Color = Color3.fromRGB(2, 112, 255)
				templateBlock.CollisionGroup = "Particle"
				templateBlock.AssemblyLinearVelocity = volume.AssemblyLinearVelocity
				templateBlock.AssemblyAngularVelocity = volume.AssemblyAngularVelocity

				local block_offset_objectspace = Vector3.new(x, y, z)
				local block_cframe = volume.CFrame * CFrame.new(first_block_pos + block_offset_objectspace)

				templateBlock.CFrame = block_cframe
				templateBlock.Parent = game.Workspace

				task.delay(math.random(10,30)/10, function()
					templateBlock.Trail.Enabled = false
					local t = TweenService:Create(
						templateBlock,
						TweenInfo.new(math.random(8, 100) / 100, Enum.EasingStyle.Quad),
						{ Size = Vector3.new(0, 0, 0), Transparency = 1 }
					)
					t:Play()
					t.Completed:Wait()
					templateBlock:Destroy()
				end)
			end
		end
	end
end

module.DestroyCharacter = function(character: Character)
	local Parts = {}
	for _, Part in ipairs(character:GetChildren()) do
		if Part:IsA("BasePart") then
			table.insert(Parts, Part)
		end
	end

	local impulseCenter = (character.PrimaryPart.CFrame * CFrame.new(0, -5, -20)).Position

	for _, Part: BasePart in ipairs(Parts) do
		if Part.Name == "UpperTorso" then
			Part.Parent = workspace
			Part.Anchored = true
			Part.CanCollide = false
			Debris:AddItem(Part, 6)
			for _, p in ipairs(ReplicatedStorage.Assets.Models.ExplosionParticles:GetChildren()) do
				local c = p:Clone()
				c.Parent = Part
				task.delay(0.1, function()
					c:Emit(4)
					task.wait(4)
					c:Destroy()
				end)
			end
			local r = math.random(1, 3)
			for _, s in ipairs(ReplicatedStorage.Assets.Sounds["Eliminate" .. r]:GetChildren()) do
				local c = s:Clone()
				c.Parent = Part
				c.PlayOnRemove = true
				c:Destroy()
			end
		end
		Part.Transparency = 1

		local connectionVector = (Part.Position - impulseCenter).Unit

		Part.AssemblyLinearVelocity = connectionVector * 40 + Vector3.new((math.random() - 0.5) * 20, (math.random() - 0.5) * 50, (math.random() - 0.5) * 20) + Vector3.new(0,20,0)

		fillPart(Part)
	end

	character:Destroy()
end

module.Play = function(Parts: {})
	local order = 1
	for _, PartToSimulate in ipairs(Parts) do
		if PartToSimulate.isModel == true then
			local base = PartToSimulate.Part

			if base.Parent then
				for i, ModelPart in base.Parent:GetChildren() do
					if ModelPart:IsA("BasePart") then
						playVisualTweens(ModelPart, order)
					end
				end
				order += 1
			end
		else
			if PartToSimulate.Part:IsA("BasePart") then
				playVisualTweens(PartToSimulate.Part, order)
				order += 1
			end
		end
	end
end

module.BuildCircularPattern = function(SimulationObject: Folder | Model, startPosition: Vector3)
	local Parts = {}
	for _, Part in ipairs(SimulationObject:GetChildren()) do --Table füllen
		if Part:IsA("BasePart") then
			if Part.Transparency ~= 1 then
				table.insert(Parts, { Part = Part, Pos = Part.Position, isModel = false })
			else
				Part:Destroy()
			end
		elseif Part:IsA("Model") or Part:IsA("Folder") then
			for _, innerPart in ipairs(Part:GetChildren()) do
				if innerPart:IsA("BasePart") then
					if innerPart.Transparency ~= 1 then
						table.insert(Parts, { Part = innerPart, Pos = innerPart.Position, isModel = true })
					else
						innerPart:Destroy()
					end
					break
				end
			end
		end
	end

	--Magnitudes ausrechnen (pls dont kill me) i'll

	for _, PartObject in ipairs(Parts) do
		local offset = PartObject.Part.Position - startPosition
		local magnitudeSquared = offset:Dot(offset)

		PartObject.MagnitudeSquared = magnitudeSquared
	end

	table.sort(Parts, function(Value1, Value2)
		return Value1.MagnitudeSquared < Value2.MagnitudeSquared
	end)

	return Parts
end

return module
