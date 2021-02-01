using System.Collections;
using System;

namespace VmScriptingFun
{
	//Converts scripts to bytecode
	public class BytecodeCompiler
	{
		//Operation precence. Lower values have lower precedence.
		private enum Precedence
		{
			None,
			Assignment, //=
			Or, //or
			And, //and
			Equality, //==, !=
			Comparison, //<, >, <=, >=
			Term, //+, -
			Factor, //*, /
			Unary, //!, -
			Call, //., ()
			Primary
		}

		//Rule for parsing a specific token
		private struct ParseRule
		{
			public readonly function void(BytecodeCompiler this, bool canAssign) Prefix;
			public readonly function void(BytecodeCompiler this, bool canAssign) Infix;
			public readonly Precedence PrecedenceLevel;

			public this(function void(BytecodeCompiler this, bool canAssign) prefix, function void(BytecodeCompiler this, bool canAssign) infix, Precedence precedenceLevel)
			{
				Prefix = prefix;
				Infix = infix;
				PrecedenceLevel = precedenceLevel;
			}
		}

		private Tokenizer _tokenizer = new Tokenizer() ~delete _;
		private BinaryBlob _binary;
		private Token _current = .(.None, "None", 0);
		private Token _previous;
		private bool _hadError = false;
		private ParseRule[25] _parseRules = .();

		public this()
		{
			_parseRules[(u32)TokenType.None] = .(null, null, .None);
			_parseRules[(u32)TokenType.ParenthesesLeft] = .(=> Grouping, null, .None);
			_parseRules[(u32)TokenType.ParenthesesRight] = .(null, null, .None);
			_parseRules[(u32)TokenType.Equal] = .(null, null, .None);
			_parseRules[(u32)TokenType.NotEqual] = .(null, => Binary, .Equality);
			_parseRules[(u32)TokenType.Plus] = .(null, => Binary, .Term);
			_parseRules[(u32)TokenType.Minus] = .(=> Unary, => Binary, .Term);
			_parseRules[(u32)TokenType.Asterisk] = .(null, =>  Binary, .Factor);
			_parseRules[(u32)TokenType.Slash] = .(null, => Binary, .Factor);
			_parseRules[(u32)TokenType.Semicolon] = .(null, null, .None);
			_parseRules[(u32)TokenType.ExclamationMark] = .(=> Unary, null, .None);
			_parseRules[(u32)TokenType.GreaterThan] = .(null, => Binary, .Comparison);
			_parseRules[(u32)TokenType.LessThan] = .(null, => Binary, .Comparison);
			_parseRules[(u32)TokenType.GreaterThanOrEqual] = .(null, => Binary, .Comparison);
			_parseRules[(u32)TokenType.LessThanOrEqual] = .(null, => Binary, .Comparison);
			_parseRules[(u32)TokenType.EqualEqual] = .(null, => Binary, .Equality);
			_parseRules[(u32)TokenType.True] = .(=> Literal, null, .None);
			_parseRules[(u32)TokenType.False] = .(=> Literal, null, .None);
			_parseRules[(u32)TokenType.Null] = .(=> Literal, null, .None);
			_parseRules[(u32)TokenType.Var] = .(null, null, .None);
			_parseRules[(u32)TokenType.Identifier] = .(=> Variable, null, .None);
			_parseRules[(u32)TokenType.Number] = .(=> Number, null, .None);
			_parseRules[(u32)TokenType.String] = .(=> String, null, .None);
			_parseRules[(u32)TokenType.Eof] = .(null, null, .None);
			_parseRules[(u32)TokenType.Error] = .(null, null, .None);
		}

		public VmResult Parse(BinaryBlob binary, StringView source)
		{
			//Output tokens for testing purposes. Don't have a use for them yet.
			_binary = binary;
			_tokenizer.SetSource(source);
			Advance();
			while(_current.Type != .Eof)
			{
				Declaration();
			}

			return _hadError ? .CompileError : .RuntimeError;
		}

		//Advance to next valid token
		private void Advance()
		{
			_previous = _current;
			for(;;)
			{
				_current = _tokenizer.Next();
				if(_current.Type != .Error)
					break;

				ErrorAtCurrent(_current.Value);
			}
		}

