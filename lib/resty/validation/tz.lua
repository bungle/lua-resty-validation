local parse      = require "luatz.parse".rfc_3339
local validation = require "resty.validation"
local validators = validation.validators
local factory    = getmetatable(validators)
function factory.totimetable()
    return function(value)
        if #value == 10 then
            value = value .. "T00:00:00Z"
        end
        local tt = parse(value)
        if tt then
            return true, tt
        end
        return false
    end
end
function factory.totimestamp()
    return function(value)
        local ok, tt = validators.totimetable(value)
        if ok then
            return true, tt:timestamp()
        end
        return false
    end
end
validators.totimetable = factory.totimetable()
validators.totimestamp = factory.totimestamp()
return {
    totimetable = validators.totimetable,
    totimestamp = validators.totimestamp
}