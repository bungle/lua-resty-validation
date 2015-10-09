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
local valid, s = validation.string.upper("hello world!")

-- You may extend the validation library with your own validators and filters...
validation.validators.capitalize = function(value) 
    return true, value:gsub("^%l", string.upper)
end

-- ... and then use it
local valid, e = validation.capitalize("abc") -- valid = true,  e = "Abc"

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
local data = fields("valid")

-- To get only the invalid fields' names and values call:
local data = fields("invalid")

-- To get only the validated fields' names and values call (whether or not they are valid):
local data = fields("validated")

-- To get only the unvalidated fields' names and values call (whether or not they are valid):
local data = fields("unvalidated")

-- To get all, call:
local data = fields("all")

-- Or combine:
local data = fields("valid", "invalid")

-- This doesn't stop here. You may also want to get only some fields by their name.
-- You can do that by calling (returns a table):
local data = data{ "artist" }
```

## Installation

Just place [`validation.lua`](https://github.com/bungle/lua-resty-validation/blob/master/lib/resty/validation.lua)
somewhere in your `package.path`, preferably under `resty` directory. If you are using OpenResty, the default
location would be `/usr/local/openresty/lualib/resty`.

### Using LuaRocks or MoonRocks

If you are using LuaRocks >= 2.2:

```Shell
$ luarocks install lua-resty-validation
```

If you are using LuaRocks < 2.2:

```Shell
$ luarocks install --server=http://rocks.moonscript.org moonrocks
$ moonrocks install lua-resty-validation
```

MoonRocks repository for `lua-resty-validation`  is located here: https://rocks.moonscript.org/modules/bungle/lua-resty-validation.

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

`lua-resty-validation` currently supports one predefined validator, and that is:

* `compare(comparison)`, compares two fields and sets fields invalid or valid according to comparison:

```lua
local ispassword = validation.trim:minlen(8)
local group = validation.new{
    password1 = ispassword,
    password2 = ispassword
}
group:compare "password1 == password2"
local valid, fields, errors = group{ password1 = "qwerty123", password2 = "qwerty123" }
```

You can use normal Lua relational operators in `compare` group validator:

* `<`
* `>`
* `<=`
* `>=`
* `==`
* `~=`

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
local ok, val = validation:optional("default"):minlen(10)(nil)
local ok, val = validation:ifoneof("", nil, validation.stop("default"), nil):minlen(10)(nil)
```

## License

`lua-resty-validation` uses two clause BSD license.

```
Copyright (c) 2015, Aapo Talvensaari
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
