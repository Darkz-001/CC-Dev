DEBUG = false -- Use this to enable debug prints

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

StorageSytem = {}

-- Set the __index
StorageSytem.__index = StorageSytem

-- Initialization Function
-- Sets up the storage system, including inventory blacklist, output peripheral, and initial item list
function StorageSytem.new(output_id, search_limit, inventoryBlacklist, liveUpdate, extractOnFullMatch, DumpBlacklist)
    local system = {}
    -- Handle optional parameters with default values
    if search_limit == nil then search_limit = 9 end
    system.search_limit = search_limit -- a predifeined number,
    
    if liveUpdate == nil then liveUpdate = false end
    system.liveUpdate = liveUpdate
    
    if extractOnFullMatch == nil then extractOnFullMatch = true end
    system.extractOnFullMatch = extractOnFullMatch

    if DumpBlacklist == nil then DumpBlacklist = {} end
    system.DumpBlacklist = DumpBlacklist


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
    system.output_id = output_id
    table.insert(inventoryBlacklist, output_id)
    system.output = peripheral.wrap(output_id)
    system.inventoryBlacklist = inventoryBlacklist

    -- Find connected inventories and remove blacklisted ones
    system.inventories = {peripheral.find('inventory')}
    for i, blacklist_id in pairs(inventoryBlacklist) do
        for j, inventory in pairs(system.inventories) do
            if peripheral.getName(inventory) == blacklist_id then
                table.remove(system.inventories, j)
                break
            end
        end
    end
    
    -- Get the size of each connected inventory
    system.sizes = {}
    for i, inventory in pairs(system.inventories) do
        system.sizes[i] = inventory.size()
    end

    system = setmetatable(system, StorageSytem)
    
    system:refresh() -- Get the initial list of items in inventories

    return system
end

-- Extracts a specified item from a connected inventory and moves it to the output inventory
function StorageSytem.get_item(self, item, limit)
    local inv_id, slot = table.unpack(item.space) -- Get inventory ID and slot from item data

    if DEBUG then
        print("Item being extracted:", item.name)
        print("Amount in specified item stack", item.count)
        print("Slot of specified item stack:", slot)
        print("Limit:", limit)
        print("Source id:", peripheral.getName(self.inventories[inv_id]))
    end
    
    -- Push items from the source inventory to the output inventory
    local transfered_amount = self.inventories[inv_id].pushItems(self.output_id, slot, limit)
    
    -- Update the item list:
    if transfered_amount >= item.count then -- If all items were transferred, remove entry
        self.list[inv_id][slot] = nil
    else -- Otherwise, update the remaining count
        self.list[inv_id][slot].count = item.count - transfered_amount
    end
    
    print("Extracted", transfered_amount, item.name)
    
    return transfered_amount
end

-- Deposits a specified item from the output inventory into a connected inventory
function StorageSytem.send_item(self, item, inv_id, limit, toSlot)
    if DEBUG then
        print("Item being sent:", item.name)
        print("Amount in specified item stack", item.count)
        print("Slot of specified item stack:", item.slot)
        print("Limit:", limit)
        print("Destination id:", peripheral.getName(self.inventories[inv_id]))
        print("Destination slot:", toSlot)
    end
    -- Pull items from the output inventory into the destination inventory
    local transfered_amount = self.inventories[inv_id].pullItems(self.output_id, item.slot, limit, toSlot)
    
    -- Refresh the entire inventory reference for the destination
    self.list[inv_id] = self.inventories[inv_id].list() -- refresh entire inventory reference

    print("Deposited", transfered_amount, item.name)

    return transfered_amount
end

-- Updates the internal list of items in all connected inventories
function StorageSytem.refresh(self)
    local temp = {} -- Temporary table to store updated item lists
    for i, inventory in pairs(self.inventories) do
        temp[i] = inventory.list() -- Get the current list of items for each inventory
    end

    self.list = temp -- Replace the old item list with the updated one
end

-- Searches for items matching a partial name (with or without mod ID) and returns a list of matches
function StorageSytem.find_items(self, partial_name, use_modID)
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
end

-- Locates an available inventory with space, optionally prioritizing merging with an existing item stack
function StorageSytem.find_open_inventory(self, item, tryMergeSlot, useDumpBlacklist)
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

                    if maxStackSize == 1 then -- if the item is unstackable, don't try to stack it
                        break
                    end

                    -- If the existing stack and new item can fit, return the inventory ID and slot
                    if (contained_item.count + item.count) < maxStackSize then
                        return i, slot
                    end
                end
            end
        end

        -- If no suitable merge was found, try again without merging
        return self:find_open_inventory(item, false)

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
        -- If no inventory with the item has open slots, try to find any open inventory
        return self:find_open_inventory()

    -- Case 3: No item specified, just find any inventory with open slots
    else
        for i, slots_open in pairs(open_slots) do
            if slots_open > 0 then
                if useDumpBlacklist then
                    if not table.contains(self.dump_blacklist, self.inventories[i].getName()) then
                        return i   -- Return the inventory ID of the first inventory with space
                    end
                else
                    return i   -- Return the inventory ID of the first inventory with space
                end
            end
        end
    end

    -- If no suitable inventory was found in any of the cases, return nil
    return nil
end

-- Main user interface function: prompts for item name, finds matches, and handles extraction/interaction
function StorageSytem.request_item(self, partial_name, limit, use_modID, multiChoiceSkip)
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
    local matches = self:find_items(partial_name, use_modID)

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
end


-- Moves all items from the output inventory into connected inventories
function StorageSytem.dump_items(self)
    self:refresh() -- Refresh the internal list of items in inventories to ensure accuracy
    for slot, item in pairs(self.output.list()) do -- Iterate over each item in the output inventory
        item.slot = slot -- Add the slot information to the item object for later use

        -- Find an open inventory to deposit the item, prioritizing merging with an existing stack if possible
        local dest_id, toSlot = self:find_open_inventory(item, true)

        if dest_id then -- If a suitable inventory was found
            local temp = self:send_item(item, dest_id, nil, toSlot) -- (limit is nil to move the entire stack)
            if temp == 0 then -- silly stackable nbt item exception (EX: tipped arrows)
                dest_id = self:find_open_inventory(item, false)
                if dest_id then
                    self:send_item(item, dest_id)
                end
            end
        end
    end
end

return StorageSytem