local function main(process, file, delay, expectReturn, channel)
    if process == "read" then
        local spell = readSpell(file)
        for i, angles in ipairs(spell) do
            print(angles)
        end
    elseif process == "write" then
        writeSpell(file)
    elseif process == "cast" then
        local spell = readSpell(file)
        
        require("magic")
        delay = tonumber(delay)
        channel = tonumber(channel)
        
        cast(makeSpell(spell), nil, delay, expectReturn, channel)
    end
end
 
 
function writeSpell(file, spell, folder)
    if type(spell) ~= "table" then
        local port = peripheral.find("focal_port")
        if port then
            spell = port.readIota()
        else
            error("no port")
        end
    end
    
    if folder == nil then folder = "disk/spells" end
    io.output(folder .. "/" .. file .. ".spell")
    for i, pattern in ipairs(spell) do
        io.write(pattern.angles .. "\n")
    end
end
 
 
function readSpell(file, folder)
    if folder == nil then folder = "disk/spells" end
    io.input(folder .. "/" .. file .. ".spell")
    
    local spell = {}
    for line in io.lines() do
        table.insert(spell, #spell + 1, line)
    end
    return spell
end