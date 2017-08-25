# lua-resty-validation

**lua-resty-validation** is an extendable chaining validation and filtering library for Lua and OpenResty.

## Hello World with lua-resty-validation

```lua
local validation = require "resty.validation"

local valid, e = validation.number:between(0, 9)(5)  -- valid = true,  e = 5
local valid, e = validation.number:between(0, 9)(50) -- valid = false, e = "between"

-- Validators can be reused
local smallnumber = validation.number:between(0, 9)
local valid, e = smallnumber(5)  -- valid = true,  e = 5
local valid, e = smallnumber(50) -- valid = false, e = "between"

-- Validators can do filtering (i.e. modify the value being validated)
-- valid = true, s = "HELLO WORLD!"
local valid, s = validation.string.upper "hello world!"

-- You may extend the validation library with your own validators and filters...
validation.validators.capitalize = function(value) 
    return true, value:gsub("^%l", string.upper)
end

-- ... and then use it
local valid, e = validation.capitalize "abc" -- valid = true,  e = "Abc"

-- You can also group validate many values
local group = validation.new{
    artist = validation.string:minlen(5),
    number = validation.tonumber:equal(10)
}

local valid, fields, errors = group{ artist = "Eddie Vedder", number = "10" }

if valid then
  print("all the group fields are valid")
else
  print(fields.artist.name,      fields.artist.error,
        fields.artist.valid,     fields.artist.invalid,
        fields.artist.input,     fields.artist.value, ,
        fields.artist.validated, fields.artist.unvalidated)
end

-- You can even call fields to get simple name, value table
-- (in that case all the `nil`s are removed as well)

-- By default this returns only the valid fields' names and values:
local data = fields()
local data = fields "valid"

-- To get only the invalid fields' names and values call:
local data = fields "invalid"

-- To get only the validated fields' names and values call (whether or not they are valid):
local data = fields "validated"

-- To get only the unvalidated fields' names and values call (whether or not they are valid):
local data = fields "unvalidated"

-- To get all, call:
local data = fields "all"

-- Or combine:
local data = fields("valid", "invalid")

-- This doesn't stop here. You may also want to get only some fields by their name.
-- You can do that by calling (returns a table):
local data = data{ "artist" }
```

## Installation

