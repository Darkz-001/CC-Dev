local Output_id = "minecraft:barrel_1" -- Default access point if script is run directly (change if needed)

-- DEBUG = true -- Uncomment this line to enable debug prints (yes I know it is an undefined global, deal with it)

StorageSytem = {
    -- Initialization Function
    -- Sets up the storage system, including inventory blacklist, output peripheral, and initial item list
    initilaize = function(self, output_id, search_limit, inventoryBlacklist, liveUpdate, extractOnFullMatch)
        -- Handle optional parameters with default values
        if search_limit == nil then search_limit = 9 end
        self.search_limit = search_limit -- a predifeined number,
        if liveUpdate == nil then liveUpdate = false end
        self.liveUpdate = liveUpdate
        if extractOnFullMatch == nil then extractOnFullMatch = true end
        self.extractOnFullMatch = extractOnFullMatch

        -- Ensure inventoryBlacklist is a table, and add default blacklisted sides
        if type(inventoryBlacklist) == "string" then
            inventoryBlacklist = {inventoryBlacklist}
        elseif type(inventoryBlacklist) ~= "table" then
            inventoryBlacklist = {}
        end
        for _, side in ipairs({"top", "bottom", "left", "right", "back", "front"}) do
            table.insert(inventoryBlacklist, side) -- remove any inventories directly attached to the computer as they are buggy
        end
        
        -- Set output parameters and blacklist the output container itself
        self.output_id = output_id
        table.insert(inventoryBlacklist, output_id)
        self.output = peripheral.wrap(output_id)
        self.inventoryBlacklist = inventoryBlacklist

        -- Find connected inventories and remove blacklisted ones
        self.inventories = {peripheral.find('inventory')}
        for i, blacklist_id in pairs(inventoryBlacklist) do
            for j, inventory in pairs(self.inventories) do
                if peripheral.getName(inventory) == blacklist_id then
                    table.remove(self.inventories, j)
                    break
                end
            end
        end
        
        -- Get the size of each connected inventory
        self.sizes = {}
        for i, inventory in pairs(self.inventories) do
            self.sizes[i] = inventory.size()
        end
        
        self:refresh() -- Get the initial list of items in inventories
    end,

    -- Extracts a specified item from a connected inventory and moves it to the output chest
    get_item = function(self, item, limit)
        local inv_id, slot = table.unpack(item.space) -- Get inventory ID and slot from item data

        if DEBUG then
            print("Item being extracted:", item.name)
            print("Amount in specified item stack", item.count)
            print("Slot of specified item stack:", slot)
            print("Limit:", limit)
            print("Source id:", peripheral.getName(self.inventories[inv_id]))
        end
        
        -- Push items from the source inventory to the output chest
        local transfered_amount = self.inventories[inv_id].pushItems(self.output_id, slot, limit)
        
        -- Update the item list:
        if transfered_amount >= item.count then -- If all items were transferred, remove entry
            self.list[inv_id][slot] = nil
        else -- Otherwise, update the remaining count
            self.list[inv_id][slot].count = item.count - transfered_amount
        end
        
        print("Extracted", transfered_amount, item.name)
        
        return transfered_amount
    end,
    
    -- Deposits a specified item from the output chest into a connected inventory
    send_item = function(self, item, inv_id, limit, toSlot)
        if DEBUG then
            print("Item being sent:", item.name)
            print("Amount in specified item stack", item.count)
            print("Slot of specified item stack:", item.slot)
            print("Limit:", limit)
            print("Destination id:", peripheral.getName(self.inventories[inv_id]))
            print("Destination slot:", toSlot)
        end
        -- Pull items from the output chest into the destination inventory
        local transfered_amount = self.inventories[inv_id].pullItems(self.output_id, item.slot, limit, toSlot)
        
        -- Refresh the entire inventory reference for the destination
        self.list[inv_id] = self.inventories[inv_id].list() -- refresh entire inventory reference

        print("Deposited", transfered_amount, item.name)

        return transfered_amount
    end,

    -- Updates the internal list of items in all connected inventories
    refresh = function(self)
        local temp = {} -- Temporary table to store updated item lists
        for i, inventory in pairs(self.inventories) do
            temp[i] = inventory.list() -- Get the current list of items for each inventory
        end

        self.list = temp -- Replace the old item list with the updated one
    end,

    -- Searches for items matching a partial name (with or without mod ID) and returns a list of matches
    find_items = function(self, partial_name, use_modID)
        local items = {} -- Table to store matching items

        for i, list in pairs(self.list) do -- Iterate over each inventory and its item list
            for slot, item in pairs(list) do
                if use_modID then -- Check the full item name (including mod ID)
                    if string.find(item.name, partial_name) then
                        -- Check if item is already in the 'items' list and replace with the larger stack if found
                        local already_found = nil
                        local already_found_ind = -1
                        for j, found_item in ipairs(items) do
                            if item.name == found_item.name then
                                already_found = found_item
                                already_found_ind = j
                            end
                        end
                        
                        if already_found then
                            if item.count > already_found.count then
                                item.space = {i, slot}  -- Store inventory ID and slot
                                items[already_found_ind] = item
                            end
                        else
                            item.space = {i, slot}
                            table.insert(items, item)
                        end
                    end
                else -- Search by item name only (without mod ID)
                    local _, loc = string.find(item.name, ":")
                    local cut_name = string.sub(item.name, loc + 1, -1) --- Extract name after first colon, cutting off the mod id
                    item.cut_name = cut_name -- Store cut name for later reference
                    if string.find(cut_name, partial_name) then
                         -- Same logic as above for checking and replacing with larger stacks
                        local already_found = nil
                        local already_found_ind = -1
                        for j, found_item in ipairs(items) do
                            if item.name == found_item.name then
                                already_found = found_item
                                already_found_ind = j
                            end
                        end
                        
                        if already_found then
                            if item.count > already_found.count then
                                item.space = {i, slot}
                                items[already_found_ind] = item
                            end
                        else
                            item.space = {i, slot}
                            table.insert(items, item)
                        end
                    end
                end
            end
        end
        return items -- Return the list of matching items
    end,
    
    -- Locates an available chest with space, optionally prioritizing merging with an existing item stack
    find_open_chest = function(self, item, tryMergeSlot)
        local open_slots = {}  -- Table to store the number of open slots per inventory

        -- Calculate available slots in each inventory
        for i, inventory in pairs(self.inventories) do
            open_slots[i] = self.sizes[i] - #self.list[i]
        end

        -- Case 1: An item is specified, and we want to prioritize merging
        if item and tryMergeSlot then
            for i, single_list in pairs(self.list) do  -- Iterate over inventories
                for slot, contained_item in pairs(single_list) do  -- Iterate over items in each inventory
                    if contained_item.name == item.name then   -- Check for matching item
                        -- Calculate the max stack size for this item in the inventory
                        local stack_multiplier = self.inventories[i].getItemDetail(slot)['maxCount'] / 64
                        local maxStackSize = self.inventories[i].getItemLimit(slot) * stack_multiplier

                        -- If the existing stack and new item can fit, return the inventory ID and slot
                        if (contained_item.count + item.count) < maxStackSize then
                            return i, slot
                        end
                    end
                end
            end

            -- If no suitable merge was found, try again without merging
            return self:find_open_chest(item, false) 

        -- Case 2: An item is specified, but merging is not prioritized or not possible
        elseif item then
            for i, single_list in pairs(self.list) do -- Iterate over inventories
                for slot, contained_item in pairs(single_list) do  -- Iterate over items in each inventory
                    if contained_item.name == item.name then   -- Check for matching item
                        -- Even if merging isn't possible, return this inventory if it has open slots
                        if open_slots[i] > 0 then 
                            return i  -- Return the inventory ID
                        end
                    end
                end
            end
            -- If no inventory with the item has open slots, try to find any open chest
            return self:find_open_chest() 

        -- Case 3: No item specified, just find any chest with open slots
        else
            for i, slots_open in pairs(open_slots) do
                if slots_open > 0 then
                    return i   -- Return the inventory ID of the first chest with space
                end
            end
        end

        -- If no suitable chest was found in any of the cases, return nil
        return nil 
    end,

    -- Main user interface function: prompts for item name, finds matches, and handles extraction/interaction
    request_item = function(self, partial_name, limit, use_modID, multiChoiceSkip)
        -- Refresh inventory if liveUpdate is enabled to ensure up-to-date item data
        if self.liveUpdate then
            self:refresh()
        end

        -- Warn the user about the stack limit if they try to extract more than 64 items
        if limit then
            if limit > 64 then
                print("Please note that the system can only extract one item stack at a time\nExtracting more than 64 items will only work when both the output container and the pulled storages can hold larger stacks\nIf these conditions are not met you may need to refresh after the request\n\n")
            end
        end
        
        -- Find items matching the given partial name, using modID if specified
        matches = self:find_items(partial_name, use_modID)

        -- Handle different scenarios based on the number of matches found:

        if #matches == 0 and use_modID then -- No matches found using modID
            print("No items found matching the given id")
        elseif #matches == 0 and not use_modID then -- No matches found without modID, try again with modID
            print("Now including mod name in search ...")
            self:request_item(partial_name, limit, true)
        elseif #matches == 1 then -- Exactly one match found, extract the item directly
            self:get_item(matches[1], limit)
        elseif #matches <= self.search_limit or multiChoiceSkip then -- Multiple matches found within the search limit or choice is already chosen:
            local do_prompt = not multiChoiceSkip -- Determine whether to prompt the user (false if skipping)

            -- Check for exact match (with or without modID) and extract if found
            for i, match in pairs(matches) do
                if (match.cut_name == partial_name or match.name == partial_name) and self.extractOnFullMatch then
                    self:get_item(match, limit)
                    do_prompt = false -- Skip the prompt since an exact match was found
                    break
                end
            end

            -- Extract item if multiChoiceSkip is enabled
            if multiChoiceSkip then
                self:get_item(matches[multiChoiceSkip], limit)
            end

            -- Prompt the user to choose an item if not skipped
            if do_prompt then
                print("Found", #matches, "matching items, please select one")
                print("[0]: Cancel request")
                for i, match in ipairs(matches) do
                    print("[" .. tostring(i) .. "]: " .. match.name .. " x" .. tostring(match.count))
                end

                -- Get user input and validate the selection
                local selected = -1
                while not (selected % 1 == 0 and selected >= 0 and selected <= #matches) do
                    selected = tonumber(io.read())
                    if selected == nil then selected = -1 end
                end

                -- Extract the selected item or cancel the request
                if selected ~= 0 then
                    self:get_item(matches[selected], limit)
                else
                    print("Request cancled")
                end
            end
        elseif #matches > self.search_limit and not use_modID then -- Too many matches found without modID
            local do_print = true -- Flag to indicate whether to print a message

            -- Iterate through matches to see if an exact match by item name exists
            for i, match in pairs(matches) do
                if match.cut_name == partial_name and self.extractOnFullMatch then
                    self:get_item(match, limit) -- Extract the item if found
                    do_print = false -- Don't print the message since an exact match was found
                    break
                end
            end
            
            -- If no exact match was found, print a message suggesting a more specific search
            if do_print then
                print("More than", self.search_limit, " items were included in the given search, try a more specific search")
            end
        elseif #matches > self.search_limit and use_modID then -- Too many matches found even with modID
            local do_print = true -- Flag to indicate whether to print a message

            -- Iterate through matches to see if an exact match by full name exists
            for i, match in pairs(matches) do
                if match.name == partial_name and self.extractOnFullMatch then
                    self:get_item(match, limit)
                    do_print = false
                    break
                end
            end

            -- If no exact match was found, print a message informing the user
            if do_print then
                print("More than", self.search_limit, " items were included in the given search with mod name included")
            end
        else -- This should never be reached, but included as a safety check
            print("I don't think you should be able to see this message, but if you managed, good job")
        end
    end,


    -- Moves all items from the output chest into connected inventories 
    dump_items = function(self)
        self:refresh() -- Refresh the internal list of items in inventories to ensure accuracy
        for slot, item in pairs(self.output.list()) do -- Iterate over each item in the output chest
            item.slot = slot -- Add the slot information to the item object for later use

            -- Find an open chest to deposit the item, prioritizing merging with an existing stack if possible
            local dest_id, toSlot = self:find_open_chest(item, true)

            if dest_id then -- If a suitable chest was found
                self:send_item(item, dest_id, nil, toSlot) -- (limit is nil to move the entire stack)
            end
        end
    end
}

-- Check if script is being imported or run directly (thank you random internet code)
if not pcall(debug.getlocal, 4, 1) then
    -- Helper function to split a string into tokens (words), optionally converting to lowercase
    function splitTokens(str, lower)
        if str == nil then return {} end -- Return empty table if input is nil
        
        local t = {} -- Table to store tokens

        -- Iterate through each token in the string, matching non-whitespace characters
        for token in string.gmatch(str, "[^%s]+") do -- regex i made like a year ago
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
    StorageSytem:initilaize(Output_id, 9)
    print("System Initilaized")

    -- Main command loop:
    while true do
        -- Read user input and split it into tokens (command and optional limit)
        local request, limit = table.unpack(splitTokens(io.read(), true))
        
        -- Handle different commands:


        -- If a limit is specifed (even if the limit is not a valid number) then ignore keywords
        if request == "refresh" and limit == nil then -- Refresh the inventory
            print("Refreshing...")
            StorageSytem:refresh()
            print("Refreshed")
        elseif request == "exit" and limit == nil then -- Exit the script
            break
        elseif request == "dump" and limit == nil then -- Dump all items from the output chest
            StorageSytem:dump_items()
        elseif request then -- Process item requests (default case)
            limit = tonumber(limit) -- Convert limit to number (nil if not provided)
            if limit then limit = math.floor(limit) end -- Round down the limit if it's a decimal

            -- Call the request_item function to handle item extraction/interaction
            StorageSytem:request_item(request, limit, false) -- Search without using modID initially
        end
    end
end