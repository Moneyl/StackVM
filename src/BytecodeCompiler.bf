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
			public readonly function void(BytecodeCompiler this) Prefix;
			public readonly function void(BytecodeCompiler this) Infix;
			public readonly Precedence PrecedenceLevel;

			public this(function void(VmScriptingFun.BytecodeCompiler this) prefix, function void(VmScriptingFun.BytecodeCompiler this) infix, Precedence precedenceLevel)
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
		private ParseRule[24] _parseRules = .();

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
			_parseRules[(u32)TokenType.Identifier] = .(null, null, .None);
			_parseRules[(u32)TokenType.Number] = .(=> Number, null, .None);
			_parseRules[(u32)TokenType.String] = .(null, null, .None);
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
				Expression();
				Consume(.Semicolon, "Expressions must end with a semicolon ';'");
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
			prefixFunc(this);

			//Parse infix tokens until none remain
			while(precedence <= GetRule(_current.Type).PrecedenceLevel)
			{
				Advance();
				var infixFunc = GetRule(_previous.Type).Infix;
				infixFunc(this);
			}	
		}

		//Parse a number token
		private void Number()
		{
			f64 value = f64.Parse(_previous.Value);
			EmitValue(.Number(value));
		}

		//Parse a literal (bool, null, string)
		private void Literal()
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
		private void Grouping()
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
		private void Unary()
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
		void Binary()
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
			_binary.Emit(bytecode);
			_binary.Lines.Add(_current.Line);
		}

		//Emit value bytecode followed by 4 byte signed integer
		private void EmitValue(VmValue value)
		{
			_binary.EmitValue(value);
			//Emit line 5 times since EmitValue takes up 5 bytes
			_binary.Lines.Add(_current.Line);
			_binary.Lines.Add(_current.Line);
			_binary.Lines.Add(_current.Line);
			_binary.Lines.Add(_current.Line);
			_binary.Lines.Add(_current.Line);
		}

		//Report error at provided token
		private void ErrorAt(ref Token token, StringView message)
		{
			Console.Write($"[Line {_current.Line}] Error");

			if(token.Type == .Eof)
			{
				Console.Write(" at end of file");
			}
			else if(token.Type == .Error)
			{

			}
			else
			{
				Console.Write($" at '{token.Value}'");
			}

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
