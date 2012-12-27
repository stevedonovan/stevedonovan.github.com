-- basic-flot.lua
local flot = require 'flot'

local sin, cos = {},{}
for i = 1,100 do
   local x = i/10
   sin[i] = {x,math.sin(x)}
   cos[i] = {x,math.cos(x)}
end

local p = flot.Plot { -- legend at 'south east' corner
   legend = { position = "se" },
}
p:add_series("sin",sin)
p:add_series("cos",cos, {color="#000"} )

flot.render(p)
