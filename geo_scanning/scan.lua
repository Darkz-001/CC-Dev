Scanner = peripheral.find("geoScanner")


function main(target)
    blocks = Scanner.scan(8)
    sleep(1)

    dis = math.huge
    local Closest = {}

    for i, block in pairs(blocks) do
        if getDistance(block) < dis and string.find(block.name, target) then
            Closest = block
            dis = getDistance(block)
        end
    end

    print(Closest.name, "-", Closest.x, Closest.y, Closest.z)
end


function getDistance(block)
    return math.abs(block.x) + math.abs(block.y) + math.abs(block.z)
end


main(...)