return function(sound: Sound)
	local newSound = sound:Clone()

	newSound.PlayOnRemove = true
	newSound.Parent = workspace.CurrentCamera
	newSound:Destroy()
end