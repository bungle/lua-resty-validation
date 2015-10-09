local parse      = require "luatz.parse".rfc_3339
local validation = require "resty.validation"
local validators = validation.validators
local factory    = getmetatable(validators)
function factory.totimestamp()
    return function(value)
        local ok, tt = pcall(parse, value)
        if ok then
            return true, tt:timestamp()
        end
        return false
    end
end
validators.totimestamp = factory.totimestamp()
return {
    totimestamp = validators.totimestamp
}