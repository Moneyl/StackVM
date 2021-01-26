using System.Collections;
using System;

namespace VmScriptingFun
{
	//Stack based virtual machine. Runs bytecode
	public class VM
	{
		private i32[VMConfig.StackSize] _stack = .(); //Contains temporary variables and state. Data stored LIFO.
		private u32 _stackPos = 0; //Current position in the stack

		//Todo: Move this into a struct that is passed to the VM
		private List<Bytecode> _binary = new List<Bytecode>() ~delete _; //Binary blob that the vm runs

		//Test values used for VM dev. Will be removed once it has variables
		public i32 X = 0;
		public i32 Y = 0;

		private void Push(i32 value)
		{
			//Ensure no stack overflow
#if DEBUG
			Runtime.Assert(_stackPos < VMConfig.StackSize, "Stack overflow occurred in VM.");
#endif

			_stack[_stackPos++] = value;
		}

		private i32 Pop()
		{
			//Ensure stack isn't empty
#if DEBUG
			Runtime.Assert(_stackPos > 0, "Tried to pop a value from an empty stack in the VM.");
#endif
			return _stack[--_stackPos];
		}

		private i32 GetStackTop()
		{
			i32 value = Pop();
			Push(value);
			return value;
		}

		public void Interpret()
		{
			//Loop through all bytecodes and interpret them
			u32 i = 0;
			while(i < _binary.Count)
			{
				//Todo: See if array of function pointers indexed by bytecode value is faster/more reliably fast
				//Interpret bytecode
				Bytecode bytecode = _binary[i];
				switch(bytecode)
				{
				case .SetX:
					X = Pop();
					break;
				case .SetY:
					Y = Pop();
					break;
				case .Add:
					i32 a = Pop();
					i32 b = Pop();
					Push(a + b);
					break;
				case .Subtract:
					i32 a = Pop();
					i32 b = Pop();
					Push((i32)(a - b)); //Todo: Why is a u32 - u32 a i64
					break;
				case .Print:
					Console.WriteLine($"Top of stack: {GetStackTop()}");
					break;
				case .TestPrint:
					Console.WriteLine($"X: {X}, Y: {Y}");
					break;
				case .Value:
					i32 value = *(i32*)&_binary[i + 1];
					i += 4;
					Push(value);
					break;
				case .Pop:
					Pop();
					break;
				default:
					break;
				}

				i++;
			}
		}

		public void AddBytecode(Bytecode bytecode)
		{
			_binary.Add(bytecode);
		}

		public void AddValueBytecode(i32 value)
		{
			//Ensure there's enough for the value bytecode and 4 byte value
			if(_binary.Capacity < _binary.Count + 5)
				_binary.Reserve(_binary.Capacity + 5);

			//Add value bytecode
			_binary.Add(.Value);
			//Add value by interpreting next 4 bytes as a single u32
			i32* valuePtr = (i32*)((&_binary.Back) + 1);
			*valuePtr = value;
			_binary.[Friend]mSize += 4;
		}
	}
}
