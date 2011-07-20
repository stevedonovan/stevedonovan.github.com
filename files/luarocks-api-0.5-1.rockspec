package = "luarocks-api"
version = "0.5-1"

source = {
  dir = "api",
  url = "http://stevedonovan.github.com/files/luarocks-api-0.5.tar.gz"
}

description = {
  summary = "a simple API for LuaRocks",
  detailed = [[
   luarocks-api allows you to query local and remote packages,
   and to install or remove them.
  ]],
  license = "MIT/X11",
  homepage = "http://stevedonovan.github.com/luarocks-api",
  maintainer = "steve.j.donovan@gmail.com"
}

build = {
  type = "builtin",
  modules = {
    ["luarocks.api"] = "luarocks/api.lua"
  }
}

