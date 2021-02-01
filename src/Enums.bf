using System;

namespace VmScriptingFun
{
	//Instructions ran by the VM
	public enum Bytecode : u8
	{
		Nop,
		Add, //Pop top two values from the stack. Add together. Push result onto stack.
		Subtract, //Pop top two values from the stack. Subtract together. Push result onto stack.
		Multiply, //Pop top two values from the stack. Multiply together. Push result onto stack.
		Divide, //Pop top two values from the stack. Divide first value by second. Push result onto stack.
		Value, //Push value onto the stack. 4 byte unsigned integer follows it in bytecode blob
		Pop, //Pop value off the top of stack
		Negate, //Negate value at the top of the stack
		Not, //Negate boolean value
		EqualEqual, //Pop two values off of stack. Push true onto stack if a == b, and false if not
		GreaterThan, //Pop two values off of stack. Push true onto stack a > b, false if not
		LessThan, //Pop two values off of stack. Push true onto stack a < b, false if not
		DefineGlobal, //Assigns value at the top of the stack to a global variable
		GetGlobal, //Get global name and push it onto the stack
		SetGlobal, //Set value of global at the top of the stack
	}

	//Token identifier
	public enum TokenType
	{
		//Default value
		None,

		//Single character tokens
		ParenthesesLeft, ParenthesesRight, Equal, NotEqual, Plus, Minus, Asterisk, Slash, Semicolon, ExclamationMark,
		GreaterThan, LessThan,

		//Two character tokens
		GreaterThanOrEqual, LessThanOrEqual, EqualEqual,

		//Keywords
		True, False, Null, Var,

		//Literals
		Identifier, Number, String, 

		//Special
		Eof, Error
	}

	public enum VmValueType
	{
		Bool,
		Number,
		Null,
		Obj,
		String
	}

	//Heap allocated object
	public class VmObject
	{
		public void* Ptr;
		public u32 Size;

		public this(void* ptr, u32 size)
		{
			Ptr = ptr;
			Size = size;
		}

		public ~this()
		{
			delete Ptr;
		}

		public VmObject Copy()
		{
			u8[] newObj = new u8[Size];
			return new VmObject((void*)(u8[]*)&newObj, Size);
		}
	}

	//Variable value
	public enum VmValue
	{
	    case Bool(bool value);
	    case Number(f64 value);
		case Null;
		case Obj(VmObject obj);
		case String(String string);

		public bool IsNumber() => ValueType() == .Number;
		public bool IsBool() => ValueType() == .Bool;
		public bool IsNull() => ValueType() == .Null;
		public bool IsObj() => ValueType() == .Obj;
		public bool IsString() => ValueType() == .String;
		//Returns true if the value can be interpreted as boolean false (so either null or false)
		public bool IsFalsey() mut => IsNull() || (IsBool() && !AsBool());
		//Return true if the value is heap allocated
		public bool IsHeapAllocated() mut => IsObj() || IsString();
		public bool AsBool() mut => *(bool*)&this;
		public f64 AsNumber() mut => *(f64*)&this;
		public VmObject AsObj() mut => *(VmObject*)&this;
		public String AsString() mut => *(String*)&this;
		public bool EqualTo(VmValue b)
		{
			if(ValueType() != b.ValueType())
				return false;

			var temp = b; //Move into temp var so we can use mutable functions AsBool() and AsNumber()
			switch(this)
			{
			case .Bool(let value):
				return value == temp.AsBool();
			case .Number(let value):
				return value == temp.AsNumber();
			case .Null:
				return true;
			case .Obj(let obj):
				return obj == temp.AsObj();
			case .String(let string):
				return string == temp.AsString();
			}
		}
		//Return number representing enum type
		public VmValueType ValueType()
		{
			switch(this)
			{
			case .Bool(let value):
				return .Bool;
			case .Number(let value):
				return .Number;
			case .Null:
				return .Null;
			case .Obj(let obj):
				return .Obj;
			case .String(let string):
				return .String;
			}
		}
		//Free any heap allocated objects
		public void DeleteHeapAllocatedData() mut
		{
			if(IsString())
				delete AsString();
			else if(IsObj())
				delete AsObj();
		}	
	}

	//VM function result
	public enum VmResult
	{
		Ok,
		CompileError,
		RuntimeError
	}
}
