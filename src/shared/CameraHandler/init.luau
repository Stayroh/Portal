--!nocheck
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Configuration = require(script.OpenFPC)
local Spring = require(script:WaitForChild("Spring"))

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Camera = workspace.CurrentCamera

local CameraTick = 0
local Offstates = {"Jumping", "Freefall"}
local MouseDelta = nil

local SpeedSpring = Spring.new(0)
SpeedSpring.s = 16
local BreathAlphaSpring = nil
local TiltSpring = nil
local LookSwaySpring = nil
local LandEffectSpring = nil
if Configuration.BreathingEnabled then
	BreathAlphaSpring = Spring.new(1)
	BreathAlphaSpring.s = 8
	BreathAlphaSpring.d = 0.9
end
if Configuration.TiltingEnabled then
	TiltSpring = Spring.new(0)
	TiltSpring.s = Configuration.TiltSpeed
	TiltSpring.d = Configuration.TiltDamper
end
if Configuration.LookSwayEnabled then
	LookSwaySpring = Spring.new(Vector2.new())
	LookSwaySpring.s = Configuration.LookSwaySpeed
	LookSwaySpring.d = Configuration.LookSwayDamper
end
if Configuration.LandEffectEnabled then
	LandEffectSpring = Spring.new(0)
	LandEffectSpring.s = Configuration.LandEffectSpeed
	LandEffectSpring.d = Configuration.LandEffectDamper
end

Humanoid.StateChanged:Connect(function(OldState : Enum.HumanoidStateType, NewState : Enum.HumanoidStateType)
	if NewState == Enum.HumanoidStateType.Landed then
		if LandEffectSpring then
			LandEffectSpring:Impulse(-Configuration.LandEffectVelocity)
			task.delay(0.1, function()
				LandEffectSpring:Impulse(Configuration.LandEffectVelocity)
			end)
		end
	end
end)

local function GetBreathing(Alpha : number)
	return Vector3.new(Alpha * (Configuration.BreathingScale.X/10 * math.sin(tick() * Configuration.BreathingSpeed)), Alpha * (Configuration.BreathingScale.Y/10 * math.cos(tick() * Configuration.BreathingSpeed)), 0)
end

RunService.RenderStepped:Connect(function(DeltaTime : number)
	if workspace.CurrentCamera.CameraType == Enum.CameraType.Scriptable then return end

	local RelativeVector = CFrame.new().VectorToObjectSpace(Humanoid.RootPart.CFrame, Humanoid.RootPart.Velocity)
	local CurrentSpeed = (Vector3.new(1, 0, 1) * RelativeVector).magnitude
	local MoveDirection = Humanoid.RootPart.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)
	local IsActive = not table.find(Offstates, Humanoid:GetState().Name)
	MouseDelta = UserInputService:GetMouseDelta()
	SpeedSpring.t = IsActive and CurrentSpeed or 0
	if BreathAlphaSpring then BreathAlphaSpring.t = (not IsActive and 0 or CurrentSpeed > 0.1 and 0 or 1) end
	
	if TiltSpring then TiltSpring.t = -MoveDirection.X end
	if LookSwaySpring then LookSwaySpring.t = Vector2.new(math.clamp(MouseDelta.X/Configuration.LookSwayMouseDamper.X, -Configuration.LookSwayMaxAngle.X, Configuration.LookSwayMaxAngle.X), math.clamp(MouseDelta.Y/Configuration.LookSwayMouseDamper.Y, -Configuration.LookSwayMaxAngle.Y, Configuration.LookSwayMaxAngle.Y)) end
	CameraTick = CameraTick + DeltaTime * SpeedSpring.p
	
	Humanoid.CameraOffset = Vector3.new(SpeedSpring.p / 64 * math.sin(CameraTick / 2.15) + (Configuration.BreathingEnabled and GetBreathing(BreathAlphaSpring.p).X or 0), SpeedSpring.p / 82 * math.cos(CameraTick / 1.65) + (Configuration.BreathingEnabled and GetBreathing(BreathAlphaSpring.p).Y or 0), 0)
	Camera.CFrame = Camera.CFrame * CFrame.Angles((Configuration.LandEffectEnabled and math.rad(LandEffectSpring.p * (DeltaTime * 60)) or 0) + (Configuration.LookSwayEnabled and math.rad(LookSwaySpring.p.Y) or 0), 0, (Configuration.TiltingEnabled and math.rad(TiltSpring.p * Configuration.TiltAngle) or 0) + (Configuration.LookSwayEnabled and math.rad(LookSwaySpring.p.X) or 0))
end)

return 42