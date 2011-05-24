package = "rockspec"
version = "0.1-1"

source = {
  url = "http://stevedonovan.github.com/files/rockspec-0.1.zip",
  dir = "rockspec"  
}

description = {
  summary = "A Rockspec Build Mini-language",
  detailed = [[
   The rockspec library allows for the concise specification of
   LuaRocks rockspecs using the builtin back-end.
  ]],
  license = "MIT/X11",
  homepage = "https://github.com/stevedonovan/LuaRocksTools/tree/master/rockspec",
  maintainer = "steve.j.donovan@gmail.com"
}

dependencies = {
  "penlight"
}


build = {
  type = "builtin",
  modules = {
    rockspec = "./rockspec.lua"
  }
}

