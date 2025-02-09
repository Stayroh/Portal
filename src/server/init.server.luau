local Player 
while not Player do
    Player = game:GetService("Players"):FindFirstChildOfClass("Player")
    wait()
end

for _, part in pairs(workspace:GetDescendants()) do
    if part:IsA("BasePart") then
        if not part.Anchored then
            part:SetNetworkOwner(Player)
            print("part found")
        end
    end
end

workspace.DescendantAdded:Connect(function(part)
    if part:IsA("BasePart") then
        if not part.Anchored then
            part:SetNetworkOwner(Player)
            print("Part added")
        end
    end
end)