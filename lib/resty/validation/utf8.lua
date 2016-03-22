local u          = require "resty.utf8rewind"
local validation = require "resty.validation"
local validators = validation.validators
local factory    = getmetatable(validators)
local type       = type
function factory.utf8upper()
    return function(value)
        local t = type(value)
        if t == "string" then
            return true, u.utf8toupper(value)
        end
        return false
    end
end
function factory.utf8lower()
    return function(value)
        local t = type(value)
        if t == "string" then
            return true, u.utf8tolower(value)
        end
        return false
    end
end
function factory.utf8title()
    return function(value)
        local t = type(value)
        if t == "string" then
            return true, u.utf8title(value)
        end
        return false
    end
end
function factory.utf8normalize(form)
    return function(value)
        local t = type(value)
        if t == "string" then
            return true, u.utf8normalize(value, form)
        end
        return false
    end
end
function factory.utf8category(category)
    return function(value)
        local t = type(value)
        if t == "string" then
            return (u.utf8iscategory(value, category))
        end
        return false
    end
end
validators.utf8upper     = factory.utf8upper()
validators.utf8lower     = factory.utf8lower()
validators.utf8title     = factory.utf8title()
return {
    utf8upper     = validators.utf8upper,
    utf8lower     = validators.utf8lower,
    utf8title     = validators.utf8title,
    utf8normalize = factory.utf8normalize,
    utf8category  = factory.utf8category
}