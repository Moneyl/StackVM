

namespace VmScriptingFun
{
	public enum Bytecode : u8
	{
		SetX, //Pop value off top of stack and set x with it. Preset value for basic vm testing. Will be removed when variables are a thing.
		SetY, //Pop value off top of stack and set y with it. Preset value for basic vm testing. Will be removed when variables are a thing.
		Add, //Pop top two values from the stack. Add together. Push result onto stack.
		Subtract, //Pop top two values from the stack. Subtract together. Push result onto stack.
		Print, //Print value of variable at the top of the stack
		TestPrint, //Print x and y vm testing values
		Value, //Push value onto the stack. 4 byte unsigned integer follows it in bytecode blob
		Pop //Pop value off the top of stack
	}
}