Just place [`validation.lua`](https://github.com/bungle/lua-resty-validation/blob/master/lib/resty/validation.lua) and [`validation`](https://github.com/bungle/lua-resty-template/tree/master/lib/resty/validation) directory somewhere in your `package.path`, under `resty` directory. If you are using OpenResty, the default location would be `/usr/local/openresty/lualib/resty`.

### Using OpenResty Package Manager (opm)

```Shell
$ opm get bungle/lua-resty-validation
```

### Using LuaRocks

```Shell
$ luarocks install lua-resty-validation
```

LuaRocks repository for `lua-resty-validation` is located at https://luarocks.org/modules/bungle/lua-resty-validation.

## Built-in Validators and Filters

`lua-resty-validation` comes with several built-in validators, and the project is open for contributions of more validators.

### Validators and Filters without Arguments

Type validators can be used to validate the type of the validated value. These validators are argument-less
validators (call them with dot `.`):

* `null` or `["nil"]` (as the nil is a reserved keyword in Lua)
* `boolean`
* `number`
* `string`
* `table`
* `userdata`
* `func` or `["function"]` (as the function is a reserved keyword in Lua)
* `callable` (either a function or a table with metamethod `__call`)
* `thread`
* `integer`
* `float`
* `file` (`io.type(value) == 'file'`)

Type conversion filters:

* `tostring`
* `tonumber`
* `tointeger`
* `toboolean`

Other filters:

* `tonil` or `tonull`
* `abs`
* `inf`
* `nan`
* `finite`
* `positive`
* `negative`
* `lower`
* `upper`
* `trim`
* `ltrim`
* `rtrim`
* `reverse`
* `email`
* `optional`

#### Example

```lua
local validation = require "resty.validation"
local ok, e = validation.null(nil)
local ok, e = validation.boolean(true)
local ok, e = validation.number(5.2)
local ok, e = validation.string('Hello, World!')
local ok, e = validation.integer(10)
local ok, e = validation.float(math.pi)
local f = assert(io.open('filename.txt', "r"))
local ok, e = validation.file(f)
```

### Validation Factory Validators and Filters

Validation factory consist of different validators and filters used to validate or filter the value
(call them with colon `:`):

* `type(t)`, validates that the value is of type `t` (see Type Validators)
* `nil()` or `["null"]()`, check that value type is `nil`
* `boolean()`, check that value type is `boolean`
* `number()`, check that value type is `number`
* `string()`, check that value type is `string`
* `table()`, check that value type is `table`
* `userdata()`, check that value type is `userdata`
* `func()` or `["function"]()`, check that value type is `function`
* `callable()`, check that value is callable (aka a function or a table with metamethod `__call`)
* `thread()`, check that value type is `thread`
* `integer()`, check that value type is `integer`
* `float()`, check that value type is `float`
* `file()`, check that value type is `file` (`io.type(value) == 'file'`)
* `abs()`, filters value and returns absolute value (`math.abs`)
* `inf()`, checks that the value is `inf` or `-inf`
* `nan()`, checks that the value is `nan`
* `finite()`, checks that the value is not `nan`, `inf` or `-inf`
* `positive()`, validates that the value is positive (`> 0`)
* `negative()`, validates that the value is negative (`< 0`)
* `min(min)`, validates that the value is at least `min` (`>=`)
* `max(max)`, validates that the value is at most `max` (`<=`)
* `between(min[, max = min])`, validates that the value is between `min` and `max`
* `outside(min[, max = min])`, validates that the value is not between `min` and `max`
* `divisible(number)`, validates that the value is divisible with `number`
* `indivisible(number)`, validates that the value is not divisible with `number`
* `len(min[, max = min])`, validates that the length of the value is exactly `min` or between `min` and `max`  (UTF-8)
* `minlen(min)`, validates that the length of the value is at least `min` (UTF-8)
* `maxlen(max)`, validates that the length of the value is at most `max`  (UTF-8)
* `equals(equal)` or `equal(equal)`, validates that the value is exactly something
* `unequals(equal)` or `unequal(equal)`, validates that the value is not exactly something
* `oneof(...)`, validates that the value is equal to one of the supplied arguments
* `noneof(...)`, validates that the value is not equal to any of the supplied arguments
* `match(pattern[, init])`, validates that the value matches (`string.match`) the pattern
* `unmatch(pattern[, init])`, validates that the value does not match (`string.match`) the pattern
* `tostring()`, converts value to string
* `tonumber([base])`, converts value to number
* `tointeger()`, converts value to integer
* `toboolean()`, converts value to boolean (using `not not value`)
* `tonil()` or `tonull()`, converts value to nil
* `lower()`, converts value to lower case (UTF-8 support is not yet implemented)
* `upper()`, converts value to upper case (UTF-8 support is not yet implemented)
* `trim([pattern])`, trims whitespace (you may use pattern as well) from the left and the right
* `ltrim([pattern])`, trims whitespace (you may use pattern as well) from the left
* `rtrim([pattern])`, trims whitespace (you may use pattern as well) from the right
* `starts(starts)`, checks if string starts with `starts`
* `ends(ends)`, checks if string ends with `ends`
* `reverse`, reverses the value (string or number) (UTF-8)
* `coalesce(...)`, if the value is nil, returns first non-nil value passed as arguments
* `email()`, validates that the value is email address
* `call(function)`, validates / filters the value against custom inline validator / filter
* `optional([default])`, stops validation if the value is empty string `""` or `nil` and returns `true`, and either, `default` or `value`

#### Conditional Validation Factory Validators

For all the Validation Factory Validators there is a conditional version that always validates to true,
but where you can replace the actual value depending whether the original validator validated. Hey, this
is easier to show than say:

```lua
local validation = require "resty.validation"

-- ok == true, value == "Yes, the value is nil"
local ok, value = validation:ifnil(
    "Yes, the value is nil",
    "No, you did not supply a nil value")(nil)

-- ok == true, value == "No, you did not supply a nil value"
local ok, value = validation:ifnil(
    "Yes, the value is nil",
    "No, you did not supply a nil value")("non nil")
    
-- ok == true, value == "Yes, the number is betweeb 1 and 10"    
local ok, value = validation:ifbetween(1, 10,
    "Yes, the number is between 1 and 10",
    "No, the number is not between 1 and 10")(5)

-- ok == true, value == "No, the number is not between 1 and 10"
local ok, value = validation:ifbetween(1, 10,
    "Yes, the number is between 1 and 10",
    "No, the number is not between 1 and 10")(100)
```

The last 2 arguments to conditional validation factory validators are the `truthy` and `falsy` values.
Every other argument is passed to the actual validation factory validator.

### Group Validators

`lua-resty-validation` currently supports a few predefined validators:

* `compare(comparison)`, compares two fields and sets fields invalid or valid according to comparison
* `requisite{ fields }`, at least of of the requisite fields is required, even if they by themselves are optional
* `requisites({ fields }, number)`, at least `number` of requisites fields are required (by default all of them)
* `call(function)`, calls a custom (or inline) group validation function

```lua
local ispassword = validation.trim:minlen(8)
local group = validation.new{
    password1 = ispassword,
    password2 = ispassword
}
group:compare "password1 == password2"
local valid, fields, errors = group{ password1 = "qwerty123", password2 = "qwerty123" }

local optional = validation:optional"".trim
local group = validation.new{
    text = optional,
    html = optional
}
group:requisite{ "text", "html" }
local valid, fields, errors = group{ text = "", html = "" }


local optional = validation:optional ""
local group = validation.new{
    text = optional,
    html = optional
}
group:requisites({ "text", "html" }, 2)
-- or group:requisites{ "text", "html" }
local valid, fields, errors = group{ text = "", html = "" }


group:call(function(fields)
    if fields.text.value == "hello" then
        fields.text:reject "text cannot be 'hello'"
        fields.html:reject "because text was 'hello', this field is also invalidated"
    end
end)
```

You can use normal Lua relational operators in `compare` group validator:

* `<`
* `>`
* `<=`
* `>=`
* `==`
* `~=`

`requisite` and `requisites` check if the field value is `nil` or `""`(empty string).
With `requisite`, if all the specified fields are `nil` or `""` then all the fields are
invalid (provided they were not by themselves invalid), and if at least one of the fields
is valid then all the fields are valid. `requisites` works the same, but there you can
define the number of how many fields you want to have a value that is not `nil` and not
an empty string `""`. These provide conditional validation in sense of:

1. I have (two or more) fields
2. All of them are optional
3. At least one / defined number of fields should be filled but I don't care which one as long as there is at least one / defined number of fields filled

### Stop Validators

Stop validators, like `optional`, are just like a normal validators, but instead of returning
`true` or `false` as a validation result OR as a filtered value, you can return `validation.stop`.
This value can also be used inside conditional validators and in validators that support default values. Here is how
the `optional` validator is implemented:

```lua
function factory.optional(default)
    return function(value)
        if value == nil or value == "" then
            return validation.stop, default ~= nil and default or value
        end
        return true, value
    end
end
```

These are roughly equivalent:

```lua
-- Both return: true, "default" (they stop prosessing :minlen(10) on nil and "" inputs
local input = ""
local ok, val = validation.optional:minlen(10)(input)
local ok, val = validation:optional(input):minlen(10)(input)
local ok, val = validation:ifoneof("", nil, validation.stop(input), input):minlen(10)(input)
```

### Filtering Value and Setting the Value to `nil`

Most of the validators, that are not filtering the value, only return `true` or `false` as a result.
That means that there is now no way to signal `resty.validation` to actually set the value to `nil`.
So there is a work-around, you can return `validation.nothing` as a value, and that will change the
value to `nil`, e.g. the built-in `tonil` validator is actually implemented like this (pseudo):

```lua
function()
    return true, validation.nothing
end
```

### Custom (Inline) Validators and Filters

Sometimes you may just have one-off validators / filters that you are not using elsewhere, or that you just
want to supply quickly an additional validator / filter for a specific case. To make that easy and straight
forward, we introduced `call` factory method with `lua-resty-validation` 2.4. Here is an example:

```lua
validation:call(function(value)
    -- now validate / filter the value, and return the results
    -- here we just return false (aka making validation to fail) 
    return false
end)("Check this value"))
```

(of course it doesn't need to be inline function as in Lua all functions are first class citizens and they can 
be passed around as parameters)

### Built-in Validator Extensions

Currently `lua-resty-validation` has support for two extensions or plugins that you can enable:

* `resty.validation.ngx`
* `resty.validation.tz`
* `resty.validation.utf8`

These are something you can look at if you want to build your own validator extension. If you do
so, and think that it would be usable for others as well, mind you to send your extension as a pull-request
for inclusion in this project, thank you very much, ;-).

