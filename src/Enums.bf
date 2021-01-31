

namespace VmScriptingFun
{
	//Instructions ran by the VM
	public enum Bytecode : u8
	{
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
		True, False, Null,

		//Literals
		Identifier, Number, String, 

		//Special
		Eof, Error
	}

	public enum VmValueType
	{
		Bool,
		Number,
		Null
	}

	//Variable value
	public enum VmValue
	{
	    case Bool(bool value);
	    case Number(f64 value);
		case Null;

		public bool IsNumber()
		{
			switch(this)
			{
			case .Number(let value):
				return true;
			default:
				return false;
			}
		}
		public bool IsBool()
		{
			switch(this)
			{
			case .Bool(let value):
				return true;
			default:
				return false;
			}
		}
		public bool IsNull()
		{
			switch(this)
			{
			case .Null:
				return true;
			default:
				return false;
			}
		}
		//Returns true if the value can be interpreted as boolean false (so either null or false)
		public bool IsFalsey() mut
		{
			return IsNull() || (IsBool() && !AsBool());
		}
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
				return  true;
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
			}
		}
		public bool AsBool() mut => *(bool*)&this;
		public f64 AsNumber() mut => *(f64*)&this;
		
	}

	//VM function result
	public enum VmResult
	{
		Ok,
		CompileError,
		RuntimeError
	}
}
