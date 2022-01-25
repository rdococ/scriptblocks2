Scriptblocks 2
==============

Scriptblocks 2 is a Minetest mod and toy programming language using nodes called scriptblocks. Scriptblocks are nodes which can be used to build reusable programs.

# Features

* Support for nested expressions.
* Lexically scoped variables.
* Custom, named procedures with up to 2 named parameters.
* First-class lists, dictionaries, and closures with up to 1 named parameter.
* Coroutines, closures that can be paused and resumed.
* Processes can persist for more than one tick.
* Ability to interface with digiline networks.

This mod is an experiment to see what kind of fully-fledged programming language you can design using nodes. Some precautions have been taken to prevent server crashes, but they are not thoroughly tested. Use with care.

# Experiments

* Spawnable processes, enabling pre-emptive multitasking.
* Introspective blocks for debug purposes, such as one to report a string representation of the call stack.

These features can be accessed by enabling the 'Enable Experiments' setting.

# Examples

This procedure calculates the factorial of a given number.

![Factorial](screenshots/factorial.png)

This procedure takes a list and a closure. It calls the closure for each item in the list, and reports the results in a new list.

![Map](screenshots/map.png)