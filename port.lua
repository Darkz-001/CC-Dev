port = peripheral.find("focal_port")

local function align_vector(plane, v2)
	if plane == "x" then
		return {x = 0, y = v2[1], z = v2[2]}
	elseif plane == "y" then
		return {x = v2[1], y = 0, z = v2[2]}
	elseif plane == "z" then
		return {x = v2[1], y = v2[2], z = 0}
	else
		error("invalid plane")
	end
end
	
local v2_mat = {
    { 1, 1}, { 1, 0}, { 1,-1},
    { 0, 1}, { 0, 0}, { 0,-1},
    {-1, 1}, {-1, 0}, {-1,-1}
}

planes = {"x","y","z"}
aligned = {}

for i, plane in ipairs(planes) do
    for j, v2 in pairs(v2_mat) do
        table.insert(aligned[i], align_vector(plane, v2))
    end
end

for plane, mat in pairs(aligned) do
    print("\n\n" .. plane)
    for i, v3 in ipairs(mat) do
        print(v3.x,v3.y,v3.z)
    end
end

port.writeIota(aligned)