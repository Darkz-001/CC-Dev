local Output_id = "minecraft:barrel_1" -- the acces point if the script is being run directly

-- DEBUG = true -- yes i know this is an undefined global when commented, too bad nerd

StorageSytem = {
    -- initilize the storage system (please note that the output_id cannot be directional for some reason)
    initilaize = function(self, output_id, search_limit, inventoryBlacklist, liveUpdate, extractOnFullMatch)
        if search_limit == nil then
            search_limit = 9
        end
        self.search_limit = search_limit -- a predifeined number,
        if liveUpdate == nil then
            liveUpdate = false
        end
        self.liveUpdate = liveUpdate
        if extractOnFullMatch == nil then
            extractOnFullMatch = true
        end
        self.extractOnFullMatch = extractOnFullMatch

        if type(inventoryBlacklist) == "string" then
            inventoryBlacklist = {inventoryBlacklist}
        elseif type(inventoryBlacklist) ~= "table" then
            inventoryBlacklist = {}
        end

        for _, side in ipairs({"top", "bottom", "left", "right", "back", "front"}) do
            table.insert(inventoryBlacklist, side) -- remove any inventories directly attached to the computer as they are buggy
        end
        
        self.output_id = output_id -- the output inventory wrap id
        table.insert(inventoryBlacklist, output_id) -- remove the output as an accesible inventory
        
        self.output = peripheral.wrap(output_id) -- the output inventory peripheral
        
        self.inventoryBlacklist = inventoryBlacklist -- store the finalized blacklist

        self.inventories = {peripheral.find('inventory')} -- the list of all connected inventories (that are not the output)
        self.sizes = {} -- table of numbers
        
        for i, blacklist_id in pairs(inventoryBlacklist) do
            for j, inventory in pairs(self.inventories) do
                if peripheral.getName(inventory) == blacklist_id then
                    table.remove(self.inventories, j) -- remove output from system, can no longer use ipairs
                    break
                end
            end
        end
        
        for i, inventory in pairs(self.inventories) do
            self.sizes[i] = inventory.size()
        end
        
        self:refresh() -- set self.list
    end,

    get_item = function(self, item, limit)
        local inv_id, slot = table.unpack(item.space)

        if DEBUG then
            print("Item being extracted:", item.name)
            print("Amount in specified item stack", item.count)
            print("Slot of specified item stack:", slot)
            print("Limit:", limit)
            print("Source id:", peripheral.getName(self.inventories[inv_id]))
        end
        
        local transfered_amount = self.inventories[inv_id].pushItems(self.output_id, slot, limit)
        
        if transfered_amount >= item.count then
            self.list[inv_id][slot] = nil
        else
            self.list[inv_id][slot].count = item.count - transfered_amount
        end
        
        print("Extracted", transfered_amount, item.name)
        
        return transfered_amount
    end,
    
    send_item = function(self, item, inv_id, limit, toSlot)
        if DEBUG then
            print("Item being sent:", item.name)
            print("Amount in specified item stack", item.count)
            print("Slot of specified item stack:", item.slot)
            print("Limit:", limit)
            print("Destination id:", peripheral.getName(self.inventories[inv_id]))
            print("Destination slot:", toSlot)
        end

        local transfered_amount = self.inventories[inv_id].pullItems(self.output_id, item.slot, limit, toSlot)
        self.list[inv_id] = self.inventories[inv_id].list() -- refresh entire inventory reference

        print("Deposited", transfered_amount, item.name)

        return transfered_amount
    end,


    refresh = function(self)
        local temp = {}
        for i, inventory in pairs(self.inventories) do
            temp[i] = inventory.list()
        end

        self.list = temp
    end,


    find_items = function(self, partial_name, use_modID)
        local items = {}
        for i, list in pairs(self.list) do
            for slot, item in pairs(list) do
                if use_modID then
                    if string.find(item.name, partial_name) then
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
                else
                    local _, loc = string.find(item.name, ":")
                    local cut_name = string.sub(item.name, loc + 1, -1) -- searches the part of the item same after the first colon (aka the name of the item without the mod name in front)
                    item.cut_name = cut_name -- store for later reference
                    if string.find(cut_name, partial_name) then
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
        return items
    end,

    request_item = function(self, partial_name, limit, use_modID, multiChoiceSkip) -- the ultimate function
        if self.liveUpdate then
            self:refresh()
        end

        if limit then
            if limit > 64 then
                print("Please note that the system can only extract one item stack at a time\nExtracting more than 64 items will only work when both the output container and the pulled storages can hold larger stacks\nIf these conditions are not met you may need to refresh after the request\n\n")
            end
        end
        
        matches = self:find_items(partial_name, use_modID)

        if #matches == 0 and use_modID then
            print("No items found matching the given id")
        elseif #matches == 0 and not use_modID then
            print("Now including mod name in search ...")
            self:request_item(partial_name, limit, true)
        elseif #matches == 1 then
            self:get_item(matches[1], limit)
        elseif #matches <= self.search_limit then
            local do_prompt = not multiChoiceSkip

            for i, match in pairs(matches) do
                if (match.cut_name == partial_name or match.name == partial_name) and self.extractOnFullMatch then
                    StorageSytem:get_item(match, limit)
                    do_prompt = false
                    break
                end
            end

            if multiChoiceSkip then
                self:get_item(matches[multiChoiceSkip], limit)
            end

            if do_prompt then
                print("Found", #matches, "matching items, please select one")
                print("[0]: Cancel request")
                for i, match in ipairs(matches) do
                    print("[" .. tostring(i) .. "]: " .. match.name .. " x" .. tostring(match.count))
                end
                local selected = -1
                while not (selected % 1 == 0 and selected >= 0 and selected <= #matches) do
                    selected = tonumber(io.read())
                    if selected == nil then selected = -1 end
                end
                if selected ~= 0 then
                    self:get_item(matches[selected], limit)
                else
                    print("Request cancled")
                end
            end
        elseif #matches > self.search_limit and not use_modID then
            local do_print = true
            for i, match in pairs(matches) do
                if match.cut_name == partial_name and self.extractOnFullMatch then
                    StorageSytem:get_item(match, limit)
                    do_print = false
                    break
                end
            end
            
            if do_print then
                print("More than", self.search_limit, " items were included in the given search, try a more specific search")
            end
        elseif #matches > self.search_limit and use_modID then
            local do_print = true
            for i, match in pairs(matches) do
                if match.name == partial_name and self.extractOnFullMatch then
                    StorageSytem:get_item(match, limit)
                    do_print = false
                    break
                end
            end

            if do_print then
                print("More than", self.search_limit, " items were included in the given search with mod name included")
            end
        else
            print("I don't think you should be able to see this message, but if you managed good job")
        end
    end,

    find_open_chest = function(self, item, tryMergeSlot)
        local open_slots = {}
        for i, inventory in pairs(self.inventories) do
            open_slots[i] = self.sizes[i] - #self.list[i]
        end

        if item then
            for i, single_list in pairs(self.list) do
                for slot, contained_item in pairs(single_list) do
                    if contained_item.name == item.name then
                        local stack_multiplier = self.inventories[i].getItemDetail(slot)['maxCount'] / 64
                        if self.inventories[i].getItemLimit(slot) * stack_multiplier > (contained_item.count + item.count) and tryMergeSlot then
                            return i, slot
                        elseif open_slots[i] > 0 then
                            return i
                        end
                    end
                end
            end
            return self:find_open_chest()
        else
            for i, slots_open in pairs(open_slots) do
                if slots_open > 0 then
                    return i
                end
            end
        end

        return nil
    end,

    dump_items = function(self)
        self:refresh()
        for slot, item in pairs(self.output.list()) do
            item.slot = slot
            local dest_id, toSlot = self:find_open_chest(item, true)
            if dest_id then
                self:send_item(item, dest_id, nil, toSlot)
            end
        end
        self:refresh()
    end
}

if not pcall(debug.getlocal, 4, 1) then -- thank you random internet code, jokes on you I dont even know how pcall works
    function splitTokens(str, lower)
        if str == nil then return {} end
        
        local t = {}
        for token in string.gmatch(str, "[^%s]+") do -- regex i made like a year ago
            if lower then
                table.insert(t, string.lower(token))
            else
                table.insert(t, token)
            end
        end
        return t
    end
    
    StorageSytem:initilaize(Output_id, 9)
    print("System Initilaized")
    while true do
        local request, limit = table.unpack(splitTokens(io.read()))
        
        if request == "refresh" and limit == nil then -- if a limit is specifed (even if the limit is not a valid number) then ignore keywords
            print("Refreshing...")
            StorageSytem:refresh()
            print("Refreshed")
        elseif request == "exit" and limit == nil then
            break
        elseif request == "dump" then
            StorageSytem:dump_items()
        elseif request then
            limit = tonumber(limit)
            if limit then limit = math.floor(limit) end

            StorageSytem:request_item(request, limit, false)
        end
    end
end