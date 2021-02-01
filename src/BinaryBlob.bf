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

		//Reset state and free heap allocated data
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
