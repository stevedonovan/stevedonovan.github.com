# Lua 5.1.4 Annotated Source

## Interpreter/Compiler

 * [lua.c](lua.c.html) *interpreter*
 * [luac.c](luac.c.html) *compiler front-end*
 * [print.c](print.c.html) *dissembler*
 * [ldump.c](ldump.c.html) *saving compiled code*
 
## Public API

Well-behaved Lua extensions should only need these.

  * [lua.h](lua.h.html)
  * [lauxlib.h](lauxlib.h.html)
  * [luaconf.h](luaconf.h.html)
  
## Libraries

Referenced from [linit.c](linit.c.html) and [lualib.h](lualib.h.html). 

  * [lbaselib.c](lbaselib.c.html) **globals and coroutine**
  * [loadlib.c](loadlib.c.html) **package**
  * [loslib.c](loslib.c.html)  **os**
  * [liolib.c](liolib.c.html)  **io**
  * [lstrlib.c](lstrlib.c.html) **string**
  * [lmathlib.c](lmathlib.c.html) **math**
  * [ltablib.c](ltablib.c.html) **table**
  
These only depend on the public API. The debug library needs more intimate 
knowledge of Lua internals:

  * [ldebug.c](ldebug.c.html) **debug**
  
## Core

### API Implementation

  * [lapi.c](lapi.c.html) *main API*
  * [lauxlib.c](lauxlib.c.html) *auxililary API*
  
### Lexer/Parser

  * [llex.c](llex.c.html) *lexer*
  * [lparser.c](lparser.c.html) *parser*
  * [lzio.c](lzio.c.html) *generic input stream*
  * [lundump.c](lundump.c.html) *loading precompiled code*  
  * [lcode.c](lcode.c.html) *code generator*
  * [lfunc.c](lfunc.c.html) *manipulating prototypes and closures*
  * [lopcodes.c](lopcodes.c.html) *opcodes*
  
### Virtual Machine

  * [ltable.c](ltable.c.html) *table implementation*
  * [lstring.c](lstring.c.html) *string implementation*
  * [lstate.c](lstate.c.html) *Lua State*
  * [lobject.c](lobject.c.html) *Lua object management*
  * [lmem.c](lmem.c.html) *memory management*  
  * [lgc.c](lgc.c.html) *garbage collection*
  * [ltm.c](ltm.c.html) *metamethod dispatch ('tags')*
  * [ldo.c](ldo.c.html) *stack and call structure*
  * [lvm.c](lvm.c.html) *virtual machine core*
  
