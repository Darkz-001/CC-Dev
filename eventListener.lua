while true do
    local event, side, channel, replyChannel, message, distance = os.pullEvent()
    
    -- overide nils with "nil" so they still print
    if not event then event = "nil" end
    if not side then side = "nil" end
    if not channel then channel = "nil" end
    if not replyChannel then replyChannel = "nil" end
    if not message then message = "nil" end
    if not distance then distance = "nil" end
    
    print(event, side, channel, replyChannel, message, distance)
end