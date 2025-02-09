return function(part: BasePart)
	return part.Position + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * part.Size
end