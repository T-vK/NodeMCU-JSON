json = {}
setmetatable(json, {
    __call = function(filePath)
        local jsonFile = file.open(filePath)
        local fileLen = jsonFile:stat().size
        
        local jsonPath = {} -- Would store `{'aa',2,'gg'}` for `example['aa'][2]['gg']()`
        
        local fakeJson = {}
        setmetatable(fakeJson, { 
            __index = function (t, k)
                jsonPath[#jsonPath+1] = k
                return fakeJson
            end;
            __call = function()
                -- The jsonPath contains e.g. {'aa',2,'gg'} at this point
                local brcStack = {} -- will be used to push/pop braces/brackets
                local jsonPathDim = 1 -- table dimension (['a'] ==  1; ['a']['b'] == 2; ...)
                -- Loop through the json file char by char
                local valueToReturn
                local filePos = 0
                local nextChar = function()
                    jsonFile:seek("set", filePos)
                    filePos = filePos + 1
                    local char = jsonFile:read(1)
                    --print(char)
                    return char
                end
                local jsonValid = true
                for o=1, fileLen do -- infinite
                    if jsonPathDim > #jsonPath then -- jsonPath followed. Now we can extract the value.
                        while true do
                            local currentChar = nextChar()
                            if currentChar == '"' then -- string
                                valueToReturn = ''
                                for i=1, fileLen do
                                    currentChar = nextChar()
                                    if currentChar == '"' then
                                        break
                                    elseif currentChar == nil then
                                        jsonValid = false
                                        break
                                    else
                                        valueToReturn = valueToReturn .. currentChar
                                    end
                                end
                                break
                            elseif string.find(currentChar,'[%d.]') then -- numbers 0.3, .3, 99 etc
                                local rawValue = ''
                                if currentChar == '.' then
                                    rawValue = '0'
                                end
                                for i=1, fileLen do
                                    if string.find(currentChar, '[%s,\r\n%]%}]') then
                                        break
                                    elseif filePos > fileLen then
                                        jsonValid = false
                                        break
                                    else
                                        rawValue = rawValue .. currentChar
                                    end
                                    currentChar = nextChar()
                                end
                                valueToReturn = tonumber(rawValue)
                                break
                            elseif currentChar == 't' then -- true
                                valueToReturn = true
                                break
                            elseif currentChar == 'f' then -- false
                                valueToReturn = false
                                break
                            elseif currentChar == 'n' then -- null
                                valueToReturn = nil -- ?
                                break
                            elseif currentChar == '{' then -- null
                                valueToReturn = {}
                                brcStack[#brcStack+1] = '{'
                                local origBrcLvl = #brcStack
                                while true do
                                    currentChar = nextChar()
                                    if filePos > fileLen then
                                        jsonValid = false
                                        break
                                    elseif currentChar == '\\' then
                                        nextChar()
                                        -- Continue
                                    elseif origBrcLvl == #brcStack and currentChar == '"' then
                                        local keyToPush = ''
                                        while true do
                                            currentChar = nextChar()
                                            if currentChar == '"' then
                                                while true do
                                                    currentChar = nextChar()
                                                    if currentChar == ':' then
                                                        valueToReturn[keyToPush] = 0
                                                        break
                                                    elseif filePos > fileLen then
                                                        break
                                                    end
                                                end
                                                break
                                            elseif filePos > fileLen then
                                                jsonValid = false
                                                break
                                            else
                                                keyToPush = keyToPush .. currentChar
                                            end
                                        end
                                        break
                                    elseif currentChar == '[' or currentChar == '{' then
                                        brcStack[#brcStack+1] = currentChar
                                    elseif currentChar == ']' then
                                        if brcStack[#brcStack] == ']' then
                                            brcStack[#brcStack] = nil
                                        else
                                            jsonValid = false
                                            break
                                        end
                                    elseif currentChar == '}' then
                                        if brcStack[#brcStack] == '}' then
                                            brcStack[#brcStack] = nil
                                        else
                                            jsonValid = false
                                            break
                                        end
                                    end
                                end
                                break
                            elseif currentChar == '[' then
                                brcStack[#brcStack+1] = '['
                                valueToReturn = {} 
                                local origBrcLvl = #brcStack
                                while true do
                                    currentChar = nextChar()
                                    
                                    if origBrcLvl == #brcStack and #valueToReturn == 0 and not string.find(currentChar, '[%s\r\n%]]') then
                                        valueToReturn[#valueToReturn+1] = 0
                                    end
                                    if filePos > fileLen then
                                        jsonValid = false
                                        break
                                    elseif currentChar == '\\' then
                                        nextChar()
                                        -- Continue
                                    elseif origBrcLvl == #brcStack and currentChar == ',' then
                                        valueToReturn[#valueToReturn+1] = 0
                                    elseif currentChar == '[' or currentChar == '{' then
                                        brcStack[#brcStack+1] = currentChar
                                    elseif currentChar == ']' then
                                        if brcStack[#brcStack] == ']' then
                                            brcStack[#brcStack] = nil
                                        else
                                            jsonValid = false
                                            break
                                        end
                                    elseif currentChar == '}' then
                                        if brcStack[#brcStack] == '}' then
                                            brcStack[#brcStack] = nil
                                        else
                                            jsonValid = false
                                            break
                                        end
                                    end
                                end
                                break
                            end
                        end
                        break
                    end
                    local currentKey = jsonPath[jsonPathDim]
                    local currentKeyLen = string.len(currentKey)
                    if type(jsonPath[jsonPathDim]) == 'string' then -- Parsing { object
                        while true do
                            local currentChar = nextChar()
                            if currentChar == '{' then
                                brcStack[#brcStack+1] = '{'
                                local origBrcLvl = #brcStack
                                local keyFound = true
                                for z=1, fileLen do -- loop over keys until we find it
                                    currentChar = nextChar()
                                    if currentChar == '\\' then
                                        nextChar()
                                        -- Continue
                                    elseif origBrcLvl == #brcStack and currentChar == '"' then
                                        local keyMatched = false
                                        for i=1, fileLen do
                                            local expectedChar = string.sub(currentKey,i,i)
                                            if nextChar() == expectedChar then
                                                if i == currentKeyLen and nextChar() == '"' then
                                                    keyMatched = true
                                                    while true do 
                                                        currentChar = nextChar()
                                                        if currentChar == ':' then
                                                            break
                                                        elseif currentChar == nil then
                                                            jsonValid = false
                                                            break
                                                        end
                                                    end
                                                    break
                                                end
                                                -- Continue
                                            else
                                                keyMatched = false
                                                break
                                            end
                                        end
                                        if keyMatched then
                                            keyFound = true
                                            break
                                        end
                                    elseif currentChar == '[' or currentChar == '{' then
                                        brcStack[#brcStack+1] = currentChar
                                    elseif currentChar == ']' then
                                        if brcStack[#brcStack] == ']' then
                                            brcStack[#brcStack] = nil
                                        else
                                            jsonValid = false
                                            break
                                        end
                                    elseif currentChar == '}' then
                                        if brcStack[#brcStack] == '}' then
                                            brcStack[#brcStack] = nil
                                        else
                                            jsonValid = false
                                            break
                                        end
                                    end
                                end
                                if keyFound then
                                    jsonPathDim = jsonPathDim+1
                                end
                                break
                            elseif currentChar == nil then
                                jsonValid = false
                                break
                            end
                        end
                    elseif type(jsonPath[jsonPathDim]) == 'number' then -- Parsing [ array
                        while true do
                            local currentChar = nextChar()
                            if currentChar == '[' then
                                brcStack[#brcStack+1] = '['
                                local origBrcLvl = #brcStack
                                local currentIndex = 1
                                -- currentKey
                                local keyMatched = true
                                for i=1, fileLen do
                                    currentChar = nextChar()
                                    if currentChar == '\\' then
                                        nextChar()
                                        -- Continue
                                    elseif origBrcLvl == #brcStack and currentChar == ',' then
                                        currentIndex = currentIndex +1
                                        if currentIndex == currentKey then
                                            jsonPathDim = jsonPathDim+1
                                            break
                                        end
                                    elseif currentChar == '[' or currentChar == '{' then
                                        brcStack[#brcStack+1] = currentChar
                                    elseif currentChar == ']' then
                                        if brcStack[#brcStack] == ']' then
                                            brcStack[#brcStack] = nil
                                        else
                                            jsonValid = false
                                            break
                                        end
                                    elseif currentChar == '}' then
                                        if brcStack[#brcStack] == '}' then
                                            brcStack[#brcStack] = nil
                                        else
                                            jsonValid = false
                                            break
                                        end
                                    else
                                        -- Continue
                                    end
                                end
                                break
                            elseif currentChar == nil then
                                jsonValid = false
                                break
                            end
                        end
                    else
                        jsonValid = false
                        break -- Invalid json
                    end
                end
                jsonPath = {} -- Reset the jsonPath
                return valueToReturn
            end;
        })
      return fakeJson
    end;
})