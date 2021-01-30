using System.Collections;
using System.Diagnostics;
using System.IO;
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

			//Load and parse source code file
			var sourceString = File.ReadAllText(scope $"{BuildConfig.AssetsBasePath}/Test0.script", .. scope String());
			vm.Parse(sourceString);

			//Equal to: X = (10 + 15) - (2 + 3)
			vm.AddValueBytecode(2);
			vm.AddValueBytecode(3);
			vm.AddBytecode(.Add);
			vm.AddValueBytecode(15);
			vm.AddValueBytecode(10);
			vm.AddBytecode(.Add);
			vm.AddBytecode(.Subtract);
			vm.AddBytecode(.Print);
			vm.AddBytecode(.SetX);
			vm.AddBytecode(.TestPrint);

			Console.WriteLine("\nInterpreting bytecode... ");
			vm.Interpret();
			Console.WriteLine("Done!\n");

			//Todo: Move into VM
			Console.WriteLine("Writing VM state:");
			Console.WriteLine("Stack state:");
			for(u32 i = 0; i < vm.[Friend]_stackPos; i++)
			{
				i32 value = vm.[Friend]_stack[i];
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
					i32 value = *(i32*)&vm.[Friend]_binary[i + 1];
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

			//Benchmark VM interpreter speed
			BenchmarkVm(vm);

			//Wait for input so the console doesn't close immediately
			Console.WriteLine("\nPress any key to exit.");
			Console.Read();
		}

		//Benchmark VM interpreter speed
		public static void BenchmarkVm(VM vm)
		{
			//Custom bytecode for benchmarks. No prints since they slow things down immensely
			//Main purpose of benchmarks is to test the performance effects of different vm changes/optimizations
			//Equal to: X = (10 + 15) - (2 + 3)
			vm.ClearBytecode();
			vm.AddValueBytecode(2);
			vm.AddValueBytecode(3);
			vm.AddBytecode(.Add);
			vm.AddValueBytecode(15);
			vm.AddValueBytecode(10);
			vm.AddBytecode(.Add);
			vm.AddBytecode(.Subtract);
			vm.AddBytecode(.SetX);

			u32 numBenchmarkRuns = 5000;
			var timer = scope Stopwatch(false);
			var times = scope List<f64>(); //Sample times in ms
			times.Reserve(numBenchmarkRuns);
			for(u32 j = 0; j < numBenchmarkRuns; j++)
			{
				vm.ClearStack();
				timer.Restart();
				vm.Interpret();
				timer.Stop();
				times.Add(timer.Elapsed.TotalMilliseconds);
			}

			//Calculate average and print result
			f64 average = 0.0f;
			for(u32 j = 0; j < numBenchmarkRuns; j++)
				average += times[j];

			average /= numBenchmarkRuns;
			Console.WriteLine($"Average time after {numBenchmarkRuns} runs: {average:F4}ms | {average * 1000.0f:F4}us | {average * 1000000.0f:F4}ns");
		}
	}
}
