using System.Collections;
using System;

namespace VmScriptingFun
{
	//Stack based virtual machine. Runs bytecode
	public class VM
	{


		private VmValue[VMConfig.StackSize] _stack = .(); //Contains temporary variables and state. Data stored LIFO.
		private u32 _stackPos = 0; //Current position in the stack

		//Binary blob executed by the VM. Contains constants and bytecodes
		private BinaryBlob _binary = new BinaryBlob();
		private u32 _binaryPos = 0;

		//Converts a script string to bytecode
		private BytecodeCompiler _compiler = new BytecodeCompiler() ~delete _;

		private void Push(VmValue value)
		{
			//Ensure no stack overflow
#if DEBUG
			Runtime.Assert(_stackPos < VMConfig.StackSize, "Stack overflow occurred in VM.");
#endif

			_stack[_stackPos++] = value;
		}

		private VmValue Pop()
		{
			//Ensure stack isn't empty
#if DEBUG
			Runtime.Assert(_stackPos > 0, "Tried to pop a value from an empty stack in the VM.");
#endif
			return _stack[--_stackPos];
		}

		private VmValue GetStackTop()
		{
			VmValue value = Pop();
			Push(value);
			return value;
		}

		public VmResult Interpret()
		{
			//Loop through all bytecodes and interpret them
			_binaryPos = 0;
			while(_binaryPos < _binary.Bytecodes.Count)
			{
				//Todo: See if array of function pointers indexed by bytecode value is faster/more reliably fast
				//Interpret bytecode
				Bytecode bytecode = _binary.Bytecodes[_binaryPos];
				switch(bytecode)
				{
				case .Add:
					VmValue b = Pop();
					VmValue a = Pop();
					if(!a.IsNumber() || !b.IsNumber())
					{
						RuntimeError(scope $"Operands for add bytecode must be a number. Bytecode: {bytecode}, a: {a}, b: {b}");
						return .RuntimeError;
					}
					Push(.Number(a.AsNumber() + b.AsNumber()));
					break;
				case .Subtract:
					VmValue b = Pop();
					VmValue a = Pop();
					if(!a.IsNumber() || !b.IsNumber())
					{
						RuntimeError(scope $"Operands for subtract bytecode must be a number. Bytecode: {bytecode}, a: {a}, b: {b}");
						return .RuntimeError;
					}
					Push(.Number(a.AsNumber() - b.AsNumber()));
					break;
				case .Multiply:
					VmValue b = Pop();
					VmValue a = Pop();
					if(!a.IsNumber() || !b.IsNumber())
					{
						RuntimeError(scope $"Operands for multiply bytecode must be a number. Bytecode: {bytecode}, a: {a}, b: {b}");
						return .RuntimeError;
					}
					Push(.Number(a.AsNumber() * b.AsNumber()));
					break;
				case .Divide:
					VmValue b = Pop();
					VmValue a = Pop();
					if(!a.IsNumber() || !b.IsNumber())
					{
						RuntimeError(scope $"Operands for divide bytecode must be a number. Bytecode: {bytecode}, a: {a}, b: {b}");
						return .RuntimeError;
					}
					Push(.Number(a.AsNumber() / b.AsNumber()));
					break;
				case .Negate:
					VmValue value = Pop();
					if(!value.IsNumber())
					{
						RuntimeError(scope $"Operand for negate bytecode must be a number. Bytecode: {bytecode}, Value: {value}");
						return .RuntimeError;
					}
					Push(.Number(-value.AsNumber()));
					break;
				case .Not:
					Push(.Bool(Pop().IsFalsey()));
					break;
				case .EqualEqual:
					VmValue b = Pop();
					VmValue a = Pop();
					Push(.Bool(a.EqualTo(b)));

					break;
				case .GreaterThan:
					VmValue b = Pop();
					VmValue a = Pop();
					if(!a.IsNumber() || !b.IsNumber())
					{
						RuntimeError(scope $"Operands for greater than bytecode must be a number. Bytecode: {bytecode}, a: {a}, b: {b}");
						return .RuntimeError;
					}
					Push(.Bool(a.AsNumber() > b.AsNumber()));
					break;
				case .LessThan:
					VmValue b = Pop();
					VmValue a = Pop();
					if(!a.IsNumber() || !b.IsNumber())
					{
						RuntimeError(scope $"Operands for less than bytecode must be a number. Bytecode: {bytecode}, a: {a}, b: {b}");
						return .RuntimeError;
					}
					Push(.Bool(a.AsNumber() < b.AsNumber()));

					break;
				case .Value:
						u32 constantIndex = *(u32*)&_binary.Bytecodes[_binaryPos + 1];
						_binaryPos += 4;
						Push(_binary.Constants[constantIndex]);
						break;
				case .Pop:
						Pop();
						break;
				default:
					break;
				}

				_binaryPos++;
			}

			return .Ok;
		}

		public void Emit(Bytecode bytecode)
		{
			_binary.Emit(bytecode);
		}

		public void EmitValue(VmValue value)
		{
			_binary.EmitValue(value);
		}

		//Reset vm state. Clear stack, bytecode, and constants
		public void Reset()
		{
			_binary.Reset();
			_stackPos = 0;
		}

		//Parse script and generate bytecode from it
		public VmResult Parse(StringView source)
		{
			return _compiler.Parse(_binary, source);
		}

		public void PrintState()
		{
			//Todo: Move into VM
			Console.WriteLine("Writing VM state:");
			Console.WriteLine("Stack state:");
			for(u32 i = 0; i < _stackPos; i++)
			{
				VmValue value = _stack[i];
				Console.WriteLine($"    [{i}]: {value}");
			}

			u32 i = 0;
			u32 bytecodeCount = 0;
			Console.WriteLine("Disassembled bytecode:");
			while(i < _binary.Bytecodes.Count)
			{
				Bytecode bytecode = _binary.Bytecodes[i];
				if(bytecode == .Value)
				{
					u32 constantIndex = *(u32*)&_binary.Bytecodes[i + 1];
					VmValue value = _binary.Constants[constantIndex];
					Console.WriteLine($"    [{bytecodeCount}]: {bytecode.ToString(.. scope String())}, {value}");
					i += 5;
				}
				else
				{
					Console.WriteLine($"    [{bytecodeCount}]: {bytecode.ToString(.. scope String())}");
					i++;
				}
				bytecodeCount++;
			}
		}

		private void RuntimeError(StringView message)
		{
			Console.WriteLine($"[Line {_binary.Lines[_binaryPos]}] Runtime error: '{message}'");
		}
	}
}
