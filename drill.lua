target = ...

turtle.refuel()

block = {name = "{"}
n = 0

while not string.find(block.name, target) do
    turtle.digDown()
    turtle.down()
    n = n + 1
    exists, block = turtle.inspectDown()
    if not exists then
        block = {name = "{"}
    end
end

for i = 1, n do
    turtle.up()
end