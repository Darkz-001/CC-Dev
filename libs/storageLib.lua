LiveUpdate = false -- will slow down all requests based on the number of connected storages but will always be accurate

local Inventories = {peripheral.find('inventory')} -- get all inventories
local Output_id = "minecraft:barrel_1" -- determine the output location (cannot be directional for some reason)
local Search_limit = 9

for i, inventory in pairs(Inventories) do
    if peripheral.getName(inventory) == Output_id then
        table.remove(Inventories, i) -- remove output from system, can no longer use ipairs
        break
    end
end
StorageSytem = {
    inventories = Inventories,
    output_id = Output_id,
    search_limit = Search_limit,
    list = {},

    get_item = function(self, item, limit)
        local inv_id, slot = table.unpack(item.space)
        self.inventories[inv_id].pushItems(self.output_id, slot, limit)

        self.list[inv_id][slot] = nil
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
                        local already_found = false
                        for _, found_item in ipairs(items) do
                            if item.name == found_item.name then
                                already_found = true
                            end
                        end
                        if not already_found then
                            item.space = {i, slot}
                            table.insert(items, item)
                        end
                    end
                else
                    local _, loc = string.find(item.name, ":")
                    local cut_name = string.sub(item.name, loc + 1, -1) -- searches the part of the item same after the first colon (aka the name of the item without the mod name in front)
                    if string.find(cut_name, partial_name) then
                        local already_found = false
                        for _, found_item in ipairs(items) do
                            if item.name == found_item.name then
                                already_found = true
                            end
                        end
                        if not already_found then
                            item.space = {i, slot}
                            table.insert(items, item)
                        end
                    end
                end
            end
        end
        return items
    end,

    request_item = function(self, partial_name, limit, use_modID) -- the ultimate function
        if limit then
            if limit > 64 then
                print("Requesting more than 64 items is currently not supported, request will be capped at 64")
                limit = 64
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
            print("Found", #matches, "matching items, please select one")
            print("[0]: Cancel request")
            for i, match in ipairs(matches) do
                print("[" .. tostring(i) .. "]: " .. match.name)
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
        elseif #matches > self.search_limit and not use_modID then
            print("More than", self.search_limit, " items were included in the given search, try a more specific search")
        elseif #matches > self.search_limit and use_modID then
            print("More than", self.search_limit, " items were included in the given search with mod name included")
        else
            print("I don't think you should be able to see this message, but if you managed good job")
        end
    end
}

if not pcall(debug.getlocal, 4, 1) then -- thank you random internet code, jokes on you I dont even know how pcall works
    function splitTokens(str, lower)
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
    
    StorageSytem:refresh()
    while true do
        local request, limit = table.unpack(splitTokens(io.read()))
        limit = tonumber(limit)
        if limit then limit = math.floor(limit) end

        if request == "refresh" and limit == nil then
            print("Refreshing...")
            StorageSytem:refresh()
            print("Refreshed")
        else
            if LiveUpdate then
                StorageSytem:refresh()
            end
            StorageSytem:request_item(request, limit, false)
        end
    end
end