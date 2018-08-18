---
layout: post
title: "Why Rust Closures are (Somewhat) Hard"
author: Steve Donovan
---

## The Easy Case: Lua

Since hard is _always_ relative to something else, I'd like to start with a
dynamic language. Functions in Lua are essentially _anonymous_ and can
_capture_ variables from their environment - much like with JavaScript, which Lua resembles
in several important ways):

```lua
local m,c = 1,2
local line = function(x) return m*x + c end

print(line(0)) -- 2
print(line(1)) -- 3

function call(f,x)
    return f(x)
end

print(call(line,1)) --3
```
That's cool and useful - we have created a function and _bound_
it to the variable `line`. These function values can be passed around,
since functions are _first class objects_ in Lua:

Since functions are values, it is easy to write functions which return
functions - _higher-order functions_:

```lua
function make_line(m,c)
    return function
        return m*x + c
    end
end

local line = make_line(1,2)
-- as before
```

Rust closures are harder for three main reasons:

The first is that it is both statically and strongly typed, so
we'll need to explicitly annotate these function types.

Second, Lua functions are dynamically allocated ('boxed'.)
Rust does not allocate _silently_ because it prefers
to be explicit and is a system language designed for maximally efficient code.

Third, closures share references with their environment.
In the case of Lua, the garbage collector ensures that these references
will _live long enough_. With Rust, the borrow checker needs
to be able to track the lifetimes of these references.

## The Easy Case: Rust

The notation for Rust closures is very concise in comparison:

```rust
let m = 1.0;
let c = 2.0;

let line = |x| m*x + c;

println!("{} {}", line(0.0), line(1.0));
```
Two points need emphasis. The first is that closures are quite distinct from
plain functions - I can define a function `line` here but it will _not_ share
references to the local variables `m` and `c`. The second is that the argument
and return type are established by type inference.  As soon as we say `line(0.0)`
the compiler knows that this closure takes a `f64` and returns an `f64`. If I
subsequently try to call `line(1)` it will complain because no way Rust will
convert an integer into a float without a typecast.

Rust has a very similar attitude to C++ here - that closures should be a
_zero-overhead abstraction_.  Here we have a vector of integers, and wish to know
how many elements are greater than zero:

```rust
let k = my_vec.iter().filter(|n| **n > 0).count();
```
The guarantee is that this will be _just as fast_ as writing out an explicit loop!
What is the type of `n`? `iter()` produces a iterator over references to the
elements (say `&i32`) and `filter` takes a closure which is passed a reference to
the iterator type - so it will be `&&i32` in this case.  So we need a double dereference
to get the actual integer - Rust references don't automagically dereference themselves,
except if a method is called. (A more idiomatic way of writing this is `|&&n| n > 0`.)
So, although type inference saves us typing and makes iterator expressions much less noisy,
it does not not save us from having to know the type.

The way that Rust (and C++) avoids overhead in this most important case is
_not to box_ closures. This means that they can be _inlined_.

## How Rust Closures are Implemented

Our first little example is syntactical sugar for creating a struct:

```rust
struct SomeUnknownType<'a> {
    m: &'a f64,
    c: &'a f64
}

impl <'a>SomeUnknownType<'a> {
    // pseudo-code - note the 'call operator' is a _method_
    fn call(&self, x: f64) -> f64 {
        self.m * x + self.c
    }
}

let s = SomeUnknownType{m: &1.0, c: &2.0};

assert_eq!(s.call(1.0), 3.0);

```
The actual concrete type is not known to the
program. You will only see this type in error messages - here we use a common
trick to provoke `rustc` into telling us the actual type of the right-hand side:

```
27 |     let f: () = |x| m*x + c;
   |                 ^^^^^^^^^^^ expected (), found closure
   |
   = note: expected type `()`
              found type `[closure@/home/steve/closure1.rs:27:17: 27:28 m:_, c:_]`

```

This a struct that _borrows references_ to its environment and so must have a _lifetime_.

This is pretty much what happens with C++ lambdas, where the actual generated type
is unknown.  (This is one of the reasons why `auto` has become so important in
modern C++, because not all types can be expressed explicitly). With C++ one
has detailed control about what gets captured by reference or by copy; with Rust
by default everything is implicitly borrowed.

However, if we said `move |x| m*x + c` then the struct would look like this:

