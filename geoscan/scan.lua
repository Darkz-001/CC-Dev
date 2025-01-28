Unlimited_works = false

Scanner = peripheral.find("geoScanner")

if Unlimited_works then
    Scanner = peripheral.find("universal_scanner") -- different mod, different name and syntax
end

function Scan(distance)
    if Unlimited_works then
        return Scanner.scan("block", distance) -- different mod, different name and syntax
    end

    return Scanner.scan(distance)
end


local function main(target)
    local blocks = Scan(8)
    sleep(1)

    local dis = math.huge
    local Closest = {}

    for i, block in pairs(blocks) do
        if GetDistance(block) < dis and string.find(block.name, target) then
            Closest = block
            dis = GetDistance(block)
        end
    end

    print(Closest.name, "-", Closest.x, Closest.y, Closest.z)
end


function GetDistance(block)
    return math.abs(block.x) + math.abs(block.y) + math.abs(block.z)
end


main(...)