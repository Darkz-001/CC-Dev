function cast(spell, link, delay, expectReturn, channel)
    if spell == nil then
        local port = peripheral.find("focal_port")
        if port then
            spell = port.readIota()
        else
            error("no port")
        end
    end
    if link == nil then link = peripheral.find("focal_link") end
    if link == nil then error("no focal link") end
    
    if delay == nil then delay = 0 end
    if channel == nil then channel = 0 end
    
    sleep(delay)
    link.sendIota(channel, spell)
    
    if expectReturn then
        link.clearReceivedIotas()
        os.pullEvent("received_iota")
        return link.receiveIota()
    end
end
 
 
function makeSpell(patterns)
    local spell = {}
    for i, pattern in ipairs(patterns) do
        spell[i] = {
            angles = pattern,
            startDir = "EAST"
        }
    end
    return spell
end