```rust
struct AnotherUnknownType {
    m: f64,
    c: f64
}

impl AnotherUnknownType {
    fn call(&self, x: f64) -> f64 {
        self.m * x + self.c
    }
}
```
The environment has been captured by _copying_ `m` and `c` - no borrowing and
no lifetime associated with borrowing.

So there's no magic involved with Rust closures - just sugar.

These are obviously very different types - what do they have in common?
They both match the trait bound `Fn(f64)->f64`.  Here is a generic function
which simply invokes the closure it has been given:

```rust
fn invoke<F>(f: F, x: f64) -> f64
where F: Fn(f64)->f64 {
    f(x)
}
```

With Rust 1.26, there's a simpler but completely equivalent notation:

```rust
fn new_invoke(f: impl Fn(f64)->f64, x: f64) -> f64 {
    f(x)
}
```
Either way, the type bound for the `f` argument reads:
`f` is _any_ type that implements `Fn(f64)->f64`.

Now, if we wanted to _store_ closures, we have to box them. We can store
any functions matching `Fn(f64)->f64` as `Box<Fn(f64)->f64>`. A boxed closure
is also callable, but has a known fixed size because it is a pointer to the
closure struct, so you can put these boxes into a vector or a map.

It is equivalent to the `std::function` type in C++, which also involves
calling a _virtual method_.  `Box<Fn(f64)->f64>` is a Rust _trait object_.

These are three function traits in Rust, which correspond to the three kinds
of methods (remember that the calling a closure is executing a method on a struct)

  - `Fn`  call is `&self` method
  - `FnMut` call is `&mut self` method
  - `FnOnce` call is `self` method

## Implications of "Closures are Structs"

`|x| m*x + c` has a lifetime tied to that of `m` and `c`.
It cannot live longer than these variables.  The lifetime appears explictly
when we try to store closures in boxes:

```rust
struct HasAClosure<'a> {
    closure: Box<Fn(f64)->f64 + 'a>
}

impl <'a>HasAClosure<'a> {

    fn new<C>(f: C) -> HasAClosure<'a>
    where C: Fn(f64)->f64 + 'a {
        HasAClosure {
            closure: Box::new(f)
        }
    }

}
```
I recall being a little puzzled at the lifetime bound, until I fully internalized
the fact that closures are structs, and structs that borrow have lifetimes.

The borrow checker is going to be particularly strict about closures that borrow
mutably (`FnMut`) since there may be only one mutable reference to a value, and
that reference will be captured by the closure.

```rust
let mut x = 1.0;
let mut change_x = || x = 2.0;
change_x();
println!("{}",x);
....
25 |     let mut change_x = || x = 2.0;
   |                    -- - previous borrow occurs due to use of `x` in closure
   |                    |
   |                    mutable borrow occurs here
26 |     change_x();
27 |     println!("{}",x);
   |                   ^ immutable borrow occurs here

```
The closure bound to `change_x` has got its sticky paws on `x` and will not release
it until it goes out of scope!  So this will work:

```rust
let mut x = 1.0;
{
    let mut change_x = || x = 2.0;
    change_x();
}
println!("{}",x);
```
This is annoying, but it truly becomes a bastard when you have some struct keeping
actions as closures.
Only one of those actions can manipulate the environment! Working
with Rust is sometimes like the old joke about the person who goes to the doctor:
"It hurts when I do this". To which the doctor replies, "Then don't do it". In the
case of actions that need to manipulate some state, make the owner of the actions
keep the state and explicitly pass a mutable reference to it in the actions. That is,
the closures themselves do not borrow mutably.

The problem goes beyond mutable references, particularly when the lifetime
of the closures has to be longer than any temporary scope. For instance, you may
attach an action to a button in some function - that action must last longer
than the function.

`move` closures avoid borrow-checking problems by avoiding borrowing - they _move_
the values.  If those values are `Copy`, then Rust will copy.  But otherwise the value
will be moved and not be available afterwards. This is the only way to get
a closure with a `'static` lifetime.

