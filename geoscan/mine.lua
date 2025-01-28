Scanner = peripheral.find("geoScanner")

turtle.facing = 0 -- 0 = +X, 1 = -X, 2 = +Z, 3 = -Z

local function main(target, targetAmount)
    turtle.refuel()

    if turtle.getFuelLevel() < 1000 then
        print("You need at least 1000 units of fuel to start mining")
        return
    end

    if target == nil then
        print("Must provide a target")
        return
    elseif targetAmount == nil then
        print("must provide an amount of", target, "to mine")
        return
    elseif tonumber(targetAmount) == nil then
        print(targetAmount, "is not a NUMBER")
    end

    targetAmount = tonumber(targetAmount)

    local obtained = 0
    local traveled = {
        x = 0,
        y = 0,
        z = 0
    }

    local scanDistance = 1

    while obtained < targetAmount and turtle.getFuelLevel() > 2 * GetDistance(traveled) do
        local block = Find(target)
        if block ~= nil then
            GoTo(block.x, block.y, block.z)
            traveled = AddDistance(traveled, block)
            obtained = obtained + 1
            scanDistance = 1 -- set scan distance to 1 so if another block is close it will be found faster
        elseif scanDistance < 8 then
            scanDistance = scanDistance * 2
        elseif traveled.y == 0 then
            GoTo(9, 0, 0)
            traveled = AddDistance(traveled, {
                x = 9,
                y = 0,
                z = 0
            })
        else
            GoTo(0, -traveled.y, 0)
            traveled.y = 0
        end
    end
    GoTo(-traveled.x, -traveled.y, -traveled.z)
end


-- Go to a realitive x y z
function GoTo(x, y, z)
    if x > 0 then
        Forward(x)
    elseif x < 0 then
        turtle.turnLeft()
        turtle.turnLeft()
        Forward(math.abs(x))
        turtle.turnLeft()
        turtle.turnLeft()
    end

    if z > 0 then
        turtle.turnRight()
        Forward(z)
        turtle.turnLeft()
    elseif z < 0 then
        turtle.turnLeft()
        Forward(math.abs(z))
        turtle.turnRight()
    end

    if y > 0 then
        for i = 1, y do
            while not turtle.up() do
                turtle.digUp()
            end
        end
    elseif y < 0 then
        for i = 1, -y do
            while not turtle.down() do
                turtle.digDown()
            end
        end
    end
end


function AddDistance(coords, otherCoords)
    coords.x = coords.x + otherCoords.x
    coords.y = coords.y + otherCoords.y
    coords.z = coords.z + otherCoords.z

    return coords
end


function Forward(n)
    for i = 1, n do
        while not turtle.forward() do
            turtle.dig()
        end
    end
end


function Find(target, distance)
    if distance == nil then distance = 8 end

    local blocks = Scanner.scan(distance)
    
    while blocks == nil do
        blocks = Scanner.scan(distance)
        sleep(0.75)
    end

    local dis = math.huge
    local closestBlock

    for i, block in pairs(blocks) do
        if GetDistance(block) < dis and string.find(block.name, target) then
            closestBlock = block
            dis = GetDistance(block)
        end
    end

    return closestBlock
end


function GetDistance(block)
    return (math.abs(block.x) + math.abs(block.y) + math.abs(block.z))
end


main(...)
