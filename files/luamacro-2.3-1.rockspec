package = "luamacro"
version = "2.3-1"

source = {
  dir = "luamacro",
  url = "http://stevedonovan.github.com/files/luamacro-2.3.zip"
}

description = {
  summary = "A macro preprocessor for Lua",
  detailed = [[
   Provides intelligent lexical macros that can be scoped. By default it
   translates and runs code, keeping track of line numbers.
   LuaMacro 2 uses a LPeg lexical scanner and no longer needs the token filter
   patch.
  ]],
  license = "MIT/X11",
  homepage = "http://stevedonovan.github.com/LuaMacro/docs",
  maintainer = "steve.j.donovan@gmail.com"
}

dependencies = {
  "lpeg"
}

build = {
  type = "builtin",
  modules = {
    ["macro.lexer"] = "./macro/lexer.lua",
    ["macro.TokenList"] = "./macro/TokenList.lua",
    ["macro.do"] = "./macro/do.lua",
    ["macro.with"] = "./macro/with.lua",
    ["macro.lib.test"] = "./macro/lib/test.lua",
    ["macro.lib.class"] = "./macro/lib/class.lua",
    ["macro.clexer"] = "./macro/clexer.lua",
    ["macro.assert"] = "./macro/assert.lua",
    ["macro.builtin"] = "./macro/builtin.lua",
    ["macro.lambda"] = "./macro/lambda.lua",
    ["macro.module"] = "./macro/module.lua",
    ["macro.lc"] = "./macro/lc.lua",
    ["macro.forall"] = "./macro/forall.lua",
    ["macro.all"] = "./macro/all.lua",
    ["macro.try"] = "./macro/try.lua",
    macro = "./macro.lua",
    ["macro.Getter"] = "./macro/Getter.lua"
  },
  copy_directories = {
    "tests"
  },
  install = {
    bin = {
      "luam"
    }
  }
}

