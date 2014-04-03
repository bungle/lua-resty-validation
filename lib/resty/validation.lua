local setmetatable = setmetatable
local tostring = tostring
local tonumber = tonumber
local ipairs = ipairs
local assert = assert
local match = string.match
local type = type
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
function validators.len(min, max)
    if not max then max = min end
    return function(value)
        local l = #value
        return type(l) == "number" and l >= min and l <= max
    end
end
function validators.utf8len(min, max, i)
    if not max then max = min end
    return function(value)
        local l = utf8.len(value, i)
        return type(l) == "number" and l >= min and l <= max
    end
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
return setmetatable({ validators = validators }, { __index = function(_, k)
    assert(validators[k], "Invalid validator '" .. k .. "'")
    return function(...)
        return setmetatable({ validators = {{ validators[k](...), k }}}, {
            __index = function(t, k)
                assert(validators[k], "Invalid validator '" .. k .. "'")
                return function(...)
                    t.validators[#t.validators+1] = { validators[k](...), k }
                    return t
                end
            end,
            __call = function(t, value)
                for _, v in ipairs(t.validators) do
                    local valid, val = v[1](value)
                    if not valid  then return false, v[2] end
                    if val ~= nil then value = val end
                end
                return true, nil
            end
        })
    end
end })
