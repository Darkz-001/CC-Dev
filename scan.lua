target = ...

function main(target)
    scanner = peripheral.find("geoScanner")

    blocks = scanner.scan(8)

    dis = math.huge

    for i, block in pairs(blocks) do
        if getDistance(block) < dis and string.find(block.name, target) then
            Closest = block
        end
    end

    print(Closest.name, "-", Closest.x, Closest.y, Closest.z)
end


function getDistance(block)
    return math.abs(block.x) + math.abs(block.y) + math.abs(block.z)
end