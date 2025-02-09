--!nocheck
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenService = game:GetService("TweenService")

local HighlightModule = require(script.Parent.HighlightModule)

local MAX_DISTANCE = 100
local MAX_HIGHLIGHTS = 25
local GUI_FLASH_DURATION = 0.55
local GUI_START_TRANSPARENCY = 0.1

local Player = Players.LocalPlayer

local RedGui = Player.PlayerGui:WaitForChild("Effects"):WaitForChild("SmallRed")

local function screenFlashRed()
	local lighting = game.Lighting.CombatColorCorrection
	lighting.TintColor = Color3.fromRGB(255, 210, 210)

	local Tween = TweenService:Create(lighting, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TintColor = Color3.fromRGB(255, 255, 255)})
	Tween:Play()
end
local function playDamageSound()
    local newHitSound = ReplicatedStorage.Assets.Sounds.damage_hit:Clone()
		newHitSound.Parent = workspace.CurrentCamera
		newHitSound.PlayOnRemove = true
		newHitSound:Destroy()
end
local function tweenGuiFlash()
    RedGui.ImageTransparency = GUI_START_TRANSPARENCY
    local GuiTween = TweenService:Create(RedGui, TweenInfo.new(GUI_FLASH_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 1})
    GuiTween:Play()
end

local lastStoredPosition = Vector3.new(0,0,0)
local currentDamageFlashes = 0
local function doDamageFlash(Character)
    if Character == Player.Character then --Play local damage flash
        tweenGuiFlash()
        playDamageSound()
        screenFlashRed()
    end

    if not Character:FindFirstChild("HumanoidRootPart") then return end

    local middlePosition = Character.HumanoidRootPart.Position
    lastStoredPosition = (Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.HumanoidRootPart.Position) or lastStoredPosition

    local playerPosition = lastStoredPosition

    local distance = (middlePosition-playerPosition).Magnitude

    if distance < MAX_DISTANCE then --occlude flashes far away from the player
        if currentDamageFlashes < MAX_HIGHLIGHTS then --ensure, limit of 31 never gets hit
            currentDamageFlashes += 1
            HighlightModule.damageFlash(Character) 
            currentDamageFlashes -= 1
        end
    end
end

return doDamageFlash