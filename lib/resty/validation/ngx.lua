local validation   = require "resty.validation"
local escape_uri   = ngx.escape_uri
local unescape_uri = ngx.unescape_uri
local base64enc    = ngx.encode_base64
local base64dec    = ngx.decode_base64
local crc32short   = ngx.crc32_short
local crc32long    = ngx.crc32_long
validation.validators.factory.escape_uri = function()
    return function(value)
        return true, escape_uri(value)
    end
end
validation.validators.factory.unescape_uri = function()
    return function(value)
        return true, unescape_uri(value)
    end
end
validation.validators.factory.base64enc = function()
    return function(value)
        return true, base64enc(value)
    end
end
validation.validators.factory.base64dec = function()
    return function(value)
        local decoded = base64dec(value)
        if decoded == nil then
            return false
        end
        return true, decoded
    end
end
validation.validators.factory.crc32short = function()
    return function(value)
        return true, crc32short(value)
    end
end
validation.validators.factory.crc32long = function()
    return function(value)
        return true, crc32long(value)
    end
end
validation.validators.factory.crc32 = function()
    return function(value)
        if #value < 61 then
            return true, crc32short(value)
        end
        return true, crc32long(value)
    end
end
