using System.Collections;
using System;

namespace VmScriptingFun
{
	//Binary blob. Executed by the VM
	public class BinaryBlob
	{
		public List<Bytecode> Bytecodes = new List<Bytecode>() ~delete _;
		public List<VmValue> Constants = new List<VmValue>() ~delete _;
		public List<u32> Lines = new List<u32>() ~delete _; //Line number of each bytecode

		//Emit bytecode
		public void Emit(Bytecode bytecode)
		{
			Bytecodes.Add(bytecode);
		}

		//Emit value bytecode and add value to constants list
		public void EmitValue(VmValue value)
		{
			//Ensure there's enough for the value bytecode and 4 byte constant index
			if(Bytecodes.Capacity < Bytecodes.Count + 5)
				Bytecodes.Reserve(Bytecodes.Capacity + 5);

			//Emit value
			Emit(.Value);

			//Emit constant index by interpreting next 4 bytes as a single u32
			u32* valuePtr = (u32*)((&Bytecodes.Back) + 1);
			*valuePtr = (u32)Constants.Count;
			Bytecodes.[Friend]mSize += 4;

			//Add value to constants list
			Constants.Add(value);
		}

		public void Reset()
		{
			Bytecodes.Clear();
			//Delete heap allocated values
			for(var value in Constants)
			{
				if(value.IsString())
					delete value.AsString();
				else if(value.IsObj())
					delete value.AsObj();
			}
			Constants.Clear();
		}
	}
}
