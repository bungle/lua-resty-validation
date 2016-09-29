local validation   = require "resty.validation"
local ngx          = ngx
local escapeuri    = ngx.escape_uri
local unescapeuri  = ngx.unescape_uri
local base64enc    = ngx.encode_base64
local base64dec    = ngx.decode_base64
local crc32short   = ngx.crc32_short
local crc32long    = ngx.crc32_long
local md5          = ngx.md5
local md5bin       = ngx.md5bin
local match        = ngx.re.match
local validators   = validation.validators
local factory      = getmetatable(validators)
function factory.escapeuri()
    return function(value)
        return true, escapeuri(value)
    end
end
function factory.unescapeuri()
    return function(value)
        return true, unescapeuri(value)
    end
end
function factory.base64enc()
    return function(value)
        return true, base64enc(value)
    end
end
function factory.base64dec()
    return function(value)
        local decoded = base64dec(value)
        if decoded == nil then
            return false
        end
        return true, decoded
    end
end
function factory.crc32short()
    return function(value)
        return true, crc32short(value)
    end
end
function factory.crc32long()
    return function(value)
        return true, crc32long(value)
    end
end
function factory.crc32()
    return function(value)
        if #value < 61 then
            return true, crc32short(value)
        end
        return true, crc32long(value)
    end
end
function factory.md5(bin)
    return function(value)
        local digest = bin and md5bin(value) or md5(value)
        return true, digest
    end
end

function factory.regex(regex, options)
    return function(value)
        return (match(value, regex, options)) ~= nil
    end
end
validators.escapeuri   = factory.escapeuri()
validators.unescapeuri = factory.unescapeuri()
validators.base64enc   = factory.base64enc()
validators.base64dec   = factory.base64dec()
validators.crc32short  = factory.crc32short()
validators.crc32long   = factory.crc32long()
validators.crc32       = factory.crc32()
validators.md5         = factory.md5()
return {
    escapeuri   = validators.escapeuri,
    unescapeuri = validators.unescapeuri,
    base64enc   = validators.base64enc,
    base64dec   = validators.base64dec,
    crc32short  = validators.crc32short,
    crc32long   = validators.crc32long,
    crc32       = validators.crc32,
    md5         = validators.md5,
    regex       = factory.regex
}