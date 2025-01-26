local chatBox = peripheral.find("chatBox")

local apiKey = ... -- load the API key from the command line
if not apiKey then
    error("API key not provided. Please provide the API key as the first argument.")
end

-- clear the screen to hide the API key
term.clear()
term.setCursorPos(1, 1)

local gemini = require("gemini")
gemini.setAPIKey(apiKey)

while true do
    local event, side, channel, replyChannel, message, distance = os.pullEvent('chat')
    if string.find(message, "Hey Gemini") then
        local response, err = gemini.generateContent(message)
        if response then
            chatBox.sendMessage(response, "Gemini")
        else
            print(err)
        end
    end
end