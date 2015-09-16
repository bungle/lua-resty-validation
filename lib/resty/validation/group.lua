local setmetatable = setmetatable
local pairs = pairs
local rmt = {
    __tostring = function(self)
        return self.value
    end
}
local mt = {}

function mt:__call(t)
    local errors  = {}
    local results = {}
    for index, value in pairs(t) do
        local ok, err = true, value
        if self[index] then
            ok, err = self[index](value)
        end
        if ok then
           results[index] = setmetatable({
               name = name,
               input = value,
               value = err,
               valid = true,
               invalid = false,
               error = nil
           }, rmt)
        else
            errors[#errors + 1] = index
            errors[index] = err
            results[index] = setmetatable({
                name = name,
                input = value,
                value = value,
                valid = false,
                invalid = true,
                error = err
            }, rmt)
        end
    end
    return false, results, errors
end

local group = {}

function group.new()
    return setmetatable({}, mt)
end

return group
