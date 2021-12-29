Scriptblocks 2
==============

Scriptblocks 2 is a Minetest mod and toy programming language using nodes called scriptblocks. It is something of a spiritual sequel to the original scriptblocks mod, which was lost to the ages.

Features:

- Support for nested expressions.
- Lexically scoped variables.
- Custom, named procedures with up to 2 named parameters.
- First-class lists, dictionaries and functions with up to 1 named parameter.
- (Incomplete) mesecons and digilines support.

This mod is an experiment to see what kind of fully-fledged programming language you can design using nodes. It is not ready or safe for use in public servers, nor is it thoroughly tested. Use in private servers and singleplayer worlds with care!

# Examples

This procedure calculates the factorial of a given number.

![Factorial](screenshots/factorial.png)

This procedure takes a list and a closure. It calls the closure for each item in the list, and reports the results in a new list.

![Map](screenshots/map.png)