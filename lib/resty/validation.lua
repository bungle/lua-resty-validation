local setmetatable = setmetatable
local tostring = tostring
local tonumber = tonumber
local ipairs = ipairs
local assert = assert
local match = string.match
local lower = string.lower
local upper = string.upper
local pairs = pairs
local type = type
local function len(func, ...)
    local args = {...}
    local min, max
    if #args == 1 then
        if type(args[1]) == "table" then
            if args[1].min then min = args[1].min end
            if args[1].max then max = args[1].max end
        else
            min = args[1]
            max = args[1]
        end
    else
        min = args[1]
        max = args[2]
    end
    return function(value)
        local l
        if func then l = func(value) else l = #value end
        if type(l)  ~= "number" then return false end
        if min and l < min      then return false end
        if max and l > max      then return false end
        return true
    end
end
local validators = {}
function validators.type(t)
    return function(value)
        return type(value) == t
    end
end
function validators.min(min)
    return function(value)
        return value >= min
    end
end
function validators.max(max)
    return function(value)
        return value <= max
    end
end
function validators.between(min, max)
    if not max then max = min end
    return function(value)
        return value >= min and value <= max
    end
end
function validators.len(...)
    return len(nil, ...)
end
function validators.utf8len(...)
    return len(utf8.len, ...)
end
function validators.equal(...)
    local values = {...}
    return function(value)
        for _,v in ipairs(values) do
            if v == value then return true end
        end
        return false
    end
end
function validators.match(pattern, init)
    return function(value)
        return match(value, pattern, init) ~= nil
    end
end
function validators.tostring()
    return function(value)
        return true, tostring(value)
    end
end
function validators.tonumber(base)
    return function(value)
        local nbr = tonumber(value, base)
        return nbr ~= nil, nbr
    end
end
function validators.lower()
    return function(value)
        if type(value) == "string" or type(value) == "number" then
            return true, lower(value)
        end
        return false
    end
end
function validators.upper()
    return function(value)
        if type(value) == "string" or type(value) == "number" then
            return true, upper(value)
        end
        return false
    end
end
validators.types = {
    ["nil"]      = validators.type("nil"),
    ["boolean"]  = validators.type("boolean"),
    ["number"]   = validators.type("number"),
    ["string"]   = validators.type("string"),
    ["userdata"] = validators.type("userdata"),
    ["function"] = validators.type("function"),
    ["thread"]   = validators.type("thread")
}
local mt = {}
function mt.__index(t, k)
    if validators.types[k] then
        t.validators[#t.validators+1] = { validators.types[k], k }
        return t
    end
    assert(validators[k], "Invalid validator '" .. k .. "'")
    return function(...)
        t.validators[#t.validators+1] = { validators[k](...), k }
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
        if validators.types[k] then
            return setmetatable({ validators = {{ validators.types[k], k }}}, mt)
        end
        assert(validators[k], "Invalid validator '" .. k .. "'")
        return function(...)
            return setmetatable({ validators = {{ validators[k](...), k }}}, mt)
        end
    end
})
function validation.new(values)
    return setmetatable({
        valid = true,
        invalid = false,
        validate = function(self)
            local errors = {}
            self.valid   = true
            self.invalid = false
            for _, field in pairs(self) do
                if type(field) == "table" and field.invalid == true then
                    if self.valid then
                        self.valid   = false
                        self.invalid = true
                    end
                    errors[#errors+1] = field
                end
            end
            if self.valid then
                return true, nil
            else
                return false, errors
            end
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
