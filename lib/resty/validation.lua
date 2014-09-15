local setmetatable = setmetatable
local tostring = tostring
local tonumber = tonumber
local ipairs = ipairs
local assert = assert
local match = string.match
local lower = string.lower
local upper = string.upper
local pairs = pairs
local gsub = string.gsub
local type = type
local iotype = io.type
local mathtype = math.type
local tointeger = math.tointeger
local len = string.len
if utf8 and utf8.len then
    len = utf8.len
end
local function istype(t)
    if t == "integer" or t == "float" then
        return function(value)
            return mathtype(value) == t
        end
    elseif t == "file" then
        return function(value)
            return iotype(value) == t
        end
    else
        return function(value)
            return type(value) == t
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
    assert(type(number) == "number")
    return function(value)
        if type(value) == "number" then
            return value % number == 0
        else
            return false
        end
    end
end
function factory.indivisible(number)
    assert(type(number) == "number")
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
    return factory.len(nil, min)
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
        if type(value) == "string" or type(value) == "number" then
            return true, lower(value)
        end
        return false
    end
end
function factory.upper()
    return function(value)
        if type(value) == "string" or type(value) == "number" then
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
        if type(value) == "string" or type(value) == "number" then
            return true, (gsub(value, r, ""):gsub(l, ""))
        end
        return false
    end
end
function factory.ltrim(pattern)
    pattern = "^" .. (pattern or "%s+")
    return function(value)
        if type(value) == "string" or type(value) == "number" then
            return true, (gsub(value, pattern, ""))
        end
        return false
    end
end
function factory.rtrim(pattern)
    pattern = (pattern or "%s+") .. "$"
    return function(value)
        if type(value) == "string" or type(value) == "number" then
            return true, (gsub(value, pattern, ""))
        end
        return false
    end
end
local validators = { factory = factory }
validators["nil"]      = istype("nil")
validators["null"]     = istype("nil")
validators["boolean"]  = istype("boolean")
validators["number"]   = istype("number")
validators["string"]   = istype("string")
validators["userdata"] = istype("userdata")
validators["function"] = istype("function")
validators["func"]     = istype("function")
validators["thread"]   = istype("thread")
validators["integer"]  = istype("integer")
validators["float"]    = istype("float")
validators["file"]     = istype("file")
local mt = {}
function mt.__index(t, k)
    if validators[k] then
        t.validators[#t.validators+1] = { validators[k], k }
        return t
    end
    assert(validators.factory[k], "Invalid validator '" .. k .. "'")
    return function(...)
        t.validators[#t.validators+1] = { validators.factory[k](...), k }
        return t
    end
end
function mt.__call(t, value)
    for _, validator in ipairs(t.validators) do
        local valid, v = validator[1](value)
        if not valid then return false, validator[2] end
        if v ~= nil then value = v end
    end
    return true, value
end
local validation = setmetatable({ validators = validators }, {
    __index = function(_, k)
        if validators[k] then
            return setmetatable({ validators = {{ validators[k], k }}}, mt)
        end
        assert(validators.factory[k], "Invalid validator '" .. k .. "'")
        return function(...)
            return setmetatable({ validators = {{ validators.factory[k](...), k }}}, mt)
        end
    end
})
function validation.new(values)
    return setmetatable({
        valid   = true,
        invalid = false,
        errors  = {},
        validate = function(self)
            self.errors = {}
            self.valid   = true
            self.invalid = false
            for _, field in pairs(self) do
                if type(field) == "table" and field.invalid == true then
                    if self.valid then
                        self.valid   = false
                        self.invalid = true
                    end
                    self.errors[#self.errors+1] = field
                end
            end
            return self.valid, self.errors
        end
    }, {
        __index = function(f, k)
            f[k] = setmetatable({
                name     = k,
                valid    = true,
                invalid  = false,
                input    = values[k],
                value    = values[k],
                validate = function(t, ...)
                    for _, validator in ipairs({...}) do
                        local valid, v = validator(t.value)
                        if not valid then
                            t.error   = v
                            t.valid   = false
                            t.invalid = true
                            return false, v
                        end
                        if v ~= nil then t.value = v end
                    end
                    return true, t.value
                end
            }, {
                __tostring = function(self)
                    return self.value
                end
            })
            f:validate()
            return f[k]
        end
    })
end
return validation
