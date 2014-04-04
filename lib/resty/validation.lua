local setmetatable = setmetatable
local tostring = tostring
local tonumber = tonumber
local ipairs = ipairs
local assert = assert
local match = string.match
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
local mt = {}
function mt.__index(t, k)
    assert(validators[k], "Invalid validator '" .. k .. "'")
    return function(...)
        t.validators[#t.validators+1] = { validators[k](...), k }
        return t
    end
end
function mt.__call(t, value)
    for _, v in ipairs(t.validators) do
        local valid, val = v[1](value)
        if not valid  then return false, v[2] end
        if val ~= nil then value = val end
    end
    return true, nil
end
local validation = setmetatable({ validators = validators }, {
    __index = function(_, k)
        assert(validators[k], "Invalid validator '" .. k .. "'")
        return function(...)
            return setmetatable({ validators = {{ validators[k](...), k }}}, mt)
        end
    end
})
function validation.new(values)
    --for k,v in pairs(values) do
    --end
end
return validation


