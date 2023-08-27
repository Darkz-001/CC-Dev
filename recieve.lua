CHANNEL = 1204

function loadCommands()
    COMMANDS = {
        --["name"] = function
        ["break"] = dig,
        ["move"] = move,
        ["turn"] = turn,
        ["eval"] = evaluateSlot,
        ["select"] = selectSlot,
        ["refuel"] = refuel,
        ["inspect"] = inspect,
        ["place"] = place,
        ["getdistance"] = function () return "You shouldn't see this" end,
        ["terminate"] = function () return "Goodbye!" end,
        ["put"] = put,
        ["take"] = take,
        ["emit"] = emit,
        ["rebootother"] = rebootOther
    }
end


function main()
    loadCommands()
    modem = peripheral.find("modem")
    if modem == nil then
        print("No modem attached")
        return nil
    end
    modem.open(CHANNEL)
    local command = "start"
    while command ~= "terminate" do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        local reply = "You shouldn't see this"
        if channel == CHANNEL then
            local tokens = splitTokens(message, true)
            command = table.remove(tokens, 1)
            func = COMMANDS[command]
            if func ~= nil then
                reply = func(table.unpack(tokens))
                if command == "getdistance" then
                    reply = tostring(distance)
                end
            else
                reply = "Invalid Command"
            end
        else
            reply = "Connection closed"
        end
        modem.transmit(replyChannel, CHANNEL, reply)
    end
end

function move(n, dir, mine)
    if n == nil then
        return "This function has 1 required argument: a number of spaces (and an optionally a direction and if it should mine)"
    end

    if dir == nil then
        dir = "forward"
    end

    if string.find(" false no n _ void nil ", " " .. tostring(mine) .. " ") then
        mine = false
    end
    
    dir = string.lower(dir)
    n = tonumber(n)
    
    if n == nil then
        return "You must move a NUMBER of spaces"
    end
    
    if dir == "forward" or dir == "f" then
        for i = 1, n do
            if mine then
                turtle.dig()
            end
            turtle.forward()
        end
    elseif dir == "up" or dir == "u" then
        for i = 1, n do
            if mine then
                turtle.digUp()
            end
            turtle.up()
        end
    elseif dir == "down" or dir == "d" then
        for i = 1, n do
            if mine then
                turtle.digDown()
            end
            turtle.down()
        end
    elseif dir == "right" or dir == "r" then
        turtle.turnRight()
        move(n, "forward", mine)
        turtle.turnLeft()
    elseif dir == "left" or dir == "l" then
        turtle.turnLeft()
        move(n, "forward", mine)
        turtle.turnRight()
    elseif dir == "back" or dir == "b" then
        if mine then
            turtle.turnLeft()
            turtle.turnLeft()
            move(n, "forward", true)
            turtle.turnLeft()
            turtle.turnLeft()
        else
            for i = 1, n do
                turtle.back()
            end
        end
    else
        return "Invalid Direction"
    end
    
    local fuel = turtle.getFuelLevel()
    if fuel > 300 then
        return "Arrived"
    else
        return "Only " .. tostring(fuel) .. " blocks of movement left"
    end
end


function selectSlot(n)
    if n == nil then
        return "This function has 1 arguement: the slot to select (1-16)"
        end
        n = tonumber(n)
        if n == nil then
            return "Slot must be a NUMBER"
        end
        
        if n < 1 or n > 16 then
            return "Slot must be between 1 and 16"
        end
        
        turtle.select(n)
        return "Selected slot: " .. tostring(n)
    end
    
    
    function evaluateSlot(n)
        n = tonumber(n)
        if n ~= nil then
            if n < 1 or n > 16 then
                return "Slot must be between 1 and 16"
            end
        end
        
        local item = turtle.getItemDetail(n)
        
        if item ~= nil then
            return tostring(item.name) .. " - " .. tostring(item.count)
        else
            return "No item in slot"
    end
end


function refuel()
    local fueled = turtle.refuel()
    
    if fueled then
        return "You now have " .. tostring(turtle.getFuelLevel()) .. " units of fuel"
    else
        return "Currently selected item is not fuel"
    end
end