		//Consume a single token and check that it's the token we expect
		private void Consume(TokenType type, StringView message)
		{
			if (_current.Type == type)
			{
		    	Advance();
		    	return;
		 	}

		  	ErrorAtCurrent(message);
		}

		//Parse token at provided precedence level
		private void ParsePrecedence(Precedence precedence)
		{
			//Advance parser and get prefix function
			Advance();
			var prefixFunc = GetRule(_previous.Type).Prefix;
			if(prefixFunc == null)
			{
				ErrorAt(ref _current, "Expected token with valid prefix rule in expression."); //Todo: Make this error more useful to users
				return;
			}

			//Parse prefix tokens
			bool canAssign = precedence <= .Assignment; //Whether the precedence level is low enough to assign values to the prefix expression
			prefixFunc(this, canAssign);

			//Parse infix tokens until none remain
			while(precedence <= GetRule(_current.Type).PrecedenceLevel)
			{
				Advance();
				var infixFunc = GetRule(_previous.Type).Infix;
				infixFunc(this, canAssign);
			}

			if(canAssign && _current.Type == .Equal)
			{
				Advance();
				ErrorAtCurrent("Invalid assignment target.");
			}
		}

		//Parse variable declaration
		private void Declaration()
		{
			if(_current.Type == .Var)
			{
				Advance();
				VarDeclaration();
			}
			else
				Statement();

			//Handle errors. Moves to the end of this statement so we can check other statements for syntax errors
			if(_hadError)
				Synchronize();
		}

		//Parse variable name for assignment purposes
		private void Variable(bool canAssign)
		{
			NamedVariable(canAssign);
		}

		private void NamedVariable(bool canAssign)
		{
			u32 nameConstantIndex = CreateConstant(.String(new String(_previous.Value)));
			if(canAssign && _current.Type == .Equal) //If equal sign is present, we're setting a global value
			{
				Advance();
				Expression();
				Emit(.SetGlobal);
				EmitInlineValue(nameConstantIndex);
			}
			else //Else we're getting a global value
			{
				Emit(.GetGlobal);
				EmitInlineValue(nameConstantIndex);
			}
		}

		//Parse variable declaration
		private void VarDeclaration()
		{
			//Consume identifier and create constant storing variable name
			u32 globalNameIndex = ParseVariable("Variable identifier expected after 'var'.");

			//Emit expression which the variable is being set to
			if(_current.Type == .Equal)
			{
				Advance();
				Expression();
			}
			else
				EmitValue(.Null); //Set variable to null if no value is provided

			//Emit global variable bytecode
			Consume(.Semicolon, "Semicolon expected after variable declaration.");
			DefineGlobalVariable(globalNameIndex);
		}

		//Read variable identifier string and add it to the binary constants list. Return name constant index.
		private u32 ParseVariable(StringView message)
		{
			u32 constantIndex = CreateConstant(.String(new String(_current.Value)));
			Consume(.Identifier, message);
			return constantIndex;
		}

		//Emit bytecode defining a global variable
		private void DefineGlobalVariable(u32 nameStringIndex)
		{
			Emit(.DefineGlobal);
			EmitInlineValue(nameStringIndex);
		}

		//Parse statement
		private void Statement()
		{
			ExpressionStatement();
		}

		//Parse expression statement
		private void ExpressionStatement()
		{
			Expression();
			Consume(.Semicolon, "Expressions must end with a semicolon ';'");
			Emit(.Pop);
		}

		//Parse a number token
		private void Number(bool canAssign)
		{
			f64 value = f64.Parse(_previous.Value);
			EmitValue(.Number(value));
		}

		//Parse string token
		private void String(bool canAssign)
		{
			EmitValue(.String(new String(_previous.Value)));
		}

		//Parse a literal (bool, null, string)
		private void Literal(bool canAssign)
		{
			switch(_previous.Type)
			{
			case .True:
				EmitValue(.Bool(true));
				break;
			case .False:
				EmitValue(.Bool(false));
				break;
			case .Null:
				EmitValue(.Null);
				break;
			default:
				return;
			}
		}

		//Parse a set of grouping tokens (E.g. parentheses)
		private void Grouping(bool canAssign)
		{
			Expression();
			Consume(.ParenthesesRight, "Expected closing parentheses ')'.");
		}

		//Parse an expression
		private void Expression()
		{
			ParsePrecedence(.Assignment);
		}

