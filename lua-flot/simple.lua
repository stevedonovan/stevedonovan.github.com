-- simple.lua
local flot = require 'flot'

local p = flot.Plot { -- legend at 'south east' corner
}

p:add_series("test",{{0,1},{1,1.4},{2,2.5}})

flot.render(p)
