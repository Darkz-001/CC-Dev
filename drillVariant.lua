target, replace = ...

turtle.refuel()

block = {name = "{"}
n = 0

while not string.find(block.name, target) and block.name ~= "minecraft:bedrock" do
    if turtle.detectDown() then
        turtle.digDown()
    end

    turtle.down()

    if not turtle.detect() or replace then
        if turtle.getItemCount() == 0 then
            turtle.select(turtle.getSelectedSlot() + 1)
        end

        if turtle.detect() then
            turtle.dig()
        end

        turtle.place()
    end

    n = n + 1
    exists, block = turtle.inspectDown()
    if not exists then
        block = {name = "{"}
    end
end

for i = 1, n do
    turtle.up()
end

if block.name == "minecraft:bedrock" then
    print("Hit Bedrock")
else
    print(block.name, "found", tostring(n), "blocks down")
end