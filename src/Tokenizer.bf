using System.Collections;
using System;

namespace VmScriptingFun
{
	//Converts source code into useful elements called tokens. Outputs tokens on demand.
	public class Tokenizer
	{
		private StringView _source;
		private u32 _pos = 0;
		private u32 _line = 0;
		private char8[24] _invalidIdentifierCharacters = .(' ', '\n', '\t', '\0', '(', ')', '{', '}',
			',', '.', '=', '!', '+', '-', '*', '/', '^',
			'%', '?', '>', '<', '!', ':', ';');
		private char8[23] _invalidNumberCharacters = .(' ', '\n', '\t', '\0', '(', ')', '{', '}',
			',', '=', '!', '+', '-', '*', '/', '^',
			'%', '?', '>', '<', '!', ':', ';');

		//Set source string. Doesn't take ownership of string. The string must stay alive until the tokenizer is destroyed.
		public void SetSource(StringView source)
		{
			_source = source;
			_pos = 0;
			_line = 0;
		}

		//Get next token
		public Token Next()
		{
			if(_pos >= _source.Length)
				return .(.Eof, "EOF", _line);

			//return .(.None, _source.Substring(_pos++, 1));
			while(_pos < _source.Length)
			{
				char8 character = _source[_pos++];
				if(IsIgnoredCharacter(character))
					continue;

				//TODO: Make mixin for adding two character tokens to shorten this switch
				switch(character)
				{
				case '(':
					return .(.ParenthesesLeft, "(", _line);
				case ')':
					return .(.ParenthesesRight, ")", _line);
				case '=':
					if(At("="))
					{
						_pos++;
						return .(.EqualEqual, "==", _line);
					}
					else
					{
						return .(.Equal, "=", _line);
					}
				case '>':
					if(At("="))
					{
						_pos++;
						return .(.GreaterThanOrEqual, ">=", _line);
					}
					else
					{
						return .(.GreaterThan, ">", _line);
					}
				case '<':
					if(At("="))
					{
						_pos++;
						return .(.LessThanOrEqual, "<=", _line);
					}
					else
					{
						return .(.LessThan, "<", _line);
					}
				case '+':
					return .(.Plus, "+", _line);
				case '-':
					return .(.Minus, "-", _line);
				case '*':
					return .(.Asterisk, "*", _line);
				case '/':
					return .(.Slash, "/", _line);
				case ';':
					return .(.Semicolon, ";", _line);
				case '!':
					if(At("="))
					{
						_pos++;
						return .(.NotEqual, "!=", _line);
					}
					else
					{
						return .(.ExclamationMark, "!", _line);
					}
				case 't':
					if(At("rue"))
					{
						_pos += 3;
						return .(.True, "true", _line);
					}
					break;
				case 'f':
					if(At("alse"))
					{
						_pos += 4;
						return .(.False, "false", _line);
					}

					break;
				case 'n':
					if(At("ull"))
					{
						_pos += 3;
						return .(.Null, "null", _line);
					}
				case 'v':
					if(At("ar"))
					{
						_pos += 2;
						return .(.Var, "var", _line);
					}
				default:
					break;
				}

				//Attempt to read literal if not a keyword or operator
				_pos--; //Decrease _pos to revert previous read
				var maybeLiteral = TryReadLiteralOrIdentifier(_source[_pos]);
				if(maybeLiteral == .Err)
					return .(.Error, "Invalid literal error", _line);
				else
					return maybeLiteral.Value;
			}

			return .(.Eof, "EOF", _line);
		}

		//Returns true if the provided string is present at the current position
		private bool At(StringView string)
		{
			if(_pos + string.Length - 1 > _source.Length)
				return false;

			var substring = _source.Substring(_pos, string.Length);
			return string == substring;
		}

		//Returns true if the character is ignored by the tokenizer
		private bool IsIgnoredCharacter(char8 character)
		{
			return character == ' ' || character == '\n' || character == '\t' || character == '\0' || character == '\r';
		}

		//Returns true if the character is a number
		private bool IsNumber(char8 character)
		{
			return character >= '0' && character <= '9';
		}

		//Returns true if the character is a letter or underscore
		private bool IsAlpha(char8 character)
		{
			return (character >= 'a' && character <= 'z') || (character >= 'A' && character <= 'Z') || character == '_';
		}

		//Returns true if the character isn't permitted in identifiers
		private bool IsInvalidIdentifierCharacter(char8 character)
		{
			for(var _invalidChar in _invalidIdentifierCharacters)
				if(_invalidChar == character)
					return true;

			return false;
		}

		//Returns true if the character isn't permitted in numbers
		private bool IsInvalidNumberCharacter(char8 character)
		{
			for(var _invalidChar in _invalidNumberCharacters)
				if(_invalidChar == character)
					return true;

			return false;
		}

		//Attempts to read a literal token (number, identifier, string)
		private Result<Token> TryReadLiteralOrIdentifier(char8 character)
		{
			//Determine token type
			TokenType tokenType = .None;
			if(character == '"')
				tokenType = .String;
			else if (IsNumber(character))
				tokenType = .Number;
			else if (IsAlpha(character))
				tokenType = .Identifier;
			else
				return .Err;

			//Get token sub string and return it
			u32 identifierEnd = 0;
			if(tokenType == .Number)
			{
				for (identifierEnd = _pos; identifierEnd < _source.Length; identifierEnd++)
					if (IsInvalidNumberCharacter(_source[identifierEnd]))
						break;
			}
			else if(tokenType == .String)
			{
				for (identifierEnd = _pos + 1; identifierEnd < _source.Length; identifierEnd++)
					if (_source[identifierEnd] == '"')
					{
						identifierEnd++;
						break;
					}
			}
			else if(tokenType == .Identifier)
			{
				for (identifierEnd = _pos; identifierEnd < _source.Length; identifierEnd++)
					if (IsInvalidIdentifierCharacter(_source[identifierEnd]))
						break;
			}


			//Get substring and return token
			u32 substringLength = identifierEnd - _pos;
			_pos += substringLength;

			if(tokenType == .String)
				return .Ok(.(tokenType, _source.Substring(_pos - substringLength + 1, substringLength - 2), _line));
			else
				return .Ok(.(tokenType, _source.Substring(_pos - substringLength, substringLength), _line));
		}
	}
}