# Stack VM
Stack based VM written in [Beef](https://www.beeflang.org/). For fun/learning purposes. The design and implementation of the VM is based on the second half of [Crafting Interpreters](https://craftinginterpreters.com/). It's not intended to be a perfect recreation of clox so it may vary in areas. This repo has a console app for testing the VM that loads a preset script, runs it, and prints out the VM state. It also has a gui app that lets you step through a script and see the VM state.

![](https://github.com/moneyl/StackVM/blob/master/images/VmGui_Example.png)

## Syntax
The VM includes a scripting language which is compiled into bytecode the VM runs. It's syntax/features:
- Common binary arithmetic operators `-`, `+`, `*`, `/`, unary `-`, parentheses for precedence control.
- Common comparison and logic operators `!`, `==`, `!=`, `>`, `<`, `>=`, and `<=`.

# Requirements
- Beef nightly build from January 31st or later. Nightly downloads can be found at the very bottom of the beef homepage.
- The debug gui needs [imgui-beef](https://github.com/RogueMacro/imgui-beef) in your BeefLibs folder. The console tester app for the VM doesn't have any dependencies.