ORIGIN = "back"

EXACT = false


SPLITS = {
    ["crushed"] = "left"
}

OTHER = "right"

local function main()
    local read = peripheral.wrap(ORIGIN)

    while true do
        local slot, name, count = pop(read)

        if slot ~= nil then
            local matches = false
            for filter, wrap in pairs(SPLITS) do
                if (EXACT and filter == name) or (not EXACT and string.find(name, filter)) then
                    read.pushItems(wrap, slot, count)
                    matches = true
                    break
                end
            end

            if not matches then
                read.pushItems(OTHER, slot, count)
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

function detach_key(t)
    local new = {}
    for key, value in pairs(t) do
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