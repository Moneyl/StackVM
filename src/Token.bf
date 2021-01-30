using System;

namespace VmScriptingFun
{
	//Source code element. Output of Tokenizer
	public struct Token
	{
		public readonly TokenType Type;
		public readonly StringView Value;

		public this(TokenType type, StringView value)
		{
			Type = type;
			Value = value;
		}
	}
}
