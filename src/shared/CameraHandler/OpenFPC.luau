local FlagStandService = game:GetService("FlagStandService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptProfilerService = game:GetService("ScriptProfilerService")
local StudioData = game:GetService("StudioData")
local doDamageFlash = require(ReplicatedStorage.Shared.Util.doDamageFlash)
return {
	BreathingEnabled = true,
	BreathingScale = { X = 0, Y = 0.5 },
	BreathingSpeed = 3,

	TiltingEnabled = true, --Allow the camera to tilt when moving left or right
	TiltAngle = 1, --In degrees
	TiltSpeed = 8,
	TiltDamper = 0.8,

	LookSwayEnabled = true,
	LookSwayMaxAngle = { X = 2, Y = 0.5 }, --In Degrees
	LookSwayMouseDamper = { X = 1, Y = 12 },
	LookSwaySpeed = 10,
	LookSwayDamper = 0.65,

	LandEffectEnabled = true, --Allow the camera to tilt when the player lands
	LandEffectVelocity = 5,
	LandEffectSpeed = 8,
	LandEffectDamper = 0.6,
	dawdw = 1,
	hallo = 2,
	bye = 32321,
}