#### resty.validation.ngx extension

As the name tells, this set of validator extensions requires OpenResty (or Lua Nginx module at least).
To use this extension all you need to do is:

```lua
require "resty.validation.ngx"
```

It will monkey patch the adapters that it will provide in `resty.validation`, and those are currently:

* `escapeuri`
* `unescapeuri`
* `base64enc`
* `base64dec`
* `crc32short`
* `crc32long`
* `crc32`
* `md5`

(there is both factory and argument-less version of these)

There is also regex matcher in ngx extension that uses `ngx.re.match`, and parameterized `md5`:

* `regex(regex[, options])`
* `md5([bin])`

##### Example

```lua
require "resty.validation.ngx"
local validation = require "resty.validation"
local valid, value = validation.unescapeuri.crc32("https://github.com/")
local valid, value = validation:unescapeuri():crc32()("https://github.com/")
```

#### resty.validation.tz extension

This set of validators and filters is based on the great [`luatz`](https://github.com/daurnimator/luatz)
library by [@daurnimator](https://github.com/daurnimator), that is a library for time and date manipulation. To use this extension, all you need
to do is:

```lua
require "resty.validation.tz"
```

It will monkey patch the adapters that it will provide in `resty.validation`, and those are currently:

* `totimetable`
* `totimestamp`

(there is both factory and argument-less version of these)

`totimestamp` and `totimetable` filters work great with HTML5 date and datetime input fields. As the name
tells, `totimetable` returns luatz `timetable` and `totimestamp` returns seconds since unix epoch (`1970-01-01`)
as a Lua number.

##### Example

```lua
require "resty.validation.tz"
local validation = require "resty.validation"
local valid, ts = validation.totimestamp("1990-12-31T23:59:60Z")
local valid, ts = validation.totimestamp("1996-12-19")
```

#### resty.validation.utf8 extension

This set of validators and filters is based on the great [`utf8rewind`](https://bitbucket.org/knight666/utf8rewind)
library by Quinten Lansu - a system library written in C designed to extend the default string handling functions
with support for UTF-8 encoded text. It needs my LuaJIT FFI wrapper [`lua-resty-utf8rewind`](https://github.com/bungle/lua-resty-utf8rewind)
to work. When the mentioned requirements are installed, the rest is easy. To use this extension, all you need
to do is:

```lua
require "resty.validation.utf8"
```

It will monkey patch the adapters that it will provide in `resty.validation`, and those are currently:

* `utf8upper`
* `utf8lower`
* `utf8title`

(there is both factory and argument-less version of these)

There is also a few factory validators / filters:

* `utf8normalize(form)`
* `utf8category(category)`

The `utf8normalize` normalizes the UTF-8 input to one of these normalization formats:

* `C` (or `NFC`)
* `D` (or `NFD`)
* `KC` (or `NFKC`)
* `KD` (or `NFKD`)

The `utf8category` checks that the input string is in one of the following categories (so, you may think it has
multiple validators built-in to work with UTF-8 string validation):

* `LETTER_UPPERCASE`
* `LETTER_LOWERCASE`
* `LETTER_TITLECASE`
* `LETTER_MODIFIER`
* `CASE_MAPPED`
* `LETTER_OTHER`
* `LETTER`
* `MARK_NON_SPACING`
* `MARK_SPACING`
* `MARK_ENCLOSING`
* `MARK`
* `NUMBER_DECIMAL`
* `NUMBER_LETTER`
* `NUMBER_OTHER`
* `NUMBER`
* `PUNCTUATION_CONNECTOR`
* `PUNCTUATION_DASH`
* `PUNCTUATION_OPEN`
* `PUNCTUATION_CLOSE`
* `PUNCTUATION_INITIAL`
* `PUNCTUATION_FINAL`
* `PUNCTUATION_OTHER`
* `PUNCTUATION`
* `SYMBOL_MATH`
* `SYMBOL_CURRENCY`
* `SYMBOL_MODIFIER`
* `SYMBOL_OTHER`
* `SYMBOL`
* `SEPARATOR_SPACE`
* `SEPARATOR_LINE`
* `SEPARATOR_PARAGRAPH`
* `SEPARATOR`
* `CONTROL`
* `FORMAT`
* `SURROGATE`
* `PRIVATE_USE`
* `UNASSIGNED`
* `COMPATIBILITY`
* `ISUPPER`
* `ISLOWER`
* `ISALPHA`
* `ISDIGIT`
* `ISALNUM`
* `ISPUNCT`
* `ISGRAPH`
* `ISSPACE`
* `ISPRINT`
* `ISCNTRL`
* `ISXDIGIT`
* `ISBLANK`
* `IGNORE_GRAPHEME_CLUSTER`

##### Example

```lua
require "resty.validation.utf8"
local validation = require "resty.validation"
local valid, ts = validation:utf8category("LETTER_UPPERCASE")("TEST")
```

#### resty.validation.injection extension

This set of validators and filters is based on the great [`libinjection`](https://github.com/client9/libinjection)
library by Nick Galbreath - a SQL / SQLI / XSS tokenizer parser analyzer. It needs my LuaJIT FFI wrapper
[`lua-resty-injection`](https://github.com/bungle/lua-resty-injection) to work. When the mentioned requirements
are installed, the rest is easy. To use this extension, all you need to do is:

```lua
require "resty.validation.injection"
```

It will monkey patch the adapters that it will provide in `resty.validation`, and those are currently:

* `sqli`, returns `false` if SQL injection was detected, otherwise returns `true`
* `xss`, returns `false` if Cross-Site Scripting injection was detected, otherwise returns `true`

##### Example

```lua
require "resty.validation.injection"
local validation = require "resty.validation"
local valid, ts = validation.sqli("test'; DELETE FROM users;")
local valid, ts = validation.xss("test <script>alert('XSS');</script>")
```

## API

I'm not going here for details for all the different validators and filters there is because they all follow the
same logic, but I will show some general ways how this works.

### validation._VERSION

This field contains a version of the validation library, e.g. it's value can be `"2.5"` for
the version 2.5 of this library.

### boolean, value/error validation...

That `...` means the validation chain. This is used to define a single validator chain. There is no limit to
chain length. It will always return boolean (if the validation is valid or not). The second return value will
be either the name of the filter that didn't return `true` as a validation result, or the filtered value.

```lua
local v = require "resty.validation"

-- The below means, create validator that checks that the input is:
-- 1. string
-- If, it is, then trim whitespaces from begin and end of the string:
-- 2. trim
-- Then check that the trimmed string's length is at least 5 characters (UTF-8):
-- 3. minlen(5)
-- And if everything is still okay, convert that string to upper case
-- (UTF-8 is not yet supported in upper):
-- 4. upper
local myvalidator = v.string.trim:minlen(5).upper

-- This example will return false and "minlen"
local valid, value = myvalidator(" \n\t a \t\n ")

-- This example will return true and "ABCDE"
local valid, value = myvalidator(" \n\t abcde \t\n ")
```

Whenever the validator fails and returns `false`, you should not use the returned value for other purposes than
error reporting. So, the chain works like that. The `lua-resty-validation` will not try to do anything if you
specify chains that will never get used, such as:

```lua
local v = require "resty.validation"
-- The input value can never be both string and number at the same time:
local myvalidator = v.string.number:max(3)
-- But you could write this like this
-- (take input as a string, try to convert it to number, and check it is at most 3):
local myvalidator = v.string.tonumber:max(3)
```

As you see, this is a way to define single reusable validators. You can for example predefine your set of basic
single validator chains and store it in your own module from which you can reuse the same validation logic in
different parts of your application. It is good idea to start defining single reusable validators, and then reuse
them in group validators.

E.g. say you have module called `validators`:

```lua
local v = require "resty.validation"
return {
    nick     = v.string.trim:minlen(2),
    email    = v.string.trim.email,
    password = v.string.trim:minlen(8)
}
```

And now you have `register` function somewhere in your application:

```lua
local validate = require "validators"
local function register(nick, email, password)
    local vn, nick     = validate.nick(nick)
    local ve, email    = validate.email(email)
    local vp, password = validate.password(password)
    if vn and ve and vp then
        -- input is valid, do something with nick, email, and password
    else
        -- input is invalid, nick, email, and password contain the error reasons
    end
end
```

This quickly gets a little bit dirty, and that's why we have Group validators.

### table validation.new([table of validators])

This function is where the group validation kicks in. Say that you have a registration
form that asks you nick, email (same twice), and password (same twice).

We will reuse the single validators, defined in `validators` module:

```lua
local v = require "resty.validation"
return {
    nick     = v.string.trim:minlen(2),
    email    = v.string.trim.email,
    password = v.string.trim:minlen(8)
}
```

Now, lets create the reusable group validator in `forms` module:

```lua
local v        = require "resty.validation"
local validate = require "validators"

-- First we create single validators for each form field
local register = v.new{
    nick      = validate.nick,
    email     = validate.email,
    email2    = validate.email,
    password  = validate.password,
    password2 = validate.password
}

-- Next we create group validators for email and password:
register:compare "email    == email2"
register:compare "password == password2"

-- And finally we return from this forms module

return {
    register = register
}

```

Now, somewhere in your application you have this `register` function:


```lua
local forms = require "forms"
local function register(data)
    local valid, fields, errors = forms.register(data)
    if valid then
        -- input is valid, do something with fields
    else
        -- input is invalid, do something with fields and errors
    end
end

-- And you might call it like:

register{
    nick      = "test",
    email     = "test@test.org",
    email2    = "test@test.org",
    password  = "qwerty123",
    password2 = "qwerty123"
}

```

The great thing about group validators is that you can JSON encode the fields and errors
table and return it to client. This might come handy when building a single page application
and you need to report server side errors on client. In the above example, the `fields`
variable will look like this (`valid` would be true:, and `errors` would be `nil`):

```lua
{
    nick = {
        unvalidated = false,
        value = "test",
        input = "test",
        name = "nick",
        valid = true,
        invalid = false,
        validated = true
    },
    email = {
        unvalidated = false,
        value = "test@test.org",
        input = "test@test.org",
        name = "email",
        valid = true,
        invalid = false,
        validated = true
    },
    email2 = {
        unvalidated = false,
        value = "test@test.org",
        input = "test@test.org",
        name = "email2",
        valid = true,
        invalid = false,
        validated = true
    },
    password = {
        unvalidated = false,
        value = "qwerty123",
        input = "qwerty123",
        name = "password",
        valid = true,
        invalid = false,
        validated = true
    },
    password2 = {
        unvalidated = false,
        value = "qwerty123",
        input = "qwerty123",
        name = "password2",
        valid = true,
        invalid = false,
        validated = true
    }
}
```

This is great for further processing and sending the fields as JSON encoded back
to the client-side Javascript application, but usually this is too heavy construct
to be send to the backend layer. To get a simple key value table, we can call this
fields table:

```lua
local data = fields()
```

The `data` variable will now contain:

```lua
{
    nick = "test",
    email = "test@test.org",
    email2 = "test@test.org",
    password = "qwerty123",
    password2 = "qwerty123"
}
```

Now this is something you can send for example in Redis or whatever database (abstraction) layer
you have. But, well, this doesn't stop here, if say your database layer is only interested in
`nick`, `email` and `password` (e.g. strip those duplicates), you can even call the `data` table:

```lua
local realdata = data("nick", "email", "password")
```

The `realdata` will now contain:

```lua
{
    nick = "test",
    email = "test@test.org",
    password = "qwerty123"
}
```

### field:accept(value)

For field you can call `accept` that does this:

```lua
self.error = nil
self.value = value
self.valid = true
self.invalid = false
self.validated = true
self.unvalidated = false
```

### field:reject(error)

For field you can call `reject` that does this:

```lua
self.error = error
self.valid = false
self.invalid = true
self.validated = true
self.unvalidated = false
```

### string field:state(invalid, valid, unvalidated)

Calling `state` on field is great when embedding validation results inside say HTML template, such as `lua-resty-template`. Here is an example using `lua-resty-template`:

```html
<form method="post">
    <input class="{{ form.email:state('invalid', 'valid') }}"
            name="email"
            type="text"
            placeholder="Email"
            value="{{ form.email.input }}">
    <button type="submit">Join</button>
</form>
```

So depending on email field's state this will add a class to input element (e.g. making input's border red or green for example). We don't care about unvalidated (e.g. when the user first loaded the page and form) state here.

## Changes

The changes of every release of this module is recorded in [Changes.md](https://github.com/bungle/lua-resty-validation/blob/master/Changes.md) file.

## See Also

* [lua-resty-route](https://github.com/bungle/lua-resty-route) — Routing library
* [lua-resty-reqargs](https://github.com/bungle/lua-resty-reqargs) — Request arguments parser
* [lua-resty-session](https://github.com/bungle/lua-resty-session) — Session library
* [lua-resty-template](https://github.com/bungle/lua-resty-template) — Templating Engine

## License

`lua-resty-validation` uses two clause BSD license.

```
Copyright (c) 2014 - 2017, Aapo Talvensaari
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
  list of conditions and the following disclaimer in the documentation and/or
  other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES`