A common strategy is to use shared references like
`Rc` and `Arc` (equivalent to C++'s `shared_ptr`). Cloning a shared reference just
increments the reference count, and dropping them decrements the count; when the count
goes to zero the actual value is dropped. This is a kind of garbage collection and
provides the important guarantee that the references will last 'just long enough'. So typically
you would clone a reference and move it into a closure, and avoid explicit lifetime
problems.

## Threads

There is an intimate relationship between threads and closures - `std::thread::spawn` is
passed a closure and runs in a new thread. In this case, Rust insists that the closure has
a static lifetime, and usually we `move` the closure.

This isn't an inherent feature of threads though! Consider _scoped threads_ from the **crossbeam**
crate:

```rust
let greeting = "hello".to_string();
crossbeam::scope(|scope| {
    scope.spawn(|| {
        println!("{} thread!", greeting);
    });
});
```
The spawned thread is _guaranteed_ to be terminated by the end of the scope, and it is
_quite_ happy with the lifetime of `greeting`, which lasts longer than the scope.

It gets better:

```rust
let mut greeting = "hello".to_string();
crossbeam::scope(|scope| {
    scope.spawn(|| {
        greeting.push_str(" eh");
        println!("{} thread!", greeting);
    });
});
```
There's no problem passing a mutable reference either. But, if you tried to mutate
the greeting in another thread within the scope you would get the usual "only one mutable
reference allowed" error. For sharing between threads you will still need `Arc`.

## Higher-Order Functions

These are less elegant than with Lua. Explicit type
annotations are a necessary part of life (if you want to remain sane.)

In the Bad Old Days, explicit boxing was your only option if you wanted to return a closure:

```rust
fn old_adder(a: f64) -> Box<Fn(f64)->f64> {
    Box::new(move |x| a + x)
}

let a1 = old_adder(1.0);
assert_eq!(a1(2.0), 3.0);
```
Boxing is not always a bad choice, but it does make certain optimizations
impossible - like inlining the closure completely. (Note that the returned closure has
to be `move`, since any reference to the argument `a` is not going
to last longer than the body of `old_adder`. For a primitive like `f64`,
moving means copying.)

With Rust 1.26, you can say:

```rust
fn new_adder(a: f64) -> impl Fn(f64)->f64 {
    move |x| a + x
}
```
That is, `new_adder` returns a _particular_ type, but all the caller needs know
is that it implements `Fn(f64)->f64`. In this case, even the callee doesn't
know the exact type! Cleaner, and no boxing involved.

`impl Trait` certainly helps with generic function signatures, although they
can still get a little unwieldy:

```rust
fn compose (f1: impl Fn(f64)->f64, f2: impl Fn(f64)->f64) -> impl Fn(f64)->f64 {
    move |x| f1(f2(x))
}

let f = compose(f64::sin, |x| x*x);
...
```
Note that plain old functions match the same trait as closures.

These are already generic functions, since they are passed _any_ type
that implements `Fn(f64)->f64`; for each unique type, a new implementation
is created - so-called _monomorphism_ (the expression has the same shape,
but the generated code is different in each case.)

We can get even more generic, and define `compose` for any function
that maps a value to another value of that same type:

```rust
fn compose <T>(f1: impl Fn(T)->T, f2: impl Fn(T)->T) -> impl Fn(T)->T {
    move |x| f1(f2(x))
}
let g = compose(str::trim_left, |s| &s[0..2]);
assert_eq!(compose(" hello "),"h");
....
```
Type inference is a marvelous thing - `compose` knows from the first argument that the
type parameter `T` must be `&str` in this case.

An entertaining property of Rust generic functions is that the declaration is often more
scary than the implementation. C++ cheats with templates, since they are effectively
compile-time duck-typing. Easier to type, certainly, but the error messages can be less than helpful.

## Summary: the Hardness is (Mostly) Necessary

There's always going to be some trade-off between programmer convenience
and performance. Rust would certainly be _easier_ if it boxed closures and
used 'smart pointer' references by default, but it would not be Rust - in fact,
it would be similar to Swift. Instead, Rust aims for the same niche
occupied by C, C++ and Ada - predictable high performance and optimal use of
system resources (a "systems language"). The novelty it brings to that party
is explicitly enforcing lifetime analysis on references.

Closures make functional style possible, and Rust's implementation makes
this efficient as possible. There is a lot less explicit looping needed,
and you (generally) don't have to worry about the performance implications
of avoiding loops. Here Rust is following the 'generic programming'
tradition of C++, where you don't loop if the operation is already
provided by `<algorithm>` - the main difference is that `Iterator`
takes the place of iterator ranges and the operations are methods.

Closures are synthesized structs which either
borrow or move/copy their environment, very much like C++ lambdas.
The restrictions we've discussed follow directly from this implementation
and its interaction with the borrow checker.

