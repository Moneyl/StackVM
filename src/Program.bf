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
			Console.WriteLine($"Created VM.");
			Console.WriteLine("Creating binary...\n");

			//Load and parse source code file
			var sourceString = File.ReadAllText(scope $"{BuildConfig.AssetsBasePath}/Test0.script", .. scope String());
			Console.WriteLine("Tokenizing source code...");
			vm.Parse(sourceString);

			Console.WriteLine("Interpreting bytecode... ");
			vm.Interpret();
			Console.WriteLine("Done!\n");

			//Write internal state to console
			vm.PrintState();

			//Benchmark VM interpreter speed
			Console.WriteLine("\nBenchmarking VM...");
			BenchmarkVm(vm, sourceString);

			//Wait for input so the console doesn't close immediately
			Console.WriteLine("\nPress any key to exit.");
			Console.Read();
		}

		//Benchmark VM interpreter speed
		public static void BenchmarkVm(VM vm, StringView sourceString)
		{
			//Main purpose of benchmarks is to test the performance effects of different vm changes/optimizations
			u32 numBenchmarkRuns = 5000;
			var timer = scope Stopwatch(false);
			var times = scope List<f64>(); //Sample times in ms
			times.Reserve(numBenchmarkRuns);
			for(u32 j = 0; j < numBenchmarkRuns; j++)
			{
				vm.Reset();
				timer.Restart();
				vm.Parse(sourceString);
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
