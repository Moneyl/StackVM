using System;

namespace VmScriptingFun
{
	public static class Program
	{
		public static void Main()
		{
			var vm = new VM();
			defer delete vm;
			Console.WriteLine($"Created VM. Stack size: {vm.[Friend]_binary.Count}");
			Console.WriteLine("Creating binary...\n");

			vm.AddValueBytecode(2);
			vm.AddValueBytecode(5);
			vm.AddBytecode(.Add);
			vm.AddBytecode(.Print);

			Console.WriteLine("Interpreting bytecode... ");
			vm.Interpret();
			Console.WriteLine("Done!\n");

			//Todo: Move into VM
			Console.WriteLine("Writing VM state:");
			Console.WriteLine("Stack state:");
			for(u32 i = 0; i < vm.[Friend]_stackPos; i++)
			{
				u32 value = vm.[Friend]_stack[i];
				Console.WriteLine($"    [{i}]: {value}");
			}

			//Todo: Move into VM
			u32 i = 0;
			u32 bytecodeCount = 0;
			Console.WriteLine("Disassembled bytecode:");
			while(i < vm.[Friend]_binary.Count)
			{
				Bytecode bytecode = vm.[Friend]_binary[i];
				if(bytecode == .Value)
				{
					u32 value = *(u32*)&vm.[Friend]_binary[i + 1];
					Console.WriteLine($"    [{bytecodeCount}]: {bytecode.ToString(.. scope String())}, {value}");
					i += 5;
				}
				else
				{
					Console.WriteLine($"    [{bytecodeCount}]: {bytecode.ToString(.. scope String())}");
					i++;
				}
				bytecodeCount++;
			}

			Console.WriteLine("\nPress any key to exit.");
			Console.Read();
		}
	}
}
