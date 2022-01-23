Scriptblocks 2
==============

Scriptblocks 2 is a Minetest mod and toy programming language using nodes called scriptblocks. Scriptblocks are nodes which can be used to build reusable programs.

# Features

* Support for nested expressions.
* Lexically scoped variables.
* Custom, named procedures with up to 2 named parameters.
* First-class lists, dictionaries, and closures with up to 1 named parameter.
* Coroutines, which can be cloned to implement multi-shot delimited continuations.
* Processes can persist for more than one tick.
* Ability to interface with digiline networks.

This mod is an experiment to see what kind of fully-fledged programming language you can design using nodes. Some precautions have been taken to prevent server crashes, but they are not thoroughly tested. Use with care.

# Experiments

* Spawnable processes.
* Introspective blocks.
* Features slated for removal, such as continuations.

These features can be accessed by enabling the 'Enable Experiments' setting. Some are merely for fun, other features may be included in the future, and a few features such as continuations will be removed in the future.

# Examples

This procedure calculates the factorial of a given number.

![Factorial](screenshots/factorial.png)

This procedure takes a list and a closure. It calls the closure for each item in the list, and reports the results in a new list.

![Map](screenshots/map.png)