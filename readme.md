Scriptblocks 2
==============

Scriptblocks 2 is a Minetest mod and toy programming language using nodes called scriptblocks. Scriptblocks are nodes which can be used to build reusable programs.

## Features

* Support for nested expressions and variables.
* Custom, named procedures with up to 2 named parameters and dynamic scoping.
* First-class lists, dictionaries, and lexically scoped closures with up to 1 named parameter.
* Coroutines, closures that can be paused and resumed.
* Processes can run for more than one tick.
* Ability to interface with digiline networks.

## Experiments

* Spawnable processes, providing primitives for parallelism rather than just concurrency.
* Introspective blocks for debug purposes, such as one to report a string representation of the call stack.

These features can be accessed through the 'Enable Experiments' setting. Some of these features can cause a lot of lag, even with the limits that have been imposed. Others are only useful for debugging purposes. Either way, don't enable these on a public server!

First-class continuations have been moved to their own mod, [SB2 Continuations](https://github.com/rdococ/sb2_continuations).

## Examples

This procedure calculates the factorial of a given number.

![Factorial](screenshots/factorial.png)

This procedure takes a list and a closure. It calls the closure for each item in the list, and reports the results in a new list.

![Map](screenshots/map.png)