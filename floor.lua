function main(l, w, replace)
    l, w = tonumber(l) - 1, tonumber(w)

    for i = 1, w do
        for j = 1, l do
            mineForward_placeDown(replace)
        end

        local turn
        if i%2 == 0 then
            turn = turtle.turnLeft
        else
            turn = turtle.turnRight
        end

        if i ~= w then
            turn()
            mineForward_placeDown(replace)
            turn()
        end
    end
end


function mineForward_placeDown(replace)
    while turtle.detect() do
        turtle.dig()
        sleep(0.1)
    end
    turtle.forward()
    if turtle.detectUp() then
        turtle.digUp()
    end

    if not turtle.detectDown() or replace then
        if turtle.detectDown() then
            turtle.digDown()
            sleep(0.1)
        end

        if turtle.getItemCount() == 0 then
            turtle.select(turtle.getSelectedSlot() + 1)
        end

        turtle.placeDown()
    end

end


main(...)