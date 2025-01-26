while true do
    local eventData = {os.pullEvent()}
    
    for i, v in ipairs(eventData) do
        print(i, v)
    end
    print("\n\n")
end