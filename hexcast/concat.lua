function concat(t)
    out = "{\n"
    
    for k, v in pairs(t) do
        
        if type(k) == "number" then
            out = out .. "[" .. tostring(k) .. "] = "
        elseif type(k) == "string" then
            out = out .. "['" .. k .. "'] = "
        else
            error("type " .. type(k) .. " not supported for table keys")
        end
        
        if type(v) == "table" then
            out = out .. concat(v) .. ",\n"
        elseif type(v) == "number" or type(v) == "boolean" then
            out = out .. tostring(v) .. ",\n"
        elseif type(v) == "string" then
            out = out .. "'" .. v .. "',\n"
        else
            error("type " .. type(v) .. " not supported for table values")
        end
    end 
    
    out = string.sub(out, 1, -3) .. "\n}"
    return out
end

