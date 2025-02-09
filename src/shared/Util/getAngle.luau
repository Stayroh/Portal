-- returns the angle in radians between vecA and vecB
return function(vecA: Vector3, vecB: Vector3)
	return math.acos(vecA:Dot(vecB) / (vecA.Magnitude * vecB.Magnitude))
end