function turn(dir)
    dir = string.lower(dir)
    if dir == "left" or dir == "l" then
        turtle.turnLeft()
    elseif dir == "right" or dir == "r" then
        turtle.turnRight()
    elseif tonumber(dir) then
        local n = tonumber(dir)
        for i = 1, n do
            turtle.turnRight()
        end
    else
        return "Invalid/No direction"
    end
    
    return 'turned ig'
end

function inspect(dir)
    dir = string.lower(dir)
    if dir == nil then
        dir = "forward"
    end
    
    local isThere = nil
    local data = {}
    
    if dir == "forward" or dir == "f" then
        isThere, data = turtle.inpect()
    elseif dir == "up" or dir == "u" then
        isThere, data = turtle.inspectUp()
    elseif dir == "down" or dir == "d" then
        isThere, data = turtle.inspectDown()
    else
        return "Invalid direction"
    end
    
    if isThere then
        if type(data) == "table" then
            return tostring(data.name)
        else
            return(tostring(data))
        end
    else
        return "No block present"
    end
end


function dig(dir)
    if dir == nil then
        dir = "forward"
    end
    
    local ret
    
    if dir == "forward" or dir == "f" then
        _, ret = turtle.dig()
    elseif dir == "up" or dir == "u" then
        _, ret = turtle.digUp()
    elseif dir == "down" or dir == "d" then
        _, ret = turtle.digDown()
    else
        return "Invalid direction"
    end
    
    if ret then
        return ret
    else
        return "Block broken"
    end
end


function place(dir, text)
    if dir == nil then
        dir = "forward"
    end
    
    local ret
    
    if dir == "forward" or dir == "f" then
        _, ret = turtle.place(text)
    elseif dir == "up" or dir == "u" then
        _, ret = turtle.placeUp(text)
    elseif dir == "down" or dir == "d" then
        _, ret = turtle.placeDown(text)
    else
        return "Invalid direction"
    end
    
    if ret then
        return ret
    else
        return "Block placed"
    end
end


function put(dir, all)
    local temp = turtle.drop()
    if string.find(" false no n _ void nil ", " " .. tostring(all) .. " ") then
        all = false
    end
    
    local temp, d
    
    if dir == "forward" or dir == "f" then
        d = turtle.drop
    elseif dir == "up" or dir == "u" then
        d = turtle.dropUp
    elseif dir == "down" or dir == "down" then
        d = turtle.dropDown
    else
        return "Invalid direction"
    end
    
    if all then
        local slot, n = turtle.getSelectedSlot(), 0
        for i = 1, 16 do
            turtle.select(i)
            if d() then
                n = n + 1
            end
        end
        turtle.select(slot)
        temp = "Put away " .. tostring(n) .. " different items"
    else
        temp = d()
    end
    
    return tostring(temp)
end


function take(dir, all)
    if dir == nil then
        dir = "forward"
    end

    if string.find(" false no n _ void nil ", " " .. tostring(all) .. " ") then
        all = false
    end
    
    local temp, d
    
    if dir == "forward" or dir == "f" then
        d = turtle.suck
    elseif dir == "up" or dir == "u" then
        d = turtle.suckUp
    elseif dir == "down" or dir == "down" then
        d = turtle.suckDown
    else
        return "Invalid direction"
    end
    
    if all then
        local n = 0
        while d() do n = n + 1 end
        temp = "Got " .. tostring(n) .. " different items"
    else
        temp = d()
    end
    
    return tostring(temp)
end


function emit(side, sec)
    if string.find(" front back left right top bottom ", " " .. side .. " ") then
        if sec == nil then
            sec = 0.5
        else
            sec = tonumber(sec)
            if sec == nil then
                return "Seconds must be a NUMBER"
            end
        end
        redstone.setOutput(side, true)
        sleep(sec)
        redstone.setOutput(side, false)
    else
        return "Invalid side"
    end
    
    return "Signal emitted"
end


function rebootOther()
    local other = peripheral.find("computer")
    if other == nil then
        other = peripheral.find("turtle")
    end
    
    if other == nil then
        return "No computer to reboot"
    end
    
    if other.isOn() then
        other.reboot()
    else
        other.turnOn()
    end
end


function splitTokens(str, lower)
    local t = {}
    for token in string.gmatch(str, "[^%s]+") do
        if lower then
            table.insert(t, string.lower(token))
        else
            table.insert(t, token)
        end
    end
    return t
end


main()
