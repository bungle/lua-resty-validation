local i          = require "resty.injection"
local validation = require "resty.validation"
local validators = validation.validators
function validators.sqli(value)
    return not i.sql(value)
end
function validators.xss(value)
    return not i.xss(value)
end
return {
    sqli = validators.sqli,
    xss  = validators.xss
}