package = "luamacro"
version = "2.5.0-1"
source = {
   url = "http://stevedonovan.github.com/files/luamacro-2.5.0.zip",
   dir = "LuaMacro"
}
description = {
   summary = "A macro preprocessor for Lua",
   detailed = [[
   Provides intelligent lexical macros that can be scoped. By default it
   translates and runs code, keeping track of line numbers.
   LuaMacro 2 uses a LPeg lexical scanner and no longer needs the token filter
   patch.
  ]],
   homepage = "http://stevedonovan.github.com/LuaMacro/docs",
   license = "MIT/X11",
   maintainer = "steve.j.donovan@gmail.com"
}
dependencies = {
   "lpeg ~= 0.11"
}
build = {
   type = "builtin",
   modules = {
      macro = "./macro.lua",
      ['macro.Getter'] = "./macro/Getter.lua",
      ['macro.TokenList'] = "./macro/TokenList.lua",
      ['macro.all'] = "./macro/all.lua",
      ['macro.assert'] = "./macro/assert.lua",
      ['macro.builtin'] = "./macro/builtin.lua",
      ['macro.clexer'] = "./macro/clexer.lua",
      ['macro.do'] = "./macro/do.lua",
      ['macro.forall'] = "./macro/forall.lua",
      ['macro.lambda'] = "./macro/lambda.lua",
      ['macro.lc'] = "./macro/lc.lua",
      ['macro.lexer'] = "./macro/lexer.lua",
      ['macro.lib.class'] = "./macro/lib/class.lua",
      ['macro.lib.test'] = "./macro/lib/test.lua",
      ['macro.module'] = "./macro/module.lua",
      ['macro.try'] = "./macro/try.lua",
      ['macro.with'] = "./macro/with.lua",
      ['macro.ifelse'] = "./macro/ifelse.lua"
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
