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
local form = validation.new()
form.artist = validation.string:minlen(5)
form.number = validation:equal(10)

local valid, fields, errors = form{ artist = "Eddie Vedder", number = 10 }

if valid then
  print("all the form fields are valid")
else
  print(fields.artist.name,  fields.artist.valid, fields.artist.input,
        fields.artist.value, fields.artist.error, fields.artist.invalid)
  print(fields.number.name,  fields.number.valid, fields.number.input,
        fields.number.value, fields.number.error, fields.number.invalid)
end
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

* `nil` or `null` (as the nil is a reserved keyword in Lua)
* `boolean`
* `number`
* `string`
* `userdata`
* `function` or `func` (as the function is a reserved keyword in Lua)
* `thread`
* `integer` (works only with Lua >= 5.3, `math.type(nbr) == 'integer'`)
* `float` (works only with Lua >= 5.3,   `math.type(nbr) == 'float'`)
* `file` (`io.type(value) == 'file'`)

Type conversion filters:

* `tostring`
* `tonumber`
* `tointeger`
* `toboolean`

Other filters:

* `lower`
* `upper`
* `trim`
* `ltrim`
* `rtrim`
* `reverse`

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
* `min(min)`, validates that the value is at least `min` (`>=`)
* `max(max)`, validates that the value is at most `max` (`<=`)
* `between(min[, max = min])`, validates that the value is between `min` and `max`
* `outside(min[, max = min])`, validates that the value is not between `min` and `max`
* `divisible(number)`, validates that the value is divisible with `number`
* `indivisible(number)`, validates that the value is not divisible with `number`
* `len(min[, max = min])`, validates that the length (`#` or `string.len` or `utf8.len` (if available)) of the value is exactly `min`, at least `min`, at most `max` or between `min` and `max`
* `minlen(min)`, validates that the length of the value is at least `min`
* `maxlen(min)`, validates that the length of the value is at most `max`
 most `max` or between `min` and `max`
* `equals(values)` or `equal(values)`, validates that the value is exactly something or one of the values
* `unequals(values)` or `unequal(values)`, validates that the value is not exactly something or one of the values.
* `match(pattern[, init])`, validates that the value matches (`string.match`) the pattern
* `unmatch(pattern[, init])`, validates that the value does not match (`string.match`) the pattern
* `tostring()`, converts value to string
* `tonumber([base])`, converts value to number
* `tointeger()`, converts value to integer (works only with Lua >= 5.3, `math.tointeger`)
* `toboolean()`, converts value to boolean (using `not not value`)
* `lower()`, converts value to lower case
* `upper()`, converts value to upper case
* `trim([pattern])`, trims whitespace (you may use pattern as well) from the left and the right
* `ltrim([pattern])`, trims whitespace (you may use pattern as well) from the left
* `rtrim([pattern])`, trims whitespace (you may use pattern as well) from the right
* `reverse`, reverses the value (string or number)

#### Examples

```lua
local validation = require "resty.validation"
local ok, e = validation.string.trim:len(8)("my value")
local ok, e = validation.string.trim:len{ max = 8 }("my value")
local ok, e = validation.number:between(1, 100):outside(40, 50)(90)
local ok, e = validation:equal(10)(10)
local ok, e = validation:equal{ 10, 20, 30, 40, 50 }(30)
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
