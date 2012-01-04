package = "ldoc"
version = "1.1.0-1"

source = {
  dir="ldoc",
  url = "http://stevedonovan.github.com/files/ldoc-1.1.0-core.zip"
}

description = {
  summary = "A Lua Documentation Tool",
  detailed = [[
   LDoc is a LuaDoc-compatible documentation generator which can also
   process C extension source. Markdown may be optionally used to
   render comments, as well as integrated readme documentation and
   pretty-printed example files
  ]],
  license = "MIT/X11",
  homepage = "http://ldoc.org",
  maintainer = "you@your.org"
}


dependencies = {
  "penlight"
}


build = {
  type = "builtin",
  modules = {
    ["ldoc.tools"] = "ldoc/tools.lua",
    ["ldoc.lang"] = "ldoc/lang.lua",
    ["ldoc.html.ldoc_css"] = "ldoc/html/ldoc_css.lua",
    ["ldoc.html.ldoc_ltp"] = "ldoc/html/ldoc_ltp.lua",
    ["ldoc.prettify"] = "ldoc/prettify.lua",
    ["ldoc.doc"] = "ldoc/doc.lua",
    ["ldoc.builtin.globals"] = "ldoc/builtin/globals.lua",
    ["ldoc.parse"] = "ldoc/parse.lua",
    ["ldoc.html"] = "ldoc/html.lua",
    ["ldoc.lexer"] = "ldoc/lexer.lua",
    ["ldoc.markup"] = "ldoc/markup.lua",
    ["ldoc.html.ldoc_one_css"] = "ldoc/html/ldoc_one_css.lua"
  },
  install = {
    bin = {
      ldoc = "ldoc.lua"
    }
  }
}

