# Express.js-like HTTP server library for NodeMCU

## About
I wrote this JSON parser because the ESP8266 has very tight memory constraints.  
A normal JSON parser requires you to load the JSON string into a variable and then craetes a gigantic table that contains all the information form the string. This is INCREDIBLY memory intensise.  
But I came up with the ingenious idea of parsing a JSON string of almost arbitrary size by reading it from directly form a storage device (not RAM).
It only stores one single character of the JSON string at a time in the RAM and immediately discards it if it is irrelevant. 
So now you can easily parse and access a JSON string that it 100 times bigger than your RAM wihtout any issues.

## The interface
Using some metatable magic I created an interface that allows to access/parse a json string at a specified place, by almost accessing it like a table.  
While you would access a table like this for instance: `foo['bar'][123]['name']`, you have to do `foo['bar'][123]['name']()` instead.
If the value you are trying to access is an array/object then it will return a table that only contains the keys/indexes of the direct children.  
This is enough to start iteration over it.

## Use cases
I mainly developed this libary to be used by HTTP server libraries. The idea is that a json request body can be received in chunks and be written into a file.  
This way  you never have to store the json request body in your memory, but jsut on the flash.  
Then this library can read the string from the file one byte at a time and parse it this way.

## Examples
``` Lua
local example =  json('example.json') -- Specify which file you want to read the JSON string from

-- Read a value
local value = example["aa"][2]['k1']() -- Notice the brackets in the end!
print(value)

-- Loop over a key value table and print the keys and values
for key, value in pairs(example["aa"][2]()) do
    print('key: ' .. key, 'value: ' .. example["aa"][2][key]())
end
```

## Need help? Have a feature request? Found a bug?
Create an issue right here on github.