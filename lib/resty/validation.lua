local setmetatable = setmetatable
local getmetatable = getmetatable
local rawget = rawget
local tostring = tostring
local tonumber = tonumber
local type = type
local ipairs = ipairs
local error = error
local match = string.match
local lower = string.lower
local upper = string.upper
local gsub = string.gsub
local len = string.len
local reverse = string.reverse
local iotype = io.type
local mathtype = math.type
local tointeger = math.tointeger
local abs = math.abs
local unpack = unpack or table.unpack

if utf8 and utf8.len then
    len = utf8.len
end

local function istype(t)
    if t == "integer" or t == "float" then
        return function(value)
            return t == mathtype(value)
        end
    elseif t == "file" then
        return function(value)
            return t == iotype(value)
        end
    else
        return function(value)
            return t == type(value)
        end
    end
end

local factory = {}

function factory.type(t)
    return istype(t)
end
function factory.min(min)
    return function(value)
        return value >= min
    end
end
function factory.max(max)
    return function(value)
        return value <= max
    end
end
function factory.between(min, max)
    if not max then max = min end
    if max < min then min, max = max, min end
    return function(value)
        return value >= min and value <= max
    end
end
function factory.outside(min, max)
    if not max then max = min end
    if max < min then min, max = max, min end
    return function(value)
        return value < min and value > max
    end
end
function factory.divisible(number)
    return function(value)
        if type(value) == "number" then
            return value % number == 0
        else
            return false
        end
    end
end
function factory.indivisible(number)
    return function(value)
        if type(value) == "number" then
            return value % number ~= 0
        else
            return false
        end
    end
end
function factory.len(min, max)
    local mn, mx
    if type(min) == "table" then
        if min.min then mn = min.min end
        if min.max then mx = min.max end
    else
        mn, mx = min, max
    end
    return function(value)
        local l
        if type(value) == "string" then l = len(value) else l = #value end
        if type(l)     ~= "number" then return false end
        if mn and l < mn           then return false end
        if mx and l > mx           then return false end
        return true
    end
end
function factory.minlen(min)
    return factory.len(min)
end
function factory.maxlen(max)
    return factory.len(nil, max)
end
function factory.nulif()
end
function factory.equal(values)
    return function(value)
        if type(values) == "table" then
            for _,v in ipairs(values) do
                if v == value then return true end
            end
        end
        return value == values
    end
end
function factory.unequal(values)
    return function(value)
        if type(values) == "table" then
            for _,v in ipairs(values) do
                if v == value then return false end
            end
        end
        return value ~= values
    end
end
function factory.match(pattern, init)
    return function(value)
        return match(value, pattern, init) ~= nil
    end
end
function factory.unmatch(pattern, init)
    return function(value)
        return match(value, pattern, init) == nil
    end
end
function factory.tostring()
    return function(value)
        return true, tostring(value)
    end
end
function factory.tonumber(base)
    return function(value)
        local nbr = tonumber(value, base)
        return nbr ~= nil, nbr
    end
end
function factory.tointeger()
    return function(value)
        local nbr = tointeger(value)
        return nbr ~= nil, nbr
    end
end
function factory.lower()
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, lower(value)
        end
        return false
    end
end
function factory.upper()
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, upper(value)
        end
        return false
    end
end
function factory.trim(pattern)
    pattern = pattern or "%s+"
    local l = "^" .. pattern
    local r = pattern .. "$"
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, (gsub(value, r, ""):gsub(l, ""))
        end
        return false
    end
end
function factory.ltrim(pattern)
    pattern = "^" .. (pattern or "%s+")
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, (gsub(value, pattern, ""))
        end
        return false
    end
end
function factory.rtrim(pattern)
    pattern = (pattern or "%s+") .. "$"
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, (gsub(value, pattern, ""))
        end
        return false
    end
end
function factory.reverse()
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, reverse(value)
        end
        return false
    end
end

factory.__index = factory

local validators = setmetatable({
    ["nil"]      = istype("nil"),
    null         = istype("nil"),
    boolean      = istype("boolean"),
    number       = istype("number"),
    string       = istype("string"),
    userdata     = istype("userdata"),
    ["function"] = istype("function"),
    func         = istype("function"),
    thread       = istype("thread"),
    integer      = istype("integer"),
    float        = istype("float"),
    file         = istype("file"),
    tostring     = factory.tostring(),
    tonumber     = factory.tonumber(),
    tointeger    = factory.tointeger(),
    lower        = factory.lower(),
    upper        = factory.upper(),
    trim         = factory.trim(),
    ltrim        = factory.ltrim(),
    rtrim        = factory.rtrim(),
    reverse      = factory.reverse()
}, factory)

local function validation(func, parent_f, parent, method)
    return setmetatable({ validators = validators }, {
        __index = function(self, index)
            return validation(function(...)
                local valid, value = func(...)
                if not valid then error(index, 0) end
                local validator = rawget(self.validators, index)
                if not validator then
                    error(index, 0)
                end
                local valid, v = validator(value)
                if not valid then error(index, 0) end
                return valid, v or value
            end, func, self, index)
        end,
        __call = function(_, self, ...)
            if self == parent then
                local args = { ... }
                return validation(function(...)
                    local valid, value = parent_f(...)
                    if not valid then error(method, 0) end
                    local validator = rawget(getmetatable(self.validators), method)
                    if not validator then
                        error(method, 0)
                    end
                    local valid, v = validator(unpack(args))(value)
                    if not valid then error(method, 0) end
                    return valid, v or value
                end)
            end
            local ok, error, value = pcall(func, self, ...)
            if ok then
                return true, value
            end
            return false, error
        end
    })
end

return validation(function(...)
    return true, ...
end)