##Getting an easy, good-looking plot of your data from Lua

The [Flot](http://www.flotcharts.org/) JavaScript library does very [nice](http://people.iola.dk/olau/flot/examples/) plots which render in modern browsers with Canvas support. 'Flot' means 'pretty' _or_ 'handsome' in Danish, and it definitely provides the cleanest most attractice results I've seen for browser-side plots.

Modern browsers are an attractive display option for a minimal language like Lua. `lua-flot` describes a straightforward little Lua library for generating HTML with embedded Flot plots.

I like to describe things that can be done with 'about 100 lines' of Lua. We can get this compactness because the job of this library is to generate some HTML boilerplate and set up a JavaScript call with object arguments. And the close similarities between Lua and JavaScript make this job mechanical and easy: converting a Lua table constructor to a JavaScript object literal is mostly a matter of making array-like tables use `[]` and hash-like tables use `:` instead of `=`.

    function as_js (t)
       local mt = getmetatable(t)
       if type(t) ~= 'table' or (mt and mt.__tostring) then
          if type(t) == 'string' then
            return '"'..t..'"'
          else
            return tostring(t)
          end
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

I will cheerfully admit that this is a partial solution, that doesn't yet handle some crucial differences, like the fact that JavaScript associative arrays can have `null` values.  And it's deliberately not meant to be a full JSON encoder (there are enough of those!)

Creating a custom `null` type is actually straightforward:

    flot.null = setmetatable({},{
       __tostring = function(self) return "null" end
    })

That is, it's a unique table which always renders as 'null'.

The idea is to make the Lua API a thin cover over the Flot API.  So you can pretty much take the [Flot documentation](https://github.com/flot/flot/blob/master/API.md) and code away.

The `Plot` class is defined in the Lua closure style, which pretty much corresponds to how it could be done in JavaScript.  Here the methods of the object are closures which access the state of the object expressed as local variables of the constructor function.

    function flot.Plot (opts)
       local plot = {}
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
          elseif plot.xvalues then
             data = interleave(plot.xvalues,data)
          end
          kind.data = data
          append(dataset,kind)
       end

       function plot:script ()
          return script:format(as_js(dataset),as_js(opts))
       end

       return plot
     end

There's only one public API method, `add_series`, and it allows series to be added incrementally. The other major difference from the original API is that the label and the data array are arguments; the third argument is the rest of the data series object. The argument to `flot.Plot` is essentially the 'options' object in Flot, although it may also contain extra fields `width`, `height` (for plot size in pixels) and `xvalues`,`x` and `y` for data. Generally series data is an array of two-element arrays, but if you specify `xvalues` then it can be an array of y values; `x` and `y` are for separate arrays of coordinates.

This closure-based method for creating objects works particularly well when the number
of objects of each 'class' is relatively few.  (With a trivial change, we could
actually use dot `.` instead of colon `:` when calling these objects, but that would confuse most Lua programmers.)

Now, we could have gone overboard on designing a wrapper API, but it would require a lot of code to get the same flexibility as the original, and (most importantly) would need to be documented! Instead, we exploit the near-isomorphism between Lua and JavaScript data and get a notation which is close to the original.

Basic plotting is very similar to the original Flot API:

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

@plot basic-flot

To run this script, the fastest way is to download and unzip Flot to a directory, and copy [flot.lua](flot.lua) and [basic-flot.lua](basic-flot.lua) to the same directory. (After that you can move `flot.lua` to your module path and modify `flot.path` in the source to be the absolute path to the Flot directory, or to a public internet uRL)

Running this program will create a corresponding `basic-flot.html` which you can open in your browser.

There's also a convenient way to input data that comes as a separate array of x and y values:

    -- normal.lua
    local flot = require 'flot'

    function make_gaussian (m,s,values)
       local s2 = 2*s^2
       local norm = 1/math.sqrt(math.pi*s2)
       local res = {}
       for i = 1,#values do
          res[i] = norm*math.exp(-(values[i]-m)^2/s2)
       end
       return res
    end

    local xvalues = flot.range(0,10,0.1)
    local n1 = make_gaussian (5,1,xvalues)
    local npoint7 = make_gaussian (5,0.7,xvalues)

    -- sampled Guassian with random noise
    local n1r,n1rx,k = {},{},1
    for i = 1,#xvalues,3 do
       n1r[k] = n1[i] + math.random()/10 - 0.05
       n1rx[k] = xvalues[i]
       k = k + 1
    end

    local plot = flot.Plot {
       grid = {
          markings = { -- a filled plot annotation
             {xaxis={from=4,to=6},color="#FFEEFE"}
          }
       },
       -- this provides x coordinates for all series!
       xvalues = xvalues
    }

    -- then the y data can be provided as a simple array
    plot:add_series('norm s=1',n1)
    plot:add_series('norm s=0.7',npoint7)
    -- can also specify with explicit x and y coord arrays
    plot:add_series('data',{x=n1rx,y=n1r},{points={show=true}})


    flot.render(plot)

@plot normal

Flot series may consist of segments separated by `null` (which is why we needed such an object):

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

@plot filled

## Files

  * [flot.lua](flot.lua) is just 146 lines...
  * [filled](filled.lua), [basic-flot](basic-flot.lua) and [normal](normal.lua) are examples
  * [prettify.lua](prettify.lua) is the script that generated this semi-nice HTML output with inlined plots. With a little styling, could be used as a tool for a blogger who likes to argue using code and numbers.


