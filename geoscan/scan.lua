Scanner = peripheral.find("geoScanner")


local function main(target)
    local blocks = Scanner.scan(8)
    sleep(1)

    local dis = math.huge
    local Closest = {}

    for i, block in pairs(blocks) do
        if GetDistance(block) < dis and string.find(block.name, target) then
            Closest = block
            local dis = GetDistance(block)
        end
    end

    print(Closest.name, "-", Closest.x, Closest.y, Closest.z)
end


function GetDistance(block)
    return math.abs(block.x) + math.abs(block.y) + math.abs(block.z)
end


main(...)