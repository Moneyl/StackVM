using System;

namespace VmScriptingFun
{
	//Source code element. Output of Tokenizer
	public struct Token
	{
		public readonly TokenType Type;
		public readonly StringView Value;
		public readonly u32 Line;

		public this(TokenType type, StringView value, u32 line)
		{
			Type = type;
			Value = value;
			Line = line;
		}
	}
}
