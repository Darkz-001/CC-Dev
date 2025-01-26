while true do
    local event, side, channel, replyChannel, message, distance = os.pullEvent()
    print(event, side, channel, replyChannel, message, distance)
end