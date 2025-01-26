-- gemini.lua - Gemini API Library for ComputerCraft

local gemini = {}

-- Configuration
gemini.apiKey = nil
gemini.apiEndpointBase = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"

-- Error Handling
local function error(msg)
    return nil, msg
end

-- Internal function for making the HTTP request to Gemini
local function makeRequest(prompt)
    if not gemini.apiKey then
        return error("API Key not set. Please set gemini.apiKey.")
    end

    local apiEndpoint = gemini.apiEndpointBase .. "?key=" .. gemini.apiKey

    local headers = {
        ["Content-Type"] = "application/json",
    }

    local data = {
        contents = {
            {
                parts = {
                    {
                        text = prompt
                    }
                }
            }
        }
    }

    local encodedData = textutils.serializeJSON(data)

    print(apiEndpoint)
    print(encodedData)
    print(headers)

    local response = http.post(apiEndpoint, encodedData, headers)

    if not response then
       return error("Failed to make HTTP request. Check network connection.")
    end

    local body = response.readAll()
    response.close()

    if response.getResponseCode() ~= 200 then
        return error("API Error: HTTP " .. response.getResponseCode() .. "\n" .. body)
    end

    local json, err = textutils.unserializeJSON(body)
    if not json then
        return error("Error parsing JSON response: " .. (err or ""))
    end

    return json, nil
end

-- Function to get a response from Gemini
function gemini.generateContent(prompt)
   if not prompt or #prompt == 0 then
       return error("Prompt cannot be empty.")
   end
   
    local jsonResponse, err = makeRequest(prompt)

    if not jsonResponse then
        return nil, err
    end

    if not jsonResponse.candidates or #jsonResponse.candidates == 0 then
        return nil, error("No valid candidates found in the response")
    end

    local firstCandidate = jsonResponse.candidates[1]

    if not firstCandidate or not firstCandidate.content or not firstCandidate.content.parts or #firstCandidate.content.parts == 0 then
       return nil, error("No content parts found in response")
    end
   
    local responseText = ""
    for _, part in ipairs(firstCandidate.content.parts) do
        if part.text then
            responseText = responseText .. part.text
        end
    end

    return responseText, nil
end

-- Function to set the API key (you could just do this manually in the code with gemini.apiKey = "YOUR_API_KEY")
function gemini.setAPIKey(key)
    gemini.apiKey = key
end

return gemini