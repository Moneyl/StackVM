# Stack VM
Stack based VM written in [Beef](https://www.beeflang.org/). For fun/learning purposes. The design and implementation of the VM is based on the second half of [Crafting Interpreters](https://craftinginterpreters.com/). Though it's not intended to be a perfect recreation of clox so it may vary in areas.

## Syntax
The VM includes a scripting language which is compiled into bytecode the VM runs. It's syntax/features:
- Common binary arithmetic operators `-`, `+`, `*`, `/`, unary `-`, parentheses for precedence control.
- Common comparison and logic operators `!`, `==`, `!=`, `>`, `<`, `>=`, and `<=`.

# Requirements
- Beef nightly build from January 31st or later. Nightly downloads can be found at the very bottom of the beef homepage linked above.