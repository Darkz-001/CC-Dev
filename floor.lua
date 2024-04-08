argv = {...}
argc = argv.length

function main(l, w, block, replace, n_dig_up)
    l, w = tonumber(l) - 1, tonumber(w)

    if replace == "false" then replace = false end
    if n_dig_up == "false" then n_dig_up = false end
    for i = 1, w do
        for j = 1, l do
            mineForward_placeDown(block, replace)
        end

        local turn
        if i%2 == 0 then
            turn = turtle.turnLeft
        else
            turn = turtle.turnRight
        end

        if i ~= w then
            turn()
            mineForward_placeDown(block, replace, n_dig_up)
            turn()
        end
    end
end


function mineForward_placeDown(block, replace, n_dig_up)
    while turtle.detect() do
        turtle.dig()
        sleep(0.1)
    end
    turtle.forward()
    if turtle.detectUp() and not(n_dig_up) then
        turtle.digUp()
    end

    if not turtle.detectDown() or replace then
        if turtle.detectDown() then
            turtle.digDown()
            sleep(0.1)
        end

        if turtle.getItemDetail() == nil then
            turtle.select(turtle.getSelectedSlot() + 1)
        elseif not string.find(turtle.getItemDetail().name, block) then
            turtle.select(turtle.getSelectedSlot() + 1)
        end

        turtle.placeDown()
    end

end

if argc == 0 or argv[1] == "-h" then
    print("Usage: floor dist_forward dist_right floor_block [replace_existing] [don't destroy above]")
else
    main(...)
end