using System.Collections;
using System;

namespace VmScriptingFun
{
	//Converts scripts to bytecode
	public class Compiler
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
			public readonly function void(VmScriptingFun.Compiler this) Prefix;
			public readonly function void(VmScriptingFun.Compiler this) Infix;
			public readonly Precedence PrecedenceLevel;

			public this(function void(VmScriptingFun.Compiler this) prefix, function void(VmScriptingFun.Compiler this) infix, Precedence precedenceLevel)
			{
				Prefix = prefix;
				Infix = infix;
				PrecedenceLevel = precedenceLevel;
			}
		}

		private Tokenizer _tokenizer = new Tokenizer() ~delete _;
		private List<Bytecode> _binary;
		private Token _current = .(.None, "None", 0);
		private Token _previous;
		private bool _hadError = false;
		private ParseRule[13] _parseRules = .();

		public this()
		{
			_parseRules[(u32)TokenType.None] = .(null, null, .None);
			_parseRules[(u32)TokenType.ParenthesesLeft] = .(=> Grouping, null, .None);
			_parseRules[(u32)TokenType.ParenthesesRight] = .(null, null, .None);
			_parseRules[(u32)TokenType.Equals] = .(null, null, .None);
			_parseRules[(u32)TokenType.Plus] = .(null, => Binary, .Term);
			_parseRules[(u32)TokenType.Minus] = .(=> Unary, => Binary, .Term);
			_parseRules[(u32)TokenType.Asterisk] = .(null, =>  Binary, .Factor);
			_parseRules[(u32)TokenType.Slash] = .(null, => Binary, .Factor);
			_parseRules[(u32)TokenType.Semicolon] = .(null, null, .None);
			_parseRules[(u32)TokenType.Identifier] = .(null, null, .None);
			_parseRules[(u32)TokenType.Number] = .(=> Number, null, .None);
			_parseRules[(u32)TokenType.Eof] = .(null, null, .None);
			_parseRules[(u32)TokenType.Error] = .(null, null, .None);
		}

		public void Parse(List<Bytecode> binary, StringView source)
		{
			//Output tokens for testing purposes. Don't have a use for them yet.
			_binary = binary;
			_tokenizer.SetSource(source);
			Advance();
			Expression();
			Consume(.Eof, "Expected end of expression.");
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
			i32 value = i32.Parse(_previous.Value);
			EmitValue(value);
		}

		//Parse a set of grouping tokens (E.g. parentheses)
		private void Grouping()
		{
			Expression();
			Consume(.ParenthesesRight, "Expected ')' after expression.");
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
			Expression();

			//Emit the operator instruction.
		  	switch (operatorType)
			{
		    case .Minus:
				Emit(.Negate);
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
			_binary.Add(bytecode);
		}

		//Emit value bytecode followed by 4 byte signed integer
		private void EmitValue(i32 value)
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
