CHANNEL = 6016

require("file_spell")

modem = peripheral.wrap("modem_0")
if modem == nil then
    print("No modem attached")
    return nil
end
modem.open(CHANNEL)

function main()
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        
        local file, delay, expect, channel = unpack(splitTokens(message, true))
        
        local spell = readSpell(file)
                
        require("magic")
        delay = tonumber(delay)
        channel = tonumber(channel)
        
        local out = cast(makeSpell(spell), nil, delay, expect, channel)
        
        if expect then
            modem.transmit(CHANNEL, CHANNEL, tostring(out))
        else
            modem.transmit(CHANNEL, CHANNEL, "done")
        end
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