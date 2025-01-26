StorageLib = require("storageLib")

local Output_id = "" -- Default access point (change if needed)
local DumpBlacklist = {} -- Blacklist for the dump command (when not stacking)

-- Helper function to split a string into tokens, optionally converting to lowercase
local function splitTokens(str, lower)
    if str == nil then return {} end -- Return empty table if input is nil
    
    local t = {} -- Table to store tokens

    -- Iterate through each token in the string, matching non-whitespace characters
    for token in string.gmatch(str, "[^%s]+") do -- regex I made like a year ago
        -- Insert the token into the table, converting to lowercase if specified
        if lower then
            table.insert(t, string.lower(token))
        else
            table.insert(t, token)
        end
    end
    return t
end

-- Initialize the storage system with default parameters (output_id and search limit)
StorageSytem = StorageLib.new(Output_id, 9, {}, false, true, DumpBlacklist)
print("System Initilaized")

-- Main command loop:
while true do
    -- Read user input, split into tokens, and convert to lowercase
    local argv = splitTokens(io.read(), true)
    local argc = #argv

    -- Command dispatcher based on first argument (argv[1])
    if argc > 0 then
        local command = argv[1]

        -- Check for specific commands first (keywords)
        if command == "refresh" and argc == 1 then
            print("Refreshing...")
            StorageSytem:refresh()
            print("Refreshed")
        elseif command == "exit" and argc == 1 then
            break
        elseif command == "dump" and argc == 1 then
            StorageSytem:dump_items()
        elseif command == "help" and argc == 1 then
            print("No argument commands: refresh, reset, dump, exit, help")
            print("Other commands: count (unimplemented) [requires exact item name (with or without modId)]")
            print("To request an item, simply type its name. Use '> <item_name> [limit]' to bypass keywords.")
        elseif command == "count" and argc == 2 then
            local exact_name = argv[2]
            -- [TODO: Implement count functionality]
        
        -- If not a specific command, treat the input as an item request
        else
            local limit = argc >= 2 and tonumber(argv[2]) or nil -- Optional limit from second argument
            if limit then limit = math.floor(limit) end
            StorageSytem:request_item(command, limit, false) -- Request the item
        end
    end
end