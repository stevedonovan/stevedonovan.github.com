-- translate Markdown with code blocks into HTML
-- with syntax highlighting.
-- If article.md was the source, Lua was the language and we
-- wanted a preview:
-- lua prettify.lua article lua preview
-- Without the last argument it will just write out the HTML body.
-- Languages supported are 'lua', 'cpp', 'java' and 'go
-- Indented code blocks may begin with an explicit @lang name line;
-- if you do this then mark every code block explicitly
-- Needs markdown.lua and Penlight.
-- Steve Donovan, 2011 MIT license.
require 'pl'
require 'markdown'

local tnext = lexer.skipws
local concat = table.concat

local escaped_chars = {
   ['&'] = '&amp;',
   ['<'] = '&lt;',
   ['>'] = '&gt;',
}
local escape_pat = '[&<>]'

local function escape(str)
   return (str:gsub(escape_pat,escaped_chars))
end

local function span(t,val)
   return ('<span class="%s">%s</span>'):format(t,val)
end

local spans = {keyword=true,number=true,string=true,comment=true}


local jkeywords = {
   final = true, extends = true, implements = true,
   interface = true, import = true, throws = true, null = true
}

local gkeywords = { byte=true,chan=true,complex64=true,
complex128=true,defer=true,func=true,fallthrough=true,
float32=true,float64=true,string=true,uint=true,uintptr=true,
uint8=true,uint16=true,uint32=true,uint64=true,
var=true,len=true,map=true,package=true,range=true,select=true,
type=true,interface=true,int8=true,int16=true,int32=true,
int64=true,['nil']=true,func=true
}

local function prettify (code,lang)
   local res = List()
   res:append '<pre>\n'
   local xkeywords = {}
   local scanner
   local olang = lang
   if lang == 'java' then
      lang = 'cpp'
      xkeywords = jkeywords
   elseif lang == 'go' then
      lang = 'cpp'
      xkeywords = gkeywords
   end

   local tok = lexer[lang](code,{},{})
   local t,val = tok()
   local close_span
   if not t then return nil,"empty file" end
   while t do
      val = escape(val)
      if xkeywords[val] then -- hack for non-supported languages
        t = 'keyword'
      end
      if spans[t] then
        if t == 'comment' then -- support for //back line background
            back = val:match('back #(%S+)')
            if back then
                res:append(('<span style="background-color:#%s">'):format(back))
                t = nil
                close_span = true
            end
        end
        if t then res:append(span(t,val)) end
      else
        if t == 'space' and close_span and val:match '\n' then
            res:append '</span>'
            close_span = false
        end
        if t == '`' and olang == 'go' then -- Go raw strings
            local _,rest = tok '[^`]+`'
            res:append(span('string','`'..rest))
        else
            res:append(val)
        end
      end
      t,val = tok()
   end
   res:append '</pre>\n'
   return res:join ()
end

local function indent_line (line)
   line = line:gsub('\t','    ') -- support for barbarians ;)
   local indent = #line:match '^%s*'
   return indent,line
end

local plotk = 1

function prettify_code_blocks (txt,lang)
   local res, append = {}, table.insert
   local getline = stringx.lines(txt)
   local line = getline()
   local indent,code,start_indent
   while line do
      indent,line = indent_line(line)
      if indent >= 4 then -- indented code block
         code = {}
         while indent >= 4 do
            if not start_indent then start_indent = indent end
            append(code,line:sub(start_indent))
            line = getline()
            if line == nil then break end
            indent,line = indent_line(line)
         end
         code = concat(code,'\n')
         local llang = code:match('^%s*@lang (%a+)')
         if llang then
            lang = llang
            code = code:gsub('%s*@lang%s+%a+\n','')
         end
         code = prettify(code,lang)
         append(res,code)
         start_indent = nil
      else
         local plot = line:match '^@plot%s+(.+)$'
         if plot then
            local tmpfile = path.tmpname()
            io.output(tmpfile)
            _G.FLOT_PLACEHOLDER = plotk
            plotk = plotk + 1
            require (plot)
            io.close()
            line = utils.readfile(tmpfile)
         end
      end
      append(res,line)
      line = getline()
   end
   return concat(res,'\n')
end

local function remove_spurious_lines (txt)
   return txt:gsub('</p>%s*','</p>\n'):gsub('</pre>%s*','</pre>\n')
end

if #arg == 0 then
   return print("markdown-file-without-extension language (preview)")
end

name = arg[1]
lang = arg[2] or 'lua'
preview = arg[3]

preamble = [[
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>Lua Flot</title>
    <!--[if lte IE 8]><script language="javascript" type="text/javascript" src="flot/excanvas.min.js"></script><![endif]-->
    <script language="javascript" type="text/javascript" src="flot/jquery.js"></script>
    <script language="javascript" type="text/javascript" src="flot/jquery.flot.js"></script>
   <style type="text/css">
       .keyword {font-weight: bold; color: #6666AA; }
       .number  { color: #AA6666; }
       .string  { color: #8888AA; }
       .comment { color: #666600; }
       pre { font-weight: bold; }
       body {
           padding-left: 7em;
           width: 50em;
           font-family: arial, helvetica, geneva, sans-serif;
           background-color: #ffffff; margin: 0px;
       }
   </style>
</head>
<body>
]]

coda = [[
</body></html>
]]

text = utils.readfile(name..'.md')
text = prettify_code_blocks(text,lang)
text = markdown(text)
text = remove_spurious_lines(text)
if preview then
   text = preamble .. text .. coda
end
utils.writefile(name..'.html',text)
