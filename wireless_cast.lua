CHANNEL = 6016

modem = peripheral.find("modem")
if modem == nil then
    print("No modem attached")
    return nil
end
modem.open(CHANNEL)

while true do
    local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    
    file, delay, expect, channel = unpack(splitTokens(message, true))
    
    local spell = readSpell(file)
            
    require("magic")
    delay = tonumber(delay)
    channel = tonumber(channel)
    
    cast(makeSpell(spell), nil, delay, expectReturn, channel)

    modem.transmit(CHANNEL, CHANNEL, "done")
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