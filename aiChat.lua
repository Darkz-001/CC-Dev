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
    local event, username, message, user_uuid, isHidden = os.pullEvent('chat')
    if string.find(string.lower(message), "gemini") then
        local response, err = gemini.generateContent(username .. " said:" .. message)
        if response then
            chatBox.sendMessage(response, "Gemini")
        else
            print(err)
        end
    end
end