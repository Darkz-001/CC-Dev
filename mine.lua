function main(target, targetAmount)
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

    while obtained < targetAmount and turtle.getFuelLevel < getDistance(traveled) do
        
    end
end


-- Go to a realitive x y z
function GoTo(x, y, z)
    if x > 0 then
        forward(x)
    elseif x < 0 then
        turtle.turnLeft()
        turtle.turnLeft()
        forward(math.abs(x))
        turtle.turnLeft()
        turtle.turnLeft()
    end

    if z > 0 then
        turtle.turnRight()
        forward(z)
        turtle.turnLeft()
    elseif z < 0 then
        turtle.turnLeft()
        forward(math.abs(z))
        turtle.turnRight()
    end

    if y > 0 then
        for i = 1, y do
            while not turtle.forward() do
                turtle.dig()
            end
        end
    elseif y < 0 then
        for i = 1, y do
            while not turtle.forward() do
                turtle.dig()
            end
        end
    end
end


function addDistance(coords, otherCoords)
    coords.x = coords.x + otherCoords.x
    coords.y = coords.y + otherCoords.y
    coords.z = coords.z + otherCoords.z

    return coords
end


function forward(n)
    for i = 1, n do
        while not turtle.forward() do
            turtle.dig()
        end
    end
end


function find(target)
    scanner = peripheral.find("geoScanner")

    blocks = scanner.scan(8)

    dis = math.huge
    local closestBlock

    for i, block in pairs(blocks) do
        if getDistance(block) < dis and string.find(block.name, target) then
            closestBlock = block
        end
    end

    return closestBlock
end


function getDistance(block)
    return math.abs(block.x) + math.abs(block.y) + math.abs(block.z)
end


main(...)