		//Parse unary operator
		private void Unary(bool canAssign)
		{
			TokenType operatorType = _previous.Type;

			//Parse the operand
			ParsePrecedence(.Unary);

			//Emit the operator instruction.
		  	switch (operatorType)
			{
		    case .Minus:
				Emit(.Negate);
				break;
			case .ExclamationMark:
				Emit(.Not);
				break;
		    default:
		      return;
		  	}
		}

		//Parse binary expression
		void Binary(bool canAssign)
		{
			//Remember the operator.
		  	TokenType operatorType = _previous.Type;

		  	//Compile the right operand.
		  	var rule = GetRule(operatorType);
		  	ParsePrecedence((Precedence)(rule.PrecedenceLevel + 1));

		  	//Emit the operator instruction.
		  	switch (operatorType)
			{
		    case .Plus:
				Emit(.Add);
				break;
		    case .Minus:
				Emit(.Subtract);
				break;
		    case .Asterisk:
				Emit(.Multiply);
				break;
		    case .Slash:
				Emit(.Divide);
			case .NotEqual:
				Emit(.EqualEqual);
				Emit(.Not);
				break;
			case .EqualEqual:
				Emit(.EqualEqual);
				break;
			case .GreaterThan:
				Emit(.GreaterThan);
				break;
			case .GreaterThanOrEqual:
				Emit(.LessThan);
				Emit(.Not);
				break;
			case .LessThan:
				Emit(.LessThan);
				break;
			case .LessThanOrEqual:
				Emit(.GreaterThan);
				Emit(.Not);
				break;
		    default:
		      return;
		  	}
		}

		private ParseRule* GetRule(TokenType tokenType)
		{
			return &_parseRules[(u32)tokenType];
		}

		//Emit bytecode
		private void Emit(Bytecode bytecode)
		{
			_binary.Bytecodes.Add(bytecode);
			_binary.Lines.Add(_current.Line);
		}

		//Emit value bytecode followed by 4 byte signed integer which is the index of the constant the value bytecode represents. Returns index of created constant.
		private u32 EmitValue(VmValue value)
		{
			Emit(.Value);
			EmitInlineValue((u32)_binary.Constants.Count);

			//Add value to constants list
			_binary.Constants.Add(value);

			//Return constant index
			return (u32)_binary.Constants.Count;
		}

		//Emit 4 byte value inline with the bytecode
		private void EmitInlineValue(u32 value)
		{
			//Ensure there's enough room for the value
			if(_binary.Bytecodes.Capacity < _binary.Bytecodes.Count + 4)
				_binary.Bytecodes.Reserve(_binary.Bytecodes.Capacity + 4);

			//Emit constant index by interpreting next 4 bytes as a single u32
			u32* valuePtr = (u32*)((&_binary.Bytecodes.Back) + 1);
			*valuePtr = value;
			_binary.Bytecodes.[Friend]mSize += 4; //Manually update internal pos counter for list

			_binary.Lines.Add(_current.Line);
			_binary.Lines.Add(_current.Line);
			_binary.Lines.Add(_current.Line);
			_binary.Lines.Add(_current.Line);
		}

		//Create constant and return it's index.
		public u32 CreateConstant(VmValue value)
		{
			_binary.Constants.Add(value);
			return (u32)_binary.Constants.Count - 1;
		}

		//Called when an error is encountered. Moves to the next statement so other lines can be checked for errors.
		private void Synchronize()
		{
			_hadError = false;

			//Loop until end of file or next statement
			while (_current.Type != .Eof)
			{
				if (_previous.Type == .Semicolon)
					return;

			  	switch (_current.Type)
				{
			    //case .Class
			    //case .Function:
			    //case .Var:
			    //case .For:
			    //case .If:
			    //case .While:
			    //case .Return:
			    //  return;

			    default:
			      // Do nothing.
				}
			}

			Advance();
		}

		//Report error at provided token
		private void ErrorAt(ref Token token, StringView message)
		{
			Console.Write($"[Line {_current.Line}] Error");
			if(token.Type == .Eof)
				Console.Write(" at end of file");
			else
				Console.Write($" at '{token.Value}'");

			Console.Write($": {message}\n");
		  	_hadError = true;
		}

		//Report error at current token
		private void ErrorAtCurrent(StringView message)
		{
			ErrorAt(ref _current, message);
		}
	}
}
