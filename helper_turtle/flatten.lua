argv = {...}
argc = argv.length


function main(l, w)
    l, w = tonumber(l) - 1, tonumber(w)

    for i = 1, w do
        for j = 1, l do
            mineForward()
        end

        local turn
        if i%2 == 0 then
            turn = turtle.turnLeft
        else
            turn = turtle.turnRight
        end

        if i ~= w then
            turn()
            mineForward()
            turn()
        end
    end
end


function mineForward()
    while turtle.detect() do
        turtle.dig()
        sleep(0.1)
    end
    turtle.forward()
    if turtle.detectUp() then
        turtle.digUp()
    end
end

if argc == 0 or argv[1] == "-h" then
    print("Usage: flatten dist_forward dist_right")
else
    main(...)
end