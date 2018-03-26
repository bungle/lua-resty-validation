local _VERSION = "2.7"
local setmetatable = setmetatable
local getmetatable = getmetatable
local rawget = rawget
local select = select
local tostring = tostring
local tonumber = tonumber
local type = type
local pairs = pairs
local ipairs = ipairs
local error = error
local pcall = pcall
local string = string
local match = string.match
local lower = string.lower
local upper = string.upper
local find = string.find
local gsub = string.gsub
local sub = string.sub
local len = utf8 and utf8.len or function(s) return select(2, gsub(s, '[^\x80-\xC1]', '')) end
local iotype = io.type
local math = math
local mathtype = math.type
local tointeger = math.tointeger
local abs = math.abs
local unpack = unpack or table.unpack
local nothing = {}
local inf = math.huge
local sreverse = string.reverse
local stopped = {}
local operators = { "<=", ">=", "==", "~=", "<", ">" }
local function stop(value)
    return setmetatable({ value = value }, stopped)
end
local function reverse(s)
    return sreverse(gsub(s, "[%z-\x7F\xC2-\xF4][\x80-\xBF]*", function(c) return #c > 1 and sreverse(c) end))
end
local function trim(s)
    return (gsub(s, "%s+$", ""):gsub("^%s+", ""))
end
if not mathtype then
    mathtype = function(value)
        if type(value) ~= "number" then
            return nil
        end
        return value % 1 == 0 and "integer" or "float"
    end
end
if not tointeger then
    tointeger = function(value)
        local v = tonumber(value)
        return mathtype(value) == "integer" and v or nil
    end
end
local function istype(t)
    if t == "integer" or t == "float" then
        return function(value)
            return t == mathtype(value)
        end
    elseif t == "file" then
        return function(value)
            return t == iotype(value)
        end
    elseif t == "callable" then
        return function(value)
            if type(value) == "function" then
                return true
            end
            local m = getmetatable(value)
            return m and type(m.__call) == "function"
        end
    else
        return function(value)
            return t == type(value)
        end
    end
end
local factory = {}
factory.__index = factory
function factory.type(t)
    return istype(t)
end
function factory.iftype(t, truthy, falsy)
    local check = istype(t)
    return function(value)
        if check(value) then
            return true, truthy
        end
        return true, falsy
    end
end
function factory.null()
    return factory.type("nil")
end
factory["nil"] = factory.null
function factory.boolean()
    return factory.type "boolean"
end
function factory.number()
    return factory.type "number"
end
function factory.string()
    return factory.type "string"
end
function factory.table()
    return factory.type "table"
end
function factory.userdata()
    return factory.type "userdata"
end
function factory.func()
    return factory.type "function"
end
function factory.callable()
    return factory.type "callable"
end
factory["function"] = factory.func
function factory.thread()
    return factory.type "thread"
end
function factory.integer()
    return factory.type "integer"
end
function factory.float()
    return factory.type "float"
end
function factory.file()
    return factory.type "file"
end
function factory.inf()
    return function(value)
        return value == inf or value == -inf
    end
end
function factory.nan()
    return function(value)
        return value ~= value
    end
end
function factory.finite()
    return function(value)
        if value ~= value then
            return false
        end
        return value ~= inf and value ~= -inf
    end
end
function factory.abs()
    return function(value)
        return true, abs(value)
    end
end
function factory.positive()
    return function(value)
        return value > 0
    end
end
function factory.negative()
    return function(value)
        return value < 0
    end
end
function factory.min(min)
    return function(value)
        return value >= min
    end
end
function factory.max(max)
    return function(value)
        return value <= max
    end
end
function factory.between(min, max)
    if not max then max = min end
    if max < min then min, max = max, min end
    return function(value)
        return value >= min and value <= max
    end
end
function factory.outside(min, max)
    if not max then max = min end
    if max < min then min, max = max, min end
    return function(value)
        return value < min and value > max
    end
end
function factory.divisible(number)
    return function(value)
        if type(value) == "number" then
            return value % number == 0
        else
            return false
        end
    end
end
function factory.indivisible(number)
    return function(value)
        if type(value) == "number" then
            return value % number ~= 0
        else
            return false
        end
    end
end
function factory.len(min, max)
    if max then
        if max < min then min, max = max, min end
    else
        max = min
    end
    return function(value)
        local t = type(value)
        if t ~= "string" and t ~= "table" then return false end
        if type(min) ~= "number" or type(max) ~= "number" or type(value) == "nil" then return false end
        local l
        if t == "string" then l = len(value) else l = #value end
        if type(l) ~= "number" then return false end
        return l >= min and l <= max
    end
end
function factory.minlen(min)
    return function(value)
        local t = type(value)
        if t ~= "string" and t ~= "table" then return false end
        if type(min) ~= "number" or type(value) == "nil" then return false end
        local l
        if t == "string" then l = len(value) else l = #value end
        if type(l) ~= "number" then return false end
        return l >= min
    end
end
function factory.maxlen(max)
    return function(value)
        local t = type(value)
        if t ~= "string" and t ~= "table" then return false end
        if type(max) ~= "number" then return false end
        local l
        if t == "string" then l = len(value) else l = #value end
        if type(l) ~= "number" then return false end
        return l <= max
    end
end
function factory.equals(equal)
    return function(value)
        return value == equal
    end
end
factory.equal = factory.equals
function factory.unequals(unequal)
    return function(value)
        return value ~= unequal
    end
end
factory.unequal = factory.unequals
function factory.oneof(...)
    local n = select("#", ...)
    local args = { ... }
    return function(value)
        for i = 1, n do
            if value == args[i] then
                return true
            end
        end
        return false
    end
end
function factory.noneof(...)
    local n = select("#", ...)
    local args = { ... }
    return function(value)
        for i = 1, n do
            if value == args[i] then
                return false
            end
        end
        return true
    end
end
function factory.match(pattern, init)
    return function(value)
        return match(value, pattern, init) ~= nil
    end
end
function factory.unmatch(pattern, init)
    return function(value)
        return match(value, pattern, init) == nil
    end
end
function factory.tostring()
    return function(value)
        return true, tostring(value)
    end
end
function factory.tonumber(base)
    return function(value)
        local nbr = tonumber(value, base)
        return nbr ~= nil, nbr
    end
end
function factory.tointeger()
    return function(value)
        local nbr = tointeger(value)
        return nbr ~= nil, nbr
    end
end
function factory.toboolean()
    return function(value)
        return true, not not value
    end
end
function factory.tonil()
    return function()
        return true, nothing
    end
end
factory.tonull = factory.tonil
function factory.lower()
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, lower(value)
        end
        return false
    end
end
function factory.upper()
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, upper(value)
        end
        return false
    end
end
function factory.trim(pattern)
    pattern = pattern or "%s+"
    local l = "^" .. pattern
    local r = pattern .. "$"
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, (gsub(value, r, ""):gsub(l, ""))
        end
        return false
    end
end
function factory.ltrim(pattern)
    pattern = "^" .. (pattern or "%s+")
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, (gsub(value, pattern, ""))
        end
        return false
    end
end
function factory.rtrim(pattern)
    pattern = (pattern or "%s+") .. "$"
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, (gsub(value, pattern, ""))
        end
        return false
    end
end
function factory.starts(starts)
    return function(value)
        return sub(value, 1, len(starts)) == starts
    end
end
function factory.ends(ends)
    return function(value)
        return ends == '' or sub(value, -len(ends)) == ends
    end
end
function factory.reverse()
    return function(value)
        local t = type(value)
        if t == "string" or t == "number" then
            return true, reverse(value)
        end
        return false
    end
end
function factory.coalesce(...)
    local args = { ... }
    return function(value)
        if value ~= nil then return true, value end
        for _, v in ipairs(args) do
            if v ~= nil then return true, v end
        end
        return true
    end
end
function factory.email()
    return function(value)
        if value == nil or type(value) ~= "string" then return false end
        local i, at = find(value, "@", 1, true), nil
        while i do
            at = i
            i = find(value, "@", i + 1)
        end
        if not at or at > 65 or at == 1 then return false end
        local lp = sub(value, 1, at - 1)
        if not lp then return false end
        local dp = sub(value, at + 1)
        if not dp or #dp > 254 then return false end
        local qp = find(lp, '"', 1, true)
        if qp and qp > 1 then return false end
        local q, p
        for i = 1, #lp do
            local c = sub(lp, i, i)
            if c == "@" then
                if not q then return false end
            elseif c == '"' then
                if p ~= [[\]] then
                    q = not q
                end
            elseif c == " " or c == '"' or c == [[\]] then
                if not q then
                    return false
                end
            end
            p = c
        end
        if q or find(lp, "..", 1, true) or find(dp, "..", 1, true) then return false end
        if match(lp, "^%s+") or match(dp, "%s+$") then return false end
        return match(value, "%w*%p*@+%w*%.?%w*") ~= nil
    end
end
function factory.call(func)
    return function(value)
        return func(value)
    end
end
function factory.optional(default)
    return function(value)
        if value == nil or value == "" then
            return stop, default ~= nil and default or value
        end
        return true, value
    end
end
local validators = setmetatable({
    ["nil"]      = factory.null(),
    null         = factory.null(),
    boolean      = factory.boolean(),
    number       = factory.number(),
    string       = factory.string(),
    table        = factory.table(),
    userdata     = factory.userdata(),
    ["function"] = factory.func(),
    func         = factory.func(),
    callable     = factory.callable(),
    thread       = factory.thread(),
    integer      = factory.integer(),
    float        = factory.float(),
    file         = factory.file(),
    tostring     = factory.tostring(),
    tonumber     = factory.tonumber(),
    tointeger    = factory.tointeger(),
    toboolean    = factory.toboolean(),
    tonil        = factory.tonil(),
    tonull       = factory.tonull(),
    abs          = factory.abs(),
    inf          = factory.inf(),
    nan          = factory.nan(),
    finite       = factory.finite(),
    positive     = factory.positive(),
    negative     = factory.negative(),
    lower        = factory.lower(),
    upper        = factory.upper(),
    trim         = factory.trim(),
    ltrim        = factory.ltrim(),
    rtrim        = factory.rtrim(),
    reverse      = factory.reverse(),
    email        = factory.email(),
    optional     = factory.optional()
}, factory)
local data = {}
function data:__call(...)
    local argc = select("#", ...)
    local data = setmetatable({}, data)
    if argc == 0 then
        return self
    else
        for _, index in ipairs{ ... } do
            if self[index] then
                data[index] = self[index]
            end
        end
    end
    return data
end
local field = {}
field.__index = field
function field.new(name, input)
    return setmetatable({
        name = name,
        input = input,
        value = input,
        valid = true,
        invalid = false,
        validated = false,
        unvalidated = true
    }, field)
end
function field:__tostring()
    if type(self.value) == "string" then return self.value end
    return tostring(self.value)
end
function field:state(invalid, valid, unvalidated)
    if self.unvalidated then
        return unvalidated
    end
    return self.valid and valid or invalid
end
function field:accept(value)
    self.error = nil
    self.value = value
    self.valid = true
    self.invalid = false
    self.validated = true
    self.unvalidated = false
end
function field:reject(error)
    self.error = error
    self.valid = false
    self.invalid = true
    self.validated = true
    self.unvalidated = false
end
local fields = {}
function fields:__call(...)
    local valid, invalid, validated, unvalidated
    local argc = select("#", ...)
    if argc == 0 then
        valid = true
    else
        for _, v in ipairs({ ... }) do
            if v == "valid" then
                valid = true
            elseif v == "invalid" then
                invalid = true
            elseif v == "validated" then
                validated = true
            elseif v == "unvalidated" then
                unvalidated = true
            elseif v == "all" then
                valid = true
                invalid = true
                validated = true
                unvalidated = true
            end
        end
    end
    local data = setmetatable({}, data)
    for index, field in pairs(self) do
        if valid and field.valid then
            data[index] = field.value
        elseif invalid and field.invalid then
            data[index] = field.value
        elseif validated and field.validated then
            data[index] = field.value
        elseif unvalidated and field.unvalidated then
            data[index] = field.value
        end
    end
    return data
end
function fields:__index()
    return field.new()
end
local group = {}
group.__index = group
function group:compare(comparison)
    local s, e, o
    for _, operator in ipairs(operators) do
        s, e = find(comparison, operator, 2, true)
        if s then
            o = operator
            break
        end
    end
    local f1 = trim(sub(comparison, 1, s - 1))
    local f2 = trim(sub(comparison,    e + 1))
    self[#self+1] = function(fields)
        if not fields[f1] then
            fields[f1] = field.new(f1)
        end
        if not fields[f2] then
            fields[f2] = field.new(f2)
        end
        local v1 = fields[f1]
        local v2 = fields[f2]
        if v1.valid and v2.valid then
            local valid, x, y = true, v1.value, v2.value
            if o == "<=" then
                valid = x <= y
            elseif o == ">=" then
                valid = x >= y
            elseif o == "==" then
                valid = x == y
            elseif o == "~=" then
                valid = x ~= y
            elseif o == "<" then
                valid = x < y
            elseif o == ">" then
                valid = x > y
            end
            if valid then
                v1:accept(x)
                v2:accept(y)
            else
                v1:reject "compare"
                v2:reject "compare"
            end
        end
    end
end
function group:requisite(r)
    local c = #r
    self[#self+1] = function(fields)
        local n = c
        local valid = true
        for i = 1, c do
            local f = r[i]
            if not fields[f] then
                fields[f] = field.new(f)
            end
            local field = fields[f]
            if field.valid then
                local v = field.value
                if v == nil or v == "" then
                    n = n - 1
                end
            end
        end
        if n > 0 then
            for i = 1, c do
                local f = fields[r[i]]
                if f.valid then
                    f:accept(f.value)
                end
            end
        else
            for i = 1, c do
                local f = fields[r[i]]
                f:reject "requisite"
            end
        end
    end
end
function group:requisites(r, n)
    local c = #r
    local n = n or c
    self[#self+1] = function(fields)
        local j = c
        local valid = true
        for i = 1, c do
            local f = r[i]
            if not fields[f] then
                fields[f] = field.new(f)
            end
            local field = fields[f]
            if field.valid then
                local v = field.value
                if v == nil or v == "" then
                    j = j - 1
                end
            end
        end
        if n <= j then
            for i = 1, c do
                local f = fields[r[i]]
                if f.valid then
                    f:accept(f.value)
                end
            end
        else
            for i = 1, c do
                local f = fields[r[i]]
                f:reject "requisites"
            end
        end
    end
end
function group:call(func)
    self[#self+1] = func
end
function group:__call(data)
    local results = setmetatable({}, fields)
    local validators = self.validators
    for name, func in pairs(validators) do
        local input = data[name]
        local valid, value = func(input)
        local fld = field.new(name, input)
        if valid then
            fld:accept(value)
        else
            fld:reject(value)
        end
        results[name] = fld
    end
    for name, input in pairs(data) do
        if not results[name] then
            results[name] = field.new(name, input)
        end
    end
    for _, v in ipairs(self) do
        v(results)
    end
    local errors
    for name, field in pairs(results) do
        if field.invalid then
            if not errors then
                errors = {}
            end
            errors[name] = field.error or "unknown"
        end
    end
    return errors == nil, results, errors
end
local function new(validators)
    return setmetatable({ validators = validators }, group)
end
local function check(validator, value, valid, v)
    if not valid then
        error(validator, 0)
    elseif getmetatable(valid) == stopped then
        error(valid, 0)
    elseif v == stop then
        error(stop(value), 0)
    elseif getmetatable(v) == stopped then
        error(v, 0)
    elseif v == nothing then
        v = nil
    elseif v == nil then
        v = value
    end
    if valid == stop then
        error(stop(v), 0)
    end
    return true, v
end
local function validation(func, parent_f, parent, method)
    return setmetatable({ new = new, group = group, fields = setmetatable({}, fields), nothing = nothing, stop = stop, validators = validators, _VERSION = _VERSION }, {
        __index = function(self, index)
            return validation(function(...)
                local valid, value = check(index, select(1, ...), func(...))
                local validator = rawget(validators, index)
                if not validator then
                    error(index, 0)
                end
                return check(index, value, validator(value))
            end, func, self, index)
        end,
        __call = function(_, self, ...)
            if parent ~= nil and self == parent then
                local n = select("#", ...)
                local args = { ... }
                return validation(function(...)
                    local valid, value = check(method, select(1, ...), parent_f(...))
                    if sub(method, 1, 2) == "if" then
                        local validator = rawget(getmetatable(validators), sub(method, 3))
                        if not validator then error(method, 0) end
                        local v
                        if n > 2 then
                            valid, v = validator(unpack(args, 1, n - 2))(value)
                        else
                            valid, v = validator()(value)
                        end
                        return check(method, value, true, valid and args[n - 1] or args[n])
                    end
                    local validator = rawget(getmetatable(validators), method)
                    if not validator then error(method, 0) end
                    return check(method, value, validator(unpack(args, 1, n))(value))
                end)
            end
            local ok, error, value = pcall(func, self, ...)
            if ok then
                return true, value
            elseif getmetatable(error) == stopped then
                return true, error.value
            end
            return false, error
        end
    })
end
return validation(function(...)
    return true, ...
end)
