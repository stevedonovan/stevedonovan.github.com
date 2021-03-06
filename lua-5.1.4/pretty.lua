-- pretty.lua
-- Formating C code using tags from exuberant ctags.
-- You will first need to generate a tags file with line number info, e.g
-- $ ctags -n *.c *.h
-- Requires Penlight.
--
-- Steve Donovan, 2010, X11/MIT

require 'pl'

local url_shortcuts = {
    manl = 'doc/manual.html#pdf-',
    manc = 'doc/manual.html#',
    wiki = 'http://lua-users.org/wiki/'
}

function read_annotations(file)
    file = file or 'annotations.txt'
    local anot = {}
    local f = io.open(file)
    local line = f:read();
    while line do
        local file,sym = line:match('#%s+([^:]+):(.*)')
        if not anot[file] then anot[file] = {} end
        line = f:read()
        local body = List()
        while line and not line:match '^#' do
            body:append(line)
            line = f:read()
        end
        body:remove(#body)
        body = body:join '\n'
        if #sym == 0 then
            anot[file]["#file"] = body
        else
            anot[file][sym] = body
        end
    end
    f:close()
    return anot
end

local append = table.insert

function readtags(file)
    file = file or 'tags'
    local f = io.open(file)
    local symbols = {}    

    -- skip the comment header
    local line = f:read()
    while line:find '^!' do
        line = f:read()
    end

    local k = 1
    for line in f:lines() do
        local sym,file,lno,tp,rest = line:match('([%w_]+)\t(%S+)\t(%S+)\t(%a)(.*)')
        lno = lno:match '(%d+);"'
        if lno then lno = tonumber(lno) end
        -- generally more than one entry per symbol
        if not symbols[sym] then symbols[sym] = {} end
        append(symbols[sym],{name=sym,file=file,lno=lno,tp=tp, ts=k })
        k = k + 1
    end

    f:close()

    return symbols
end

function get_file_refs(syms,file)
    -- need all symbols contained within this file
    local file_refs = {}
    for name,entries in pairs(syms) do
        for _,entry in ipairs(entries) do
            if entry.file == file then
                file_refs[name] = entry
            end
        end
    end
    return file_refs
end

function find_refs(syms,fname)
    local res = List()
    for name,entries in pairs(syms) do for _,entry in ipairs(entries) do
        if entry.refs then
            for rname,e in pairs(entry.refs) do
                if rname == fname then res:append(entry) end
            end                
        end
    end end
    return res
end


local header = [[
<html>
<head>
<link rel='stylesheet' type='text/css' href='style.css'></link>
<body>
]]

local footer = [[
<hr/>
Generated by <a href="pretty.lua.html">pretty.lua</html>
</body></html>
]]

local syms = readtags()
local anot = read_annotations()

function do_refs(file)
    local file_refs = get_file_refs(syms,file)
    print('refs',file)
    local res = List()
    res:append(header)
    res:append (('<h1>Lua 5.1.4: %s references</h1>\n<hr/>\n'):format(file))    
    -- for all the symbols referenced in this file.....
    for name,entry in pairs(file_refs) do
        local refs = find_refs(syms,name)
        if refs and #refs > 0 then
            res:append(('<a name="%s"/><h3>%s</h3>\n<ul>'):format(name,name))
            for _,ref in ipairs(refs) do
                res:append(('<li><a href="%s.html#%s">%s</a> in %s</li>\n'):format(
                                        ref.file,ref.name,ref.name,ref.file) )
            end
            res:append '</ul>\n'
        end
    end
    res:append(footer)
    utils.writefile(file..'.ref.html',res:join '')
end

local lbrack,rbrack = '\001','\002'
local escaped_chars = {
    ['&'] = '&amp;',
    ['<'] = '&lt;',
    ['>'] = '&gt;',
    [lbrack] = '<',
    [rbrack] = '>',
}
local escape_pat = '[&<>'..lbrack..rbrack..']'

local function escape(str)
    str = str:gsub('<%a+:[^>]->',function(ref)
        local url
        ref = ref:sub(2,-2)
        local proto,rest = ref:match('^(%a+):(.+)')
        if proto ~= 'http' then
            local base_url = url_shortcuts[proto]
            assert(base_url,"unknown url shortcut "..proto)
            url = base_url .. rest
        else
            url = ref
        end
        return ('%sa href="%s"%s%s%s/a%s'):format(lbrack,url,rbrack,ref,lbrack,rbrack)    
    end)
    return (str:gsub(escape_pat,escaped_chars))
end

local function span(t,val)
    return ('<span class="%s">%s</span>'):format(t,val)
end

local function link(file,ref,text)
    text = text or ref
    return ('<a class="L" href="%s.html#%s">%s</a>'):format(file,ref,text)           
end

local function anchor(name)
    return ('<a name="%s"/a>'):format(name)
end

local function block(text)
    return ('<div class="block">%s\n</div>'):format(escape(text))
end

local function add_ref(fun,sym)
    if not fun then return end
    if not fun.refs then fun.refs = {} end    
    fun.refs[sym.name] = sym
end

function prettify_c (file)
    local code = List()
    local f,err = io.open(file)
    if not f then return nil,err end
    local aa = anot[file]

    print('reading',file, aa and 'annotated' or '')
    
    -- serious hack; add line numbers to the orginal source
    -- (must do this because this lexical scanner is not line-driven.)
    local lno = 1
    for line in f:lines() do
        code:append(('L%04d    %s\n'):format(lno,line))
        lno = lno + 1
    end
    code = code:join ''

    local res = List()
    res:append(header)
    res:append (('<h1>Lua 5.1.4: %s</h1>\n<hr/>\n'):format(file))    
    res:append '<pre>\n'

    if aa and aa['#file'] then
        res:append(block(aa['#file']))
    end

    local no_refs = path.extension(file) == '.lua'
    local scanner = lexer.cpp
    if no_refs then
        scanner = lexer.lua
        syms = {}
    end
    
    local spans = {keyword=true,number=true,string=true,comment=true,prepro=true}
    local curr_fun
    local dcl
    
    for t,val in scanner(code,{},{}) do
        val = escape(val)
        if t == 'iden' then
            -- a bit of a hack
            local ll = val:match('^L(%d%d%d%d)')
            if ll then
                lno = tonumber(ll)
                --val = span('lno',ll)
                if dcl then
                    if aa and aa[dcl] then
                        res:append(block(aa[dcl]))
                    end                
                    dcl = nil
                end
            else
                local sym = syms[val]
                if sym then
                    local e = sym[1]
                    if e.file == file and e.lno == lno then
                        -- hit a symbol definition
                        curr_fun = e
                        res:append (anchor(val))
                        val = link(file..'.ref',val)
                        dcl = e.name
                    elseif e.tp ~= 'm' then -- ignore struct field refs
                        val =  link(e.file,val)
                        add_ref(curr_fun,e)
                    end
                end
            end
            res:append(val)
        elseif spans[t] then
            if t == 'prepro' then
                local mname = val:match('#%s*define%s+([%w_]+)')
                if mname then
                    res:append(anchor(mname))
                    dcl = mname
                end
                local file = val:match('#%s*include "([^"]+)"')
                if file then
                    val = link(file,'',val)
                end
            end
            res:append(span(t,val))
        else
            res:append(val)
        end
    end

    res:append '</pre>\n'
    res:append(footer)    
    utils.writefile(file..'.html',res:join '')
end

if arg[1] then
    prettify_c(arg[1])
    if path.extension(arg[1]) == '.c' then
        do_refs(arg[1])
    end
else
    local function getfiles(mask)
        return dir.getfiles('.',mask):map(path.basename)        
    end
    local c_files = getfiles '*.c'
    local h_files = getfiles '*.h'
    c_files:foreach(prettify_c)
    h_files:foreach(prettify_c)
    -- once the main .html files are generated, can make .ref.html files
    c_files:foreach(do_refs)
    h_files:foreach(do_refs)
end
