using System.Collections;
using System;

namespace VmScriptingFun
{
	//Stack based virtual machine. Runs bytecode
	public class VM
	{
		private VmValue[VMConfig.StackSize] _stack = .(); //Contains temporary variables and state. Data stored LIFO.
		private u32 _stackPos = 0; //Current position in the stack
		private u32 _stackSize = 0;

		//Global variables
		Dictionary<String, VmValue> _globals = new Dictionary<String, VmValue>() ~delete _;

		//Binary blob executed by the VM. Contains constants and bytecodes
		private BinaryBlob _binary = new BinaryBlob() ~delete _;
		private u32 _binaryPos = 0;

		//Converts a script string to bytecode
		private BytecodeCompiler _compiler = new BytecodeCompiler() ~delete _;

		public this()
		{

		}

		public ~this()
		{
			//Reset state and free heap resources
			Reset();
		}

		private void Push(VmValue value)
		{
			//Ensure no stack overflow
#if DEBUG
			Runtime.Assert(_stackPos < VMConfig.StackSize, "Stack overflow occurred in VM.");
#endif

			_stack[_stackPos++] = value;
			_stackSize++;
		}

		private VmValue Pop()
		{
			//Ensure stack isn't empty
#if DEBUG
			Runtime.Assert(_stackPos > 0, "Tried to pop a value from an empty stack in the VM.");
#endif
			_stackSize--;
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
			while(_binaryPos < _binary.Bytecodes.Count)
			{
				var result = Step();
				if(result != .Ok)
					return result;
			}

			return .Ok;
		}

		//Interpret a single bytecode
		public VmResult Step()
		{
			if(_binaryPos >= _binary.Bytecodes.Count)
				return .Ok;

			//Todo: See if array of function pointers indexed by bytecode value is faster/more reliably fast
			//Interpret bytecode
			Bytecode bytecode = _binary.Bytecodes[_binaryPos];
			switch(bytecode)
			{
			case .Add:
				VmValue b = Pop();
				VmValue a = Pop();
				if(a.IsNumber() && b.IsNumber())
				{
					Push(.Number(a.AsNumber() + b.AsNumber()));
				}
				else if(a.IsString() && b.IsString())
				{
					Push(.String(new String()..AppendF("{}{}", a.AsString(), b.AsString())));
				}
				else
				{
					RuntimeError(scope $"Operands for add bytecode must be a number. Bytecode: {bytecode}, a: {a}, b: {b}");
					return .RuntimeError;
				}

				//Delete heap data if present (for strings and objects)
				a.DeleteHeapAllocatedData();
				b.DeleteHeapAllocatedData();
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

				//Delete heap data if present (for strings and objects)
				a.DeleteHeapAllocatedData();
				b.DeleteHeapAllocatedData();
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
				//Get value from constant list
				u32 constantIndex = *(u32*)&_binary.Bytecodes[_binaryPos + 1];
				_binaryPos += 4;
				var value = _binary.Constants[constantIndex];

				//Push value onto stack. Makes a copy if the value is heap allocated
				if(value.IsString())
					Push(.String(new String(value.AsString())));
				else if(value.IsObj())
					Push(.Obj(value.AsObj().Copy()));
				else
					Push(value);

				break;
			case .DefineGlobal:
				//Get global name string
				u32 constantIndex = *(u32*)&_binary.Bytecodes[_binaryPos + 1];
				_binaryPos += 4;
				VmValue globalName = _binary.Constants[constantIndex];

				//Set global value with stack top
				_globals[globalName.AsString()] = GetStackTop();
				break;
			case .GetGlobal:
				//Get global name string and check that the variable exists
				u32 constantIndex = *(u32*)&_binary.Bytecodes[_binaryPos + 1];
				_binaryPos += 4;
				VmValue globalName = _binary.Constants[constantIndex];
				if(!_globals.ContainsKey(globalName.AsString()))
				{
					RuntimeError(scope $"Undefined global variable {globalName.AsString()}");
					return .RuntimeError;
				}

				//Push global onto stack
				VmValue global = _globals[globalName.AsString()];
				if(global.IsString())
					Push(.String(new String(global.AsString())));
				else if(global.IsObj())
					Push(.Obj(global.AsObj().Copy()));
				else
					Push(global);
				break;
			case .SetGlobal:
				//Get global name string and check that the variable exists
				u32 constantIndex = *(u32*)&_binary.Bytecodes[_binaryPos + 1];
				_binaryPos += 4;
				VmValue globalName = _binary.Constants[constantIndex];
				if(!_globals.ContainsKey(globalName.AsString()))
				{
					RuntimeError(scope $"Undefined global variable {globalName.AsString()}");
					return .RuntimeError;
				}

				//Set global value with stack top
				_globals[globalName.AsString()] = GetStackTop();

				break;
			case .Pop:
				var value = Pop();
				value.DeleteHeapAllocatedData();
				break;
			default:
				break;
			}

			_binaryPos++;
			return .Ok;
		}

		//Reset vm state. Clear stack, bytecode, and constants
		public void Reset()
		{
			_binary.Reset();
			_globals.Clear();
			//Delete heap allocated values
			for(u32 i = 0; i < _stackPos; i++)
			{
				var value = ref _stack[i];
				if(value.IsHeapAllocated())
					value.DeleteHeapAllocatedData();
			}
			_stackPos = 0;
			_stackSize = 0;
			_binaryPos = 0;
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
			Console.WriteLine("Global variables:");
			for(var global in _globals)
			{
				Console.WriteLine($"    {global.key} = {global.value}");
			}

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
				if(bytecode == .Value || bytecode == .DefineGlobal || bytecode == .GetGlobal || bytecode == .SetGlobal)
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
