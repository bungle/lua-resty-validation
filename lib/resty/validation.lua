local setmetatable = setmetatable
local getmetatable = getmetatable
local rawget = rawget
local select = select
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
function factory.iftype(t, truthy, falsy)
    local check = istype(t)
    return function(value)
        if check(value) then
            return true, truthy
        end
        return true, falsy
    end
end
function factory.ifnil(truthy, falsy)
    return factory.iftype("nil", truthy, falsy)
end
factory.ifnull = factory.ifnil
function factory.ifboolean(truthy, falsy)
    return factory.iftype("boolean", truthy, falsy)
end
function factory.ifnumber(truthy, falsy)
    return factory.iftype("number", truthy, falsy)
end
function factory.ifstring(truthy, falsy)
    return factory.iftype("string", truthy, falsy)
end
function factory.ifuserdata(truthy, falsy)
    return factory.iftype("userdata", truthy, falsy)
end
function factory.iffunction(truthy, falsy)
    return factory.iftype("function", truthy, falsy)
end
factory.iffunc = factory.iffunction
function factory.ifthread(truthy, falsy)
    return factory.iftype("thread", truthy, falsy)
end
function factory.ifinteger(truthy, falsy)
    return factory.iftype("integer", truthy, falsy)
end
function factory.iffloat(truthy, falsy)
    return factory.iftype("float", truthy, falsy)
end
function factory.iffile(truthy, falsy)
    return factory.iftype("file", truthy, falsy)
end
function factory.iftrue(truthy, falsy)
    return function(value)
        if value then
            return true, truthy
        end
        return true, falsy
    end
end
function factory.iffalse(truthy, falsy)
    return function(value)
        if not value then
            return true, truthy
        end
        return true, falsy
    end
end
function factory.abs()
    return function(value)
        return true, abs(value)
    end
end
function factory.positive()
    return function(value)
        return value > 0
    end
end
function factory.negative()
    return function(value)
        return value < 0
    end
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
    if not max then max = min end
    if max < min then min, max = max, min end
    return function(value)
        local l
        if type(value) == "string" then l = len(value) else l = #value end
        if type(l)     ~= "number" then return false end
        return l >= min and l <= max
    end
end
function factory.minlen(min)
    return factory.len(min)
end
function factory.maxlen(max)
    return factory.len(nil, max)
end
function factory.equals(equal)
    return function(value)
        return value == equal
    end
end
factory.equal = factory.equals
function factory.unequals(unequal)
    return function(value)
        return value ~= unequal
    end
end
factory.unequal = factory.unequals
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
function factory.toboolean()
    return function(value)
        return true, not not value
    end
end
function factory.tonil()
    return function()
        return true, nil
    end
end
factory.tonull = factory.tonil
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
function factory.coalesce(...)
    local args = { ... }
    return function(value)
        if value ~= nil then return true, value end
        for _, v in ipairs(args) do
            if v ~= nil then return true, v end
        end
        return true, nil
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
    toboolean    = factory.toboolean(),
    tonil        = factory.tonil(),
    tonull       = factory.tonull(),
    abs          = factory.abs(),
    positive     = factory.positive(),
    negative     = factory.negative(),
    lower        = factory.lower(),
    upper        = factory.upper(),
    trim         = factory.trim(),
    ltrim        = factory.ltrim(),
    rtrim        = factory.rtrim(),
    reverse      = factory.reverse()
}, factory)

local field = {}

function field:__tostring()
    if type(self.value == "string") then return self.value end
    return tostring(self.value)
end

local dmt = {}

function dmt:__call(...)
    local argc = select("#", ...)
    local data = setmetatable({}, dmt)
    if argc == 0 then
        for index, value in pairs(self) do
            data[index] = value
        end
    else
        for _, index in ipairs{ ... } do
            if self[index] then
                data[index] = self[index]
            end
        end
    end
    return data
end

local fields = {}

function fields:__call(...)
    local valids, invalids
    local argc = select("#", ...)
    if argc == 0 then
        valids = true
    else
        local argv = select(1, ...)
        if argv == "valid" then
            valids = true
        elseif argv == "invalid" then
            invalids = true
        elseif argv == "all" then
            valids = true
            invalids = true
        elseif argv then
            valids = true
        end
        if argc > 1 then
            argv = select(2, ...)
            if argv == "valid" then
                if not valids then
                    valids = true
                end
            elseif not invalids and argv then
                invalids = true
            end
        end
    end
    local data = setmetatable({}, dmt)
    for index, field in pairs(self) do
        if valids and field.valid then
            data[index] = field.value
        elseif invalids and field.invalid then
            data[index] = field.value
        end
    end
    return data
end

local mt = {}

function mt:__call(t)
    local errors  = {}
    local results = setmetatable({}, fields)
    for index, func in pairs(self) do
        local input = t[index]
        local ok, value = func(input)
        if ok then
            results[index] = setmetatable({
                name = index,
                input = input,
                value = value,
                valid = true,
                invalid = false,
                error = nil
            }, field)
        else
            errors[#errors + 1] = index
            errors[index] = value
            results[index] = setmetatable({
                name = index,
                input = input,
                value = input,
                valid = false,
                invalid = true,
                error = err
            }, field)
        end
    end
    for index, input in pairs(t) do
        if not results[index] then
            results[index] = setmetatable({
                name = index,
                input = input,
                value = input,
                valid = true,
                invalid = false,
                error = nil
            }, field)
        end
    end
    return #errors == 0, results, errors
end

function group()
    return setmetatable({}, mt)
end

local function validation(func, parent_f, parent, method)
    return setmetatable({ new = group, validators = validators }, {
        __index = function(self, index)
            return validation(function(...)
                local valid, value = func(...)
                if not valid then error(index, 0) end
                local validator = rawget(self.validators, index)
                if not validator then
                    error(index, 0)
                end
                local valid, v = validator(value)
                if not valid then error(index, 0)  end
                return valid, v or value
            end, func, self, index)
        end,
        __call = function(_, self, ...)
            if parent ~= nil and self == parent then
                local n = select("#", ...)
                local args = { ... }
                return validation(function(...)
                    local valid, value = parent_f(...)
                    if not valid then error(method, 0) end
                    local validator = rawget(getmetatable(self.validators), method)
                    if not validator then
                        error(method, 0)
                    end
                    local valid, v = validator(unpack(args, 1, n))(value)
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