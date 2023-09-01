ORIGIN = "back"

SPLIT1 = {
    name = "minceraft:brich_log", 
    destination = "right"
}
SPLIT2 = {
    name = "techreborn:rubber_log",
    destination = "left"
}

WASTE = "bottom"

function main()
    read = peripheral.wrap(ORIGIN)

    while true do
        local slot, name, count = pop(read)
        
        if slot ~= nil then
            if name == SPLIT1.name then
                read.pushItems(SPLIT1.destination, slot, count)
            elseif name == SPLIT2.name then
                read.pushItems(SPLIT2.destination, slot, count)
            else
                read.pushItems(WASTE, slot, count)
            end
        end

        sleep(0.1)
    end
end


function pop(inv)
    local items = inv.list()
    if #items == 0 then
        return
    end

    items = detach_key(items)
    local item = items[math.random(#items)]
    return item.key, item.value.name, item.value.count
end

function detach_key(table)
    new = {}
    for key, value in pairs(table) do
        table.insert(new,
            {
                key = key,
                value = value
            }
        )
    end
    return new
end


main()