# lua-resty-validation

**lua-resty-validation** is an extendable chaining validation and filtering library for Lua and OpenResty.

## Hello World with lua-resty-validation

```lua
local validation = require "resty.validation"

local valid, e = validation.number.between(0, 9)(5)  -- valid = true,  e = 5
local valid, e = validation.number.between(0, 9)(50) -- valid = false, e = "between"

-- Validators can be reused
local smallnumber = validation.number.between(0, 9)
local valid, e = smallnumber(5)  -- valid = true,  e = 5
local valid, e = smallnumber(50) -- valid = false, e = "between"

-- Validators can do filtering (i.e. modify the value being validated)
-- valid = true, s = "HELLO WORLD!"
local valid, s = validation.string.upper()("hello world!")

-- You may extend the validation library with your own validators and filters...
validation.validators.factory.reverse = function() 
  return function(value)
    if type(value) == "string" then
      return true, string.reverse(value)
    end
    return false
  end
end

-- ... and then use it
local valid, e = validation.reverse()("ABC") -- valid = true,  e = "CBA"
local valid, e = validation.reverse()(5)     -- valid = false, e = "reverse"

-- You can also group validate many values
local form = validation.new{ artist = "Eddie Vedder", number = 10 }
form.artist:validate(validation.string.len{ min = 5 })
form.number:validate(validation.equal(10))

if form.valid then
  print("all the form fields are valid")
else
  print(form.artist.name,  form.artist.valid, form.artist.input,
        form.artist.value, form.artist.error, form.artist.invalid)
  print(form.number.name,  form.number.valid, form.number.input,
        form.number.value, form.number.error, form.number.invalid)
end
```

## Built-in Validators and Filters

`lua-resty-validation` comes with several built-in validators, and the project is open for contributions of more validators.

### Type Validators

Type validators can be used to validate the type of the validated value. These validators are parameter-less validators:

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

Validation factory consist of different validators and filters used to validate or filter the validated value:

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
* `equal(values)`, validates that the value is exactly something or one of the values
* `unequal(values)`, validates that the value is not exactly something or one of the values.
* `match(pattern[, init])`, validates that the value matches (`string.match`) the pattern
* `unmatch(pattern[, init])`, validates that the value does not match (`string.match`) the pattern
* `tostring()`, converts value to string
* `tonumber([base])`, converts value to number
* `tointeger()`, converts value to integer (works only with Lua >= 5.3, `math.tointeger'`)
* `lower()`, converts value to lower case
* `upper()`, converts value to upper case
* `trim()`, trims whitespace from the left and the right
* `ltrim()`, trims whitespace from the left
* `rtrim()`, trims whitespace from the right

#### Examples

```lua
local validation = require "resty.validation"
local ok, e = validation.string.trim().len(8)("my value")
local ok, e = validation.string.trim().len{ max = 8 }("my value")
local ok, e = validation.number.between(1, 100).outside(40, 50)(90)
local ok, e = validation.equal(10)(10)
local ok, e = validation.equal{ 10, 20, 30, 40, 50 }(30)
```

## License

`lua-resty-validation` uses two clause BSD license.

```
Copyright (c) 2014, Aapo Talvensaari
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
