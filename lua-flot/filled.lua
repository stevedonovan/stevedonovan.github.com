-- filled.lua
local flot = require 'flot'

local xx = flot.range(0,3*math.pi,0.1)
local cos = {}
for i,x in ipairs(xx) do
   cos[i] = math.cos(x)
end

local bot = -1.5
local p = flot.Plot {
   legend = { position = "se" }, -- 'south east'
   yaxis = { min = bot }, -- force mininum value
   xvalues = xx, -- provides x for any array of y values
   width = 300, height = 300, -- size of plot in px
}

p:add_series("cos",cos,
   { color = "#000", shadowSize = 0} -- override colour, switch off shadow
)

-- filled line with breaks down to x axis
p:add_series("misc",
   -- a series may consist of multiple segments separated by null
   {{1,-1,bot},{2,0,bot},flot.null,{5,0.5,bot},{6,0.5,bot}},
   {lines={fill=0.3}} -- set opacity for fill
)

flot.render(p)

