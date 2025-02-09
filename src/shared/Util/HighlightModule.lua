local HighlightModule = {}

local RStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Effects = RStorage:WaitForChild("Assets"):WaitForChild("Effects")

local DAMAGE_FLASH_DURATION = 0.3
local VOID_DMG_FLASH_DURATION = 0.07

function HighlightModule.damageFlash(AdorneePart,void)
	local DamageIndicator = Instance.new("Highlight")

	DamageIndicator.OutlineTransparency = 1
	DamageIndicator.FillColor = Color3.fromRGB(255, 255, 255)
	DamageIndicator.FillTransparency = 0.2
	DamageIndicator.DepthMode = Enum.HighlightDepthMode.Occluded
	
	DamageIndicator.Parent = AdorneePart
	DamageIndicator.Adornee = AdorneePart
	DamageIndicator.Enabled = true

	local duration = void and VOID_DMG_FLASH_DURATION or DAMAGE_FLASH_DURATION

	local TweenGoals = {}
	TweenGoals.FillColor = Color3.fromRGB(255, 0, 0)
	local TweenGoals2 = {}
	TweenGoals2.FillTransparency = 1

	local DamageTween = TweenService:Create(DamageIndicator, TweenInfo.new(duration/2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), TweenGoals)
	local DamageTween2 = TweenService:Create(DamageIndicator, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), TweenGoals2)
	DamageTween:Play()
	DamageTween2:Play()
	
	task.wait(duration)
	if DamageIndicator then
		DamageIndicator:Destroy()
	end
end

function HighlightModule.entityDeathHighlight(AdorneePart)
	local WinnerIndicator = Effects.DamageIndicator:Clone()

	WinnerIndicator.Parent = AdorneePart
	WinnerIndicator.Adornee = AdorneePart
	WinnerIndicator.Enabled = true
end

return HighlightModule
