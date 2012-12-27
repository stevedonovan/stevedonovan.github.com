-----------
-- Generating Flot plots from Lua scripts

local flot = {}

flot.path = ''
-- can set it to absolute URL of directory containing flot subdir, or to a remote URI
--flot.path = 'file:///c:/users/steve/utils/web/'

local prefix = [[
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
 <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>Lua Flot</title>
    <!--[if lte IE 8]><script language="javascript" type="text/javascript" src="%sflot/excanvas.min.js"></script><![endif]-->
    <script language="javascript" type="text/javascript" src="%sflot/jquery.js"></script>
    <script language="javascript" type="text/javascript" src="%sflot/jquery.flot.js"></script>
 </head>
    <body>
]]

local div = [[
<div id="placeholder%d" style="width:%spx;height:%spx"></div>
<script type="text/javascript">
$(function () {
  %s
});
</script>
]]

local coda = [[
 </body>
</html>
]]

local script = [[
   $.plot($("#placeholder%d"),
   %s,
   %s);
]]


local concat,append = table.concat,table.insert
local as_js

flot.null = setmetatable({},{
   __tostring = function(self) return "null" end
})

-- you can of course use any available Lua JSON library here - this is good
-- enough for our purposes.
function as_js (t)
   local mt = getmetatable(t)
   if type(t) ~= 'table' or (mt and mt.__tostring) then
      return type(t) == 'string' and '"'..t..'"' or tostring(t)
   elseif #t > 0 then -- it's an array!
      local res = {}
      for i = 1,#t do
         res[i] = as_js(t[i])
      end
      return '['..concat(res,',')..']'
   else
      local res = {}
      for k,v in pairs(t) do
         append(res,k..':'..as_js(v))
      end
      return '{'..concat(res,',')..'}'
   end
end

local function interleave (xv,yv)
   local res = {}
   for i = 1,#xv do
      res[i] = {xv[i],yv[i]}
   end
   return res
end

function flot.range (x1,x2,incr)
   local res, i = {}, 1
   for x = x1,x2,incr do
      res[i] = x
      i = i + 1
   end
   return res
end

local kount = 0

function flot.Plot (opts)
   local plot = {}
   if _G.FLOT_PLACEHOLDER then
      plot.idx = _G.FLOT_PLACEHOLDER
   else
      kount = kount + 1
      plot.idx = kount
   end
   opts = opts or {}
   plot.width = opts.width or 600
   plot.height = opts.height or 400
   plot.xvalues = opts.xvalues
   opts.width = nil -- no harm, but they're not valid options.
   opts.height = nil
   opts.xvalues = nil
   local dataset, append = {}, table.insert

   function plot:add_series(label,data,kind)
      kind = kind or { lines = { show = true }}
      kind.label = label
      if data.x then
         data = interleave(data.x,data.y)
      elseif plot.xvalues and type(data[1]) ~= 'table' then
         data = interleave(plot.xvalues,data)
      end
      kind.data = data
      append(dataset,kind)
   end

   function plot:script ()
      return script:format(self.idx,as_js(dataset),as_js(opts))
   end

   return plot
end

function flot.render (plot)
   local p = flot.path
   local header = prefix:format(p,p,p)
   local div = div:format(plot.idx,plot.width,plot.height,plot:script())
   local name
   if arg then -- not interactive
      name = arg[0]:match('([%w_%-]+)%.lua')
   end
   -- hack for suppressing headers and forcing dump to stdout
   if _G.FLOT_PLACEHOLDER then name = nil end
   if name then
      local d = header .. div .. coda
      local f = io.open(name..'.html','w')
      f:write(d)
      f:close()
   else
      io.write(div)
   end
end

return flot

