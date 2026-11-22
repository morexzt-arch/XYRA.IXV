-- Scripts/utils/json.lua
-- Pure Lua JSON Decoder (Aman untuk manifest sederhana)
local json = {}

local function skipWhitespace(str, pos)
    local _, e = string.find(str, "^[ \t\r\n]*", pos)
    return e + 1
end

local function parseValue(str, pos)
    pos = skipWhitespace(str, pos)
    local char = string.sub(str, pos, pos)
    
    if char == '"' then -- String
        local res = ""
        pos = pos + 1
        while pos <= #str do
            local c = string.sub(str, pos, pos)
            if c == '"' then return res, pos + 1 end
            if c == '\\' then
                local nextC = string.sub(str, pos + 1, pos + 1)
                if nextC == 'n' then res = res .. "\n"
                elseif nextC == 't' then res = res .. "\t"
                else res = res .. nextC end
                pos = pos + 2
            else
                res = res .. c
                pos = pos + 1
            end
        end
    elseif char == '{' then -- Object
        local obj = {}
        pos = pos + 1
        pos = skipWhitespace(str, pos)
        if string.sub(str, pos, pos) == '}' then return obj, pos + 1 end
        while pos <= #str do
            local key, newPos = parseValue(str, pos)
            pos = skipWhitespace(str, newPos)
            pos = pos + 1 -- skip ':'
            local val, newPos2 = parseValue(str, pos)
            pos = skipWhitespace(str, newPos2)
            obj[key] = val
            local nextChar = string.sub(str, pos, pos)
            if nextChar == ',' then pos = pos + 1
            elseif nextChar == '}' then return obj, pos + 1 end
        end
    elseif char == '[' then -- Array
        local arr = {}
        pos = pos + 1
        pos = skipWhitespace(str, pos)
        if string.sub(str, pos, pos) == ']' then return arr, pos + 1 end
        while pos <= #str do
            local val, newPos = parseValue(str, pos)
            arr[#arr + 1] = val
            pos = skipWhitespace(str, newPos)
            local nextChar = string.sub(str, pos, pos)
            if nextChar == ',' then pos = pos + 1
            elseif nextChar == ']' then return arr, pos + 1 end
        end
    else -- Number, Boolean, Null
        local numMatch = string.match(str, "^-?%d+%.?%d*[eE]?[%+%-]?%d*", pos)
        if numMatch then return tonumber(numMatch), pos + #numMatch end
        local word = string.match(str, "^%a+", pos)
        if word == "true" then return true, pos + 4 end
        if word == "false" then return false, pos + 5 end
        if word == "null" then return nil, pos + 4 end
    end
    return nil, pos
end

function json.decode(str)
    local ok, result = pcall(parseValue, str, 1)
    if ok then return result else return nil end
end

return json
